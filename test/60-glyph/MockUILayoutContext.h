//
// MockFontMetrics.h
//
// ASCII character metrics used by MockUILayoutContext.
// Treats all printable ASCII characters with the same metrics,
// except space and selected punctuation.
//
@interface MockUILayoutContext : NSObject < UILayoutContext>


// Parameters that influence the layout values being calculated

@property( assign) float             fontSize;
@property( assign) UITextAlignment   textAlign;
@property( assign) float             textLetterSpacing;
@property( assign) float             textLineHeight;
@property( assign) NSLineBreakMode   lineBreakMode;

- (void) useDefaultFont;
- (BOOL) useFontWithNameUTF8String:(char *) name;


// Font metrics retrieval
- (struct CGTextMetrics) textMetrics;

// Single-line text bounding and glyph positioning methods
- (float) getTextBounds:(CGRect *) bounds
                   text:(char *) text
                 length:(NSUInteger) length;

- (CGRect) visualBoundsOfText:(char *) text
                        length:(NSUInteger) length;

- (NSUInteger) getGlyphPositions:(struct UIGlyphPosition *) positions
                           count:(NSUInteger) count
                            text:(char *) text
                          length:(NSUInteger) length;

// Multi-line text handling methods
- (NSInteger) getTextRows:(struct UITextRow *) outputRows
                    count:(NSUInteger) maxCount
                     text:(char *) string
                   length:(NSUInteger) length
            breakRowWidth:(CGFloat) breakRowWidth;

- (CGRect) boundsOfTextRows:(struct UITextRow *) rows
                     count:(NSUInteger) count;

@end
