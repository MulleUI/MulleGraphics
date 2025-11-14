#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>

//
// Test aliasPixelVisible flag effect on visualBounds
//

int   main( void)
{
   CATextLayer       *layer;
   CGLayoutContext   *context;
   CGRect            vbounds1;
   CGRect            vbounds2;
   
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   
   printf( "=== aliasPixelVisible Flag Test ===\n");
   
   // Default: aliasPixelVisible = NO (inset by 1)
   printf( "Default aliasPixelVisible: %s\n", 
           [layer isAliasPixelVisible] ? "YES" : "NO");
   vbounds1 = [layer visualBoundsWithContext:context];
   printf( "visualBounds with NO: %s\n", CGRectUTF8String( vbounds1));
   
   // Enable: aliasPixelVisible = YES (no inset)
   [layer setAliasPixelVisible:YES];
   printf( "Set aliasPixelVisible: %s\n", 
           [layer isAliasPixelVisible] ? "YES" : "NO");
   vbounds2 = [layer visualBoundsWithContext:context];
   printf( "visualBounds with YES: %s\n", CGRectUTF8String( vbounds2));
   
   // Verify difference is 2 pixels (1 on each side)
   printf( "Width difference: %g (expected: 2.0)\n", 
           vbounds2.size.width - vbounds1.size.width);
   printf( "Height difference: %g (expected: 2.0)\n", 
           vbounds2.size.height - vbounds1.size.height);
   
   return( 0);
}
