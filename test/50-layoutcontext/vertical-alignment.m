#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


static void  print_alignment_result( char *text,
                                      UITextVerticalAlignment vAlign,
                                      BOOL useVisualBounds,
                                      CGRect rect,
                                      CGPoint origin,
                                      int nRows)
{
   printf( "text:\"%s\" align:%s visual:%s rect:%s -> origin:%s [%d rows]\n",
           text,
           UITextVerticalAlignmentUTF8String( vAlign),
           useVisualBounds ? "YES" : "NO",
           CGRectUTF8String( rect),
           CGPointUTF8String( origin),
           nRows);
}


static void  test_alignment( CATextLayer *layer,
                              CGLayoutContext *context,
                              char *text,
                              UITextVerticalAlignment vAlign,
                              BOOL useVisualBounds,
                              CGRect rect)
{
   CATextLayerLayouter   *layouter;
   CGPoint               origin;
   int                   nRows;

   layouter = [CATextLayerLayouter instance];
   [layouter setTextLayer:layer];

   [layer setTextUTF8String:text];
   [layer setTextVerticalAlignment:vAlign];
   [layer setUseVisualBounds:useVisualBounds];

   origin = [layouter textOriginInRect:rect
                               context:context];

   // Count rows
   nRows = 1;
   for( char *p = text; *p; p++)
      if( *p == '\n') nRows++;

   print_alignment_result( text, vAlign, useVisualBounds, rect, origin, nRows);
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

   printf( "=== Baseline Alignment (Default) ===\n");
   printf( "# Single line:\n");
   test_alignment( layer, context, "VfL", UITextAlignmentBaseline, NO, rect);
   printf( "# Two lines (even - midpoint between center baselines):\n");
   test_alignment( layer, context, "VfL\nBochum", UITextAlignmentBaseline, NO, rect);
   printf( "# Three lines (odd - middle row baseline):\n");
   test_alignment( layer, context, "VfL\nBochum\n1848", UITextAlignmentBaseline, NO, rect);

   printf( "\n=== Top Alignment ===\n");
   printf( "# Font metrics bounds:\n");
   test_alignment( layer, context, "VfL", UITextAlignmentTop, NO, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", UITextAlignmentTop, NO, rect);
   printf( "# Visual bounds:\n");
   test_alignment( layer, context, "VfL", UITextAlignmentTop, YES, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", UITextAlignmentTop, YES, rect);

   printf( "\n=== Bottom Alignment ===\n");
   printf( "# Font metrics bounds:\n");
   test_alignment( layer, context, "VfL", UITextAlignmentBottom, NO, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", UITextAlignmentBottom, NO, rect);
   printf( "# Visual bounds:\n");
   test_alignment( layer, context, "VfL", UITextAlignmentBottom, YES, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", UITextAlignmentBottom, YES, rect);

   printf( "\n=== Middle Alignment ===\n");
   printf( "# Font metrics bounds:\n");
   test_alignment( layer, context, "VfL", UITextAlignmentMiddle, NO, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", UITextAlignmentMiddle, NO, rect);
   printf( "# Visual bounds:\n");
   test_alignment( layer, context, "VfL", UITextAlignmentMiddle, YES, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", UITextAlignmentMiddle, YES, rect);

   printf( "\n=== Fill Alignment (Special) ===\n");
   test_alignment( layer, context, "VfL", UITextAlignmentFill, NO, rect);

   printf( "\n=== Different Canvas Sizes ===\n");
   rect = CGRectMake( 0, 0, 400, 200);
   [layer setFrame:rect];
   test_alignment( layer, context, "VfL\nBochum", UITextAlignmentBaseline, NO, rect);
   test_alignment( layer, context, "VfL\nBochum", UITextAlignmentMiddle, NO, rect);

   rect = CGRectMake( 10, 20, 100, 60);
   [layer setFrame:rect];
   test_alignment( layer, context, "1848", UITextAlignmentBaseline, NO, rect);
   test_alignment( layer, context, "1848", UITextAlignmentTop, YES, rect);

   return( 0);
}
