//
//  CATextLayer+RowsAndGlyphs.m
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
#import "CATextLayerLayouter+RowsAndGlyphs.h"

#import "import-private.h"

#import "CATextLayer.h"


@implementation CATextLayerLayouter( RowsAndGlyphs)


/**
 **
 */
- (void) updateRowGlyphsAtIndex:(NSUInteger) i
                        context:(id <UILayoutContext>) context
{
   NSRange                         previousRange;
   NSUInteger                      maxGlyphs;
   NSUInteger                      nGlyphs;
   NSUInteger                      start;
   struct CATextLayerLayouterRow   *row;
   struct mulle_utf8data           data;
   struct UIGlyphPosition          *glyphs;

   start = 0;
   if( i > 0)
   {
      row           = _mulle_structarray_get( &_rowArray, i - 1);
      previousRange = row->glyphRange;
      start         = NSMaxRange( previousRange) + 1; // sentinel !
      assert( _mulle_structarray_get_count( &_glyphArray) == start);
   }

   // assume each char produces max one glyph, possibly, make room, in
   // the glyphArray
   row       = _mulle_structarray_get( &_rowArray, i);

   assert( mulle_range_is_valid( row->textRow.range));

   maxGlyphs = row->textRow.range.length;
   glyphs    = _mulle_structarray_advance( &_glyphArray, maxGlyphs + 1);  // sentinel !

   data      = [_textLayer textUTF8Data];
   nGlyphs   = [context getGlyphPositions:glyphs
                                    count:maxGlyphs
                                     text:(char *) &data.characters[ row->textRow.range.location]
                                   length:row->textRow.range.length];


   // put in a node at the sentinel position
   if( nGlyphs)
      glyphs[ nGlyphs].x = glyphs[ nGlyphs - 1].maxx;
   else
      glyphs[ nGlyphs].x = 0;

   glyphs[ nGlyphs].minx = 0;
   glyphs[ nGlyphs].maxx = 0;
   glyphs[ nGlyphs].str  = (char *) &data.characters[ NSMaxRange( row->textRow.range)];

   // ''   nglyphs == 0, _cursorPositon=={ 0 - 0 }
   // 'A'  nglyphs == 1, _cursorPositon=={ 0 - 1 }  |A or A|
   // 'AB' nglyphs == 2, _cursorPositon=={ 0 - 2 }  |AB or A|B or AB|

   // this is what we actually reduce the structarray to
   _mulle_structarray_set_count( &_glyphArray, start + nGlyphs + 1);

   // update row, so we know where the glyphs are
   row->glyphRange = NSRangeMake( start, nGlyphs);
}


