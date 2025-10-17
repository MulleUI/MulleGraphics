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
#import "CATextLayer+RowsAndGlyphs.h"

#import "import-private.h"



@implementation CATextLayer ( RowsAndGlyphs)


// will also be used by copy
- (void) _initRowGlyphs
{
   _mulle_structarray_init( &_rowGlyphArray, sizeof( struct CATextLayerRowGlyphs),
                                             alignof( struct CATextLayerRowGlyphs),
                                             0,
                                             MulleObjCInstanceGetAllocator( self));

   _rows  = NULL;
   _nRows = 0;

   // just cleanliness
   memset( &_glyphData, 0, sizeof( _glyphData));
}


- (void) _doneRowGlyphs
{
   struct CATextLayerRowGlyphs   *p;
   struct CATextLayerRowGlyphs   *sentinel;
   unsigned int                  n;

   n = _mulle_structarray_get_count( &_rowGlyphArray);
   if( n)
   {
      p        = _mulle_structarray_get( &_rowGlyphArray, 0);
      sentinel = &p[ n];
      do
      {
         CATextLayerRowGlyphsDone( p);
         ++p;
      }
      while( p < sentinel);
   }

   _mulle_structarray_done( &_rowGlyphArray);
}


- (void) _initRowsAndGlyphs
{
   _mulle_structarray_init( &_rowArray, sizeof( NVGtextRow),
                                        alignof( NVGtextRow),
                                        0,
                                        MulleObjCInstanceGetAllocator( self));
   [self _initRowGlyphs];
}


- (void) _doneRowsAndGlyphs
{
   [self _doneRowGlyphs];
   _mulle_structarray_done( &_rowArray);
}



- (void) invalidateRowsAndGlyphs
{
   _rowsAndGlyphsValid = NO;
}



/**
 **
 */

- (void) resizeRowsTo:(NSUInteger) max
{
   NSUInteger   size;
   NSUInteger   diff;

   assert( max);

   size = _mulle_structarray_get_size( &_rowArray);
   if( max > size)
   {
      diff = max - size;
      _mulle_structarray_advance( &_rowArray, diff);
   }

   _rows  = _mulle_structarray_get( &_rowArray, 0);
}


- (void) resizeRowGlyphsArrayTo:(NSUInteger) max
{
   NSUInteger                       size;
   NSUInteger                       diff;
   struct CATextLayerRowGlyphs   *p;
   struct CATextLayerRowGlyphs   *sentinel;

   assert( max);

   //
   // The contents of _rowGlyphArray will be reused, as they contain
   // other mulle_structarrays.
   //
   size = _mulle_structarray_get_size( &_rowGlyphArray);
   if( max > size)
   {
      diff     = max - size;
      p        = _mulle_structarray_advance( &_rowGlyphArray, diff);
      sentinel = &p[ diff];
      while( p < sentinel)
      {
         _CATextLayerRowGlyphsInit( p, MulleObjCInstanceGetAllocator( self));
         ++p;
      }
   }
   _rowGlyphs = _mulle_structarray_get( &_rowGlyphArray, 0);
}


- (void) updateRowGlyphsAtIndex:(NSUInteger) i
                        context:(id <UILayoutContext>) context
{
   NSUInteger                    nGlyphs;
   NSUInteger                    newSize;
   NSUInteger                    diff;
   NSUInteger                    sGlyphs;
   NSUInteger                    length;
   struct CATextLayerRowGlyphs   *p;
   struct UITextRow              *row;

   p       = &_rowGlyphs[ i];
   row     = &_rows[ i];
   nGlyphs = 100 / 2; // start with assumed 100 glyphs for each row

   // our assumed size, the buffer should be larger than this, so we can
   // figure out if we get truncated due to small a buffer also we need
   // one extra space for the sentinel node
   for(;;)
   {
      sGlyphs = _mulle_structarray_get_size( &p->glyphArray);
      if( sGlyphs <= nGlyphs + 1) // add sentinel node
      {
         newSize = nGlyphs + nGlyphs;
         if( newSize < 100)
            newSize = 100;
         diff      = newSize - sGlyphs;
         _mulle_structarray_advance( &p->glyphArray, diff);
         p->glyphs = _mulle_structarray_get( &p->glyphArray, 0);
         sGlyphs   = newSize;
      }

      length     = row->end - row->start;
      p->nGlyphs = [context getGlyphPositions:p->glyphs
                                        count:sGlyphs
                                         text:row->start
                                       length:length];
      if( p->nGlyphs < sGlyphs - 1) // subtract sentinel node
         break;

      nGlyphs = p->nGlyphs;
   }

   // put in a node at the sentinel position
   if( p->nGlyphs)
      p->glyphs[ p->nGlyphs].x = p->glyphs[ p->nGlyphs - 1].maxx;
   else
      p->glyphs[ p->nGlyphs].x = 0;

   p->glyphs[ p->nGlyphs].minx = 0;
   p->glyphs[ p->nGlyphs].maxx = 0;
   p->glyphs[ p->nGlyphs].str  = row->end;
   // ''   nglyphs == 0, _cursorPositon=={ 0 - 0 }
   // 'A'  nglyphs == 1, _cursorPositon=={ 0 - 1 }  |A or A|
   // 'AB' nglyphs == 2, _cursorPositon=={ 0 - 2 }  |AB or A|B or AB|
}


