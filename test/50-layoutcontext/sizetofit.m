#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


int   main( void)
{
   CATextLayer       *layer;
   CGLayoutContext   *context;
   CGSize            textSize;
   CGRect            vbounds;
   
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   
   printf( "=== Size to Fit ===\n");
   
   // Single line
   [layer setTextUTF8String:"VfL"];
   vbounds = [layer visualBoundsWithContext:context];
   printf( "\"VfL\" vbounds: %s\n", CGRectUTF8String( vbounds));
   printf( "\"VfL\" size: %g x %g\n", vbounds.size.width, vbounds.size.height);
   
   // Multi-line
   [layer setTextUTF8String:"VfL\nBochum\n1848"];
   vbounds = [layer visualBoundsWithContext:context];
   printf( "Multi-line vbounds: %s\n", CGRectUTF8String( vbounds));
   printf( "Multi-line size: %g x %g\n", vbounds.size.width, vbounds.size.height);
   
   return( 0);
}
