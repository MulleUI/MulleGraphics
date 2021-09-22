#import <MulleUICore/MulleUICore.h>


void   setupScene( UIWindowPlane *contentPlane)
{
   UIView        *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CALayer        *layer;

   frame        = [contentPlane contentRect];
   frame.origin = CGPointZero;

   // shows that border is completely inside the frame
   view  = [UIView viewWithFrame:CGRectMake( 100, 100, 200, 75)];
   layer = [view layer];
   [layer setBackgroundColor:MulleColorMakeRGB( 0.0, 1.0, 0.0)];
   [layer setBorderColor:MulleColorMakeRGB( 1.0, 0.0, 0.0)];
   [layer setCornerRadius:20];
   [layer setBorderWidth:25];

   [contentPlane addSubview:view];
}


int   main()
{
   UIWindow        *window;
   UIApplication   *app;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   /*
   * window and app
   */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:MulleColorMakeRGB( 1.0, 1.0, 1.0)];

   setupScene( [window contentPlane]);

   [window dump];

   [app addWindow:window];
   [window renderLoop];
   [app terminate];
}

