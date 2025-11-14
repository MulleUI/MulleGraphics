#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


int   main( void)
{
   CATextLayer       *layer;
   CGLayoutContext   *context;
   UIEdgeInsets      insets;
   CGRect            insetCanvas;
   
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL"];
   [layer setFontPixelSize:16.0f];
   
   printf( "=== Insets ===\n");
   
   // Default insets
   insets = [layer insets];
   printf( "Default insets: {%g, %g, %g, %g}\n",
           insets.top, insets.left, insets.bottom, insets.right);
   
   // Set insets
   insets = UIEdgeInsetsMake( 10, 20, 10, 20);
   [layer setInsets:insets];
   insets = [layer insets];
   printf( "After setInsets: {%g, %g, %g, %g}\n",
           insets.top, insets.left, insets.bottom, insets.right);
   
   // Inset canvas
   insetCanvas = [layer insetCanvas];
   printf( "Inset canvas: %s\n", CGRectUTF8String( insetCanvas));
   
   return( 0);
}
