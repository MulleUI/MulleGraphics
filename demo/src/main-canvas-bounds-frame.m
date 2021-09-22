#import "import-private.h"

#import "CGContext.h"
#import "CGGeometry+CString.h"
#import "UIApplication.h"
#import "UIWindow.h"
#import "MulleLayout.h"
#import "UIView.h"
#import "UIView+Layout.h"
#import "CALayer.h"
#import <string.h>
#import "UIEdgeInsets.h"

// See ![](main-canvas-bounds-frame.png) how it should like.
//
// We draw little rectangles exactly 20x20
// as much as we can fit into the canvas
//
static void  drawStuff( CALayer *layer, CGContext *context)
{
   NSUInteger          x;
   NSUInteger          y;
   NSUInteger          w;
   NSUInteger          h;
   struct NVGcontext   *vg;
   CGRect              bounds;
   CGFloat             col;
   CGFloat             col_inc;
   CGRect              canvas;

   vg = CGContextGetNVGContext( context);

   bounds = [layer bounds];
   nvgIntersectScissor( vg, bounds.origin.x,
                            bounds.origin.y,
                            bounds.size.width,
                            bounds.size.height);

   canvas = [layer canvas];
   w = (NSUInteger) ceil( canvas.size.width / 20.0);
   h = (NSUInteger) ceil( canvas.size.height / 20.0);

   for( y = 0; y < h; y++)
      for( x = 0; x < w; x++)
      {
         nvgBeginPath( vg);
         if( (x ^ y) & 1)
            nvgFillColor( vg, MulleColorMakeHSL( 0.2 * y / h + 0.8 * x / w, 1.0, 0.8));
         else
            nvgFillColor( vg, MulleColorMakeHSL( 0.8 * y / h + 0.2 * x / w, 0.8, 0.5));
         nvgRect( vg, x * 20.0, y * 20.0, 20.0, 20.0);
         nvgFill( vg);
      }
}


#define COLS  3
#define ROWS  3

void   setupSceneInContentPlane( MulleWindowPlane *plane)
{
   CGRect             contentRect;
   CGRect             bounds;
   CGRect             frame;
   CGRect             row_frames[ ROWS];
   CGRect             frames[ ROWS][ COLS];
   NSUInteger         row;
   NSUInteger         column;
   UIView             *view;
   CALayer            *layer;
   CGRect             canvas;

   contentRect = [plane contentRect];
   contentRect = CGRectInset( contentRect, 20, 40);

   MulleRectPartitionVertically( contentRect, ROWS, row_frames, 20);

   for( row = 0; row < ROWS; row++)
   {
      MulleRectPartitionHorizontally( row_frames[ row], COLS, frames[ row], 20);
      for( column = 0; column < COLS; column++)
      {
         frame = CGRectInset( frames[ row][ column], 5, 5);

         view  = [UIView viewWithFrame:frame];
         [view setDrawCallback:drawStuff];
         [view setBorderWidth:1.0];
         [view setBorderColor:MulleColorMake( 0x00FF00FF)];
         [plane addSubview:view];

         layer = [view layer];
         // on its own just reduces or enlarges the checkerboard to be
         // drawn, nothing will scale.
         canvas = [layer canvas];
         if( row == 1)
         {
            canvas.size.width  *= 1.5;
            canvas.size.height *= 1.5;
         }
         if( row == 2)
         {
            canvas.size.width  *= 0.75;
            canvas.size.height *= 0.75;
         }

         [layer setCanvas:canvas];
         bounds = [layer bounds];

         if( column == 1)
         {
            bounds.origin.x     = 0;
            bounds.origin.y     = 0;
            bounds.size.width  *= 2.0;
            bounds.size.height *= 2.0;
         }

         if( column == 2)
         {
            bounds.origin.x     = 40;
            bounds.origin.y     = 40;
            bounds.size.width  *= 0.75;
            bounds.size.height *= 0.75;
         }
         [layer setBounds:bounds];

         fprintf( stderr, "calc %ld.%ld: c=[%s] b=[%s]\n", 
                     column, row, 
                     CGRectUTF8String( canvas),
                     CGRectUTF8String( bounds));
         fprintf( stderr, "view %ld.%ld: c=[%s] b=[%s]\n\n", 
                     column, row, 
                     CGRectUTF8String( [[view layer] canvas]),
                     CGRectUTF8String( [[view layer] bounds]));
      }
   }
}


int   main()
{
   CGContext   *context;
   UIWindow    *window;

   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorMakeRGBA( 1.0, 1.0, 1.0, 1.0)];

   setupSceneInContentPlane( [window contentPlane]);

   [window dump];

   [[UIApplication sharedInstance] addWindow:window];
   [window renderLoop];
   [[UIApplication sharedInstance] terminate];
}

