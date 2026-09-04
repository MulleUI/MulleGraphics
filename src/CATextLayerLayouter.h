//
//  CATextLayerLayouter.h
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
#ifdef __has_include
# if __has_include( "CATextLayer.h")
#  import "CATextLayer.h"
# endif
#endif

#import "import.h"

struct CATextLayerLayouterRow
{
   struct UITextRow   textRow;
   NSRange            glyphRange;
};


#define CATextLayerVisualBoundsInsets  \
   MulleEdgeInsetsMake( 0.0f, 0.0f, 0.0f, 0.0f)
//   MulleEdgeInsetsMake( 1.0f, 2.0f, 1.0f, 2.0f)




// TODO: The CATextLayer does too much. It should be dumbed down and the smarts
//       moved to either a UITextView or some intermediate object (that for
//       example would handle (Layout), (Selection), (RowsAndGlyphs).
//
// Though the CATextLayer can do multiple lines, the number of lines it
// can usefully do is restricted. It chiefly does it for the sake of
// UILabel, which gives it multiple lines in a "textUTF8String" separated by '\n'
// It is not suitable for text with more than a screenful of lines. This is
// because it has no scrolling smarts and because it expensively recalculates
// all the glyphs of the text.
//
// CATexLayerEditor forwards all unknown methods to the CATextLayer
//
@interface CATextLayerLayouter : MulleObject
{
// SELECTION
@protected
   NSUInteger                          _startSelection;

// DEBUG
   NSUInteger                          _debuggingFlags;

//
// ROWS AND GLYPHS
@protected   
   NSUInteger                          _generationCount;

   // info in _glyphArray is only valid, if
   // _rowArrayGenerationCount == [_layer textPropertyGenerationCount]
   struct mulle_structarray            _rowArray;        // contains CATextLayerLayouterRow
   BOOL                                _rowArrayValid;

   // info in _glyphArray and _rangeArray is only valid, if
   // _glyphArrayGenerationCount == [_layer textPropertyGenerationCount]
   struct mulle_structarray            _glyphArray; // contains glyphs
   BOOL                                _glyphArrayValid;

   // * The struct UIGlyphPosition is relative to the baseline in the Y direction
   // * If you have a string "a\na" the struct UIGlyphPosition for both 'a' in terms
   //   of minx,maxx,miny,maxy will be identical.
   // * If your textAlignment is center, x will move from negative to positive

   // values exist after a frame is drawn, will change on next redraw possibly
   struct CGTextMetrics                _metrics;
   // values exist if textLayer enables useVisualBounds
   struct CGTextMetrics                _visualMetrics;

   // this can be stale if the layer text has changed, do not use
}


// this is not retained! (generally the CATextLayer will retain us, or
// the view will). If you want to reuse, it temporarily set layer then
// do your thing.
@property( assign) CATextLayer   *textLayer;

//
// this is a layouting "fummel" factor, its used by -layoutWithContext:
// to tweak the origin
//
@property( assign) CGPoint        textOffset; // in pixels

//
// if range.location is != NSNotFound (default), this will be used to "cut"
// the data. This will observe UTF8 encoding, so textRange.length is
// often < textUTF8Data.length.
//
// If you read this property, when location is actually NSNotFound, it will
// give the proper textRange back. Sometimes useful for animation
//
@property( assign) NSRange        textRange;

// cursor position as row/column (!), this is not the textRange or the
// UTF8 offset.
//
// The selection of the UTF8 characters: the selection must not
// split graphemes and combined emoji. But CATextLayer won't check that.
//
@property( assign) NSRange        selection;

@property( assign) CGPixelPoint   cursorPosition;



// returned data is zero terminated but does not show it in length
- (struct mulle_utf8data) textUTF8DataInTextRange;

// only valid after having called updateRowsAndGlyphsWithContextIfNeeded:
- (CGFloat) fontAscender;
- (CGFloat) fontDescender;
- (CGFloat) fontLineHeight;

- (void) invalidate;

@end


enum
{
   CATextLayerLayouterDebugCursor    = 0x01,
   CATextLayerLayouterDebugSelection = 0x02,
   CATextLayerLayouterDebugVerbose   = 0x04
};


#define CATextLayerLayouterLog( flag, format, ...)                     \
do                                                                     \
{                                                                      \
   if( self->_debuggingFlags & (flag))                                 \
      mulle_fprintf( stderr, "%s: " format "\n",                       \
                     __PRETTY_FUNCTION__, ## __VA_ARGS__);             \
}                                                                      \
while( 0)


@interface CATextLayer( CATextLayerLayouter_Forward)

@property( assign) CGPoint        textOffset;   // in pixels
@property( assign) NSRange        textRange;    // in unichar
@property( assign) NSRange        selection;    // in unichar
@property( assign) CGPixelPoint   cursorPosition;

// returned data is zero terminated but does not show it in length
- (struct mulle_utf8data) textUTF8DataInTextRange;

// only valid after having called updateRowsAndGlyphsWithContextIfNeeded:
- (CGFloat) fontAscender;
- (CGFloat) fontDescender;
- (CGFloat) fontLineHeight;

@end
