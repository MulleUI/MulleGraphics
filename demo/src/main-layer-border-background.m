#import "import-private.h"

#import <string.h>


//
// this demo shows how border paints do not overlap each other
//
static UIView   *demoViewWithFrame( CGRect frame, CGColor a, CGColor b)
{
   CALayer      *layer;
   CGGradient   *gradient;
   UIView       *view;

   view        = [UIView viewWithFrame:frame];

   // MEMO: could also just forward down to layer via view...
   layer       = (CGGraphicsLayer *) [view layer];
   gradient    = [CGGradient gradientWithStartColor:a
                                           endColor:b];
   [layer setBackgroundPaint:gradient];
   gradient    = [CGGradient gradientWithStartColor:b
                                           endColor:a];
   [layer setBorderWidth:6.0];
   [layer setBorderPaint:gradient];
   return( view);
}


void   setupSceneInContentView( UIView *contentView)
{
   CGRect       contentRect;
   CGRect       frame;
   UIView       *view;

   contentRect = [contentView contentRect];
   frame       = CGRectInset( contentRect, 40.0, 40.0);
   view        = demoViewWithFrame( frame, CGColorMakeYellow(), CGColorMakeMagenta());
   [contentView addSubview:view];

   frame.origin.x    -= 30.0f;
   frame.origin.y    += frame.size.height / 4.0f;
   frame.size.width   = 30.0;
   frame.size.height  = 30.0;

   view        = demoViewWithFrame( frame, CGColorMakeLimeGreen(), CGColorMakeIndigo());
   [contentView addSubview:view];
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

   setupSceneInContentView( [window contentView]);

   [app addWindow:window];

   return( [app runApp]);
}