- (void) prepareRowsAndGlyphsWithContext:(id <UILayoutContext>) context
{
   [context useFontWithNameUTF8String:_fontNameUTF8String];
   [context setFontSize:_fontPixelSize];                                 // nvgFontSize
   [context setTextAlign:UITextAlignmentToTextAlign( _textAlignment)];   // nvgTextAlign
   [context setTextLetterSpacing:_textLetterSpacing];                    // nvgTextLetterSpacing
   [context setTextLineHeight:[self textLineHeight]];                    // nvgTextLineHeight
   [context setLineBreakMode:_lineBreakMode];
}


- (void) updateRowsAndGlyphsWithContext:(id <UILayoutContext>) context
                                   size:(CGSize) size
{
   NSUInteger              max;
   NSUInteger              i;
   CGFloat                 width;
   struct mulle_utf8data   data;
   CGFloat                 lineHeight;

   _nRows     = 0;
   _glyphData = mulle_utf8data_make_invalid();
   _metrics   = [context textMetrics];
   if( _metrics.lineHeight == 0.0)
      return;


   // so when editing the text, we will likely realloc the data. But
   // glyphs contain a pointer to the data. When you change the text
   // the glyph->str is stale. We can still use glyph->str for address
   // calculation though
   data       = [self textUTF8DataInTextRange];
   _glyphData = data;

   // produce row information
   switch( _lineBreakMode)
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
   lineHeight = [self textLineHeight];
   max        = (size.height / lineHeight) + 2;

   _nRows = [context getTextRows:NULL
                           count:max
                            text:data.characters
                          length:data.length
                   breakRowWidth:width];
   if( ! _nRows)
      _nRows = 1;

   [self resizeRowsTo:_nRows];
   [context getTextRows:_rows
                  count:_nRows
                   text:data.characters
                 length:data.length
          breakRowWidth:width];

   [self resizeRowGlyphsArrayTo:_nRows];
   for( i = 0; i < _nRows; i++)
      [self updateRowGlyphsAtIndex:i
                           context:context];
}


- (void) updateRowsAndGlyphsWithContext:(id <UILayoutContext>) context
{
   CGRect  canvas;

   canvas = [self canvas];
   [self updateRowsAndGlyphsWithContext:context
                                   size:canvas.size];
}


- (void) updateRowsAndGlyphsWithContextIfNeeded:(id <UILayoutContext>) context
{
   if( ! _rowsAndGlyphsValid)
   {
      [self prepareRowsAndGlyphsWithContext:context];
      [self updateRowsAndGlyphsWithContext:context];
      _rowsAndGlyphsValid = YES;
   }
}


- (void) prepareRowsAndGlyphsWithContextIfNeeded:(id <UILayoutContext>) context
{
   [self prepareRowsAndGlyphsWithContext:context];

   if( ! _rowsAndGlyphsValid)
   {
      [self updateRowsAndGlyphsWithContext:context];
      _rowsAndGlyphsValid = YES;
   }
}