- (void) updateRowsWithContext:(id <UILayoutContext>) context
{
   NSUInteger                      max;
   CGFloat                         width;
   struct mulle_utf8data           data;
   CGFloat                         lineHeight;
   NSUInteger                      nRows;
   struct CATextLayerLayouterRow   *rows;
   CGSize                          size;
   NSUInteger                      arraySize;
   NSUInteger                      diff;

   mulle_structarray_reset( &_rowArray);

   // at this point, the layer is supposed to have set its properties
   // already (callers need to ensure this)
   _metrics = [context textMetrics];
   if( _metrics.lineHeight == 0.0)
      return;

   // so when editing the text, we will likely realloc the data. But
   // glyphs contain a pointer to the data. When you change the text
   // the glyph->str is stale. We can still use glyph->str for address
   // calculation though
   data = [_textLayer textUTF8Data];
   size = [_textLayer sizeToFitMaxSize]; // ugliness ensues
   if( size.width == 0.0)
      size = [_textLayer canvas].size;

   // produce row information
   switch( [_textLayer lineBreakMode])
   {
   case NSLineBreakByWordWrapping :
      // the width can produce more lines, we assume worst case
      // we have a string of "max" number of linefeeds, followed by
      // a last line as one large string without linefeed
      // We will have to divide this by width to get the extra lengths
      // also when word wrapping how big can the biggest word be ?

      width = size.width;
      break;

   default :
      width = INFINITY;
      break;
   }

   //
   // We can calculate max visible rows, which is
   // max.height / _textLineHeight , but
   // because of partially visible rows we added + 2
   // Now we break the whole text twice...
   //
   // This will fail, when we want to also vertically center the text
   // content.

   // we use the font line height to calculate the number of rows, the
   // CATextLayer metrics lineHeight is not available yet and may depend
   // on out nRows anyway..
   lineHeight = _metrics.lineHeight;
   max        = (size.height / lineHeight) + 2;

   // nRows = 0 can happen if we have just whitespace or ""
   nRows      = [context getTextRows:NULL
                               count:max
                         textRowSize:sizeof( struct CATextLayerLayouterRow)
                                text:data.characters
                              length:data.length
                       breakRowWidth:width];
   if( nRows)
   {
      arraySize = _mulle_structarray_get_size( &_rowArray);
      if( nRows > arraySize)
      {
         diff = nRows - arraySize;
         _mulle_structarray_advance( &_rowArray, diff);
      }
      _mulle_structarray_set_count( &_rowArray, nRows);

      rows = _mulle_structarray_get( &_rowArray, 0);

      [context getTextRows:(struct UITextRow *) rows
                     count:nRows
               textRowSize:sizeof( struct CATextLayerLayouterRow)
                      text:data.characters
                    length:data.length
             breakRowWidth:width];

   // clean up glyphRange because it would be uninitialized at least in
   // debugging
#ifdef DEBUG
      {
         struct CATextLayerLayouterRow   *p;
         struct CATextLayerLayouterRow   *sentinel;

         p        = &rows[ 0];
         sentinel = &rows[ nRows];
         while( p < sentinel)
         {
            p->glyphRange = mulle_range_make_invalid();
            ++p;
         }
      }
#endif
   }
   // we have to tell the glypharray that its invalid now
   _rowArrayValid   = YES;
   _glyphArrayValid = NO;
}


- (void) updateGlyphsWithContext:(id <UILayoutContext>) context
{
   NSUInteger   i;
   NSUInteger   nRows;

   assert( ! _glyphArrayValid);

   nRows = _mulle_structarray_get_count( &_rowArray);
   mulle_structarray_reset( &_glyphArray);

   for( i = 0; i < nRows; i++)
      [self updateRowGlyphsAtIndex:i
                           context:context];
   _glyphArrayValid = YES;
}


- (void) updateRowsWithContextIfNeeded:(id <UILayoutContext>) context
{
   if( ! _rowArrayValid)
   {
      [_textLayer prepareLayoutContext:context];
      [self updateRowsWithContext:context];
      assert( _rowArrayValid);
   }
}


- (void) updateGlyphsWithContextIfNeeded:(id <UILayoutContext>) context
{
   if( ! _glyphArrayValid)
   {
      [_textLayer prepareLayoutContext:context];
      [self updateGlyphsWithContext:context];
      assert( _glyphArrayValid);
   }
}


static BOOL   CATextLayerLayouterNeedsUpdates( CATextLayerLayouter *self)
{
   NSUInteger   generationCount;

   // if any already set to invalid, no need to check for layer
   if( ! self->_rowArrayValid || ! self->_glyphArrayValid)
      return( YES);

   generationCount = [self->_textLayer textPropertiesGenerationCount];
   if( self->_generationCount == generationCount)
      return( NO);

   // we keep the generation now, but invalidate, so we run into early exit
   // next time
   self->_generationCount = generationCount;
   self->_rowArrayValid   =
   self->_glyphArrayValid = NO;

   return( YES);
}


- (void) updateRowsAndGlyphsWithContextIfNeeded:(id <UILayoutContext>) context
{
   if( CATextLayerLayouterNeedsUpdates( self))
   {
      [_textLayer prepareLayoutContext:context];

      if( ! _rowArrayValid)
         [self updateRowsWithContext:context];

      if( ! _glyphArrayValid)
         [self updateGlyphsWithContext:context];
   }
}


