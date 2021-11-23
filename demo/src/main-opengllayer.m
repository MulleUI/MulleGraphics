#import "import-private.h"


int   main()
{
   UIWindow        *window;
   UIApplication   *app;
   CALayer         *layer;
   UIView          *view;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];
   {
      layer  = [CAOpenGLLayer layerWithFrame:CGRectMake( 0, 0, 300, 300)];
      window = [UIWindow windowWithLayer:layer
                        titleUTF8String:NULL];

      // static view, no need to refresh
      [window setFrameRate:UIWindowFrameRateAsync];

      [app addWindow:window];
      [window renderLoop];
   }
   [app terminate];
}

