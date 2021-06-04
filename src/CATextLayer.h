#import "CALayer.h"

#import "MulleCursorProtocol.h"

// not a string in MulleUI
// TODO: rename or at least alias the k constants
typedef enum CATextLayerAlignmentMode
{
   CAAlignmentLeft = 0,
   CAAlignmentRight,
   CAAlignmentCenter

   // kCAAlignmentJustified,
   // kCAAlignmentNatural,
} CATextLayerAlignmentMode;

char   *CATextLayerAlignmentModeCStringDescription( enum CATextLayerAlignmentMode mode);


#define kCAAlignmentLeft    CAAlignmentLeft
#define kCAAlignmentRight   CAAlignmentRight
#define kCAAlignmentCenter  CAAlignmentCenter

typedef enum CATextLayerVerticalAlignmentMode
{
   MulleTextVerticalAlignmentMiddle = 0,  // default
   MulleTextVerticalAlignmentBaseline,
   MulleTextVerticalAlignmentBoundsMiddle,      // only for single line
   MulleTextVerticalAlignmentTop,
   MulleTextVerticalAlignmentBottom
} CATextLayerVerticalAlignmentMode;


char   *CATextLayerVerticalAlignmentModeCStringDescription( enum CATextLayerVerticalAlignmentMode mode);

struct CATextLayerRowGlyphs
{
	struct mulle_structarray   glyphArray;
   NVGglyphPosition           *glyphs;
   NSUInteger                 nGlyphs;
};


typedef enum NSLineBreakMode
{
   NSLineBreakByClipping,
   NSLineBreakByWordWrapping
} NSLineBreakMode;


MULLE_C_NONNULL_FIRST
static inline void   _CATextLayerRowGlyphsInit( struct CATextLayerRowGlyphs *p,
                                                   struct mulle_allocator *allocator)
{
   _mulle_structarray_init( &p->glyphArray, sizeof( NVGglyphPosition),
                                            alignof( NVGglyphPosition),
                                            0,
                                            allocator);
   p->glyphs  = 0;
   p->nGlyphs = 0;
}


static inline void   CATextLayerRowGlyphsDone( struct CATextLayerRowGlyphs *p)
{
   if( p)
      _mulle_structarray_done( &p->glyphArray);
}


// search for 'x' position in row glyphs
NSUInteger   MulleNVGglyphPositionSearch( NVGglyphPosition *glyphs,
                                          NSUInteger nGlyphs,
                                          CGFloat x);

//
// Though the CATextLayer can do multiple lines, the number of lines it
// can usefully do is restricted. It chiefly does it for the sake of
// UILabel, which gives it multiple lines in a "cString" separated by '\n'
// It is not suitable for text with more than a screenful of lines. This is
// because it has no scrolling smarts and because it expensively recalculates
// all the glyphs of the text.
//
@interface CATextLayer  : CALayer
{
   // values exist after a frame is drawn,
   // will change on next redraw possibly
@private
   struct mulle_utf8data           _data;
	struct mulle_structarray        _rowArray;
   NVGtextRow                      *_rows;
   NSUInteger                      _nRows;

	struct mulle_structarray        _rowGlyphArray;
   struct CATextLayerRowGlyphs  *_rowGlyphs;

   CGPoint                         _origin;
   CGFloat                         _lineh;
   CGFloat                         _ascender;
   CGFloat                         _descender;
   NSUInteger                      _startSelection;
   float                           _textBounds[ 4];

   enum CATextLayerVerticalAlignmentMode   _verticalAlignmentMode;
}

@property( assign) char                        *fontName;
@property( observable, assign) CGFloat          fontPixelSize;
@property( observable, assign) MulleEdgeInsets  insets;

// incoming data need not be zero terminated
// resets textBounds and textRange
- (void) setUTF8Data:(struct mulle_utf8data) data;
// returned data is zero terminated but does not show it in length
- (struct mulle_utf8data) UTF8Data;
- (struct mulle_utf8data) UTF8DataInTextRange;

- (char *) cString;
- (void) setCString:(char *) s;

//
// The selection of the UTF8 characters: the selection must not
// split graphemes and combined emoji. But CATextLayer won't check that.
//
@property( observable, assign) NSRange   selection;

//
// if range.location is != NSNotFound (default), this will be used to "cut"
// the data. This will observe UTF8 encoding, so textRange.length is
// often < UTF8Data.length.
// If you read this property, when location is actually NSNotFound, it will
// give the proper textRange back. Sometimes useful for animation
//
@property( observable, assign) NSRange   textRange;
@property( observable) CGColorRef        selectionColor;
@property( observable) CGColorRef        textColor;
@property( observable) CGPoint           textOffset; // in pixels

// for cleartype it's important to know the color the text is drawn on
// if the layer backgroundColor is transparent, use this color to supply
// the correct color to use
@property( assign) CGColorRef                      textBackgroundColor;
@property( assign) enum CATextLayerAlignmentMode   alignmentMode;
@property( assign) NSLineBreakMode                 lineBreakMode;

@property( assign, getter=isMultiLineEnabled) BOOL   multiLineEnabled;

// if editable and in focus, will draw a caret/cursor
@property( assign, getter=isEditable) BOOL           editable;
// cursor position as row/column
@property( assign) struct MulleIntegerPoint          cursorPosition;

// only valid during and after render!
- (CGFloat) fontAscender;
- (CGFloat) fontDescender;
- (CGFloat) fontLineHeight;

// don't call this unless you're sure textBounds have been calculated ?
- (CGRect) textBounds;

// this is can be called anytime
- (CGRect) textBoundsWithContext:(CGContext *) context;

- (enum CATextLayerVerticalAlignmentMode)  mulleVerticalAlignmentMode;
- (void) mulleSetVerticalAlignmentMode:(enum CATextLayerVerticalAlignmentMode) mode;

- (NSUInteger) characterIndexForPoint:(CGPoint) point;

@end
