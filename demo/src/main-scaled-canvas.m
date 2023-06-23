#import "import-private.h"

//
// In this example we make it complicated. The canvas drawing is in OpenGL
// like coordinates. x1/y1=-1,-1, x2/y2=1,1 (w=2, h=2). The frame is not
// square shaped though. A circle is drawn in the canvas, and bounds are used
// to map it to the frame. You can see that this leaves borders to the left
// and to the right.
//
// A severe disadvantage of this (with nanovg) is, that the strokeWidth has
// to be scaled down to the ratio between canvas and frame, otherwise you get
// a real big circle.
//
// Also the line drawing quality is maybe not as nice.
//
//   0
// 0 .----------------------------------.
//   |                                  |
//   |                                  |
//   | frame                            | 300
//   |                                  |
//   |                                  |
//   '----------------------------------'
//                     ^       600
//                     |
//            -1/-1    |
//   ***********.-----------.************
//   *          |           |           *
//   *          |           |           *
//   * bounds   | canvas    | 2         * 2
//   *          |           |           *
//   *          |           |           *
//   ***********'-----------'************
//                    2

static void  drawStuff( CALayer *layer, void *_context)
{
   CGContext           *context = _context;
   struct NVGcontext   *vg;
   CGFloat             radius;
   CGRect              canvas;
   CGRect              frame;
   CGFloat             strokeWidth;
   CGFloat             canvasExtent;
   CGFloat             frameExtent;

   canvas       = [layer canvas];
   canvasExtent = CGFloatMinimum( CGRectGetWidth( canvas),
                                  CGRectGetHeight( canvas));
   frame        = [layer frame];
   frameExtent  = CGFloatMinimum( CGRectGetWidth( frame),
                                  CGRectGetHeight( frame));
   strokeWidth  = canvasExtent / frameExtent;

   radius       = (canvasExtent - strokeWidth) / 2.0;

   vg = CGContextGetNVGContext( context);
   mvgStrokeCircleWithColor( vg,
                             CGRectGetCenterPoint( canvas),
                             radius,
                             strokeWidth,
                             CGColorMakeRed());
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   UIView          *view;
   CGRect          frame;
   CGRect          bounds;
   CALayer         *layer;
   CGFloat         aspectFactor;

   app = [UIApplication sharedInstance];
   {
      frame = CGRectMake( 0, 0, 600, 500);
      
      view  = [UIView viewWithFrame:frame];
      [view setMargins:UIEdgeInsetsMake( 50, 100, 50, 100)];
      [view setBackgroundColor:CGColorMakeWithRGBA( 0.33, 0.33, 0.33, 1.0)];

      layer = (CALayer *) [view layer];
      assert( layer);

      [layer setDrawCallback:drawStuff];

      // The canvas is a square where we draw the circle unto. The stroke width
      // of the circle will have to be calculated so that it appears as 1 pixel
      // wide in the frame.
      [layer setCanvas:CGRectMake( -1, -1, 2, 2)];

      //
      // Bounds project a part of the square canvas unto the frame, which isn't
      // square. So we have to increase the bounds (from -1, -1, 2, 2) to draw
      // the circle aspect correct (not squished)
      //
      aspectFactor = CGSizeGetAspectRatio( frame.size);
      // if > 0 then wider then high, else reverse
      // we don't want to decrease bounds here
      bounds       = CGRectMake( -1, -1, 2, 2);
      if( aspectFactor >= 0.0)
      {
         bounds.origin.x   *= aspectFactor;
         bounds.size.width *= aspectFactor;
      }
      else
      {
         bounds.origin.y    *= aspectFactor;
         bounds.size.height *= aspectFactor;
      }

      [layer setBounds:bounds];

      window = [UIWindow windowWithView:view
                        titleUTF8String:NULL];
      [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];
      [app addWindow:window];
   }
   return( [app run]);
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

