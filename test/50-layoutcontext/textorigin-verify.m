#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


static void  verify_alignment_math( void)
{
   CGRect   rect;
   
   rect = CGRectMake( 0, 0, 200, 100);
   
   printf( "=== Alignment Math Verification ===\n");
   printf( "Test Rect: %s\n", CGRectUTF8String( rect));
   printf( "Font Size: 16.0\n");
   printf( "Expected font metrics (from 16px font):\n");
   printf( "  ascender:  ~12.56\n");
   printf( "  descender: ~3.44\n");
   printf( "  lineHeight: 16.0\n\n");
   
   printf( "Horizontal Alignment (X-axis):\n");
   printf( "  Left:   x = rect.minX = %.1f\n", CGRectGetMinX( rect));
   printf( "  Center: x = rect.midX = %.1f\n", CGRectGetMidX( rect));
   printf( "  Right:  x = rect.maxX = %.1f\n\n", CGRectGetMaxX( rect));
   
   printf( "Vertical Alignment (Y-axis) for single line:\n");
   printf( "  Top:      y = ascender = 12.56\n");
   printf( "  Middle:   y = (height + ascender - descender) / 2 = (100 + 12.56 - 3.44) / 2 = 54.56\n");
   printf( "  Bottom:   y = height - descender = 100 - 3.44 = 96.56\n");
   printf( "  Baseline: y = height / 2 = 100 / 2 = 50\n\n");
   
   printf( "For multi-line (3 lines, lineHeight=16):\n");
   printf( "  rowsHeight = 16 * 3 = 48\n");
   printf( "  Top:      y = ascender = 12.56\n");
   printf( "  Middle:   y = (height - rowsHeight) / 2 + ascender = (100 - 48) / 2 + 12.56 = 26 + 12.56 = 38.56... hmm\n");
   printf( "  Bottom:   y = height - rowsHeight + ascender = 100 - 48 + 12.56 = 64.56... hmm\n");
}


static void  test_with_context( void)
{
   CATextLayer         *layer;
   CATextLayerLayouter *layouter;
   CGLayoutContext     *context;
   CGPoint             origin;
   CGRect              rect;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   [layouter setTextLayer:layer];
   
   context = [CGLayoutContext instance];
   
   [layer setFontPixelSize:16.0f];
   [layer setTextUTF8String:"VfL"];
   
   rect = CGRectMake( 0, 0, 200, 100);
   
   printf( "\n=== Actual Values from textOriginInRect:context: ===\n");
   
   [layer setTextAlignment:UITextAlignmentCenter];
   [layer setTextVerticalAlignment:UITextAlignmentTop];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "Center/Top: %s\n", CGPointUTF8String( origin));
   
   [layer setTextVerticalAlignment:UITextAlignmentMiddle];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "Center/Middle: %s\n", CGPointUTF8String( origin));
   
   [layer setTextVerticalAlignment:UITextAlignmentBottom];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "Center/Bottom: %s\n", CGPointUTF8String( origin));
   
   [layer setTextVerticalAlignment:UITextAlignmentBaseline];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "Center/Baseline: %s\n", CGPointUTF8String( origin));
   
   // Multi-line test
   printf( "\nMulti-line (3 lines):\n");
   [layer setTextUTF8String:"VfL\nBochum\n1848"];
   
   [layer setTextVerticalAlignment:UITextAlignmentTop];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "Center/Top: %s\n", CGPointUTF8String( origin));
   
   [layer setTextVerticalAlignment:UITextAlignmentMiddle];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "Center/Middle: %s\n", CGPointUTF8String( origin));
   
   [layer setTextVerticalAlignment:UITextAlignmentBottom];
   origin = [layouter textOriginInRect:rect context:context];
   printf( "Center/Bottom: %s\n", CGPointUTF8String( origin));
}


int   main( int argc, char *argv[])
{
   verify_alignment_math();
   test_with_context();
   
   return( 0);
}
