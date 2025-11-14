#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>

//
// Test CATextLayer edge cases and robustness
// This test SHOULD find bugs - we want to stress the system
//
// BUGS FOUND AND FIXED:
//
// Bug 1 & 3: Text with only newlines (or mixed whitespace/newlines) returned
//            invalid bounds with infinity values (inf inf -inf -inf).
//
//   Root cause: In visualBoundsWithContext:, bounds are initialized to
//               minx=INFINITY, maxx=-INFINITY. When text has no visible glyphs
//               (newlines produce no strokes), these never get updated, and
//               CGRectMake(minx, miny, maxx-minx, maxy-miny) produces infinities.
//
//   Fix: Check if bounds are still at infinity after glyph processing and
//        return a valid degenerate rect (0,ascender,0,0) instead, matching
//        the behavior of whitespace-only text which also has no vertical extent.
//
//   Note: CGRectNull uses NAN values, but we return a valid zero-size rect
//         positioned at ascender because that's more useful for calculations
//         and matches how whitespace (spaces-only) behaves.
//
// Bug 2: NOT A BUG - Whitespace-only text returns zero-height bounds, which is
//        correct since spaces have no vertical extent (miny == maxy).
//
//
// KNOWN ISSUE: Tab Character Rendering Non-Determinism
//
// Single tab character "\t" shows SEVERE non-deterministic rendering with
// multiple different outputs (tested 10 runs):
//
//   Count | Output
//   ------|----------------------------------
//     5   | Single tab: vbounds=-4 0.56 9 12
//     1   | Single tab: vbounds=-9 0.56 18 12
//     1   | Single tab: vbounds=-10 0.56 21 12
//     1   | Single tab: vbounds=-6 -0.44 13 13
//     1   | Single tab: vbounds=-7 0.56 15 15
//     1   | Single tab: vbounds=-9 0.56 19 12
//
// Observations:
//   - "A\tB" is CONSISTENT: always -15 0.56 30 12
//   - Single "\t" is NON-DETERMINISTIC: 6+ different outputs
//   - Three "\t\t\t" is CONSISTENT: always -14 0.56 28 12
//   - Width varies wildly: 9, 13, 15, 18, 19, 21 pixels
//   - Y position varies: 0.56, -0.44 (should be constant!)
//   - Height varies: 12, 13, 15 (should be constant for same font size!)
//
// Root Cause: UNINITIALIZED MEMORY in fontstash/stb_truetype
//
// Call stack:
//   CATextLayer
//     └─ visualBoundsWithContext:
//         └─ CGLayoutContext (prepareLayoutContext:)
//             └─ nanovg functions
//                 └─ nvgTextBreakLines (nanovg.c:3561)
//                     └─ fonsTextIterNext (fontstash.h:1711)
//                         └─ fons__getGlyph (fontstash.h:1355)
//                             └─ fons__tt_buildGlyphBitmap (fontstash.h:1407)
//                                 └─ stb_truetype
//
// The problem occurs in fontstash.h:1407:
//
//   fons__tt_buildGlyphBitmap(&renderFont->font, g, size, scale, 
//                             &advance, &lsb, &x0, &y0, &x1, &y1, bitmapOption);
//
// Many TrueType fonts DO NOT define glyph data for tab character (codepoint 9).
// When stb_truetype encounters a missing glyph, it may return without 
// initializing the output parameters (advance, lsb, x0, y0, x1, y1), leaving 
// them with RANDOM STACK MEMORY values.
//
// These uninitialized values then get stored in the glyph cache and used for
// subsequent calculations in fons__getQuad (fontstash.h:1541):
//
//   *x += (int)(glyph->xadv / 10.0f + 0.5f);
//
// Where glyph->xadv contains random garbage.
//
// Why tabs surrounded by text ARE consistent:
//   When tab appears with other characters (like "A\tB"), the text measurement
//   happens in a full layout pass that may handle missing glyphs differently,
//   or the tab's contribution is overshadowed by actual character metrics.
//
// Why this is NOT a clearType issue:
//   Initially suspected nanovg's dual font contexts (clearType vs non-clearType)
//   were causing cache state issues. However, the test doesn't toggle clearType,
//   and the high variability (6+ different outputs) rules out a simple cache
//   state problem.
//
// Potential fixes (should be done in MulleCG/nanovg fork):
//   1. Initialize all output parameters in fons__tt_buildGlyphBitmap to zero
//      BEFORE calling stb_truetype functions
//   2. Add explicit tab character handling that uses space_width × tabstop_factor
//      instead of relying on font glyph data  
//   3. Ensure stb_truetype always initializes outputs even for missing glyphs
//   4. Add validation in fons__getGlyph to detect uninitialized metrics
//
// Workarounds for users:
//   - Use spaces instead of tabs
//   - Ensure tabs appear with surrounding text (not in isolation)
//   - Use fonts that explicitly define tab glyph metrics
//
// Impact:
//   - Low severity: Rare to have bare tab characters in real-world text
//   - High severity: Uninitialized memory is always a serious bug
//   - Priority: Should be fixed in nanovg/fontstash layer
//
// For detailed analysis see: TAB-RENDERING-ANALYSIS.md
//

static CGRect  get_visual_bounds( CATextLayer *layer, CGLayoutContext *context, char *text)
{
   [layer setTextUTF8String:text];
   [layer prepareLayoutContext:context];
   return( [layer visualBoundsWithContext:context]);
}


