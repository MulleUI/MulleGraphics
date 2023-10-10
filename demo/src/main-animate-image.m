#import "import.h"

#import <string.h>


// #define START_COLOR   CGColorMakeWhite()
// #define END_COLOR     CGColorMakeBlue()


@interface ImageLayer : CALayer

@property( observable, copy) CGPaint   *paint;

@end


@implementation ImageLayer

- (BOOL) drawInContext:(CGContext *) context
{
   struct NVGcontext   *vg;

   vg = CGContextGetNVGContext( context);
   mvgFillRectWithPaint( vg, [self canvas], [self paint]);
   return( YES);
}

@end



void  setupAnimation( UIWindow *window,
                      ImageLayer *layer,
                      CGImage *image)
{
   CAAnimationGroup   *group;

   // UIView -> CAAnimation
   [UIView beginAnimations:"animation"
                   context:NULL];
   {
      [UIView setAnimationCurve:UIViewAnimationCurveLinear];
      [UIView setAnimationDelay:0];
      [UIView setAnimationDuration:5];
      [UIView setAnimationRepeatCount:INFINITY];
      [UIView setAnimationRepeatAutoreverses:YES];

      [layer setPaint:image];
   }
   group = [UIView commitAnimations];
   assert( group);

   [[window postLayoutAnimator] addAnimation:group];
}



struct DrawContext
{
   CGColor          startColor;
   CGColor          endColor;
   CGFloat          strokeWidth;
   CAAngle          rotation;
};

struct DrawContext   circleOne =
{
   CGColorDataYellow,
   CGColorDataBlue,
   80.0,
   CARotationNone
};


struct DrawContext   circleTwo =
{
   CGColorDataRed,
   CGColorDataLime,
   80.0,
   CARotation180
};



static void   drawGradientCircle( CGContext *context, CGSize size, void *userinfo)
{
   struct DrawContext  *info = userinfo;
   CGGradient          *gradient;
   NVGcontext          *vg;
   CACircle            circle;

   gradient = [CGGradient gradientWithStartColor:info->startColor
                                        endColor:info->endColor
                                        rotation:info->rotation];
   vg       = CGContextGetNVGContext( context);
   circle   = CACircleMake( CGSizeGetCenterPoint( size),
                            CGSizeGetInnerRadius( size) - info->strokeWidth / 2.0);
   mvgStrokeCircleWithPaint( vg, circle,
                                 info->strokeWidth,
                                 gradient);
}



void   setupSceneAndAnimation( UIWindow *window, CGContext *context)
{
   CGImage         *image2;
   CGImage         *image;
   CGRect          frame;
   ImageLayer      *layer;
   UIEdgeInsets    insets;
   UIView          *view;
   UIWindowPlane   *contentPlane;

   contentPlane = [window contentView];

   frame  = [contentPlane contentRect];
   frame  = CGRectInset( frame, 20, 20);
   layer  = [ImageLayer layerWithFrame:frame];
   image  = [CGLayer layerWithBitmapSize:MulleIntegerSizeMakeWithSize( frame.size)
                         backgroundColor:CGColorMakeWhite()
                            drawFunction:drawGradientCircle
                                userInfo:&circleOne
                                 context:context];
//   [image writeToPNGUTF8String:"l1.png"];
   [layer setPaint:image];

   view = [UIView viewWithLayer:layer];
   [contentPlane addSubview:view];

   image2 = [CGLayer layerWithBitmapSize:MulleIntegerSizeMakeWithSize( frame.size)
                         backgroundColor:CGColorMakeWhite()
                            drawFunction:drawGradientCircle
                                userInfo:&circleTwo
                                 context:context];
//   [image2 writeToPNGUTF8String:"l2.png"];
   // UIView -> CAAnimation
   setupAnimation( window, layer, image2);
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   NSUInteger      styleMask;
   MulleUIPerf     *perf;
   UIApplication   *app;
   CGContext       *context;

   app = [UIApplication sharedInstance];
   /*
    * window and app
    */
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowsStyleMaskBySetting( styleMask, UIWindowStyleRetained, NO);

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)
                      titleUTF8String:"Demo"
                            styleMask:styleMask];
   assert( window);

   [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];
   [window setFrameRateHz:60.0];

   // activate context so we can draw the images
   // we use the window not the render context, because we are retained but
   // executing in the main thread
   context = (CGContext *) [window activateWindowGraphicsContext];
   {
      setupSceneAndAnimation( window, context);
   }
   [window deactivateGraphicsContext:context];

   perf = [MulleUIPerf object];
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

