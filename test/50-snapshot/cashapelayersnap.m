#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CAShapeLayer       *layer;
   CATransaction      *transaction;
   CAAnimationGroup   *group;

   layer = [CAShapeLayer object];
   [layer setFillColor:CGColorMakeBlue()];

   transaction = [CATransaction object];
   [transaction begin];
   {
      [layer setFillColor:CGColorMakeGreen()];
   }
   group = [transaction commit];

   return( 0);
}
