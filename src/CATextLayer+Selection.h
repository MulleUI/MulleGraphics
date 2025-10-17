//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
// prefer a local CATextLayer over one in import.h
#ifdef __has_include
# if __has_include( "CATextLayer.h")
#  import "CATextLayer.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


/*
 * Selection is a NSRange in the textUTF8String. The selection does not
 * interpret UTF8 characters. The ranges must be set correctly
 * already.
 */
@interface CATextLayer( Selection)

- (void) startSelectionAtPoint:(CGPoint) point;
- (void) adjustSelectionToPoint:(CGPoint) point;

// select all text and move cursor to end
- (void) selectAll;
- (void) deselectAll;
- (void) deleteSelection;

@end
