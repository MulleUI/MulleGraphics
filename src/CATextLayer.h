#ifdef __has_include
# if __has_include( "CGGraphicsLayer.h")
#  import "CGGraphicsLayer.h"
# endif
#endif

#import "import.h"


struct CATextLayerRowGlyphs
{
   struct mulle_structarray   glyphArray;
   struct UIGlyphPosition     *glyphs;
   NSUInteger                 nGlyphs;
};


MULLE_C_NONNULL_FIRST
static inline void   _CATextLayerRowGlyphsInit( struct CATextLayerRowGlyphs *p,
                                                struct mulle_allocator *allocator)
{
   _mulle_structarray_init( &p->glyphArray, sizeof( struct UIGlyphPosition),
                                            alignof( struct UIGlyphPosition),
                                            0,
                                            allocator);
   p->glyphs   = 0;
   p->nGlyphs  = 0;
}


static inline void   CATextLayerRowGlyphsDone( struct CATextLayerRowGlyphs *p)
{
   if( p)
      _mulle_structarray_done( &p->glyphArray);
}


#define CATextLayerVisualBoundsInsets  \
   MulleEdgeInsetsMake( 1.0f, 2.0f, 1.0f, 2.0f)

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
@interface CATextLayer : CGGraphicsLayer
{
   struct mulle_utf8data               _data;

// derived property
@protected
   CGPaint                            *_suggestedTextPaint;


// SELECTION
@protected
   NSUInteger                          _startSelection;

//
// LAYOUT
@protected
   CGPoint                             _layoutOrigin;  // last
//
// ROWS AND GLYPHS
@protected   
   BOOL                                _rowsAndGlyphsValid;
   // values exist after a frame is drawn, will change on next redraw possibly
   struct CGTextMetrics                _metrics;
   struct mulle_structarray            _rowArray;
   struct UITextRow                   *_rows;
   NSUInteger                          _nRows;

   struct mulle_structarray            _rowGlyphArray;

   // * The UIGlyphPosition is relative to the baseline in the Y direction
   // * If you have a string "a\na" the UIGlyphPosition for both 'a' in terms
   //   of minx,maxx,miny,maxy will be identical.
   // * If your textAlignment is center, x will move from negative to positive

   struct CATextLayerRowGlyphs        *_rowGlyphs;

@private   
   struct mulle_utf8data               _glyphData;    // don't access: it's stale!
}


//
// this is a layouting "fummel" factor, its used by -layoutWithContext:
// to tweak the _layoutOrigin
//
@property( observable) CGPoint         textOffset; // in pixels

//
// if range.location is != NSNotFound (default), this will be used to "cut"
// the data. This will observe UTF8 encoding, so textRange.length is
// often < textUTF8Data.length.
//
// If you read this property, when location is actually NSNotFound, it will
// give the proper textRange back. Sometimes useful for animation
//
@property( observable) NSRange         textRange;
@property( observable, copy) CGPaint   *selectionPaint;
@property( observable, copy) CGPaint   *cursorPaint;

// MEMO: text is drawn with a small font image as the "paint", which is 
//       colorized with a mono color, so gradients aren't possible
@property( observable, copy) CGPaint   *textPaint;

// only used with clearType. If nil, the default backgroundPaint will
// be used. The textBackgroundPaint is just informational for clearType it will
// not be used to paint
@property( observable, copy) CGPaint   *textBackgroundPaint;

// for cleartype it's important to know the color the text is drawn on
// if the layer backgroundColor is transparent, use this color to supply
// the correct color to use
@property (assign, getter=isClearTypeEnabled) BOOL  clearTypeEnabled;

// cursor position as row/column (!), this is not the textRange or the
// UTF8 offset.
//
// The selection of the UTF8 characters: the selection must not
// split graphemes and combined emoji. But CATextLayer won't check that.
//
@property( observable) NSRange                      selection;

@property( assign) CGPixelPoint                     cursorPosition;

// properties that invalidate rows and glyphs
// horizontal alignmnet
@property( assign) char                             *fontNameUTF8String;
@property( observable) CGFloat                      fontPixelSize;
@property( assign) UITextAlignment                  textAlignment;
@property( observable, assign) float                textLetterSpacing;

// if set to INFINITY (default), this will track fontPixelSize
// If you set this to 0, all lines will run into each other
@property( observable, assign) CGFloat              textLineHeight;
@property( assign) NSLineBreakMode                  lineBreakMode;

// layout properties: textVerticalAlignment should move to UIView and in
// its layout code, UIView should set the _layoutOrigin and be done with
// that.
@property( assign) UITextVerticalAlignment          textVerticalAlignment;

// clashes with UIView padding somewhat or ?
@property( observable) MulleEdgeInsets              insets;

// unused:
//@property( assign, getter=isMultiLineEnabled) BOOL  multiLineEnabled;

// if editable and in focus, will draw a caret/cursor
@property( assign, getter=isEditing) BOOL           editing;

- (void) setTextColor:(CGColor) color;
- (void) setSelectionColor:(CGColor) color;
- (void) setTextBackgroundColor:(CGColor) color;
- (void) setCursorColor:(CGColor) color;

// incoming data need not be zero terminated
// resets textBounds and textRange
- (void) setTextUTF8Data:(struct mulle_utf8data) data;

// returned data is zero terminated but does not show it in length
- (struct mulle_utf8data) textUTF8Data;
- (struct mulle_utf8data) textUTF8DataInTextRange;

// -textUTF8String will never return NULL
- (char *) textUTF8String;

// is s is NULL, "" will be used instead
- (void) setTextUTF8String:(char *) s;


// utf32 offset (a la textRange) for offset in bytes into UTF8 string (a la selection)
// returns NSNotFound if offset is ouf of bounds
- (NSUInteger) textOffsetForCharacterOffset:(NSUInteger) offset;

// only valid after layout until font change
- (CGFloat) fontAscender;
- (CGFloat) fontDescender;
- (CGFloat) fontLineHeight;

@end
