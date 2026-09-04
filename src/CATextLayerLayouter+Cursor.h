//
//  CATextLayerLayouter+Cursor.h
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
# if __has_include( "CATextLayerLayouter.h")
#  import "CATextLayerLayouter.h"
# endif
#endif

#ifdef __has_include
# if __has_include( "CATextLayer.h")
#  import "CATextLayer.h"
# endif
#endif


// we want "import.h" always anyway
#import "import.h"

/*
 * The cursor is moving along the row information in
 * and _rowGlyphs[ y].glyphs[ x]. Each _rowGlyphs has a sentinel glyph,
 * for the end of line.
 */
struct MulleCursorUTF8Data
{
   struct mulle_utf8data    dataUpToCursor;
   struct mulle_utf8data    dataAfterCursor;
};


@interface CATextLayerLayouter( Cursor)

- (CGFloat) cursorXInRow:(NSUInteger) i;

- (CGFloat) offsetNeededToMakeCursorVisible;

// point is within bounds
- (MulleCursorPosition) cursorPositionForPoint:(CGPoint) point;
- (NSUInteger) characterOffsetForCursorPosition:(MulleCursorPosition) cursor;

// point is in pixels starting from 0,0
- (CGPoint) pointAboveCursorPosition:(MulleCursorPosition) cursor;
- (CGPoint) pointBelowCursorPosition:(MulleCursorPosition) cursor;

// offset in bytes into UTF8 string translated to cursor position
- (MulleCursorPosition) cursorPositionForCharacterOffset:(NSUInteger) offset;
- (MulleCursorPosition) cursorPositionForTextOffset:(NSUInteger) offset;

// point is within bounds
- (void) setCursorPositionToPoint:(CGPoint) point;

- (MulleCursorPosition) maxCursorPosition;

/*
 * keyboard support here for now
 */
- (void) insertUTF32Character:(int32_t) c;
- (void) backspaceCharacter;

- (struct MulleCursorUTF8Data) cursorUTF8Data;

@end


@interface CATextLayer( CATextLayerLayouter_Cursor_Forward)

- (CGFloat) cursorXInRow:(NSUInteger) i;

- (CGFloat) offsetNeededToMakeCursorVisible;

// point is within bounds
- (MulleCursorPosition) cursorPositionForPoint:(CGPoint) point;
- (NSUInteger) characterOffsetForCursorPosition:(MulleCursorPosition) cursor;

// point is in pixels starting from 0,0
- (CGPoint) pointAboveCursorPosition:(MulleCursorPosition) cursor;
- (CGPoint) pointBelowCursorPosition:(MulleCursorPosition) cursor;

// offset in bytes into UTF8 string translated to cursor position
- (MulleCursorPosition) cursorPositionForCharacterOffset:(NSUInteger) offset;
- (MulleCursorPosition) cursorPositionForTextOffset:(NSUInteger) offset;

// point is within bounds
- (void) setCursorPositionToPoint:(CGPoint) point;

- (MulleCursorPosition) maxCursorPosition;

/*
 * keyboard support here for now
 */
- (void) insertUTF32Character:(int32_t) c;
- (void) backspaceCharacter;

- (struct MulleCursorUTF8Data) cursorUTF8Data;

@end

