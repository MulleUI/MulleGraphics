//
//  CATextLayer+Drawing.m
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
#import "CATextLayer+MulleGraphics.h"

#import "import-private.h"

#import "CATextLayer+Cursor.h"
#import "CATextLayer+Layout.h"
#import "CATextLayer+Selection.h"
#import "CATextLayer+RowsAndGlyphs.h"
#import "CGGraphicsLayer+MulleGraphics.h"


@implementation CATextLayer ( MulleGraphics)

- (void) drawSquareCursorAt:(CGPoint) point
                     height:(CGFloat) height
                    context:(CGContext *) context
{
   CGRect  rect;

   rect = CGRectMake( point.x, point.y, 1, height);
   CGContextFillRectWithPaintable( context, rect, _cursorPaint);
}


- (void) drawCursorWithContext:(CGContext *) context
                           row:(NSUInteger) i
{
   CGRect                        canvas;
   CGRect                        rect;
   struct CATextLayerRowGlyphs   *p;
   NSUInteger                    x;
   CGPoint                       offset;
   CGFloat                       h;
   CGFloat                       y;

   if( MulleCursorPositionIsMax( _cursorPosition))
      _cursorPosition = [self maxCursorPosition];

   if( _cursorPosition.y != i)
      return;

   canvas = [self canvas];

   // get glyphs
   p = &_rowGlyphs[ i];
   x = _cursorPosition.x;
   if( x <= p->nGlyphs)
   {
      offset.x = p->glyphs[ x].x;

      h = _metrics.lineHeight;
      y = 0.0f;
      if( h >= 8.0f)
      {
         h -= 2;
         y  = 1;
      }
      offset.y = -(_metrics.lineHeight / 2); // depends on alignment, really, use middle here

      point = CGPointMake( canvas.origin.x + _layoutOrigin.x + offset.x - 0.5,
                         canvas.origin.y + _layoutOrigin.y - _metrics.ascender + y);
      [self drawSquareCursorAt:point
                        height:h
                       context:context];
   }
}


- (void) drawSquareSelectionRect:(CGRect) rect
                         context:(CGContext *) context
{
   CGContextFillRectWithPaintable( context, rect, _selectionPaint);
}


- (BOOL) drawSelectionWithContext:(CGContext *) context
                        textRange:(NSRange) textRange
                              row:(NSUInteger) i
{
   NSInteger                     x;
   CGRect                        canvas;
   struct CATextLayerRowGlyphs   *p;
   NSRange                       selectionRange;
   CGRect                        rect;

   selectionRange = NSIntersectionRange( textRange, _selection);
   if( ! selectionRange.length)
      return( NO);

   canvas = [self canvas];

   // draw background for selection, compute area by removing
   // unselected characters
   // "a[iiii]a"

   x = selectionRange.location - textRange.location;
   p = &_rowGlyphs[ i];
   if( x + selectionRange.length > p->nGlyphs)
      abort();  // can't happen or ?

   rect.origin.x    = canvas.origin.x + _layoutOrigin.x + p->glyphs[ x].x;
   rect.origin.y    = canvas.origin.y + _layoutOrigin.y + (i * _metrics.lineHeight) - _metrics.ascender; // / 2.0;
   rect.size.width  = p->glyphs[ x + selectionRange.length].x - p->glyphs[ x].x;
   rect.size.height = _metrics.lineHeight;

   if( rect.size.width < 0.1)
      return( NO);

   [self drawSquareSelectionRect:rect
                         context:context];


   // Der nvgTextBounds code ist zum einen langsamer, zum anderen (wegen)
   // Kerning ? ist die Selektion auch nicht sonderlich stabil.
   // Es ist besser die glpyh information zu benutzen..
#if 0
   //
   // TODO: use glyphs info here possible ? Would be much faster
   //
   switch( _textAlignment)
   {
   case UITextAlignmentLeft   :
      {
         float   offset;

         // 1) get number of characters to the left of selection
         //    then get the offset in pixels
         nvgTextBounds( vg, frame.origin.x + _layoutOrigin.x,
                            frame.origin.y + _layoutOrigin.y,
                            _rows[ i].start,
                            &_rows[ i].start[ leftCharacters],
                            xyxy);
         offset = xyxy[ 2];

         nvgTextBounds( vg, offset,
                            frame.origin.y + _layoutOrigin.y,
                            &_rows[ i].start[ leftCharacters],
                            &_rows[ i].start[ leftCharacters + selectionRange.length],
                            xyxy);
         break;
      }

   case UITextAlignmentRight  :
      {
         NSUInteger   rightOffset;
         NSUInteger   rightCharacters;
         float        offset;
            // abcdef   0,5  1,3  > 4, 2 ef
         rightOffset     = selectionRange.location + selectionRange.length;
         rightCharacters = textRange.length - rightOffset;
         nvgTextBounds( vg, frame.origin.x + _layoutOrigin.x,
                            0,
                            &_rows[ i].start[ rightOffset],
                            &_rows[ i].start[ rightOffset + rightCharacters],
                            xyxy);
         offset = xyxy[ 0];

          // 2) get offset and width of characters of the selection
         nvgTextBounds( vg, offset,
                            frame.origin.y + _layoutOrigin.y,
                            &_rows[ i].start[ leftCharacters],
                            &_rows[ i].start[ leftCharacters + selectionRange.length],
                            xyxy);
         break;
      }

   case UITextAlignmentCenter :
      {
         float    offset;
         float    width;

         nvgTextBounds( vg, 0,
                            0,
                            _rows[ i].start,
                            &_rows[ i].start[ leftCharacters],
                            xyxy);
         offset = xyxy[ 2] - xyxy[ 0];
         nvgTextBounds( vg, 0,
                            0,
                            &_rows[ i].start[ leftCharacters],
                            &_rows[ i].start[ leftCharacters + selectionRange.length],
                            xyxy);
         width = xyxy[ 2] - xyxy[ 0];

         nvgTextBounds( vg, frame.origin.x + _layoutOrigin.x,
                            frame.origin.y + _layoutOrigin.y,
                            _rows[ i].start,
                            _rows[ i].end,
                            xyxy);
         xyxy[ 0] += offset;
         xyxy[ 2]  = xyxy[ 0] + width;
      }
   }
#endif
   return( YES);
}


