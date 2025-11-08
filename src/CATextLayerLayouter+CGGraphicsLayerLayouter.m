//
//  CATextLayerLayouter+CGGraphicsLayerLayouter.m
//  MulleGraphics
//
//  Copyright (c) <|YEAR|> Nat! - Mulle kybernetiK.
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
#import "CATextLayerLayouter+CGGraphicsLayerLayouter.h"

#import "import-private.h"

#import "CATextLayerLayouter+Cursor.h"
#import "CATextLayerLayouter+Layout.h"
#import "CATextLayerLayouter+Selection.h"
#import "CATextLayerLayouter+RowsAndGlyphs.h"
#import "CATextLayer.h"



@implementation CATextLayerLayouter ( CGGraphicsLayerLayouter)


// not caching this anymore
- (CGSize) layer:(CGGraphicsLayer *) layer
    sizeThatFits:(CGSize) max
         context:(id <UILayoutContext>) context
 {
   CATextLayer                     *textLayer;
   CGSize                          textSize;
   NSUInteger                      i;
   NSUInteger                      nGlyphs;
   NSUInteger                      nRows;
   float                           maxx;
   float                           minx;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition          *glyph;
   struct UIGlyphPosition          *glyphs;
   struct CATextLayerFontMetrics   metrics;

   textLayer = MULLE_OBJC_CLASS_CAST_NON_NIL( CATextLayer, layer);
   metrics   = [textLayer prepareLayoutContext:context];

   // canvas might still be 0, as we are likely calculating sizeToFit:
   // we change it to max (temporarily)
   [textLayer setSizeToFitMaxSize:max];
   {
      [self setTextLayer:textLayer];
      // MEMO: i think i need to force and update here
      [self invalidate];
      [self updateRowsAndGlyphsWithContextIfNeeded:context];
   }
   [textLayer setSizeToFitMaxSize:CGSizeZero];

   nRows = _mulle_structarray_get_count( &_rowArray);

   // the height don't change, and our virtual start is always zero
   textSize.width  = 0.0f;
   textSize.height = metrics.textLineHeight * nRows;

   // adjust for "funny" output with overlapping lineheights
   if( metrics.textLineHeight < _metrics.lineHeight)
      textSize.height += (_metrics.lineHeight - metrics.textLineHeight);

   minx = INFINITY;
   maxx = -INFINITY;

   for( i = 0; i < nRows; i++)
   {
      row     = _mulle_structarray_get( &_rowArray, i);
      glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
      nGlyphs = row->glyphRange.length;
      if( ! nGlyphs)
         continue;

      // get last
      glyph = &glyphs[ 0];
      minx  = fminf( minx, glyph->minx);
      glyph = &glyphs[ nGlyphs - 1];
      maxx  = fmaxf( maxx, glyph->maxx - 2.0f);  // fummel
   }

   if( ! isinf( maxx))
      textSize.width = maxx - minx;

   return( textSize);
}




- (void) layoutLayer:(CGGraphicsLayer *) layer
                info:(struct UILayoutInfo *) info
{
   NSUInteger                     i;
   CATextLayer                    *textLayer;
   struct CATextLayerLayouterRow  *row;
   struct CATextLayerRow          layerRow;
   struct mulle_utf8data          textData;
   id <UILayoutContext>           context;
   CGRect                         insetCanvas;
   CGPoint                        origin;

   context = info ? info->context : NULL;

   textLayer = MULLE_OBJC_CLASS_CAST( CATextLayer, layer);
   [self setTextLayer:textLayer];
   [textLayer removeAllTextLayerRows];

   textData = [textLayer textUTF8Data];
   if( mulle_utf8data_is_invalid( textData))
      return;

   memset( &layerRow, 0, sizeof( struct CATextLayerRow));

   layerRow.cursorStyle    = [textLayer isEditing] ? CATextLayerCursorStyleLine : CATextLayerCursorStyleNone;
   layerRow.selectionStyle = ([textLayer isSelectable] && _selection.length) ? CATextLayerSelectionStyleRect : CATextLayerSelectionStyleNone;

   // do not need glyphs if we have no selection or no cursor
   if( layerRow.cursorStyle != CATextLayerCursorStyleNone || layerRow.selectionStyle != CATextLayerSelectionStyleNone)
      [self updateRowsAndGlyphsWithContextIfNeeded:context];
   else
      [self updateRowsWithContextIfNeeded:context];


   i = 0;
   // ensure that noone poked it ('xcept us in the mean time)

   mulle_structarray_for( &_rowArray, row)
   {
      //struct CATextLayerRow
      //{
      //   NSRange                     textRange;
      //   CGRect                      selectionRect;
      //   CATextLayerSelectionStyle   selectionStyle;
      //   CGRect                      cursorRect;
      //   CATextLayerCursorStyle      cursorStyle;
      //}

      layerRow.textRange        = row->textRow.range;

      if( layerRow.cursorStyle != CATextLayerCursorStyleNone)
         layerRow.selectionRect = [self selectionRectInRow:i
                                                 textRange:layerRow.textRange];
      if( layerRow.cursorStyle != CATextLayerCursorStyleNone)
         layerRow.cursorRect    = [self cursorRectInRow:i];

      [textLayer addTextLayerRow:&layerRow];
      ++i;
   }


   insetCanvas = [textLayer insetCanvas];
   origin      = [self textOriginInRect:insetCanvas
                                context:info->context];

   [textLayer setOrigin:origin];
}


- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp
{
   NSUInteger   i;

   for( i = 0; i < indent; i++)
      fputc( ' ', fp);

   fprintf( fp, "%s\n", [self UTF8String]);
}

@end
