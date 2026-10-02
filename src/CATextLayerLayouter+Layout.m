//
//  CATextLayerLayouter+Layout.m
//  MulleGraphics
//
//  Copyright (c) 2025 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "CATextLayerLayouter+Layout.h"

#import "import-private.h"

#import "CATextLayerLayouter+RowsAndGlyphs.h"
#import "CATextLayerLayouter+Cursor.h"
#import "CATextLayer.h"


@implementation CATextLayerLayouter ( Layout)


/* MEMO: Font/Glyph scaling
 *
 * Truetype is a font format (we just care about truetype fonts)
 * Freetype is a font library that reads truetype fonts.
 *
 * Freetype has no dependency on opengl. Freetype returns a glyph either as a
 * vector or a bitmap (possibly rasterized from a vector font). We just care
 * about vector fonts though.
 *
 * This bitmap is transferred to a font atlas, basically a mega-texture.
 * This is done in the fons__ stuff. Confusingly, there is also an atlas in
 * nvg. But it does not seem to be used, at least as long as the fons__
 * stuff supplies glyphs ?
 *
 * Size conversion: A freetype/truetye  vector font has a height, that's fixed at 2048.
 * this is distributed to an ascender and a descender. So ascender - descender = 2048.
 * (Actually <= 2048, but we ignore that for now) https://www.freetype.org/freetype2/docs/tutorial/step2.html
 * `fons__tt_getPixelHeightScale` for example is defined as ` size / (font->font->ascender - font->font->descender)`
 * so basically `size / 2048`.
 *
 * The texture you get from freetype is upside down. So a d actually looks
 * like a q (sort of).
 *
 * The pipe glyph has a vertical overshoot of one pixel for Anonymous Pro.
 *
 * Even if you request LCD from a freetype front, you may get monochrome
 * instead. The fontstash library will correct this.
 *
 * By experiment, if running cleartype it makes no use to turn of cleartype
 * for monochrome or grayscale only fonts.
 *
 * Since emojis could be used from a fallback font, it maybe necessary to
 * split the string for multiple nvgText calls, setting the correct font
 * everytime.
 */

#if 0
static NSUInteger  count_newlines( mulle_utf8_t *s)
{
   mulle_utf32_t    c;
   mulle_utf32_t    d;
   NSUInteger       lf;

   // use code from nvg
   c  = 0;
   lf = 0;
   for(;*s;)
   {
      d = c;
      c = mulle_utf8_next_utf32character( &s);
      switch( c)
      {
      case '\n':
          if( d != '\r')
            ++lf;
         break;

      case 0x85:
      case '\r':
         ++lf;
         break;
      }
   }
   return( lf);
}
#endif