- (CGRect) visualBoundsWithContext:(id <UILayoutContext>) context
{
   CGFloat                         x;
   CGFloat                         y;
   NSUInteger                      i, j;
   NSUInteger                      nGlyphs;
   NSUInteger                      nRows;
   float                           maxx;
   float                           maxy;
   float                           minx;
   float                           miny;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition          *glyph;
   struct UIGlyphPosition          *glyphs;
   void                            *state;

   // as this routine can get called from within the render, its no
   // convenient to clobber the current state
   state = [context pushGraphicsState];
   {
      assert( context);

      [self updateRowsAndGlyphsWithContextIfNeeded:context];

      MulleUILog( "a: %g d: %g h: %g", _metrics.ascender, _metrics.descender, _metrics.lineHeight);

      assert( _metrics.lineHeight);

      nRows = _mulle_structarray_get_count( &_rowArray);

      // get x and width, then redo Y
      minx = INFINITY;
      miny = INFINITY;
      maxx = -INFINITY;
      maxy = -INFINITY;

      for( j = 0; j < nRows; j++)
      {
         row     = _mulle_structarray_get( &_rowArray, j);
         glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
         nGlyphs = row->glyphRange.length;

         // get last
         i = 0;
         for(;;)
         {
            if( i >= nGlyphs)
               goto next;

            glyph = &glyphs[ i];
            // if this is true, assume glyph produces no ink
            if( UIGlyphPositionHasStrokes( glyph))
            {
               x    = glyph->minx;
               minx = fminf( minx, x);
               break;
            }
         }

         // p->nGlyphs know to be > 0 by above loop
         for( i = nGlyphs - 1;; --i)
         {
            glyph = &glyphs[ i];
            if( UIGlyphPositionHasStrokes( glyph))
            {
               x    = glyph->maxx;
               maxx = fmaxf( maxx, x);
               break;
            }
            if ( ! i)
               break;
         }
next:
         ;
      }


      // get top y of first row with visible characters
      // we have to
      j = 0;
      for(;;)
      {
         if( j >= nRows)
            break;

         row     = _mulle_structarray_get( &_rowArray, j);
         glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
         nGlyphs = row->glyphRange.length;

         for( i = 0; i < nGlyphs; i++)
         {
            glyph = &glyphs[ i];
            if( UIGlyphPositionHasStrokes( glyph))
            {
               // converted from baseline
               y    = glyph->miny;
               y   += _metrics.ascender + j * _metrics.lineHeight;
               miny = fminf( miny, y);
            }
         }

         if( ! isinf( miny))
            break;
         ++j;
      }

      j = nRows;
      for(;;)
      {
         if( ! j)
            break;
         --j;

         row     = _mulle_structarray_get( &_rowArray, j);
         glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
         nGlyphs = row->glyphRange.length;

         for( i = 0; i < nGlyphs; i++)
         {
            glyph = &glyphs[ i];
            if( UIGlyphPositionHasStrokes( glyph))
            {
               y    = glyph->maxy;
               y   += _metrics.ascender + j * _metrics.lineHeight;
               maxy = fmaxf( maxy, y);
            }
         }

         if( ! isinf( maxy))
            break;
      }
   }
   [context popGraphicsState:state];

   MulleUILog( "%g %g %g %g", minx, miny, maxx, maxy);

   // If no visible glyphs were found, bounds are still at infinity
   // Return empty/degenerate rect like we do for whitespace-only text
   if( isinf( minx) || isinf( maxx) || isinf( miny) || isinf( maxy))
   {
      // Use ascender for y position to match whitespace behavior
      return( CGRectMake( 0.0f, _metrics.ascender, 0.0f, 0.0f));
   }

   // if aliasPixelVisible is NO (default), inset by 1 pixel to exclude
   // anti-aliasing pixels from visual bounds
   if( ! [_textLayer isAliasPixelVisible])
   {
      minx += 1.0f;
      miny += 1.0f;
      maxx -= 1.0f;
      maxy -= 1.0f;
   }

   return( CGRectMake( minx, miny, maxx - minx, maxy - miny));
}



