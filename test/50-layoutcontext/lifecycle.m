#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


int   main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   NSUInteger           gen1, gen2;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   
   printf( "=== Lifecycle & Updates ===\n");
   
   gen1 = [layer textPropertiesGenerationCount];
   printf( "Initial generation count: %tu\n", gen1);
   
   // Update text
   [layer setTextUTF8String:"Bochum"];
   gen2 = [layer textPropertiesGenerationCount];
   printf( "After setText generation: %tu (delta: %td)\n", gen2, gen2 - gen1);
   
   // Update font
   [layer setFontPixelSize:24.0f];
   gen1 = gen2;
   gen2 = [layer textPropertiesGenerationCount];
   printf( "After setFont generation: %tu (delta: %td)\n", gen2, gen2 - gen1);
   
   return( 0);
}
