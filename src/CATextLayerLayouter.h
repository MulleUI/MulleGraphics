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

   // * The UIGlyphPosition is relative to the baseline in the Y direction
   // * If you have a string "a\na" the UIGlyphPosition for both 'a' in terms
   //   of minx,maxx,miny,maxy will be identical.
   // * If your textAlignment is center, x will move from negative to positive

   // values exist after a frame is drawn, will change on next redraw possibly
   struct CGTextMetrics                _metrics;

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
