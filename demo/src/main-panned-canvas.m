#import "import-private.h"


//
// The canvas is a drawing of 1024x1024. The bounds are used to pick out
// a frame sized region off the canvas.
//
//           .----------------.
//           | frame          |
//           |                |
//           |                |
//           '----------------'
//                    ^
//                    |
//   .----------------|---.
//   |                |   |
//   | canvas         |   |
//   |       .----------------.
//   |       | bounds         |
//   |       |                |
//   |       |                |
//   |       '----------------'
//   |                    |
//   '--------------------'
//
static UIMouseMotionEvent  *handleMouseMotionEvent( UIView *contentPlane,
                                                    UIMouseMotionEvent *event)
{
   CALayer         *layer;
   CGRect          bounds;
   CGRect          contentRect;
   NSUInteger      n;
   UIView          *view;
   UIView          *views[ 1];

   //
   // any event carries mouseLocation information, so we actually needn't
   // check this, but anyway...
   //
   if( [event eventType] != UIEventTypeMotion)
      return( event);

   // get our layer somewhat clumsily,
   contentRect  = [contentPlane contentRect];
   n            = [contentPlane getSubviews:views
                                      range:NSRangeMake( 0, 1)];
   assert( n == 1);
   view  = views[ 0];
   assert( view);

   layer = (CGGraphicsLayer *) [view layer];
   assert( layer);
   //
   // there we are, now use the mouse motion event to move the bounds
   // could be nicer...
   //
   bounds           = [layer bounds];
   bounds.origin    = [event locationInView:view];
   bounds.origin.x *= contentRect.size.width / bounds.size.width;
   bounds.origin.y *= contentRect.size.height / bounds.size.height;
   [layer setBounds:bounds];
   [view setNeedsDisplay];

   return( event);  // don't consume event, even if motion
}


static BOOL   drawStuff( CGGraphicsLayer *aLayer, CGContext *context)
{
   CGFloat             canvasExtent;
   CGFloat             radius;
   CGFloat             strokeWidth;
   CGRect              canvas;

   canvas       = [aLayer canvas];
   canvasExtent = CGSizeGetMinimum( canvas.size);
   strokeWidth  = 3.0;
   radius       = (canvasExtent - strokeWidth) / 2.0;

   CGContextStrokeCircleWithColor( context, CACircleMakeWithCenterAndRadius( CGRectGetCenter( canvas), radius),
                                            strokeWidth,
                                            CGColorMakeRed());

   CGContextFontFace( context, NULL);  // default
   CGContextTextColor( context, CGColorMakeWhite());
   CGContextTextBackgroundColor( context, CGColorMakeGray());

   CGContextTextInRect( context, "Move mouse to pan",
                                 (size_t) -1,
                                 CGRectMake( 10, 10, 400, 32),
                                 CGContentModeCenterPoint,
                                 CGTextOptionAlignVisually);
   return( YES);
}


static void   setupSceneInView( UIView *contentPlane)
{
   CGGraphicsLayer   *layer;
   CGFloat           aspectFactor;
   CGRect            bounds;
   CGRect            frame;
   UIView            *view;

   frame = CGSizeCenterInRect( CGSizeMake( 600, 400), [contentPlane contentRect]);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   [view setBackgroundColor:CGColorMakeWithRGBA( 0.33, 0.33, 0.33, 1.0)];
   [contentPlane addSubview:view];

   layer = MULLE_OBJC_CLASS_CAST( CGGraphicsLayer, [view layer]);
   [layer setDrawCallback:drawStuff];

   // The canvas is a square where we draw the circle unto.

   [layer setCanvas:CGRectMake( 0, 0, 1024, 1024)];
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      assert( window);

      [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];
      [[window contentView] setMouseMotionEventCallback:handleMouseMotionEvent];
      setupSceneInView( [window contentView]);

      [app addWindow:window];
   }
   return( [app runApp]);
}


//
//                           ,╓≤æKª╨╙╙▓█D"╙╙╙*╨¥W▄╓,
//                      ╓▄ª╙└╧▓        █           ⁿ▓▓ª╦w
//                  ╓#╜^*█⌐   `╕       █           ╓▌    `╙%w
//               ╓ΦΓ      █    ╙⌐     ,█,,,Φ      ╓▌         ╙¥▄
//            ,▄▀ █▄       █µ,╓╝,╓≤╗≡≡ª╨╨╨¥≡∞╗w╓,ª█,  ,       ]▄▀V,
//          ,Φ└   ║"▀▄     ,▄▀╨"                 "╙¥▓▓       ▄▀  º▄¥,
//        ,#▌Φ▓▄╓  Φ `█Q▄M╙                           ╙¥▄ ,▄▀ ╙▄⌐`  `Φ
//       ▄▀   `V,"▀▀¼╓╩└                                 ╙¥▓╗ ,       ╙▄
//      Φ       `¥═▄▀                            ╒          ▀▄          ▓
//    .▓         ╓▓]V▄H       ▓                 ,Å            ▀,         ▀
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙███` `╙╙║█  ▐H        █
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//  ╢"▄▄#▀▀╙╟█Ü███▀`▀█  ║██J█▄▌jH █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//   █╙     ▐███▌▀█w ▀█ ╠██████j▌║█▌   ▀██▄       `╙▓██▀w,     ╙╗█'`"▀█▀╙"`║`
//   ╙▌     Φ████████▄██ ███████████    ═██▀W▄,   ╓█▀└         ╓▀ "    ╙▄ ╓▀
//    ╙▄     ╙▀███╙█▄▐██▄,╙▀█████▄▀▄▀▄   ,█M╗ ▀▄██▀╙""*ⁿ═─≈-,,▄▌,        ▄▀
//     `▌╙µ,▄Φ▀x███▄██████████▀V███▀╙└ ,▄#▌████▀`"*«,      .█▀▄▀▄,      ▄╛
//       ▀Ö█  ;▓████████▄▄█▀▄╙W "V▄██▀▀│▄███▀└ ▀╦     "*═╥▄▀ ║,  ║▀▄  ,▓
//        ╙W▀ '█████╨▀▀█████████   "▀▀████└      ╙▄   ,▄▀'   `▀▀╣H ▐▀▄▀
//          ╙▄  ▀▀Γ╓▌  ▄▀ⁿ`╙▀███      ██▌         ╓█R▀▄A█        ▀▀▄▀
//            ╙W,Φ╙  ║█        ▄╙╙ª%≡╦██≤≤╗╗≡≡╜▀▀   ╣▌   █╕     ,▄▀
//              `▀▄M█┘        ║▀▌   ╫"    *Φ▄  █       Φ` ▀▌, ▄M╙
//                 "▀╦,       M ╙▌  ▀       `█W▐▌       wæQ▄▀╙
//                     ╙▀W╥,╓╣   ╙█║        ╫M  █    ,╓▄╝╙`
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`
