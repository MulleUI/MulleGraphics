//
//  CATextLayer+RowsAndGlyphs.m
//  MulleGraphics
//
//  Copyright (c) <|YEAR|> Nat! - Mulle kybernetiK.
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
// prefer a local CATextLayer over one in import.h
#ifdef __has_include
# if __has_include( "CATextLayer.h")
#  import "CATextLayer.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"



// This category deals with glyphs and there virtual position in a coordinate
// system where the baseline is at 0 and the text is always left aligned.
//
// The textSize is based on the font information and gives the rectangle
// occupied by the text.
// visualBounds is a tight fit around the text rectangle, e.g. if there are no
// descenders, then you wont get that space.
//
// nanovg uses these value when calculating font info
//   fonsSetSize(fs, state->fontSize*scale);
//   fonsSetSpacing(fs, state->letterSpacing*scale);
//   if( ! state->clearType)
//     fonsSetBlur(fs, state->fontBlur*scale);
//   fonsSetFont(fs, state->fontId);
//
// We simplify this by always calling with UITextAlignmentLeft when asking
// for bounds and then correct this ourselves when drawing.
//
// This means, our cached information needs to change, whenever one or more
// of these properties is changed:
//
// *  font
// *  fontSize
// *  letterSpacing
// *  clearType
// *  blur
// *  text


// like in a theater, you ticket is for row 8, seat 12
typedef struct CAGlyphSeating
{
   NSUInteger   seat;
   NSUInteger   row;
} CAGlyphSeating;


// like "point" we do x, y -> seat, row
static inline struct CAGlyphSeating    
   CAGlyphSeatingMake( NSUInteger seat, NSUInteger row)
{
   return( (struct CAGlyphSeating){ .seat = seat, .row = row });
}


#define CAGlyphSeatingNull   CAGlyphSeatingMake( NSNotFound, NSNotFound)


static inline int   CAGlyphSeatingEqualToGlyphSeating( struct CAGlyphSeating a,
                                                       struct CAGlyphSeating b)
{
   return( a.seat == b.seat && a.row == b.row);
}


static inline int   CAGlyphSeatingIsNull( struct CAGlyphSeating a)
{
   return( a.seat == NSNotFound);
}



@interface CATextLayer( RowsAndGlyphs)

// called by the layouter, sets context properties and
// calls updateRowsAndGlyphsWithContext if needed
- (void) prepareRowsAndGlyphsWithContextIfNeeded:(id <UILayoutContext>) context;
- (void) prepareRowsAndGlyphsWithContext:(id <UILayoutContext>) context;


// called by property setter to invalidate
- (void) invalidateRowsAndGlyphs;


- (void) updateRowsAndGlyphsWithContext:(id <UILayoutContext>) context;
- (void) updateRowsAndGlyphsWithContextIfNeeded:(id <UILayoutContext>) context;


// canvas can be zero and this will still work (given proper max)
- (CGSize) sizeThatFits:(CGSize) max
                context:(id <UILayoutContext>) context;

// The text origin without -textOffset added. This calculates the base for the
// origin of a text for drawing. You don't pass the visual bounds, but the area
// you want to draw the text into with alignments.
// (This is used to calculate _layoutOrigin when rect == [self canvas])
// the -[CALayer insets] are not calculated into the bounds, so for
// the position in the canvas you have to use
//
// boundsInCanvas = UITextVisualBoundsExtrude( vbounds, [layer insets]);
//
// The visualBounds are purely based on font information. They do not take
// into account alignment or other non-font layouting information. i.e.
// perfect for Left and Baseline, all others need compensation for the
// changed origin.
//
- (CGRect) visualBoundsWithContext:(id <UILayoutContext>) context
                            insets:(struct MulleEdgeInsets) insets;

// convenience with CATextLayerVisualBoundsInsets as value for insets
- (CGRect) visualBoundsWithContext:(id <UILayoutContext>) context;

// does not call updateRowsAndGlyphsWithContextIfNeeded: you must ensure that
// the glyphInformation is not stale
- (NSUInteger) characterOffsetOfGlyphAtPoint:(CGPoint) point;

// does not call updateRowsAndGlyphsWithContextIfNeeded: you must ensure that
// the glyphInformation is not stale
- (CAGlyphSeating) getGlyphPosition:(struct UIGlyphPosition  *) glyphPosition
                            atPoint:(CGPoint) point;


- (void) dumpRowsAndGlyphsToFILE:(FILE *) fp;

@end
