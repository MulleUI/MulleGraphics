//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CATextLayerLayouter+Cursor.h"

#import "import-private.h"

#import "CATextLayerLayouter+Selection.h"
#import "CATextLayer.h"


@implementation CATextLayerLayouter( Cursor)


- (CGFloat) cursorXInRow:(NSUInteger) i
{
   NSUInteger                      nGlyphs;
   NSUInteger                      x;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition          *glyphs;

   if( MulleCursorPositionIsMax( _cursorPosition))
      _cursorPosition = [self maxCursorPosition];

   if( _cursorPosition.y != i)
      return( 0);

   // get glyphs for current row
   row     = _mulle_structarray_get( &_rowArray, i);
   glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
   nGlyphs = row->glyphRange.length;

   // get glyphs
   x = _cursorPosition.x;
   if( x > nGlyphs)
      return( 0);

   return( glyphs[ x].x - 0.5);
}



- (CGFloat) offsetNeededToMakeCursorVisible
{
   CGFloat                       diff;
   CGFloat                       min;
   CGPoint                       offset;
   CGPoint                       origin;
   CGRect                        canvas;
   NSUInteger                    nGlyphs;
   NSUInteger                    nRows;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition        *glyph;
   struct UIGlyphPosition        *glyphs;

   nRows = _mulle_structarray_get_count( &_rowArray);
   if( _cursorPosition.y >= nRows)
   {
      //MulleUILog( "1");
      return( 0.0);
   }

   // get glyphs for current row
   row     = _mulle_structarray_get( &_rowArray, _cursorPosition.y);
   glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
   nGlyphs = row->glyphRange.length;

   if( ! nGlyphs)
   {
      //MulleUILog( "1a");
      return( 0.0);
   }
      
   if( _cursorPosition.x > nGlyphs)
   {
      //MulleUILog( "2");
      return( 0.0);
   }

   canvas   = [_textLayer canvas];

   // if text fits in visible don't mess with it

   origin   = [_textLayer origin];

   glyph    = &glyphs[ 0];
   offset.x = origin.x + glyph->x;
   if( offset.x < CGRectGetMinX( canvas))
      goto scrolling;
   // use sentinel node to our advantage
   glyph    = &glyphs[ nGlyphs];
   offset.x = origin.x + glyph->x - 2.0;  // overshoot of nanovg
   if( offset.x > CGRectGetMaxX( canvas))
      goto scrolling;

   return( 0.0);

// may need to scroll text to visible
scrolling:   
   glyph    = &glyphs[ _cursorPosition.x];

   offset.x = origin.x + glyph->x - 0.5; // why -0.5 ?
   min      = canvas.size.width * 10.0 / 100.0;

   diff = (CGRectGetMinX( canvas) + min) - offset.x;
   if( diff > 0)
   {
      // MulleUILog( "3 %x");
      return( diff);
   }

   diff = offset.x - (CGRectGetMaxX( canvas) - min);
   if( diff > 0)
   {
      // MulleUILog( "4");
      return( -diff);
   }
   // MulleUILog( "5");
   return( 0.0);
}


- (MulleCursorPosition) cursorPositionForTextOffset:(NSUInteger) offset
{
   MulleCursorPosition           cursorPosition;
   NSUInteger                    nGlyphs;
   NSUInteger                    nRows;
   struct CATextLayerLayouterRow   *row;

   nRows = _mulle_structarray_get_count( &_rowArray);

   if( ! nRows)
      return( MulleCursorPositionNull); // or ?

   if( offset == NSNotFound)
      return( MulleCursorPositionNull); // or ?

   for( cursorPosition.y = 0; cursorPosition.y < nRows; cursorPosition.y++)
   {
      row     = _mulle_structarray_get( &_rowArray, cursorPosition.y);
      nGlyphs = row->glyphRange.length;

      if( offset < nGlyphs)
      {
         cursorPosition.x = offset;
         return( cursorPosition);
      }
   }

   // hmm shouldn't really happen
   cursorPosition.y = nRows - 1;

   row     = _mulle_structarray_get( &_rowArray, cursorPosition.y);
   nGlyphs = row->glyphRange.length;

   cursorPosition.x = nGlyphs;
   return( cursorPosition);
}


- (MulleCursorPosition) cursorPositionForCharacterOffset:(NSUInteger) offset
{
   NSUInteger   n;

   n = [_textLayer textOffsetForCharacterOffset:offset];
   return( [self cursorPositionForTextOffset:n]);
}


