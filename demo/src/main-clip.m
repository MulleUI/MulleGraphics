#import "import-private.h"

#import "CGContext.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "UIView.h"
#import "CALayer.h"
#import <string.h>
#import "UIEdgeInsets.h"


static void   setupScene( MulleWindowPlane *contentPlane)
{
   UIView        *view;
   UIView        *subview;
   UIView        *subview2;
   CGRect         frame;
   UIEdgeInsets   insets;

   frame  = [contentPlane contentRect];

   insets = UIEdgeInsetsMake( 100, 100, 100, 100);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   view  = [UIView viewWithFrame:frame];
   [view setDebugNameCString:"parent"];
   [view setBackgroundColor:CGColorCreateGenericRGB( 0.0, 1.0, 0.0, 1.0)];
   [view setBorderColor:CGColorCreateGenericRGB( 1.0, 0.0, 0.0, 1.0)];
   [view setBorderWidth:2];

   [contentPlane addSubview:view];

   insets = UIEdgeInsetsMake( 75, 75, -75, 75);
   frame  = UIEdgeInsetsInsetRect( [view contentRect], insets);

   // clipped by view
   subview = [UIView viewWithFrame:frame];
   [subview setDebugNameCString:"child"];
   [subview setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 0.0, 1.0)];
   [subview setBorderColor:CGColorCreateGenericRGB( 0.0, 1.0, 1.0, 1.0)];
   [subview setBorderWidth:2];
   [subview setClipsToBounds:NO]; 
   [view addSubview:subview];

   insets = UIEdgeInsetsMake( 50, 50, 50 + 75, -50 - 75);
   frame  = UIEdgeInsetsInsetRect( [subview contentRect], insets);

   // clipped by view, but not by subview, which doesn't clip
   subview2 = [UIView viewWithFrame:frame];
   [subview2 setDebugNameCString:"grandchild"];
   [subview2 setBackgroundColor:CGColorCreateGenericRGB( 1.0, 0.0, 1.0, 1.0)];
   [subview2 setBorderColor:CGColorCreateGenericRGB( 0.0, 0.0, 1.0, 1.0)];
   [subview2 setBorderWidth:2];
   [subview addSubview:subview2];
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *application;

   application = [UIApplication sharedInstance];
   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorCreateGenericRGB( 1.0, 1.0, 1.0, 1.0)];

   setupScene( [window contentPlane]);

   [window dump];

   [application addWindow:window];
   [window renderLoop];
   [application terminate];

   return( 0);
}

