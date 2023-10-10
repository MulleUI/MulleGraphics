#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CATransaction      *transaction;
   CAAnimationGroup   *group;
   CALayer            *layer;

   layer = [CALayer object];
   [layer setBorderPaint:[CGPaint paintWithColor:CGColorMakeIndigo()]];

   transaction = [CATransaction object];
   assert( transaction);

   [transaction begin];
   {
      // if duration is 0.0, then no animations are generated
      [transaction setAnimationDuration:1.0];
      [layer setBorderPaint:[CGPaint paintWithColor:CGColorMakeMagenta()]];
   }
   group = [transaction commit];
   printf( "%td\n", [group numberOfAnimations]);
   return( 0);
}
