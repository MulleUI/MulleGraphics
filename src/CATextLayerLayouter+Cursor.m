//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CATextLayerLayouter+Cursor.h"

#import "import-private.h"

#import "CATextLayerLayouter+Selection.h"
#import "CATextLayer.h"
#include <ctype.h>


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
   // The top of row 0 is at origin.y - ascender. Each row spans lineHeight.
   y = (NSInteger) floor( (point.y - (origin.y - _metrics.ascender)) / _metrics.lineHeight);
   if( y < 0) 
      y = 0;
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

   // before first glyph: position at start of line
   if( nGlyphs && search < glyphs[ 0].x)
      return( MulleCursorPositionMake( 0, y));

   // past last glyph: position at end of line
   return( MulleCursorPositionMake( nGlyphs, y));
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

   CATextLayerLayouterLog( CATextLayerLayouterDebugCursor,
      "char='%c' (0x%x) text=\"%s\" selection={%tu,%tu}",
      (c >= 32 && c < 127) ? c : '?', c,
      [_textLayer textUTF8String], _selection.location, _selection.length);

   [self deleteSelectionIfNeeded];

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];

   CATextLayerLayouterLog( CATextLayerLayouterDebugVerbose,
      "cursorPos=(%td,%td) charOffset=%tu",
      cursorPosition.x, cursorPosition.y, pos);

   if( pos == NSNotFound)
      return;

   data = [_textLayer textUTF8Data];
   if( pos > data.length)
      pos = data.length;

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
   if( MulleCursorPositionIsNull( cursorPosition))
      cursorPosition = MulleCursorPositionMake( pos + 1, 0);
   [self setCursorPosition:cursorPosition];

   CATextLayerLayouterLog( CATextLayerLayouterDebugCursor,
      "result text=\"%s\" cursor=(%td,%td)",
      [_textLayer textUTF8String], cursorPosition.x, cursorPosition.y);
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

   CATextLayerLayouterLog( CATextLayerLayouterDebugCursor,
      "text=\"%s\" selection={%tu,%tu}",
      [_textLayer textUTF8String], _selection.location, _selection.length);

   if( [self deleteSelectionIfNeeded])
      return;

   cursorPosition = [self cursorPosition];
   if( cursorPosition.x == NSNotFound)
      return;

   pos2           = [self characterOffsetForCursorPosition:cursorPosition];
   --cursorPosition.x; // need to move line up if hitting 0
   if( cursorPosition.x < 0)
      return;
   pos1           = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos1 == NSNotFound)
      return;
   s              = [_textLayer textUTF8String];
   if( pos2 > strlen( s))
      return;

   CATextLayerLayouterLog( CATextLayerLayouterDebugVerbose,
      "pos1=%tu pos2=%tu cursor=(%td,%td) s=\"%s\"",
      pos1, pos2, cursorPosition.x, cursorPosition.y, s);

   s = MulleObjC_asprintf( "%.*s%s", (int) pos1, s, &s[ pos2]);
   [_textLayer setTextUTF8String:s];
   [self setCursorPosition:cursorPosition];

   CATextLayerLayouterLog( CATextLayerLayouterDebugCursor,
      "result text=\"%s\" cursor=(%td,%td)",
      [_textLayer textUTF8String], cursorPosition.x, cursorPosition.y);
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

   if( _selection.length)
   {
      cursorPosition = [self cursorPositionForCharacterOffset:_selection.location];
      [self setSelection:NSRangeMake( 0, 0)];
      [self setCursorPosition:cursorPosition];
      return;
   }

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

   if( _selection.length)
   {
      cursorPosition = [self cursorPositionForCharacterOffset:_selection.location + _selection.length];
      [self setSelection:NSRangeMake( 0, 0)];
      [self setCursorPosition:cursorPosition];
      return;
   }

   cursorPosition = [self cursorPosition];
   if( cursorPosition.x == NSNotFound)
      return;

   maxPosition = [self maxCursorPosition];
   if( cursorPosition.x >= maxPosition.x)
      return;

   ++cursorPosition.x; 
   [self setCursorPosition:cursorPosition];
}


// Returns UTF8 byte offset of start of previous word (before cursor)
static NSUInteger   utf8OffsetPrevWordStart( char *s, NSUInteger pos)
{
   if( ! pos)
      return( 0);
   // skip trailing whitespace
   NSUInteger i = pos;
   while( i > 0 && isspace( (unsigned char) s[ i - 1]))
      --i;
   // skip word chars
   while( i > 0 && ! isspace( (unsigned char) s[ i - 1]))
      --i;
   return( i);
}