int   main( void)
{
   CATextLayer              *layer;
   CGLayoutContext          *context;
   struct mulle_utf8data    data;
   CGRect                   vbounds;
   char                     longText[256];
   char                     *text;
   int                      i;
   
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setFontPixelSize:16.0f];
   
   mulle_printf( "=== Empty and Nil Text ===\n");
   
   [layer setTextUTF8String:""];
   data = [layer textUTF8Data];
   mulle_printf( "Empty string: length=%tu\n", data.length);
   
   [layer setTextUTF8String:NULL];
   data = [layer textUTF8Data];
   mulle_printf( "NULL string: length=%tu\n", data.length);
   
   vbounds = get_visual_bounds( layer, context, "VfL");
   mulle_printf( "Valid text: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   mulle_printf( "\n=== Whitespace Only ===\n");
   vbounds = get_visual_bounds( layer, context, " ");
   mulle_printf( "Single space: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "   ");
   mulle_printf( "Three spaces: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "          ");
   mulle_printf( "Ten spaces: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   mulle_printf( "\n=== Newlines Only (STRESS TEST) ===\n");
   vbounds = get_visual_bounds( layer, context, "\n");
   mulle_printf( "Single newline: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "\n\n");
   mulle_printf( "Two newlines: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "\n\n\n");
   mulle_printf( "Three newlines: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "\n\n\n\n\n");
   mulle_printf( "Five newlines: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   mulle_printf( "\n=== Mixed Whitespace and Newlines ===\n");
   vbounds = get_visual_bounds( layer, context, " \n ");
   mulle_printf( "Space-newline-space: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "   \n   \n   ");
   mulle_printf( "Spaces and newlines: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   mulle_printf( "\n=== Newlines with Text ===\n");
   vbounds = get_visual_bounds( layer, context, "\nVfL");
   mulle_printf( "Leading newline: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "VfL\n");
   mulle_printf( "Trailing newline: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "\nVfL\n");
   mulle_printf( "Both newlines: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "A\n\n\nB");
   mulle_printf( "Multiple newlines between: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   mulle_printf( "\n=== Single Character ===\n");
   vbounds = get_visual_bounds( layer, context, "X");
   mulle_printf( "Single 'X': vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "i");
   mulle_printf( "Single 'i': vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "W");
   mulle_printf( "Single 'W': vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, ".");
   mulle_printf( "Single '.': vbounds=%s\n", CGRectUTF8String( vbounds));
   
   mulle_printf( "\n=== Unicode Characters ===\n");
   vbounds = get_visual_bounds( layer, context, "Müller");
   text = [layer textUTF8String];
   mulle_printf( "German umlaut: \"%s\", vbounds=%s\n",
           text, CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "100€");
   text = [layer textUTF8String];
   mulle_printf( "Euro sign: \"%s\", vbounds=%s\n",
           text, CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "⚽");
   text = [layer textUTF8String];
   mulle_printf( "Soccer emoji: \"%s\", vbounds=%s\n",
           text, CGRectUTF8String( vbounds));
   
   mulle_printf( "\n=== Long Lines ===\n");
   for( i = 0; i < 100; i++)
      longText[i] = 'A' + (i % 26);
   longText[100] = '\0';
   
   [layer setLineBreakMode:NSLineBreakByClipping];
   vbounds = get_visual_bounds( layer, context, longText);
   mulle_printf( "100 chars clipping: width=%g height=%g\n",
           vbounds.size.width, vbounds.size.height);
   
   [layer setLineBreakMode:NSLineBreakByWordWrapping];
   vbounds = get_visual_bounds( layer, context, longText);
   mulle_printf( "100 chars wrapping: width=%g height=%g\n",
           vbounds.size.width, vbounds.size.height);
   
   mulle_printf( "\n=== Small/Zero Frames ===\n");
   [layer setFrame:CGRectMake( 0, 0, 0, 100)];
   vbounds = get_visual_bounds( layer, context, "VfL");
   mulle_printf( "Zero width: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   [layer setFrame:CGRectMake( 0, 0, 200, 0)];
   vbounds = get_visual_bounds( layer, context, "VfL");
   mulle_printf( "Zero height: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   [layer setFrame:CGRectMake( 0, 0, 1, 1)];
   vbounds = get_visual_bounds( layer, context, "VfL");
   mulle_printf( "1x1 frame: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   [layer setFrame:CGRectMake( 0, 0, 10, 10)];
   vbounds = get_visual_bounds( layer, context, "VfL");
   mulle_printf( "10x10 frame (font=16): vbounds=%s\n", CGRectUTF8String( vbounds));
   
   mulle_printf( "\n=== Tab Characters ===\n");
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   vbounds = get_visual_bounds( layer, context, "A\tB");
   text = [layer textUTF8String];
   mulle_printf( "A-tab-B: \"%s\", vbounds=%s\n",
           text, CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "\t");
   mulle_printf( "Single tab: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "\t\t\t");
   mulle_printf( "Three tabs: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   mulle_printf( "\n=== Multi-line Variations ===\n");
   vbounds = get_visual_bounds( layer, context, "A\nB\nC");
   mulle_printf( "Three lines: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "VfL\nBochum\n1848");
   mulle_printf( "Three words: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   vbounds = get_visual_bounds( layer, context, "A\nBB\nCCC\nDDDD");
   mulle_printf( "Growing lines: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   return( 0);
}

