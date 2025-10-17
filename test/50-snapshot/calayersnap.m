#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CGGraphicsLayer    *layer;
   CATransaction      *transaction;
   CAAnimationGroup   *group;

   layer = [CGGraphicsLayer instance];
   [layer setBorderColor:CGColorMakeBlue()];

   transaction = [CATransaction instance];
   [transaction begin];
   {
      [transaction setAnimationDuration:1.0];
      [layer setBorderColor:CGColorMakeGreen()];
   }
   group = [transaction commit];
   printf( "%td\n", [group numberOfAnimations]);

   return( 0);
}
