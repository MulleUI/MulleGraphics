//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
// prefer a local CATextLayer over one in import.h
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

