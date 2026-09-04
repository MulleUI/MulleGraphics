//
//  CATextLayer.h
//  MulleGraphics
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
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
# if __has_include( "CGGraphicsLayer.h")
#  import "CGGraphicsLayer.h"
# endif
#endif

#import "import.h"


typedef NS_ENUM( NSUInteger, CATextLayerCursorStyle)
{
   CATextLayerCursorStyleNone,
   CATextLayerCursorStyleLine
};


typedef NS_ENUM( NSUInteger, CATextLayerSelectionStyle)
{
   CATextLayerSelectionStyleNone,
   CATextLayerSelectionStyleRect
};


struct CATextLayerRow
{
   NSRange                     textRange;

   CGFloat                     selectionX;
   CGFloat                     selectionWidth;
   NSRange                     selectionRange;  // byte range of selected text (within textData)
   CATextLayerSelectionStyle   selectionStyle;

   CGFloat                     cursorX;
   CATextLayerCursorStyle      cursorStyle;
};


struct CATextLayerFontMetrics
{
   CGFloat   fontPixelSize;
   CGFloat   textLineHeight;
};


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
   struct mulle_utf8data        _textData;
   struct mulle_structarray     _rowArray; // contains CATextLayerRow
}

@property( observable, assign) UIEdgeInsets   insets;

// place where the drawing of the first row begins. This needs to change
// with textAlignment (!) this needs to be calculated with -insetCanvas
@property( observable, assign) CGPoint   origin;

@property( observable, copy) CGPaint     *selectionPaint;
@property( observable, copy) CGPaint     *cursorPaint;

// MEMO: text is drawn with a small font image as the "paint", which is 
//       colorized with a mono color, so gradients aren't possible
@property( observable, copy) CGPaint     *textPaint;

// only used with clearType or if drawsTextBackground is set. If nil, the
// default backgroundPaint will be used. The textBackgroundPaint is just
// informational for clearType it will not be used to paint. It will get used
// if drawsTextBackground is enabled.
@property( observable, copy) CGPaint     *textBackgroundPaint;

// for cleartype it's important to know the color the text is drawn on
// if the layer backgroundColor is transparent, use this color to supply
// the correct color to use
@property( assign, getter=isClearTypeEnabled) BOOL   clearTypeEnabled;

// if YES, anti-aliasing pixels are considered visible in visualBounds
// if NO (default), visualBounds is inset by 1 pixel to exclude anti-aliasing
@property( assign, getter=isAliasPixelVisible) BOOL  aliasPixelVisible;


// properties that invalidate rows and glyphs
// increment textPropertiesGenerationCounts
@property( readonly) NSUInteger          textPropertiesGenerationCount;

@property( assign) char                  *fontNameUTF8String;
@property( observable) CGFloat           fontPixelSize;
@property( observable, assign) float     textLetterSpacing;
@property( observable, assign) CGFloat   textLineHeight;
@property( assign) UITextAlignment       textAlignment;

// if set to INFINITY (default), this will track fontPixelSize
// If you set this to 0, all lines will run into each other
// not used by CATextLayer but used by Editor, stored here for easier UI
// setup
@property( assign) NSLineBreakMode           lineBreakMode;

// not used by CATextLayer but used by Editor, stored here for easier UI
// setup
@property( assign) UITextVerticalAlignment   textVerticalAlignment;

// if YES, use visual bounds (actual rendered pixels) for vertical alignment
// if NO (default), use font metrics bounds (ascender/descender/lineHeight)
// NOTE: not observable because BOOLs cannot be animated
@property( assign) BOOL                      useVisualBounds;
@property( assign) BOOL                      drawsTextBackground;



// means: it enables drawing a selection
@property( assign, getter=isSelectable) BOOL selectable;
// means: it enables showing a cursor
@property( assign, getter=isEditable) BOOL   editable; // used by Layouter
// means: it actually shows a cursor
@property( assign, getter=isEditing) BOOL    editing;

// temporarily used by sizeToFit: only, ignore
@property( assign) CGSize                sizeToFitMaxSize;

@property( readonly) struct CATextLayerFontMetrics  renderedFontMetrics;

- (CGRect) insetCanvas; // convenience for the layouter

- (void) setTextColor:(CGColor) color;
- (void) setSelectionColor:(CGColor) color;
- (void) setTextBackgroundColor:(CGColor) color;
- (void) setCursorColor:(CGColor) color;

// given textBackgroundColor or backgroundColor suggests a visible text
// color
- (CGPaint *) suggestedTextPaint;


// setting this will wipe all textLayerRows(!). Which means nothing
// will be displayed until you fill up the textLayerRowInfos.
// increments textPropertiesGenerationCounts
- (void) setTextUTF8Data:(struct mulle_utf8data) data;
- (struct mulle_utf8data) textUTF8Data;

// convenience for above
- (void) setTextUTF8String:(char *) s;
- (char *) textUTF8String;  // will be a copy, if internal data has no trailing zero byte


// textLayerRows. The CATextLayer only displays its textLayerRows, which index
// into textUTF8Data, so you need to set both.
- (void) addTextLayerRows:(struct CATextLayerRow *) row
                    count:(NSUInteger) count;
- (void) addTextLayerRow:(struct CATextLayerRow *) row;
- (NSUInteger) numberOfRows;
- (void) removeAllTextLayerRows;


- (NSUInteger) textOffsetForCharacterOffset:(NSUInteger) offset;

// offset in bytes into UTF8 string (a la selection) for utf32 offset (a la textRange)
- (NSUInteger) characterOffsetForTextOffset:(NSUInteger) offset;

// this sets all text properties in the layer that affect text size and
// glyph positions (fontPixelSize, fontName, textLetterSpacing...)
- (struct CATextLayerFontMetrics) fontMetricsWithLayoutContext:(id <UILayoutContext>) context;

- (struct CATextLayerFontMetrics) prepareLayoutContext:(id <UILayoutContext>) context;

- (CGRect) glyphRectAtPoint:(CGPoint) point;

- (NSUInteger) characterOffsetAtPoint:(CGPoint) point;

- (CGRect) visualBoundsWithContext:(id <UILayoutContext>) context;

//
// this may change fontSize to a random value!
//
- (CGFloat) suggestedFontPixelSizeWithContext:(id <UILayoutContext>) context;

// this tries to fit the text also horizontally into canvas, this is
// used by UIButton initially (unless you set a fontPixelSize)
- (CGFloat) suggestedFontPixelSizeToFitTextWithContext:(id <UILayoutContext>) context;

@end
