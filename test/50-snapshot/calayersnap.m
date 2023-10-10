#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CALayer            *layer;
   CATransaction      *transaction;
   CAAnimationGroup   *group;

   layer = [CALayer object];
   [layer setBorderColor:CGColorMakeBlue()];

   transaction = [CATransaction object];
   [transaction begin];
   {
      [transaction setAnimationDuration:1.0];
      [layer setBorderColor:CGColorMakeGreen()];
   }
   group = [transaction commit];
   printf( "%td\n", [group numberOfAnimations]);

   return( 0);
}