// point is within bounds
// we find the range in the textUTF8String 8bit characters we do not
// interpret UTF8
//
- (NSUInteger) characterOffsetOfGlyphAtPoint:(CGPoint) point
{
   NSInteger                     y;
   NSUInteger                    x;
   CGFloat                       search;
   struct CATextLayerRowGlyphs   *p;
   struct mulle_utf8data         data;

   assert( _rowsAndGlyphsValid);

   if( ! _nRows)
      return( NSNotFound);

   // figure out the row that was hit, a row is _metrics.lineHeight and
   // drawn at frame.origin.y + i *_metrics.lineHeight
   y = (NSInteger) round( point.y / _metrics.lineHeight);
   if( y < 0)
      y = 0;
   else
      if( y >= _nRows)
         y = _nRows - 1;

   p = &_rowGlyphs[ y];

   // calculate characters up till till this

   search = point.x;

   x = UIGlyphPositionSearch( p->glyphs, p->nGlyphs, search);
   if( x == NSNotFound)
   {
      if( search >= p->glyphs[ p->nGlyphs].x - 0.5)
         x = p->nGlyphs;
      else
         x = 0;
   }
   else
   {
      // left side/right side (use third, matter of taste)
      if( search >= p->glyphs[ x].minx + (p->glyphs[ x].maxx - p->glyphs[ x].minx) / 3.0)
         x++;
   }

   data = [self textUTF8DataInTextRange];
   return( p->glyphs[ x].str - (char *) data.characters);
}


- (CAGlyphSeating) getGlyphPosition:(struct UIGlyphPosition  *) glyphPosition
                            atPoint:(CGPoint) point
{
   CAGlyphSeating                seating;
   NSInteger                     y;
   CGFloat                       search;
   CGFloat                       lineHeight;
   struct CATextLayerRowGlyphs   *p;
   struct UIGlyphPosition        dummy;

   assert( _rowsAndGlyphsValid);

   if( ! glyphPosition)
      glyphPosition = &dummy;
   *glyphPosition = (struct UIGlyphPosition) { 0 };

   seating = CAGlyphSeatingNull;
   if( ! _nRows)
      return( seating);

   // figure out the row that was hit, a row is _metrics.lineHeight and
   // drawn at frame.origin.y + i *_metrics.lineHeight
   lineHeight = [self textLineHeight];
   y = (NSInteger) round( point.y / lineHeight);
   if( y < 0)
      y = 0;
   else
      if( y >= _nRows)
         y = _nRows - 1;

   p       = &_rowGlyphs[ y];
   search  = point.x;

   seating.seat = UIGlyphPositionSearch( p->glyphs, p->nGlyphs, search);
   if( seating.seat != NSNotFound)
   {
      memcpy( glyphPosition, &p->glyphs[ seating.seat], sizeof( struct UIGlyphPosition));
      seating.row = y;
   }
   return( seating);
}


// not caching this anymore
- (CGSize) sizeThatFits:(CGSize) max
                context:(id <UILayoutContext>) context
 {
   NSUInteger                    i;
   struct CATextLayerRowGlyphs   *p;
   struct UIGlyphPosition        *glyph;
   float                         minx;
   float                         maxx;
   CGSize                        textSize;
   CGFloat                       lineHeight;

   // canvas might still be 0, as we are likely calculating sizeToFit:
   [self prepareRowsAndGlyphsWithContext:context];
   [self updateRowsAndGlyphsWithContext:context
                                   size:max];

   lineHeight = [self textLineHeight];

   // the height don't change, and our virtual start is always zero
   textSize.width  = 0.0f;
   textSize.height = lineHeight * _nRows;

   // adjust for "funny" output with overlapping lineheights
   if( lineHeight < _metrics.lineHeight)
      textSize.height += (_metrics.lineHeight - lineHeight);

   minx = INFINITY;
   maxx = -INFINITY;

   for( i = 0; i < _nRows; i++)
   {
      p = &_rowGlyphs[ i];
      if( ! p->nGlyphs)
         continue;

      // get last
      glyph = &p->glyphs[ 0];
      minx  = fminf( minx, glyph->minx);
      glyph = &p->glyphs[ p->nGlyphs - 1];
      maxx  = fmaxf( maxx, glyph->maxx - 2.0f);  // fummel
   }

   if( ! isinf( maxx))
      textSize.width = maxx - minx;

   return( textSize);
}


