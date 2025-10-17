#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CAShapeLayer       *layer;
   CATransaction      *transaction;
   CAAnimationGroup   *group;

   layer = [CAShapeLayer instance];
   [layer setFillColor:CGColorMakeBlue()];

   transaction = [CATransaction instance];
   [transaction begin];
   {
      [layer setFillColor:CGColorMakeGreen()];
   }
   group = [transaction commit];

   return( 0);
}