- (CGPoint) textOriginInRect:(CGRect) rect
                     context:(id <UILayoutContext>) context
{
   CGFloat                rowsHeight;
   CGFloat                textLineHeight;
   CGPoint                origin;
   CGRect                 visualBounds;
   NSUInteger             nRows;
   void                   *state;
   BOOL                   useVisualBounds;
   struct CGTextMetrics   *metrics;

   CATextLayerLayouterLog( CATextLayerLayouterDebugVerbose, "textOriginInRect: rect=%s", CGRectUTF8String( rect));

   state = [context pushGraphicsState];
   {
      [self updateRowsAndGlyphsWithContextIfNeeded:context];

      nRows = _mulle_structarray_get_count( &_rowArray);
      if( ! nRows)
         nRows = 1;

      textLineHeight = [_textLayer fontMetricsWithLayoutContext:context].textLineHeight;
      rowsHeight     = textLineHeight * nRows;

      // Determine bounds to use
      useVisualBounds = [_textLayer useVisualBounds];
      if( useVisualBounds)
      {
         visualBounds = [self visualBoundsWithContext:context];
         //boundsTop    = visualBounds.origin.y;

         _visualMetrics.ascender   = _metrics.ascender - visualBounds.origin.y;
         _visualMetrics.descender  = _visualMetrics.lineHeight - _visualMetrics.ascender;
         _visualMetrics.lineHeight = visualBounds.size.height / nRows;
         metrics                   = &_visualMetrics;
      }
      else
      {
         // Font metrics bounds
         // boundsTop    = 0.0;
         metrics      = &_metrics;
      }

      // Calculate the vertical origin. origin.y is the baseline of the first
      // row, measured from the top of the rect (the rect origin is added
      // later). See UITextVerticalAlignment for the meaning of each mode.
      //
      // single row:       Top      -> ascender
      //                   Bottom   -> height - descender
      //                   Middle   -> height / 2
      //                   Baseline -> ascender   (same as Top for one row)
      //
      // multiple rows, rowsHeight = lineHeight * nRows:
      //                   Top      -> ascender
      //                   Bottom   -> height - rowsHeight + ascender
      //                   Middle   -> (height - rowsHeight) / 2 + ascender
      //                   Baseline -> odd rows:
      //                                  (height - rowsHeight + lineHeight) / 2
      //                               even rows:
      //                                  (height - rowsHeight) / 2 + ascender
      //
      // metrics is _visualMetrics when the text layer uses visual bounds,
      // otherwise the plain font metrics.
      switch( [_textLayer textVerticalAlignment])
      {
      case UITextAlignmentTop :
         origin.y = metrics->ascender;
         break;

      case UITextAlignmentBottom :
         if( nRows <= 1)
            origin.y = rect.size.height - metrics->descender;
         else
            origin.y = rect.size.height - rowsHeight + metrics->ascender;
         break;

      case UITextAlignmentMiddle :
         if( nRows <= 1)
            origin.y = rect.size.height / 2.0;
         else
            origin.y = (rect.size.height - rowsHeight) / 2.0 + metrics->ascender;
         break;

      case UITextAlignmentBaseline :
         if( nRows <= 1)
            origin.y = metrics->ascender;
         else
         {
            if( nRows & 1)
               origin.y = (rect.size.height - rowsHeight + textLineHeight) / 2.0;
            else
               origin.y = (rect.size.height - rowsHeight) / 2.0 + metrics->ascender;
         }
         break;

      case UITextAlignmentFill :
         // Fill mode handled in suggestedFontPixelSizeWithContext
         origin.y = metrics->ascender;
         break;

      default :
#ifdef DEBUG
         mulle_fprintf( stderr, "textVerticalAlignment: %x is unknown\n", [_textLayer textVerticalAlignment]);
         abort();
#endif
         origin.y = metrics->ascender;
         break;
      }

      switch( [_textLayer textAlignment])
      {
      default :
#ifdef DEBUG       
         mulle_fprintf( stderr, "_textAlignment: %x is unknown\n", [_textLayer textAlignment]);
         abort();
#endif
         // fall thru in not debug
      case UITextAlignmentLeft   : origin.x = CGRectGetMinX( rect);
                                   break;
      case UITextAlignmentRight  : origin.x = CGRectGetMaxX( rect);
                                   break;
      case UITextAlignmentCenter : origin.x = CGRectGetMidX( rect);
                                   break;
      }

      CATextLayerLayouterLog( CATextLayerLayouterDebugVerbose, "%s origin: %s", NS_ENUM_PRINT( UITextVerticalAlignment, [_textLayer textVerticalAlignment]),
                                   CGPointUTF8String( origin));

      // origin.x already includes rect.origin.x via CGRectGetMin/Mid/MaxX
      origin.y += rect.origin.y;

      // If cursor is visible, keep it always visible
      // (but not for centered text, where horizontal scrolling doesn't make sense)
      if( [_textLayer isEditing] && [_textLayer textAlignment] != UITextAlignmentCenter)
         origin.x += [self offsetNeededToMakeCursorVisible];

      origin.x += _textOffset.x;
      origin.y += _textOffset.y;
   }
   [context popGraphicsState:state];

   return( origin);
}


- (CGPoint) textOriginWithContext:(id <UILayoutContext>) context
{
   CGRect         canvas;
   CGPoint        origin;
   UIEdgeInsets   insets;

   canvas = [_textLayer insetCanvas];
   if( canvas.size.width == 0.0f)
   {
      insets   = [_textLayer insets];
      origin.x = insets.left + _textOffset.x;
      origin.y = insets.right + _textOffset.y;
   }
   else
   {
      origin   = [self textOriginInRect:canvas
                                context:context];
   }

   return( origin);
}

@end
