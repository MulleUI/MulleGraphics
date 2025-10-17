//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CATextLayer+Cursor.h"

#import "import-private.h"

#import "CATextLayer+Selection.h"



@implementation CATextLayer ( Cursor)

// ------------------------------
//
//
//
// -------------------------------
//
// -------------------------------



- (CGFloat) offsetNeededToMakeCursorVisible
{
   CGPoint                       offset;
   CGRect                        canvas;
   CGFloat                       min;
   CGFloat                       diff;
   struct UIGlyphPosition        *glyph;
   struct CATextLayerRowGlyphs   *p;

   if( _cursorPosition.y >= _nRows)
   {
      //MulleUILog( "1");
      return( 0.0);
   }

   p = &_rowGlyphs[ _cursorPosition.y];
   if( ! p->nGlyphs)
   {
      //MulleUILog( "1a");
      return( 0.0);
   }
      
   if( _cursorPosition.x > p->nGlyphs)
   {
      //MulleUILog( "2");
      return( 0.0);
   }
   canvas   = [self canvas];

   // if text fits in visible don't mess with it

   glyph    = &p->glyphs[ 0];
   offset.x = _layoutOrigin.x + glyph->x;
   if( offset.x < CGRectGetMinX( canvas))
      goto scrolling;
   // use sentinel node to our advantage
   glyph    = &p->glyphs[ p->nGlyphs];
   offset.x = _layoutOrigin.x + glyph->x - 2.0;  // overshoot of nanovg
   if( offset.x > CGRectGetMaxX( canvas))
      goto scrolling;

   return( 0.0);

// may need to scroll text to visible
scrolling:   
   glyph    = &p->glyphs[ _cursorPosition.x];

   offset.x = _layoutOrigin.x + glyph->x - 0.5; // why -0.5 ?
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
   struct CATextLayerRowGlyphs   *p;

   if( ! _nRows)
      return( MulleCursorPositionNull); // or ?

   if( offset == NSNotFound)
      return( MulleCursorPositionNull); // or ?

   for( cursorPosition.y = 0; cursorPosition.y < _nRows; cursorPosition.y++)
   {
      p = &_rowGlyphs[ cursorPosition.y];
      if( offset < p->nGlyphs)
      {
         cursorPosition.x = offset;
         return( cursorPosition);
      }
   }

   // hmm shouldn't really happen
   cursorPosition.y = _nRows - 1;
   p = &_rowGlyphs[ cursorPosition.y];
   cursorPosition.x = p->nGlyphs;
   return( cursorPosition);
}


- (MulleCursorPosition) cursorPositionForCharacterOffset:(NSUInteger) offset
{
   NSUInteger   n;

   n = [self textOffsetForCharacterOffset:offset];
   return( [self cursorPositionForTextOffset:n]);
}


- (NSUInteger) characterOffsetForCursorPosition:(MulleCursorPosition) cursorPosition
{
   struct CATextLayerRowGlyphs   *p;
   struct UIGlyphPosition        *glyph;
   struct mulle_utf8data         data;

   if( MulleCursorPositionIsMax( cursorPosition))
      cursorPosition = [self maxCursorPosition];

   if( cursorPosition.y >= _nRows)
      return( NSNotFound);

   p = &_rowGlyphs[ cursorPosition.y];
   if( cursorPosition.x > p->nGlyphs)
      return( NSNotFound);

   glyph = &p->glyphs[ cursorPosition.x];

   // nothing to draw ? then bail
   data = [self textUTF8DataInTextRange];
   return( glyph->str - (char *) data.characters);
}


- (CGPoint) pointAboveCursorPosition:(MulleCursorPosition) cursorPosition
{
   struct CATextLayerRowGlyphs   *p;

   if( MulleCursorPositionIsMax( cursorPosition))
      cursorPosition = [self maxCursorPosition];

   if( cursorPosition.y < 0 || cursorPosition.y >= _nRows)
      return( CGPointMake( -1, -1));

   p = &_rowGlyphs[ cursorPosition.y];
   if( cursorPosition.x < 0 || cursorPosition.x > p->nGlyphs)
      return( CGPointMake( -1, -1));

   return( CGPointMake( _layoutOrigin.x + p->glyphs[ cursorPosition.x].x,
                        _layoutOrigin.y - 1.0));
}


