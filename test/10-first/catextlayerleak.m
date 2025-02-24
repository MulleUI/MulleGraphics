#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CATextLayer   *layer;
   CATextLayer   *layer2;

#if defined( __MULLE_OBJC__)
   if( mulle_objc_global_check_universe( __MULLE_OBJC_UNIVERSENAME__) != mulle_objc_universe_is_ok)
      return( 1);
#endif

   layer = [CATextLayer object];
   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setTextColor:CGColorMakeOliveDrab()];
   [layer setFontNameUTF8String:"sansibar"];
   
   printf( "%s\n", [layer textUTF8String]);

   return( 0);
}
