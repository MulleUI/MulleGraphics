#import <MulleGraphics/MulleGraphics.h>

#import "MockUILayoutContext.h"
#import "MockUILayoutContext.m.inc"


static void  test( CATextLayer *layer,id <UILayoutContext> context, char *s)
{
   CGSize                textSize;

   [layer setTextUTF8String:s];
   [layer updateRowsAndGlyphsWithContext:context];
   [layer dumpRowsAndGlyphsToFILE:stdout];

   textSize = [layer textSizeWithContext:context];
   mulle_printf( "textSize : %s\n\n", CGSizeUTF8String( textSize));
}


int   main( int argc, char *argv[])
{
   CATextLayer           *layer;
   id <UILayoutContext>  context;

   layer   = [CATextLayer instance];
   context = [MockUILayoutContext instance];

   test( layer, context, "VfL\nBochum\n1848");

   return( 0);
}
