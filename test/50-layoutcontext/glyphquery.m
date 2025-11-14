#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


int   main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   NSUInteger           offset;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"iWi"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   printf( "=== Glyph Query ===\n");
   
   // Character offsets
   for( offset = 0; offset < 3; offset++)
   {
      printf( "Character at offset %tu: '%c'\n", 
              offset, [layer textUTF8String][offset]);
   }
   
   return( 0);
}
