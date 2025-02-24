#import "import.h"

#import <string.h>


//
// This demo shows how to setup some textures before starting the window.
//


// #define START_COLOR   CGColorMakeWhite()
// #define END_COLOR     CGColorMakeBlue()
//#define DEBUG_WRITE_IMAGE_PNG
//#define DEBUG_NO_ANIMATION
//#define DEBUG_NO_SCENE
#define FPS               60.0


@interface ImageLayer : CGGraphicsLayer

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


#ifndef DEBUG_NO_ANIMATION

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

#endif


struct DrawContext
{
   CGColor   startColor;
   CGColor   endColor;
   CGFloat   strokeWidth;
   CAAngle   rotation;
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

   frame = [contentPlane contentRect];
   frame = CGRectInset( frame, 20, 20);
   image = [CGFramebuffer framebufferWithBitmapSize:CGPixelSizeMakeWithSize( frame.size)
                                    backgroundColor:CGColorMakeWhite()
                                       drawFunction:drawGradientCircle
                                           userInfo:&circleOne
                                            context:context];
#ifdef DEBUG_WRITE_IMAGE_PNG
   [image writeToPNGUTF8String:"l1.png"];
#endif

   layer = [ImageLayer layerWithFrame:frame];
   [layer setPaint:image];
   view = [UIView viewWithLayer:layer];
   [contentPlane addSubview:view];

#ifndef DEBUG_NO_ANIMATION
   image2 = [CGFramebuffer framebufferWithBitmapSize:CGPixelSizeMakeWithSize( frame.size)
                                     backgroundColor:CGColorMakeWhite()
                                        drawFunction:drawGradientCircle
                                            userInfo:&circleTwo
                                             context:context];
# ifdef DEBUG_WRITE_IMAGE_PNG
   [image2 writeToPNGUTF8String:"l2.png"];
# endif
   // UIView -> CAAnimation
   setupAnimation( window, layer, image2);
#endif
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   NSUInteger      styleMask;
   MulleUIPerf     *perf;
   UIApplication   *app;
   CGContext       *context;
   BOOL            flag;

   app = [UIApplication sharedInstance];
   /*
    * window and app
    */
   styleMask = UIWindowStyleMaskDefault;
   styleMask = UIWindowsStyleMaskBySetting( styleMask, UIWindowStyleRetainedOnMainThread, YES);
   styleMask = UIWindowsStyleMaskBySetting( styleMask, UIWindowStylePlanes, NO);

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)
                      titleUTF8String:"Demo"
                            styleMask:styleMask];
   assert( window);

   [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];
#ifdef FPS   
   [window setFrameRateHz:FPS];
#endif

   //
   // Need to activate a context so we can draw the images. In retained mode
   // we draw into offscreen context framebuffers. In non-retained mode, we
   // draw into regular window context framebuffers. Therefore we have to use
   // the -renderGraphicsContext and let MulleUI figure out which context to
   // activate. We can't keep the context active though. Renabling this is 
   // fairly crucial for performance though.
   //
   // As the context may move to another thread, we need to properly
   // activate and deactivate, otherwise we are in misery
   //
#ifndef DEBUG_NO_SCENE
   flag = [window keepOSGraphicsContextActive];
   [window setKeepOSGraphicsContextActive:NO];
   {
      [window activateRenderGraphicsContext];
      context = (CGContext *) [window renderGraphicsContext];
      {
         setupSceneAndAnimation( window, context);
      }
      [window deactivateRenderGraphicsContext];
   }
   // if we do this and go from NO to YES, we need to waste the contexts of
   // the window, otherwise activation won't happen.
   [window setKeepOSGraphicsContextActive:flag];
#endif

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