- (CGRect) visualBoundsWithContext:(id <UILayoutContext>) context
                           insets:(struct MulleEdgeInsets) insets
{
   NSUInteger                    i, j;
   struct CATextLayerRowGlyphs   *p;
   struct UIGlyphPosition        *glyph;
   float                         minx;
   float                         miny;
   float                         maxx;
   float                         maxy;
   CGFloat                       x;
   CGFloat                       y;
   CGFloat                       lineHeight;

   [self updateRowsAndGlyphsWithContextIfNeeded:context];

   MulleUILog( "a: %g d: %g h: %g", _metrics.ascender, _metrics.descender, _metrics.lineHeight);

   assert( _metrics.lineHeight);

   lineHeight = [self textLineHeight];

   // get x and width, then redo Y
   minx = INFINITY;
   miny = INFINITY;
   maxx = -INFINITY;
   maxy = -INFINITY;

   for( j = 0; j < _nRows; j++)
   {
      p = &_rowGlyphs[ j];

      // get last
      i = 0;
      for(;;)
      {
         if( i >= p->nGlyphs)
            goto next;

         glyph = &p->glyphs[ i];
         // if this is true, assume glyph produces no ink
         if( UIGlyphPositionHasStrokes( glyph))
         {
            x    = glyph->minx + insets.left;
            minx = fminf( minx, x);
            break;
         }
      }

      // p->nGlyphs know to be > 0 by above loop
      for( i = p->nGlyphs - 1;; --i)
      {
         glyph = &p->glyphs[ i];
         if( UIGlyphPositionHasStrokes( glyph))
         {
            x    = glyph->maxx - insets.right;
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
      if( j >= _nRows)
         break;

      p = &_rowGlyphs[ j];
      for( i = 0; i < p->nGlyphs; i++)
      {
         glyph = &p->glyphs[ i];
         if( UIGlyphPositionHasStrokes( glyph))
         {
            // converted from baseline
            y    = glyph->miny + insets.top;
            y   += _metrics.ascender + j * lineHeight;
            miny = fminf( miny, y);
         }
      }

      if( ! isinf( miny))
         break;
      ++j;
   }

   j = _nRows;
   for(;;)
   {
      if( ! j)
         break;
      --j;

      p = &_rowGlyphs[ j];
      for( i = 0; i < p->nGlyphs; i++)
      {
         glyph = &p->glyphs[ i];
         if( UIGlyphPositionHasStrokes( glyph))
         {
            y    = glyph->maxy - insets.bottom;
            y   += _metrics.ascender + j * _metrics.lineHeight;
            maxy = fmaxf( maxy, y);
         }
      }

      if( ! isinf( maxy))
         break;
   }

   MulleUILog( "%g %g %g %g", minx, miny, maxx, maxy);

   return( CGRectMake( minx, miny, maxx - minx, maxy - miny));
}



- (CGRect) visualBoundsWithContext:(id <UILayoutContext>) context;
{
   CGRect   bounds;

   bounds = [self visualBoundsWithContext:context
                                   insets:CATextLayerVisualBoundsInsets];
   return( bounds);
}


- (void) dumpRowsAndGlyphsToFILE:(FILE *) fp
{
   NSUInteger                    i;
   NSUInteger                    j;
   struct CATextLayerRowGlyphs   *p;
   struct UIGlyphPosition        *q;

   mulle_fprintf( fp, "@fontNameUTF8String : %s\n", _fontNameUTF8String ? _fontNameUTF8String: "NULL");
   mulle_fprintf( fp, "@fontPixelSize      : %g\n", _fontPixelSize);
   mulle_fprintf( fp, "@textAlignment      : %s\n", UITextAlignmentUTF8String( _textAlignment));
   mulle_fprintf( fp, "@textLetterSpacing  : %f\n", _textLetterSpacing);
   mulle_fprintf( fp, "@textLineHeight     : %f\n", [self textLineHeight]);
   mulle_fprintf( fp, "@lineBreakMode      : %s\n", NSLineBreakModeUTF8String( _lineBreakMode));

   mulle_fprintf( fp, "_metrics            : { .ascender = %g, .descender = %g, .lineheight = %g }\n",
                                               _metrics.ascender, _metrics.descender, _metrics.lineHeight);
   mulle_fprintf( fp, "_nRows              : %tu\n", _nRows);

   for( i = 0; i < _nRows; i++)
   {
      p = &_rowGlyphs[ i];
      for( j = 0; j < p->nGlyphs; j++)
      {
         q = &p->glyphs[ j];
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