// Returns UTF8 byte offset of end of next word (after cursor)
static NSUInteger   utf8OffsetNextWordEnd( char *s, NSUInteger pos, NSUInteger len)
{
   NSUInteger i = pos;
   // skip leading whitespace
   while( i < len && isspace( (unsigned char) s[ i]))
      ++i;
   // skip word chars
   while( i < len && ! isspace( (unsigned char) s[ i]))
      ++i;
   return( i);
}


- (void) selectWordAtCursor
{
   MulleCursorPosition    cursorPosition;
   NSUInteger             pos;
   NSUInteger             wordStart;
   NSUInteger             wordEnd;
   struct mulle_utf8data  data;
   char                   *s;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;

   data = [_textLayer textUTF8Data];
   s    = (char *) data.characters;
   if( ! data.length)
      return;

   // find word boundaries around cursor
   wordStart = pos;
   while( wordStart > 0 && ! isspace( (unsigned char) s[ wordStart - 1]))
      --wordStart;
   wordEnd = pos;
   while( wordEnd < data.length && ! isspace( (unsigned char) s[ wordEnd]))
      ++wordEnd;

   if( wordEnd > wordStart)
   {
      _startSelection = wordStart;
      [self setSelection:NSRangeMake( wordStart, wordEnd - wordStart)];
      [self setCursorPosition:[self cursorPositionForCharacterOffset:wordEnd]];
   }
}


- (void) cursorWordLeft
{
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos;
   NSUInteger            newPos;
   char                  *s;

   [self setSelection:NSRangeMake( 0, 0)];
   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;
   s              = [_textLayer textUTF8String];
   newPos         = utf8OffsetPrevWordStart( s, pos);
   [self setCursorPosition:[self cursorPositionForCharacterOffset:newPos]];
}


- (void) cursorWordRight
{
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos;
   NSUInteger            newPos;
   struct mulle_utf8data data;
   char                  *s;

   [self setSelection:NSRangeMake( 0, 0)];
   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;
   data           = [_textLayer textUTF8Data];
   s              = (char *) data.characters;
   newPos         = utf8OffsetNextWordEnd( s, pos, data.length);
   [self setCursorPosition:[self cursorPositionForCharacterOffset:newPos]];
}


- (void) cursorHome
{
   MulleCursorPosition   cursorPosition;

   [self setSelection:NSRangeMake( 0, 0)];
   cursorPosition   = [self cursorPosition];
   cursorPosition.x = 0;
   [self setCursorPosition:cursorPosition];
}


- (void) cursorEnd
{
   MulleCursorPosition            cursorPosition;
   struct CATextLayerLayouterRow  *row;
   NSUInteger                     nRows;

   [self setSelection:NSRangeMake( 0, 0)];
   cursorPosition = [self cursorPosition];
   nRows          = _mulle_structarray_get_count( &_rowArray);
   if( ! nRows || cursorPosition.y >= nRows)
      return;
   row              = _mulle_structarray_get( &_rowArray, cursorPosition.y);
   cursorPosition.x = row->glyphRange.length;
   [self setCursorPosition:cursorPosition];
}


- (void) cursorDocHome
{
   [self setCursorPosition:MulleCursorPositionMake( 0, 0)];
}


- (void) cursorDocEnd
{
   [self setCursorPosition:[self maxCursorPosition]];
}


- (void) deleteWordBefore
{
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos;
   NSUInteger            wordStart;
   char                  *s;

   if( [self deleteSelectionIfNeeded])
      return;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound || ! pos)
      return;
   s              = [_textLayer textUTF8String];
   wordStart      = utf8OffsetPrevWordStart( s, pos);
   s = MulleObjC_asprintf( "%.*s%s", (int) wordStart, s, s + pos);
   [_textLayer setTextUTF8String:s];
   [self setCursorPosition:[self cursorPositionForCharacterOffset:wordStart]];
}


- (void) deleteWordAfter
{
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos;
   NSUInteger            wordEnd;
   struct mulle_utf8data data;
   char                  *s;

   if( [self deleteSelectionIfNeeded])
      return;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;
   data           = [_textLayer textUTF8Data];
   s              = (char *) data.characters;
   wordEnd        = utf8OffsetNextWordEnd( s, pos, data.length);
   if( wordEnd == pos)
      return;
   s = MulleObjC_asprintf( "%.*s%s", (int) pos, s, s + wordEnd);
   [_textLayer setTextUTF8String:s];
   [self setCursorPosition:cursorPosition];
}


// Selection extension: move cursor and expand selection
- (void) extendSelectionLeft
{
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos;
   NSUInteger            anchor;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound || ! pos)
      return;

   if( ! _selection.length)
      _startSelection = pos;
   anchor = _startSelection;

   --pos;
   if( pos < anchor)
      [self setSelection:NSRangeMake( pos, anchor - pos)];
   else if( pos > anchor)
      [self setSelection:NSRangeMake( anchor, pos - anchor)];
   else
      [self setSelection:NSRangeMake( 0, 0)];

   --cursorPosition.x;
   if( cursorPosition.x >= 0)
      [self setCursorPosition:cursorPosition];
}


