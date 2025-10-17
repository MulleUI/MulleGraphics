#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CATextLayer        *layer;
   CATransaction      *transaction;
   CAAnimationGroup   *group;

   layer = [CATextLayer layerWithFrame:CGRectMake( 0, 0, 200, 100)];

   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setFontPixelSize:16.0];
   [layer setFontNameUTF8String:"sans"];
   [layer setTextColor:CGColorMakeBlue()];

   transaction = [CATransaction instance];

   // this calls CATransactionSetCurrentTransaction
   [transaction begin];
   {
      [layer setTextColor:CGColorMakeGreen()];
   }
   group = [transaction commit];

   return( 0);
}