- (BOOL) drawInContext:(CGContext *) context
{
   BOOL                    isCursorDrawn;
   BOOL                    isSelectionDrawn;
   BOOL                    useClearType;
   CGPaint                 *textBackgroundPaint;
   CGPaint                 *textPaint;
   CGRect                  canvas;
   CGPoint                 origin;
   CGFloat                 textLineHeight;
   NSRange                 textRange;
   NSUInteger              i;
   struct mulle_utf8data   data;

   if( ! [super drawInContext:context])
      return( NO);

   // nothing to draw ? then bail
   data = [self textUTF8DataInTextRange];
   if( ! data.length)
      return( YES);

   // set font, size, alignment...
   [self prepareRowsAndGlyphsWithContextIfNeeded:context];


   // if textPaint is not set, use color derived from :_backgroundPaint
   textPaint = _textPaint ? _textPaint : _suggestedTextPaint;
   assert( textPaint);

   // figure out if we can use clearType
   // as we are a CALayer, we can't walk the ancestors up, so backgroundPaint
   // has to be the exact color we are painting on

   useClearType        = _clearTypeEnabled;
   textBackgroundPaint = useClearType && _textBackgroundPaint
                         ? _textBackgroundPaint
                         : _backgroundPaint;

   useClearType &= [textBackgroundPaint isMonochrome] &&
                   [textPaint isMonochrome] &&
                   [_selectionPaint isMonochrome];
   useClearType &= [textBackgroundPaint isOpaque];

   CGContextClearType( context, useClearType);

   // need to compute _layoutOrigin during layout
   canvas = [self canvas];
   canvas = MulleEdgeInsetsInsetRect( _insets, canvas);

//   _layoutOrigin = [self textOriginInRect:canvas
//                                  context:context];
//
   isCursorDrawn  = NO;
   textLineHeight = [self textLineHeight];

   for( i = 0; i < _nRows; i++)
   {
      textRange = NSRangeMake( _rows[ i].start - (char *) data.characters,
                               _rows[ i].end - _rows[ i].start);

      origin = CGPointMake( canvas.origin.x + _layoutOrigin.x,
                            canvas.origin.y + _layoutOrigin.y + (i * textLineHeight));

//      // Draw the first line only
//      // don't render outside of myself
//      nvgIntersectScissor( vg, canvas.origin.x,
//                               canvas.origin.y,
//                               canvas.size.width,
//                               canvas.size.height);
   //   // nvgFillColor( vg, nvgRGBA(127,127,255,255));

      /*
       * Draw selection
       */
      isSelectionDrawn = [self drawSelectionWithContext:context
                                              textRange:textRange
                                                    row:i];

      // maybe a bit over kill, but I don't want to reset same colors on each
      // line
      if( i == 0 || isSelectionDrawn || isCursorDrawn)
      {
         /*
          * Draw Text
          * Bug: textBackgroundColor should be selection color, where selection
          *      is drawn. Or rather a mix of both colors
          */
         //if( useClearType)
         {
            CGContextTextColor( context, [textPaint mainColor]);
            CGContextTextBackgroundColor( context, [textBackgroundPaint mainColor]);
         }
         //else
         //{
         //   // coloring with gradients not possible, not super sure why not
         //   // but it is what it is (cleartype probably not looking good)
         //   CGContextBeginPath( context);
         //   CGContextRect( context, rect);
         //   CGContextFillPaintableOptions( context, textPaint, rect, NULL);
         //}
      }

      // redo this since we fill color may have changed
      CGContextText( context, origin, _rows[ i].start, _rows[ i].end - _rows[ i].start);

      /*
       * Draw Cursor
       */
      isCursorDrawn = [self isEditing];
      if( isCursorDrawn)
      {
         [self drawCursorWithContext:context
                                row:i];
      }
   }
   CGContextClearType( context, 0);

   return( YES);
}

@end
