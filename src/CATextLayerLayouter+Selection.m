//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CATextLayerLayouter+Selection.h"

#import "import-private.h"

#import "CATextLayerLayouter+Cursor.h"
#import "CATextLayerLayouter+Layout.h"
#import "CATextLayerLayouter+RowsAndGlyphs.h"
#import "CATextLayer.h"


@implementation CATextLayerLayouter( Selection)

- (void) selectionInRow:(NSUInteger) i
              textRange:(NSRange) textRange
            selectionX:(CGFloat *) outX
         selectionWidth:(CGFloat *) outWidth
{
   NSInteger                       x;
   NSRange                         selectionRange;
   struct UIGlyphPosition          *glyphs;
   struct CATextLayerLayouterRow   *row;
   NSUInteger                      nGlyphs;
   CGFloat                         startX;
   CGFloat                         endX;

   *outX     = 0;
   *outWidth = 0;

   selectionRange = NSIntersectionRange( textRange, _selection);
   if( ! selectionRange.length)
      return;

   // compute area by removing unselected characters
   // "a[iiii]a"

   // get glyphs for current row
   row     = _mulle_structarray_get( &_rowArray, i);
   glyphs  = _mulle_structarray_get( &_glyphArray, row->glyphRange.location);
   nGlyphs = row->glyphRange.length;

   x = selectionRange.location - textRange.location;
   if( x + selectionRange.length > nGlyphs)
      abort();  // can't happen or ?

   startX = glyphs[ x].x;
   endX   = glyphs[ x + selectionRange.length].x;
   
   *outWidth = endX - startX;
   if( *outWidth < 0.1)
   {
      *outWidth = 0;
      return;
   }

   *outX = startX;
}



// #1 When selecting left, one on the right of the actual
//    cursor is being selected
// #2 When selecting right, there is no way to deselect all
//
- (void) startSelectionAtPoint:(CGPoint) point
{
   NSUInteger   i;

   i = [self characterOffsetOfGlyphAtPoint:point];
   if( i == NSNotFound)
      return;

   _selection      = NSRangeMake( i, 0);  // memorize start
   _startSelection = i;
}


- (void) adjustSelectionToPoint:(CGPoint) point
{
   NSUInteger   i;

   i = [self characterOffsetOfGlyphAtPoint:point];
   if( i == NSNotFound)
      return;

   // is cursor to the left ?
   if( i <= _startSelection)
      _selection = NSRangeMake( i, _startSelection - i);
   else
      _selection = NSRangeMake( _startSelection, i - _startSelection);
#if 0
   fprintf( stderr, "Selection: %.*s (%ld, %ld)\n",
         (int) _selection.length, &_data.characters[ _selection.location],
         (long) _selection.location,
         (long) _selection.length);

#endif
}


- (void) selectAll
{
   NSRange   range;

   range = [self textRange];
   [self setSelection:range];
   [self setCursorPosition:MulleCursorPositionMax];
}


- (void) deselectAll
{
   [self setSelection:NSRangeMake( 0, 0)];
}


- (void) deleteSelection
{
   CGPixelPoint   cursorPosition;
   struct mulle_utf8data   data;

   data = [_textLayer textUTF8Data];
   mulle_buffer_do_inflexible_filled( buffer, data.characters, data.length)
   {
      // how to keep the cursor position stable ? move cursor to 
      // _selection.location then remove text
      mulle_buffer_remove_in_range( buffer, _selection);
      data.length = mulle_buffer_get_length( buffer);
      data.characters[ data.length] = 0;
      [_textLayer setTextUTF8Data:data];

      cursorPosition = [self cursorPositionForCharacterOffset:_selection.location];   
      [self setCursorPosition:cursorPosition];
      [self setSelection:NSRangeMake( 0, 0)];
   }
}


@end
