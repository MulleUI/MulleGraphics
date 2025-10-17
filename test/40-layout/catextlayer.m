#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CATextLayer       *layer;
   CGLayoutContext   *context;
   CGSize            size;

#if defined( __MULLE_OBJC__)
   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) != mulle_objc_universe_is_ok)
      return( 1);
#endif

   //
   // MEMO: nice demo on how to do font stuff without actually needing
   //       a window (or an OpenGL context)
   //
   context = [CGLayoutContext instance];

   layer = [CATextLayer layerWithFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setFontPixelSize:16.0];
   [layer setFontNameUTF8String:"sans"];
   size  = [layer sizeThatFits:CGSizeMake( INFINITY, INFINITY)
                       context:context];   
   printf( "%s\n", CGSizeUTF8String( size));

   return( 0);
}
