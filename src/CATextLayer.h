#ifdef __has_include
# if __has_include( "CALayer.h")
#  import "CALayer.h"
# endif
#endif

#import "import.h"

// not a string in MulleUI
// TODO: rename or at least alias the k constants
typedef NS_ENUM( NSUInteger, CATextLayerAlignmentMode)
{
   CAAlignmentLeft = 0,
   CAAlignmentRight,
   CAAlignmentCenter

   // kCAAlignmentJustified,
   // kCAAlignmentNatural,
}; 

#define kCAAlignmentLeft    CAAlignmentLeft
#define kCAAlignmentRight   CAAlignmentRight
#define kCAAlignmentCenter  CAAlignmentCenter

extern NS_ENUM_TABLE( CATextLayerAlignmentMode, 3);

static inline char   *CATextLayerAlignmentModeUTF8String( CATextLayerAlignmentMode mode)
{
   return( NS_ENUM_PRINT( CATextLayerAlignmentMode, mode));
}


typedef NS_ENUM( NSUInteger, CATextLayerVerticalAlignmentMode)
{
   MulleTextVerticalAlignmentMiddle = 0,  // default
   MulleTextVerticalAlignmentBaseline,
   MulleTextVerticalAlignmentBoundsMiddle,      // only for single line
   MulleTextVerticalAlignmentVisualMiddle,
   MulleTextVerticalAlignmentTop,
   MulleTextVerticalAlignmentBottom
};


extern NS_ENUM_TABLE( CATextLayerVerticalAlignmentMode, 6);

static inline char   *CATextLayerVerticalAlignmentModeUTF8String( CATextLayerVerticalAlignmentMode mode)
{
   return( NS_ENUM_PRINT( CATextLayerVerticalAlignmentMode, mode));
}


struct CATextLayerRowGlyphs
{
   struct mulle_structarray   glyphArray;
   NVGglyphPosition           *glyphs;
   NSUInteger                 nGlyphs;
};


typedef NS_ENUM( NSUInteger, NSLineBreakMode)
{
   NSLineBreakByClipping,
   NSLineBreakByWordWrapping
};

extern NS_ENUM_TABLE( NSLineBreakMode, 2);

static inline char   *NSLineBreakModeUTF8String( NSLineBreakMode mode)
{
   return( NS_ENUM_PRINT( NSLineBreakMode, mode));
}


MULLE_C_NONNULL_FIRST
static inline void   _CATextLayerRowGlyphsInit( struct CATextLayerRowGlyphs *p,
                                                struct mulle_allocator *allocator)
{
   _mulle_structarray_init( &p->glyphArray, sizeof( NVGglyphPosition),
                                            alignof( NVGglyphPosition),
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


// search for 'x' position in row glyphs
NSUInteger   MulleNVGglyphPositionSearch( NVGglyphPosition *glyphs,
                                          NSUInteger nGlyphs,
                                          CGFloat x);

//
// Though the CATextLayer can do multiple lines, the number of lines it
// can usefully do is restricted. It chiefly does it for the sake of
// UILabel, which gives it multiple lines in a "textUTF8String" separated by '\n'
// It is not suitable for text with more than a screenful of lines. This is
// because it has no scrolling smarts and because it expensively recalculates
// all the glyphs of the text.
//
@interface CATextLayer  : CALayer
{
   // values exist after a frame is drawn,
   // will change on next redraw possibly
@private
   struct mulle_utf8data         _data;
   struct mulle_structarray      _rowArray;
   NVGtextRow                    *_rows;
   NSUInteger                    _nRows;

   struct mulle_structarray      _rowGlyphArray;
   struct CATextLayerRowGlyphs   *_rowGlyphs;
   struct mulle_utf8data         _glyphData;    // don't access it's stale!

   CGPoint                       _origin;
   CGFloat                       _lineh;
   CGFloat                       _ascender;
   CGFloat                       _descender;
   NSUInteger                    _startSelection;
   float                         _textBounds[ 4];
   float                         _visualBounds[ 6];

   CATextLayerVerticalAlignmentMode   _verticalAlignmentMode;
}

@property( assign) char                         *fontNameUTF8String;
@property( observable, assign) CGFloat          fontPixelSize;
@property( observable, assign) MulleEdgeInsets  insets;

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

//
// The selection of the UTF8 characters: the selection must not
// split graphemes and combined emoji. But CATextLayer won't check that.
//
@property( observable, assign) NSRange   selection;

//
// if range.location is != NSNotFound (default), this will be used to "cut"
// the data. This will observe UTF8 encoding, so textRange.length is
// often < textUTF8Data.length.
//
// If you read this property, when location is actually NSNotFound, it will
// give the proper textRange back. Sometimes useful for animation
//
@property( observable, assign) NSRange   textRange;
@property( observable) CGColor           selectionColor;
@property( observable) CGColor           textColor;
@property( observable) CGPoint           textOffset; // in pixels

// for cleartype it's important to know the color the text is drawn on
// if the layer backgroundColor is transparent, use this color to supply
// the correct color to use
@property( assign) CGColor                          textBackgroundColor;
@property( assign) CATextLayerAlignmentMode         alignmentMode;
@property( assign) NSLineBreakMode                  lineBreakMode;

@property( assign, getter=isMultiLineEnabled) BOOL  multiLineEnabled;

// if editable and in focus, will draw a caret/cursor
@property( assign, getter=isEditing) BOOL           editing;

// cursor position as row/column (!), this is not the textRange or the
// UTF8 offset.
@property( assign) struct MulleIntegerPoint         cursorPosition;

// only valid during and after render!
- (CGFloat) fontAscender;
- (CGFloat) fontDescender;
- (CGFloat) fontLineHeight;

// don't call this unless you're sure textBounds have been calculated ?
- (CGRect) textBounds;

// this is can be called anytime
- (CGRect) textBoundsWithContext:(CGContext *) context;

@property( assign, setter=mulleSetVerticalAlignmentMode:) \
   CATextLayerVerticalAlignmentMode   mulleVerticalAlignmentMode;

- (NSUInteger) characterOffsetForPoint:(CGPoint) point;

// utf32 offset (a la textRange) for offset in bytes into UTF8 string (a la selection)
// returns NSNotFound if offset is ouf of bounds
- (NSUInteger) textOffsetForCharacterOffset:(NSUInteger) offset;

// offset in bytes into UTF8 string (a la selection) for utf32 offset (a la textRange)
// returns NSNotFound if offset is ouf of bounds
- (NSUInteger) characterOffsetForTextOffset:(NSUInteger) offset;

@end
