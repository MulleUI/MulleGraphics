#import "import.h"

#import <string.h>


// #define START_COLOR   CGColorMakeWhite()
// #define END_COLOR     CGColorMakeBlue()

#define START_COLOR   CGColorMakeRed()
#define END_COLOR     CGColorMakeBlue()


@interface CircleLayer : CGGraphicsLayer

@property( observable, copy) CGPaint      *paint;
@property( observable, assign) CGFloat    strokeWidth;

@end


@implementation CircleLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   [super initWithFrame:frame];

   _paint       = [[CGGradient alloc] initWithStartColor:START_COLOR
                                                endColor:END_COLOR
                                                rotation:0.5];
   _strokeWidth = 100.0;

   return( self);
}


- (CGFloat) radius
{
   CGFloat   radius;
   CGRect    canvas;

   canvas = CGRectInset( [self canvas], _strokeWidth / 2.0, _strokeWidth / 2.0);
   radius = CGFloatMinimum( CGRectGetWidth( canvas), CGRectGetHeight( canvas)) / 2.0;
   return( radius);
}

- (BOOL) drawInContext:(CGContext *) context
{
   CGContextSave( context);
   {
      CGContextStrokeCircleWithPaintable( context, CACircleMakeWithCenterAndRadius( CGRectGetCenter( [self canvas]), [self radius]), _strokeWidth, [self paint]);
   }
   CGContextRestore( context);
   return( YES);
}


//- (void) setPaint:(CGPaint *) paint 
//{
//   [self willChange];
//
//   MulleUILog( "%#@ -> %#@", _paint, paint);
//   [_paint autorelease];
//   _paint = [paint copy];
//}

@end


@interface RadialCircleLayer : CircleLayer
@end


@implementation RadialCircleLayer 

- (BOOL) drawInContext:(CGContext *) context
{
   CGContextSave( context);
   {
      CGContextStrokeCircleWithPaintable( context,
                                   CACircleMakeWithCenterAndRadius( CGRectGetCenter( [self canvas]),
                                                 [self radius]),
                                   _strokeWidth,
                                   [self paint]);
   }
   CGContextRestore( context);
   return( YES);
}

@end 


void  setupAnimation( UIWindow *window, CircleLayer *layer, CGGradient *gradient, BOOL autoreverse)
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
      [UIView setAnimationRepeatAutoreverses:autoreverse];

      [layer setPaint:gradient];  
   }
   group = [UIView commitAnimations];
   assert( group);

   [[window postLayoutAnimator] addAnimation:group];
}



void   setupSceneAndAnimation( UIWindow *window)
{
   UIView               *view;
   UIView               *view2;
   CGRect               frame;
   UIEdgeInsets         insets;
   CircleLayer          *layer;
   RadialCircleLayer    *layer2;
   CGGradient           *gradient;
   CGGradient           *gradient2;
   UIWindowPlane        *contentPlane;

   contentPlane = [window contentView];

   frame  = [contentPlane contentRect];

   insets = UIEdgeInsetsMake( 20, 20, 20, 20);
   frame  = UIEdgeInsetsInsetRect( frame, insets);
   frame  = CGRectIntegral( frame);
   layer  = [CircleLayer layerWithFrame:frame];
   view   = [UIView viewWithLayer:layer];

   [contentPlane addSubview:view];

   frame  = CGRectInset( frame, [layer strokeWidth] + 0.0, [layer strokeWidth] + 0.0);
   frame  = CGRectIntegral( frame);
   frame  = CGRectExtrude( frame, 0.5, 0.5);  // overlap a little to squish uglies
   layer2 = [RadialCircleLayer layerWithFrame:frame];
   view2  = [UIView viewWithLayer:layer2];

   [contentPlane addSubview:view2];

   // UIView -> CAAnimation
   gradient = [CGGradient gradientWithStartColor:START_COLOR
                                        endColor:END_COLOR];
   setupAnimation( window, layer, gradient, NO);
   gradient2 = [CGGradient gradientWithStartColor:END_COLOR
                                         endColor:START_COLOR];
   setupAnimation( window, layer2, gradient2, YES);
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



