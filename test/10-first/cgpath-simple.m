#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CGPath   *path;

#if defined( __MULLE_OBJC__)
   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) != mulle_objc_universe_is_ok)
      return( 1);
#endif

   path = CGPathCreate( NULL);
   CGPathMoveToPoint( path, CGPointMake( 0, 0));
   CGPathAddLineToPoint( path, CGPointMake( 100, 0));
   CGPathCloseSubpath( path);
   CGPathDestroy( path);

   return( 0);
}
