#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>

//
// Standalone test for tab character rendering non-determinism bug
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
   CATextLayer       *layer;
   CGLayoutContext   *context;
   CGRect            vbounds;
   char              *text;
   int               i;
   
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setFontPixelSize:16.0f];
   
   mulle_printf( "=== Tab Character Rendering Test ===\n\n");
   
   mulle_printf( "BUG: Single tab shows non-deterministic values\n");
   mulle_printf( "Running 10 iterations to demonstrate randomness:\n\n");
   
   for( i = 0; i < 10; i++)
   {
      vbounds = get_visual_bounds( layer, context, "\t");
      mulle_printf( "Run %2d: Single tab vbounds=%s\n", i + 1, CGRectUTF8String( vbounds));
   }
   
   mulle_printf( "Expected: A-tab-B should be consistent\n");
   vbounds = get_visual_bounds( layer, context, "A\tB");
   text = [layer textUTF8String];
   mulle_printf( "A-tab-B: \"%s\", vbounds=%s\n\n",
           text, CGRectUTF8String( vbounds));

   mulle_printf( "\nExpected: Three tabs should be consistent\n");
   vbounds = get_visual_bounds( layer, context, "\t\t\t");
   mulle_printf( "Three tabs: vbounds=%s\n", CGRectUTF8String( vbounds));
   
   mulle_printf( "\nRoot cause: Uninitialized memory in fontstash/stb_truetype\n");
   mulle_printf( "when fonts lack tab glyph definition (codepoint 9).\n");
   
   return( 0);
}
