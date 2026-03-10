#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


// Test that baseline alignment properly centers the baseline reference:
// - Odd rows: baseline of middle row at canvas center
// - Even rows: midpoint between two center row baselines at canvas center


static void  test_baseline_centering( CATextLayer *layer,
                                       CGLayoutContext *context,
                                       char *text,
                                       CGRect rect)
{
   CATextLayerLayouter              *layouter;
   CGPoint                          origin;
   int                              nRows;
   struct CATextLayerFontMetrics    metrics;
   CGFloat                          baselineY;
   CGFloat                          canvasCenter;
   int                              middleRow;

   layouter = [CATextLayerLayouter instance];
   [layouter setTextLayer:layer];

   [layer setTextUTF8String:text];
   [layer setTextVerticalAlignment:UITextAlignmentBaseline];
   [layer setUseVisualBounds:NO];

   origin  = [layouter textOriginInRect:rect context:context];
   metrics = [layer fontMetricsWithLayoutContext:context];

   // Count rows
   nRows = 1;
   for( char *p = text; *p; p++)
      if( *p == '\n') nRows++;

   // Calculate expected baseline position
   canvasCenter = rect.size.height / 2.0;

   if( nRows & 1)
   {
      // Odd rows: baseline of middle row
      middleRow = nRows / 2;
      baselineY = origin.y + middleRow * metrics.textLineHeight;
   }
   else
   {
      // Even rows: midpoint between two center baselines
      middleRow = nRows / 2;
      baselineY = origin.y + (middleRow - 0.5) * metrics.textLineHeight;
   }

   printf( "%d row%s: text=\"%s\" origin.y=%.2f lineHeight=%.2f baseline@%.2f center@%.2f diff=%.2f\n",
           nRows,
           nRows == 1 ? "" : "s",
           text,
           origin.y,
           metrics.textLineHeight,
           baselineY,
           canvasCenter,
           baselineY - canvasCenter);
}


int   main( int argc, char *argv[])
{
   CATextLayer       *layer;
   CGLayoutContext   *context;
   CGRect            rect;

   rect = CGRectMake( 0, 0, 200, 100);

   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];

   [layer setFontPixelSize:16.0f];
   [layer setFrame:rect];
   [layer setTextAlignment:UITextAlignmentCenter];

   printf( "=== Baseline Centering Test ===\n");
   printf( "Canvas: 200x100, center.y = 50\n");
   printf( "Font: 16px, lineHeight ~= 16px\n");
   printf( "Expected: baseline should be at canvas center (diff ~= 0)\n\n");

   test_baseline_centering( layer, context, "A", rect);
   test_baseline_centering( layer, context, "A\nB", rect);
   test_baseline_centering( layer, context, "A\nB\nC", rect);
   test_baseline_centering( layer, context, "A\nB\nC\nD", rect);
   test_baseline_centering( layer, context, "A\nB\nC\nD\nE", rect);

   printf( "\n=== Different Canvas Size ===\n");
   rect = CGRectMake( 0, 0, 400, 300);
   [layer setFrame:rect];
   printf( "Canvas: 400x300, center.y = 150\n\n");

   test_baseline_centering( layer, context, "One", rect);
   test_baseline_centering( layer, context, "One\nTwo", rect);
   test_baseline_centering( layer, context, "One\nTwo\nThree", rect);

   return( 0);
}