- (NSUInteger) characterOffsetForCursorPosition:(MulleCursorPosition) cursorPosition
{
   NSUInteger                    nGlyphs;
   NSUInteger                    nRows;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition        *glyph;
   struct UIGlyphPosition        *glyphs;
   struct mulle_utf8data         data;

   nRows = _mulle_structarray_get_count( &_rowArray);
   if( MulleCursorPositionIsMax( cursorPosition))
      cursorPosition = [self maxCursorPosition];

   if( cursorPosition.y >= nRows)
      return( NSNotFound);

   row     = _mulle_structarray_get( &_rowArray, cursorPosition.y);
   glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
   nGlyphs = row->glyphRange.length;

   if( cursorPosition.x > nGlyphs)
      return( NSNotFound);

   glyph = &glyphs[ cursorPosition.x];

   // nothing to draw ? then bail
   data = [self textUTF8DataInTextRange];
   return( glyph->str - (char *) data.characters);
}


- (CGPoint) pointAboveCursorPosition:(MulleCursorPosition) cursorPosition
{
   CGPoint                       origin;
   NSUInteger                    nGlyphs;
   NSUInteger                    nRows;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition        *glyphs;

   nRows = _mulle_structarray_get_count( &_rowArray);
   if( MulleCursorPositionIsMax( cursorPosition))
      cursorPosition = [self maxCursorPosition];

   if( cursorPosition.y < 0 || cursorPosition.y >= nRows)
      return( CGPointMake( -1, -1));

   row     = _mulle_structarray_get( &_rowArray, cursorPosition.y);
   glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
   nGlyphs = row->glyphRange.length;

   if( cursorPosition.x < 0 || cursorPosition.x > nGlyphs)
      return( CGPointMake( -1, -1));

   origin = [_textLayer origin];
   return( CGPointMake( origin.x + glyphs[ cursorPosition.x].x,
                        origin.y - 1.0));
}


- (CGPoint) pointBelowCursorPosition:(MulleCursorPosition) cursorPosition
{
   CGPoint                       origin;
   NSUInteger                    nGlyphs;
   NSUInteger                    nRows;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition        *glyphs;

   nRows = _mulle_structarray_get_count( &_rowArray);
   if( MulleCursorPositionIsMax( cursorPosition))
      cursorPosition = [self maxCursorPosition];

   if( cursorPosition.y < 0 || cursorPosition.y >= nRows)
      return( CGPointMake( -1, -1));

   row     = _mulle_structarray_get( &_rowArray, cursorPosition.y);
   glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
   nGlyphs = row->glyphRange.length;

   if( cursorPosition.x < 0 || cursorPosition.x > nGlyphs)
      return( CGPointMake( -1, -1));

   origin = [_textLayer origin];
   return( CGPointMake( origin.x + glyphs[ cursorPosition.x].x,
                        origin.y + 0.0));
}


- (MulleCursorPosition) cursorPositionForPoint:(CGPoint) point
{
   CGFloat                       search;
   CGPoint                       origin;
   NSInteger                     x;
   NSInteger                     y;
   NSUInteger                    nGlyphs;
   NSUInteger                    nRows;
   struct CATextLayerLayouterRow   *row;
   struct UIGlyphPosition        *glyphs;

   origin = [_textLayer origin];
   nRows  = _mulle_structarray_get_count( &_rowArray);
   // figure out the row that was hit, a row is _metrics.lineHeight and
   // drawn at frame.origin.y + origin.y  + i *_metrics.lineHeight
   y = (NSInteger) round( (point.y -origin.y) / _metrics.lineHeight);
   if( y < 0) 
      return( MulleCursorPositionMake( 0, 0));
   if( y >= nRows)
      return( MulleCursorPositionMax);

   row     = _mulle_structarray_get( &_rowArray, y);
   glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
   nGlyphs = row->glyphRange.length;   // calculate characters up till till this

   // TODO: binary search anyone ?
   search = point.x - origin.x;
   for( x = 0; x < nGlyphs; x++)
   {
      if( search >= glyphs[ x].x && search < glyphs[ x + 1].x)
      {
         // check if hitting left or right side
         if( search >= glyphs[ x].x + (glyphs[ x + 1].x - glyphs[ x].x) / 2)
            x++;
         return( MulleCursorPositionMake( x, y));
      }
   }

   return( MulleCursorPositionNull);
}


- (MulleCursorPosition) maxCursorPosition
{
   NSUInteger                    nGlyphs;
   NSUInteger                    nRows;
   struct CATextLayerLayouterRow   *row;

   nRows = _mulle_structarray_get_count( &_rowArray);
   if( ! nRows)
      return( MulleCursorPositionMax);

   row     = _mulle_structarray_get( &_rowArray, nRows - 1);
   nGlyphs = row->glyphRange.length;

   if( ! nGlyphs)
      return( MulleCursorPositionMax);

   return( MulleCursorPositionMake( nGlyphs, nRows - 1));
}


