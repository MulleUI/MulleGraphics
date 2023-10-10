#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CALayer   *layer;
   CALayer   *layer2;

   layer = [CALayer object];
   [layer setBorderColor:CGColorMakeBlue()];

   layer2 = [[layer copy] autorelease];
   [layer2 setBorderColor:CGColorMakeGreen()];

   return( 0);
}
