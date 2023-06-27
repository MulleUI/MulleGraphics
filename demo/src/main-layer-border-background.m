#import "import-private.h"

#import <string.h>



void   setupSceneInContentPlane( UIWindowPlane *contentPlane)
{
   CALayer      *layer;
   CGGradient   *gradient;
   CGRect       canvas;
   CGRect       contentRect;
   CGRect       frame;
   UIView       *view;

   contentRect = [contentPlane contentRect];
   frame       = CGRectInset( contentRect, 20.0, 20.0);
   view        = [UIView viewWithFrame:frame];

   // MEMO: could also just forward down to layer via view...
   layer       = (CALayer *) [view layer];
   gradient    = [CGGradient gradientWithStartColor:CGColorMakeYellow()
                                           endColor:CGColorMakeMagenta()];
   [layer setBackgroundPaint:gradient];
   gradient    = [CGGradient gradientWithStartColor:CGColorMakeMagenta()
                                           endColor:CGColorMakeYellow()];
   [layer setBorderWidth:6.0];
   [layer setBorderPaint:gradient];

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

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 200, 200)];
   [window setBackgroundColor:CGColorMakeBlack()];

   setupSceneInContentPlane( [window contentPlane]);

   [app addWindow:window];

   return( [app run]);
}

