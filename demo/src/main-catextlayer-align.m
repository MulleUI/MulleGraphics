#import "import-private.h"

#include <unistd.h>


@interface DemoTextLayer : CATextLayer
@end


@implementation DemoTextLayer

- (BOOL) drawInContext:(CGContext *) context
{
   CGRect                   vbounds;
   CGPoint                  point;
   struct MulleEdgeInsets   insets;
   CGRect                   canvas;

   //
   // draw visual bounds on top of what CATextLayer drew
   //
   [super drawInContext:context];

   canvas = [self canvas];

   // draw crosshair
   CGContextBeginPath( context);
   CGContextMoveTo( context, CGRectGetLeft( canvas));
   CGContextLineTo( context, CGRectGetRight( canvas));
   CGContextMoveTo( context, CGRectGetTop( canvas));
   CGContextLineTo( context, CGRectGetBottom( canvas));
   CGContextStrokeWidth( context, 1.0);
   CGContextStrokeColor( context, CGColorMakeIndigo());
   CGContextStroke( context);

   vbounds = [self visualBoundsWithContext:context];
   MulleUICLog( "vbounds: %s", CGRectUTF8String( vbounds));
   point   = [self textOriginInRect:canvas
                            context:context];
   MulleUICLog( "point  : %s", CGPointUTF8String( point));
   point   = CGPointAdd( point, [self textOffset]);
   MulleUICLog( "-> %s", CGPointUTF8String( point));
   insets  = [self insets];
   point   = CGPointMake( point.x + insets.left, point.y + insets.right);
   MulleUICLog( "-> %s", CGPointUTF8String( point));

   CGContextSave( context);
   {
      CGContextResetScissor( context);
      CGContextTranslate( context, point);
      CGContextStrokeRectWithColor( context, vbounds, 1.0, CGColorMakeLime());
   }
   CGContextRestore( context);

   // draw _layoutOrigin marker
   CGContextFillCircleWithColor( context, 
                                 CACircleMakeWithCenterAndRadius( _layoutOrigin, 10.0),
                                 CGColorMakeBlue());

   return( YES);
}

- (void) didDrawInContext:(CGContext *) context
{
   [self dumpLayoutToFILE:stderr];
   [self dumpRowsAndGlyphsToFILE:stderr];
}

@end


static char   *strings[] =
{
   "Action"
};

#define N_STRINGS   (sizeof( strings) / sizeof( strings[ 0]))


static void   changeLayerString( UIView *view)
{
   CATextLayer              *layer;
   CGFloat                  insetValue;
   CGLayoutContext          *context;
   CGRect                   frame;
   CGSize                   size;
   char                     *s;
   static NSUInteger        i;
   struct MulleEdgeInsets   insets;
   UIView                   *contentView;
   UIWindow                 *window;

   assert( view);

   window = (UIWindow *) [view window];
   assert( window);

   layer = (CATextLayer *) [view layer];
   assert( [layer isKindOfClass:[CATextLayer class]]);

   [layer setTextUTF8String:"And\nAction"];
   [layer setTextAlignment:UITextAlignmentCenter];
   [layer setTextVerticalAlignment:UITextAlignmentTop];

//   [layer setTextAlignment:UITextAlignmentCenter];
//   [layer setTextVerticalAlignment:UITextAlignmentMiddle];
}


static UIView *   setupSceneInWindow( UIWindow *window)
{
   CATextLayer   *layer;
   CGRect        frame;
   UIView        *view;
   UIView        *contentView;
   CGSize        size;

   contentView = [window contentView];
   [contentView setBackgroundColor:CGColorMakeGray()];

   // frame = CGSizeCenterInRect( CGSizeMake( 200, 100), [contentView bounds]);
   frame = CGRectMakeWithSize( CGSizeMake( 200, 100));
   layer = [DemoTextLayer layerWithFrame:frame];
   [layer setFontPixelSize:20.0f];
   [layer setBorderWidth:1.0];
   [layer setBorderColor:CGColorMakeRed()];
   [layer setBackgroundColor:CGColorMakeWhite()];
   [layer setTextColor:CGColorMakeBlack()];
   [layer setTextBackgroundColor:CGColorMakeWhite()];

   view = [UIView viewWithLayer:layer];
   [contentView addSubview:view];

   changeLayerString( view);

   return( view);
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   UIView          *view;
   NSUInteger      styleMask;
   double          delay;

   app = [UIApplication sharedInstance];
   {
      styleMask = UIWindowStyleMaskDefault; // & ~UIWindowStyleRetained;
      window    = [UIWindow windowWithFrame:CGRectMake( 0.0f, 0.0f, 640.0f, 400.0f)
                            titleUTF8String:"Demo"
                                  styleMask:styleMask];
      view = setupSceneInWindow( window);
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

