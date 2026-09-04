//
//  CATextLayerLayouter+Selection.m
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
   CGPoint      origin;

   origin = [_textLayer origin];
   point.x -= origin.x;
   point.y -= origin.y;

   i = [self characterOffsetOfGlyphAtPoint:point];
   if( i == NSNotFound)
      return;

   _selection      = NSRangeMake( i, 0);  // memorize start
   _startSelection = i;
}


- (void) adjustSelectionToPoint:(CGPoint) point
{
   NSUInteger   i;
   CGPoint      origin;

   origin = [_textLayer origin];
   point.x -= origin.x;
   point.y -= origin.y;

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
   CATextLayerLayouterLog( CATextLayerLayouterDebugSelection,
      "textRange={%tu,%tu} text=\"%s\"",
      range.location, range.length, [_textLayer textUTF8String]);
   [self setSelection:range];
   [self setCursorPosition:MulleCursorPositionMax];
}


- (void) deselectAll
{
   CATextLayerLayouterLog( CATextLayerLayouterDebugSelection, "");
   [self setSelection:NSRangeMake( 0, 0)];
}


- (void) deleteSelection
{
   struct mulle_utf8data   data;

   CATextLayerLayouterLog( CATextLayerLayouterDebugSelection,
      "selection={%tu,%tu} text=\"%s\"",
      _selection.location, _selection.length, [_textLayer textUTF8String]);

   data = [_textLayer textUTF8Data];
   if( ! data.characters || ! data.length)
   {
      CATextLayerLayouterLog( CATextLayerLayouterDebugVerbose, "empty data, bail");
      [self setSelection:NSRangeMake( 0, 0)];
      return;
   }
   if( _selection.location + _selection.length > data.length)
   {
      CATextLayerLayouterLog( CATextLayerLayouterDebugVerbose,
         "selection out of range: loc+len=%tu > data.length=%tu",
         _selection.location + _selection.length, data.length);
      [self setSelection:NSRangeMake( 0, 0)];
      return;
   }

   mulle_buffer_do_inflexible_filled( buffer, data.characters, data.length)
   {
      mulle_buffer_remove_in_range( buffer, _selection);
      data.length = mulle_buffer_get_length( buffer);
      data.characters[ data.length] = 0;
      [_textLayer setTextUTF8Data:data];

      CATextLayerLayouterLog( CATextLayerLayouterDebugSelection,
         "after delete: text=\"%s\" cursor=(%td,0)",
         [_textLayer textUTF8String], _selection.location);

      [_textLayer setCursorPosition:MulleCursorPositionMake( _selection.location, 0)];
      [self setSelection:NSRangeMake( 0, 0)];
   }
}


@end