// point is within bounds
// we find the range in the textUTF8String 8bit characters we do not
// interpret UTF8
//
- (NSUInteger) characterOffsetOfGlyphAtPoint:(CGPoint) point
{
   CGFloat                         search;
   NSInteger                       y;
   NSUInteger                      nGlyphs;
   NSUInteger                      nRows;
   NSUInteger                      x;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition          *glyphs;
   struct mulle_utf8data           data;

   assert( ! CATextLayerLayouterNeedsUpdates( self));

   nRows = _mulle_structarray_get_count( &_rowArray);
   if( ! nRows)
      return( NSNotFound);

   // figure out the row that was hit, a row is _metrics.lineHeight and
   // drawn at frame.origin.y + i *_metrics.lineHeight
   y = (NSInteger) round( point.y / _metrics.lineHeight);
   if( y < 0)
      y = 0;
   else
      if( y >= nRows)
         y = nRows - 1;

   // get glyphs for current row
   row     = _mulle_structarray_get( &_rowArray, y);
   glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
   nGlyphs = row->glyphRange.length;

   // calculate characters up till till this

   search = point.x;

   x = UIGlyphPositionSearch( glyphs, nGlyphs, search);
   if( x == NSNotFound)
   {
      if( search >= glyphs[ nGlyphs].x - 0.5)
         x = nGlyphs;
      else
         x = 0;
   }
   else
   {
      // left side/right side (use third, matter of taste)
      if( search >= (glyphs[ x].minx + glyphs[ x].maxx - glyphs[ x].minx) / 3.0)
         x++;
   }

   data = [self textUTF8DataInTextRange];
   return( glyphs[ x].str - (char *) data.characters);
}


- (CAGlyphSeating) getGlyphPosition:(struct UIGlyphPosition  *) glyphPosition
                            atPoint:(CGPoint) point
{
   CAGlyphSeating                  seating;
   CGFloat                         search;
   NSInteger                       y;
   NSUInteger                      nGlyphs;
   NSUInteger                      nRows;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition          *glyphs;
   struct UIGlyphPosition          dummy;

   assert( ! CATextLayerLayouterNeedsUpdates( self));

   if( ! glyphPosition)
      glyphPosition = &dummy;
   *glyphPosition = (struct UIGlyphPosition) { 0 };

   seating = CAGlyphSeatingNull;
   nRows   = _mulle_structarray_get_count( &_rowArray);
   if( ! nRows)
      return( seating);

   // figure out the row that was hit, a row is _metrics.lineHeight and
   // drawn at frame.origin.y + i *_metrics.lineHeight
   y = (NSInteger) round( point.y / _metrics.lineHeight);
   if( y < 0)
      y = 0;
   else
      if( y >= nRows)
         y = nRows - 1;

   // get glyphs for current row
   row     = _mulle_structarray_get( &_rowArray, y);
   glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
   nGlyphs = row->glyphRange.length;

   search  = point.x;

   seating.seat = UIGlyphPositionSearch( glyphs, nGlyphs, search);
   if( seating.seat != NSNotFound)
   {
      memcpy( glyphPosition, &glyphs[ seating.seat], sizeof( struct UIGlyphPosition));
      seating.row = y;
   }
   return( seating);
}



- (void) dumpRowsAndGlyphsToFILE:(FILE *) fp
{
   NSUInteger                    i;
   NSUInteger                    j;
   NSUInteger                    nRows;
   struct UIGlyphPosition        *q;
   struct UIGlyphPosition        *glyphs;
   struct CATextLayerLayouterRow   *row;
   NSUInteger                    nGlyphs;

   mulle_fprintf( fp, "_metrics            : { .ascender = %g, .descender = %g, .lineheight = %g }\n",
                                               _metrics.ascender, _metrics.descender, _metrics.lineHeight);

   nRows = _mulle_structarray_get_count( &_rowArray);
   mulle_fprintf( fp, "nRows               : %tu\n", nRows);

   for( i = 0; i < nRows; i++)
   {
      row     = _mulle_structarray_get( &_rowArray, j);
      glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
      nGlyphs = row->glyphRange.length;

      for( j = 0; j < nGlyphs; j++)
      {
         q = &glyphs[ j];
         mulle_fprintf( fp, "   [%tu,%tu]            : .str = '%.1S', .x = %g, { %g, %g, %g, %g }\n",
                            i, j,
                            q->str,
                            q->x,
                            q->minx, q->maxx,
                            q->miny, q->maxy);
      }
   }
}

@end
