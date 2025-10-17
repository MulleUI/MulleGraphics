//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CATextLayer+Selection.h"

#import "import-private.h"

#import "CATextLayer+Cursor.h"
#import "CATextLayer+Layout.h"
#import "CATextLayer+RowsAndGlyphs.h"


@implementation CATextLayer ( Selection)



// #1 When selecting left, one on the right of the actual
//    cursor is being selected
// #2 When selecting right, there is no way to deselect all
//
- (void) startSelectionAtPoint:(CGPoint) point
{
   NSUInteger   i;

   i = [self characterOffsetAtPoint:point];
   if( i == NSNotFound)
      return;

   _selection      = NSRangeMake( i, 0);  // memorize start
   _startSelection = i;
}


- (void) adjustSelectionToPoint:(CGPoint) point
{
   NSUInteger   i;

   i = [self characterOffsetAtPoint:point];
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

   mulle_buffer_do_inflexible_filled( buffer, _data.characters, _data.length)
   {
      // how to keep the cursor position stable ? move cursor to 
      // _selection.location then remove text
      mulle_buffer_remove_in_range( buffer, _selection);
      _data.length = mulle_buffer_get_length( buffer);
      _data.characters[ _data.length] = 0;

      cursorPosition = [self cursorPositionForCharacterOffset:_selection.location];   
      [self setCursorPosition:cursorPosition];
      [self setSelection:NSRangeMake( 0, 0)];
   }
}


@end