- (CGPoint) pointBelowCursorPosition:(MulleCursorPosition) cursorPosition
{
   struct CATextLayerRowGlyphs   *p;

   if( MulleCursorPositionIsMax( cursorPosition))
      cursorPosition = [self maxCursorPosition];

   if( cursorPosition.y < 0 || cursorPosition.y >= _nRows)
      return( CGPointMake( -1, -1));

   p = &_rowGlyphs[ cursorPosition.y];
   if( cursorPosition.x < 0 || cursorPosition.x > p->nGlyphs)
      return( CGPointMake( -1, -1));

   return( CGPointMake( _layoutOrigin.x + p->glyphs[ cursorPosition.x].x,
                        _layoutOrigin.y + 0.0));
}


- (MulleCursorPosition) cursorPositionForPoint:(CGPoint) point
{
   CGFloat                       search;
   NSInteger                     x;
   NSInteger                     y;
   struct CATextLayerRowGlyphs   *p;

   // figure out the row that was hit, a row is _metrics.lineHeight and
   // drawn at frame.origin.y + _layoutOrigin.y  + i *_metrics.lineHeight
   y = (NSInteger) round( (point.y -_layoutOrigin.y) / _metrics.lineHeight);
   if( y < 0) 
      return( MulleCursorPositionMake( 0, 0));
   if( y >= _nRows)
      return( MulleCursorPositionMax);

   p = &_rowGlyphs[ y];
   // calculate characters up till till this

   // TODO: binary search anyone ?
   search = point.x - _layoutOrigin.x;
   for( x = 0; x < p->nGlyphs; x++)
   {
      if( search >= p->glyphs[ x].x && search < p->glyphs[ x + 1].x)
      {
         // check if hitting left or right side
         if( search >= p->glyphs[ x].x + (p->glyphs[ x + 1].x - p->glyphs[ x].x) / 2)
            x++;
         return( MulleCursorPositionMake( x, y));
      }
   }

   return( MulleCursorPositionNull);
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


- (MulleCursorPosition) maxCursorPosition
{
   NSUInteger   x;
   NSUInteger   y;

   if( ! _nRows)
      return( MulleCursorPositionMax);

   y = _nRows - 1;
   x = _rowGlyphs[ y].nGlyphs;
   if( ! x)
      return( MulleCursorPositionMax);

   return( MulleCursorPositionMake( x, y));
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
   char                     *result;
   char                     *s;
   MulleCursorPosition      cursorPosition;
   NSUInteger               pos;
   struct mulle_allocator   *allocator;

   [self deleteSelectionIfNeeded];

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;

   assert( pos < _data.length);

   allocator = MulleObjCInstanceGetAllocator( self);
   s         = [self textUTF8String];
   mulle_buffer_do_string( buffer, allocator, result)
   {
      mulle_buffer_add_bytes( buffer, s, pos);
      mulle_utf32_bufferconvert_to_utf8( &c,
                                         1,
                                         buffer,
                                         mulle_buffer_add_bytes_callback);      
      mulle_buffer_add_string( buffer, &s[ pos]);
   }

   [self setTextUTF8String:result];

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
   char                  *s;
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos1;
   NSUInteger            pos2;

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
   s              = [self textUTF8String];
   s = MulleObjC_asprintf( "%.*s%s", (int) pos1, s, &s[ pos2]);
   [self setTextUTF8String:s];
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
   
   s              = [self textUTF8String];
   s = MulleObjC_asprintf( "%.*s%s", (int) pos1, s, &s[ pos2]);
   [self setTextUTF8String:s];
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
   struct MulleCursorUTF8Data  info;
   NSUInteger                  offset;
   MulleCursorPosition         cursorPosition;
   struct mulle_utf8data       data;

   cursorPosition = [self cursorPosition];
   offset         = [self characterOffsetForCursorPosition:cursorPosition];

   data                 = [self textUTF8DataInTextRange];
   info.dataUpToCursor  = mulle_utf8data_make( data.characters, offset);
   info.dataAfterCursor = mulle_utf8data_make( &data.characters[ offset], data.length);
   return( info);
}

@end
