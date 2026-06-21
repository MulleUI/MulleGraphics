#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


// Test that textOriginInRect does not double-count rect.origin.x
// for left/center/right alignment.
//
// Bug: CGRectGetMinX/MidX/MaxX(rect) already include rect.origin.x,
// but then origin.x += rect.origin.x is added again — shifting text
// too far right when insetCanvas.origin.x != 0.
//
// With left-inset=20 on a 200-wide layer:
//   insetCanvas = { origin.x=20, width=160 }
//   correct left-aligned origin.x = 20
//   buggy   left-aligned origin.x = 40

int   main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   CGRect               insetCanvas;
   CGPoint              origin;

   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];

   [layouter setTextLayer:layer];

   [layer setFrame:CGRectMake( 0, 0, 200, 40)];
   [layer setTextUTF8String:"Hi"];
   [layer setFontPixelSize:16.0f];
   [layer setInsets:UIEdgeInsetsMake( 0, 20, 0, 20)];

   [layer prepareLayoutContext:context];

   insetCanvas = [layer insetCanvas];
   printf( "insetCanvas origin.x: %.1f\n", insetCanvas.origin.x);

   // Left alignment
   [layer setTextAlignment:UITextAlignmentLeft];
   origin = [layouter textOriginInRect:insetCanvas context:context];
   printf( "left   origin.x: %.1f  expected: %.1f  %s\n",
           origin.x,
           CGRectGetMinX( insetCanvas),
           origin.x == CGRectGetMinX( insetCanvas) ? "PASS" : "FAIL (double-count bug)");

   // Center alignment
   [layer setTextAlignment:UITextAlignmentCenter];
   origin = [layouter textOriginInRect:insetCanvas context:context];
   printf( "center origin.x: %.1f  expected: %.1f  %s\n",
           origin.x,
           CGRectGetMidX( insetCanvas),
           origin.x == CGRectGetMidX( insetCanvas) ? "PASS" : "FAIL (double-count bug)");

   // Right alignment
   [layer setTextAlignment:UITextAlignmentRight];
   origin = [layouter textOriginInRect:insetCanvas context:context];
   printf( "right  origin.x: %.1f  expected: %.1f  %s\n",
           origin.x,
           CGRectGetMaxX( insetCanvas),
           origin.x == CGRectGetMaxX( insetCanvas) ? "PASS" : "FAIL (double-count bug)");

   return( 0);
}