// point is within bounds
- (void) setCursorPositionToPoint:(CGPoint) point
{
   MulleCursorPosition   cursorPosition;

   cursorPosition = [self cursorPositionForPoint:point];
   if( ! MulleCursorPositionIsNull( cursorPosition))
      [self setCursorPosition:cursorPosition];
}


- (void) setCursorPosition:(MulleCursorPosition) cursorPosition
{
   if( MulleCursorPositionIsNull( cursorPosition))
   {
      assert( 0);
      return;
   }

   // we can store MulleCursorPositionMax as is, but
   // we need to resolve it during rendering

   // NSLog( @"cursor: %lu/%lu", (long) point.x, (long) point.y);
   _cursorPosition = cursorPosition;
}



- (BOOL) deleteSelectionIfNeeded
{
   if( ! _selection.length)
      return( NO);

   [self deleteSelection];
   return( YES);
}


// typed like mulle_utf32_t
- (void) insertUTF32Character:(int32_t) c
{
   MulleCursorPosition      cursorPosition;
   NSUInteger               pos;
   char                     *result;
   char                     *s;
   struct mulle_allocator   *allocator;
   struct mulle_utf8data    data;

   [self deleteSelectionIfNeeded];

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;

   data = [_textLayer textUTF8Data];
   assert( pos < data.length);

   allocator = MulleObjCInstanceGetAllocator( self);
   s         = [_textLayer textUTF8String];
   mulle_buffer_do_string( buffer, allocator, result)
   {
      mulle_buffer_add_bytes( buffer, s, pos);
      mulle_utf32_bufferconvert_to_utf8( &c,
                                         1,
                                         buffer,
                                         mulle_buffer_add_bytes_callback);      
      mulle_buffer_add_string( buffer, &s[ pos]);
   }

   [_textLayer setTextUTF8String:result];

   // naive!! need to consider line breaks
   cursorPosition.x++;
   [self setCursorPosition:cursorPosition];
}

- (void) enterOrReturn
{
   // don't talk to a delegate, you are a layer!
}


// cursor position is in Unicode characters...
- (void) backspaceCharacter
{
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos1;
   NSUInteger            pos2;
   char                  *s;

   if( [self deleteSelectionIfNeeded])
      return;

   cursorPosition = [self cursorPosition];
   if( cursorPosition.x == NSNotFound)
      return;

   pos2           = [self characterOffsetForCursorPosition:cursorPosition];
   --cursorPosition.x; // need to move line up if hitting 0
   pos1           = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos1 == NSNotFound)
      return;
   s              = [_textLayer textUTF8String];
   s = MulleObjC_asprintf( "%.*s%s", (int) pos1, s, &s[ pos2]);
   [_textLayer setTextUTF8String:s];
   [self setCursorPosition:cursorPosition];
}


// cursor position is in Unicode characters...
- (void) deleteCharacter
{
   char                  *s;
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos1;
   NSUInteger            pos2;

   if( [self deleteSelectionIfNeeded])
      return;

   cursorPosition = [self cursorPosition];
   if( cursorPosition.x == NSNotFound)
      return;

   pos1           = [self characterOffsetForCursorPosition:cursorPosition];
   ++cursorPosition.x;
   pos2           = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos2 == NSNotFound)
      return;

   --cursorPosition.x;
   
   s              = [_textLayer textUTF8String];
   s = MulleObjC_asprintf( "%.*s%s", (int) pos1, s, &s[ pos2]);
   [_textLayer setTextUTF8String:s];
   [self setCursorPosition:cursorPosition];
}



- (void) cursorLeft
{
   MulleCursorPosition   cursorPosition;

   cursorPosition = [self cursorPosition];
   if( cursorPosition.x == NSNotFound)
      return;

   if( ! cursorPosition.x)
      return;

   --cursorPosition.x; // need to move line up if hitting 0
   [self setCursorPosition:cursorPosition];
}


- (void) cursorRight
{
   MulleCursorPosition   cursorPosition;
   MulleCursorPosition   maxPosition;

   cursorPosition = [self cursorPosition];
   if( cursorPosition.x == NSNotFound)
      return;

   maxPosition = [self maxCursorPosition];
   if( cursorPosition.x >= maxPosition.x)
      return;

   ++cursorPosition.x; 
   [self setCursorPosition:cursorPosition];
}


- (struct MulleCursorUTF8Data) cursorUTF8Data
{
   MulleCursorPosition         cursorPosition;
   NSUInteger                  offset;
   struct MulleCursorUTF8Data  info;
   struct mulle_utf8data       data;

   cursorPosition       = [self cursorPosition];
   offset               = [self characterOffsetForCursorPosition:cursorPosition];

   data                 = [_textLayer textUTF8DataInTextRange];
   info.dataUpToCursor  = mulle_utf8data_make( data.characters, offset);
   info.dataAfterCursor = mulle_utf8data_make( &data.characters[ offset], data.length);
   return( info);
}

@end
