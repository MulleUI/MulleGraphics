#import "import.h"

#import <string.h>


@interface CircleLayer : CGGraphicsLayer

@property( observable) CGFloat   scale;
@property( observable) CGColor   color;
@property( observable) CGRect    box;

@end


@implementation CircleLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   [super initWithFrame:frame];

   _scale = 1;
   _color = CGColorMakeWithHexColor( 0x000000FF);
   _box   = [self canvas];

   return( self);
}

@end


static BOOL   drawStuff( CGGraphicsLayer *aLayer, CGContext *_context)
{
   CGContext           *context = _context;
   CircleLayer         *layer = (CircleLayer *) aLayer;
   CGFloat             radius;
   CGRect              box;
   CGRect              canvas;

   canvas = [layer canvas];

   CGContextBeginPath( context);
   {
      radius  = CGFloatMinimum( CGRectGetWidth( canvas), CGRectGetHeight( canvas)) / 2 - 10;
      radius *= [layer scale];

      CGContextCircle( context, CACircleMakeWithCenterAndRadius( CGRectGetCenter( canvas), radius));
      CGContextStrokeColor( context, [layer color]);
      CGContextStrokeWidth( context, 3.5);
   }
   CGContextStroke( context);

   CGContextBeginPath( context);
   {
      box = [layer box];
      CGContextRect( context, box);
      CGContextStrokeColor( context, [layer color]);
      CGContextStrokeWidth( context, 3.5);
   }
   CGContextStroke( context);

   return( YES);
}


void  setupAnimation( UIWindow *window, CircleLayer *layer)
{
   CAAnimationGroup   *group;

   // UIView -> CAAnimation
   [UIView beginAnimations:"animation"
                    context:NULL];
   {
      [UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
      [UIView setAnimationDelay:2];
      [UIView setAnimationDuration:2];
      [UIView setAnimationRepeatCount:20];

      [layer setScale:-1.0];
      [layer setColor:CGColorMakeWithHexColor( 0x0000FFFF)];
      [layer setBox:CGRectMake( 100, 100, 100, 100)];
   }
   group = [UIView commitAnimations];
   assert( group);

   [[window postLayoutAnimator] addAnimation:group];
}


void   setupSceneAndAnimation( UIWindow *window)
{
   UIView         *view;
   CGRect         frame;
   UIEdgeInsets   insets;
   CircleLayer    *layer;

   frame  = [[window contentView] contentRect];
   insets = UIEdgeInsetsMake( 8, 8, 8, 8);
   frame  = UIEdgeInsetsInsetRect( frame, insets);

   layer = [CircleLayer layerWithFrame:frame];
   [layer setColor:CGColorMakeWithHexColor( 0xFF0000FF)];
   [layer setDrawCallback:drawStuff];

   view  = [UIView viewWithLayer:layer];
   [[window contentView] addSubview:view];

   // UIView -> CAAnimation
   setupAnimation( window, layer);
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   NSUInteger      styleMask;
   MulleUIPerf     *perf;
   UIApplication   *app;
   
   app = [UIApplication sharedInstance];
   /*
    * window and app
    */
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleRetained, YES);

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)
                      titleUTF8String:"Demo"
                            styleMask:styleMask];
   assert( window);

   [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];
   [window setFrameRateHz:60.0];

   setupSceneAndAnimation( window);

   perf = [MulleUIPerf instance];
   [window setFrameDelegate:perf];

   return( UIApplicationRunWindow( window));
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

