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
static UIEvent  *handleEvent( UIWindow *window, UIEvent *event)
{
   CALayer         *layer;
   CGRect          bounds;
   CGRect          contentRect;
   UIWindowPlane   *contentPlane;
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
   contentPlane = [window contentPlane];
   contentRect  = [contentPlane contentRect];
   n            = [contentPlane getSubviews:views
                                      range:NSMakeRange( 0, 1)];
   assert( n == 1);
   view  = views[ 0];
   layer = [view layer];

   //
   // there we are, now use the mouse motion event to move the bounds
   // could be nicer...
   //
   bounds           = [layer bounds];
   bounds.origin    = [event mouseLocationInView:view];
   bounds.origin.x *= contentRect.size.width / bounds.size.width;
   bounds.origin.y *= contentRect.size.height / bounds.size.height;
   [layer setBounds:bounds];

   return( event);  // don't consume event, even if motion
}


static void  drawStuff( CALayer *layer, CGContext *context)
{
   CGFloat             canvasExtent;
   CGFloat             radius;
   CGFloat             strokeWidth;
   CGRect              canvas;
   struct NVGcontext   *vg;

   canvas       = [layer canvas];
   canvasExtent = CGFloatMinimum( CGRectGetWidth( canvas),
                                  CGRectGetHeight( canvas));
   strokeWidth  = 3.0;
   radius       = (canvasExtent - strokeWidth) / 2.0;

   vg = CGContextGetNVGContext( context);
   nvgBeginPath( vg);
   {
      nvgCircle( vg, CGRectGetMidX( canvas), CGRectGetMidY( canvas), radius);
      nvgStrokeColor( vg, CGColorMakeRGBA( 1.0, 0.0, 0.0, 1.0));
      nvgStrokeWidth( vg, strokeWidth);
   }
   nvgStroke( vg);
}


static void   setupSceneInView( UIView *contentPlane)
{
   CALayer   *layer;
   CGFloat   aspectFactor;
   CGRect    bounds;
   CGRect    frame;
   UIView    *view;

   frame = CGSizeCenterInRect( CGSizeMake( 600, 400), [contentPlane contentRect]);

   view  = [[[UIView alloc] initWithFrame:frame] autorelease];
   [view setBackgroundColor:CGColorMakeRGBA( 0.33, 0.33, 0.33, 1.0)];
   [contentPlane addSubview:view];

   layer = [view layer];
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

      [window setBackgroundColor:CGColorMakeRGBA( 1.0, 1.0, 1.0, 1.0)];
      [window setEventCallback:handleEvent];
      setupSceneInView( [window contentPlane]);

      [app addWindow:window];
      [window renderLoop];
   }
   return( [app terminate]);
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
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌╓▀╦▄▀█   ╙█⌐               ╓█▌        ▓ `       █
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
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

