#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CAShapeLayer   *layer;
   CGPath         *path;

#if defined( __MULLE_OBJC__)
   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) != mulle_objc_universe_is_ok)
      return( 1);
#endif

   layer = [CAShapeLayer layerWithFrame:CGRectMake( 0, 0, 100, 100)];
   path  = CGPathCreate( NULL);
   CGPathMoveToPoint( path, CGPointMake( 0, 0));
   CGPathAddLineToPoint( path, CGPointMake( 100, 0));
   CGPathCloseSubpath( path);
   [layer setPath:path];
   [layer setFillColor:CGColorMakeRed()];

   return( 0);
}
