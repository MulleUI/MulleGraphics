#import "import-private.h"


int   main()
{
   UIWindow        *window;
   UIApplication   *app;
   CALayer         *layer;
   UIView          *view;
   NSUInteger      styleMask;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];
   {
      styleMask = UIWindowStyleMaskDefault;
      styleMask = UIWindowsStyleMaskBySetting( styleMask, UIWindowOpenGLDeprecated, YES);

      layer  = [CAOpenGLLayer layerWithFrame:CGRectMake( 0, 0, 300, 300)];
      window = [UIWindow windowWithLayer:layer
                         titleUTF8String:NULL
                               styleMask:styleMask];

      // static view, no need to refresh
      [window setFrameRate:UIWindowFrameRateAsync];

      [app addWindow:window];
   }
   return( [app runApp]);
}

