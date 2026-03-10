#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


static void  test_alignment( CATextLayer *layer, 
                              CGLayoutContext *context,
                              char *text,
                              UITextAlignment hAlign,
                              UITextVerticalAlignment vAlign,
                              CGRect rect)
{
   CATextLayerLayouter   *layouter;
   CGPoint               origin;

   layouter = [CATextLayerLayouter instance];
   [layouter setTextLayer:layer];

   [layer setTextUTF8String:text];
   [layer setTextAlignment:hAlign];
   [layer setTextVerticalAlignment:vAlign];

   origin = [layouter textOriginInRect:rect
                               context:context];

   // Count newlines in text to verify row detection
   int newlines = 0;
   for(char *p = text; *p; p++)
      if(*p == '\n') newlines++;

   printf( "text: \"%s\" h:%s v:%s rect:%s -> origin:%s [%d newlines]\n",
            text,
            UITextAlignmentUTF8String( hAlign),
            UITextVerticalAlignmentUTF8String( vAlign),
            CGRectUTF8String( rect),
            CGPointUTF8String( origin),
            newlines);
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
   [layer setFrame:rect];  // Set the layer frame so canvas size is known
   [layer setLineBreakMode:NSLineBreakByWordWrapping];  // Enable line breaking

   printf( "=== Single Line Tests ===\n");

   // Horizontal alignments with top vertical
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentLeft, UITextAlignmentTop, rect);
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentCenter, UITextAlignmentTop, rect);
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentRight, UITextAlignmentTop, rect);

   // Horizontal alignments with middle vertical
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentLeft, UITextAlignmentMiddle, rect);
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentCenter, UITextAlignmentMiddle, rect);
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentRight, UITextAlignmentMiddle, rect);

   // Horizontal alignments with bottom vertical
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentLeft, UITextAlignmentBottom, rect);
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentCenter, UITextAlignmentBottom, rect);
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentRight, UITextAlignmentBottom, rect);

   // Baseline alignment (single line only)
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentCenter, UITextAlignmentBaseline, rect);

   // Visual alignments (single line) - test with useVisualBounds
   [layer setUseVisualBounds:YES];
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentCenter, UITextAlignmentMiddle, rect);
   [layer setUseVisualBounds:NO];
   
   // Fill alignment
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentCenter, UITextAlignmentFill, rect);

   printf( "\n=== Multi-Line Tests ===\n");

   // Multi-line with different horizontal alignments
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentLeft, UITextAlignmentTop, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentCenter, UITextAlignmentTop, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentRight, UITextAlignmentTop, rect);

   // Multi-line with middle vertical
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentLeft, UITextAlignmentMiddle, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentCenter, UITextAlignmentMiddle, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentRight, UITextAlignmentMiddle, rect);

   // Multi-line with bottom vertical
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentLeft, UITextAlignmentBottom, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentCenter, UITextAlignmentBottom, rect);
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentRight, UITextAlignmentBottom, rect);

   // Multi-line baseline (behaves like middle for multi-line)
   test_alignment( layer, context, "VfL\nBochum\n1848", 
                   UITextAlignmentCenter, UITextAlignmentBaseline, rect);

   printf( "\n=== Two Line Tests ===\n");

   // Two lines with different alignments
   test_alignment( layer, context, "VfL\nBochum", 
                   UITextAlignmentLeft, UITextAlignmentTop, rect);
   test_alignment( layer, context, "VfL\nBochum", 
                   UITextAlignmentCenter, UITextAlignmentMiddle, rect);
   test_alignment( layer, context, "VfL\nBochum", 
                   UITextAlignmentRight, UITextAlignmentBottom, rect);
   test_alignment( layer, context, "VfL\nBochum", 
                   UITextAlignmentCenter, UITextAlignmentBaseline, rect);

   printf( "\n=== Different Rect Sizes ===\n");

   // Small rect
   rect = CGRectMake( 10, 10, 50, 30);
   test_alignment( layer, context, "VfL", 
                   UITextAlignmentCenter, UITextAlignmentMiddle, rect);

   // Large rect
   rect = CGRectMake( 0, 0, 400, 200);
   test_alignment( layer, context, "VfL\nBochum", 
                   UITextAlignmentCenter, UITextAlignmentMiddle, rect);

   // Offset rect
   rect = CGRectMake( 50, 50, 100, 80);
   test_alignment( layer, context, "1848", 
                   UITextAlignmentRight, UITextAlignmentBottom, rect);

   return( 0);
}