- (void) extendSelectionRight
{
   MulleCursorPosition   cursorPosition;
   MulleCursorPosition   maxPosition;
   NSUInteger            pos;
   NSUInteger            anchor;

   cursorPosition = [self cursorPosition];
   maxPosition    = [self maxCursorPosition];
   if( cursorPosition.x >= maxPosition.x)
      return;

   pos = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;

   if( ! _selection.length)
      _startSelection = pos;
   anchor = _startSelection;

   ++pos;
   if( pos > anchor)
      [self setSelection:NSRangeMake( anchor, pos - anchor)];
   else if( pos < anchor)
      [self setSelection:NSRangeMake( pos, anchor - pos)];
   else
      [self setSelection:NSRangeMake( 0, 0)];

   ++cursorPosition.x;
   [self setCursorPosition:cursorPosition];
}


- (void) extendSelectionWordLeft
{
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos;
   NSUInteger            newPos;
   NSUInteger            anchor;
   char                  *s;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;
   s      = [_textLayer textUTF8String];
   newPos = utf8OffsetPrevWordStart( s, pos);
   anchor = _selection.length ? _selection.location + _selection.length : pos;
   if( newPos < anchor)
      [self setSelection:NSRangeMake( newPos, anchor - newPos)];
   else
      [self setSelection:NSRangeMake( anchor, newPos - anchor)];
   [self setCursorPosition:[self cursorPositionForCharacterOffset:newPos]];
}


- (void) extendSelectionWordRight
{
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos;
   NSUInteger            newPos;
   NSUInteger            anchor;
   struct mulle_utf8data data;
   char                  *s;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;
   data   = [_textLayer textUTF8Data];
   s      = (char *) data.characters;
   newPos = utf8OffsetNextWordEnd( s, pos, data.length);
   anchor = _selection.length ? _selection.location : pos;
   if( newPos > anchor)
      [self setSelection:NSRangeMake( anchor, newPos - anchor)];
   else
      [self setSelection:NSRangeMake( newPos, anchor - newPos)];
   [self setCursorPosition:[self cursorPositionForCharacterOffset:newPos]];
}


- (void) extendSelectionHome
{
   MulleCursorPosition   cursorPosition;
   NSUInteger            pos;
   NSUInteger            anchor;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;

   if( ! _selection.length)
      _startSelection = pos;
   anchor = _startSelection;

   cursorPosition.x = 0;
   if( anchor > 0)
      [self setSelection:NSRangeMake( 0, anchor)];
   else
      [self setSelection:NSRangeMake( 0, 0)];
   [self setCursorPosition:cursorPosition];
}


- (void) extendSelectionEnd
{
   MulleCursorPosition            cursorPosition;
   NSUInteger                     pos;
   NSUInteger                     lineEnd;
   NSUInteger                     anchor;
   struct CATextLayerLayouterRow  *row;
   NSUInteger                     nRows;
   MulleCursorPosition            endPos;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;
   nRows = _mulle_structarray_get_count( &_rowArray);
   if( ! nRows || cursorPosition.y >= nRows)
      return;
   row              = _mulle_structarray_get( &_rowArray, cursorPosition.y);
   endPos           = MulleCursorPositionMake( row->glyphRange.length, cursorPosition.y);
   lineEnd          = [self characterOffsetForCursorPosition:endPos];
   if( lineEnd == NSNotFound)
      return;

   if( ! _selection.length)
      _startSelection = pos;
   anchor = _startSelection;

   if( lineEnd > anchor)
      [self setSelection:NSRangeMake( anchor, lineEnd - anchor)];
   else
      [self setSelection:NSRangeMake( 0, 0)];
   [self setCursorPosition:endPos];
}


- (void) extendSelectionDocHome
{
   NSUInteger            pos;
   MulleCursorPosition   cursorPosition;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound || ! pos)
      return;
   [self setSelection:NSRangeMake( 0, pos)];
   [self setCursorPosition:MulleCursorPositionMake( 0, 0)];
}


- (void) extendSelectionDocEnd
{
   NSUInteger            pos;
   NSUInteger            endPos;
   MulleCursorPosition   cursorPosition;
   MulleCursorPosition   maxPos;
   struct mulle_utf8data data;

   cursorPosition = [self cursorPosition];
   pos            = [self characterOffsetForCursorPosition:cursorPosition];
   if( pos == NSNotFound)
      return;
   data   = [_textLayer textUTF8Data];
   endPos = data.length;
   if( endPos <= pos)
      return;
   [self setSelection:NSRangeMake( pos, endPos - pos)];
   maxPos = [self maxCursorPosition];
   [self setCursorPosition:maxPos];
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
