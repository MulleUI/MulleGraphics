#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


int   main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   NSRange              range;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   
   printf( "=== Text Range ===\n");
   
   // Get full text range
   range = [layouter textRange];
   printf( "Full text range: {%tu, %tu}\n", range.location, range.length);
   
   // Set partial range
   [layouter setTextRange:NSMakeRange( 4, 6)];
   range = [layouter textRange];
   printf( "Partial range: {%tu, %tu}\n", range.location, range.length);
   
   return( 0);
}
