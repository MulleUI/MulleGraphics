#import "import-private.h"


//
// same demo as main-graphicslayer, just explains the various methods to
// override and shows the calling sequence in stderr
//
@interface DemoLayer : CGGraphicsLayer
@end


@implementation DemoLayer

- (void) renderInContext:(CGContext *) context
{
   FILE   *old;

   mulle_fprintf( stderr, "%s\n", __FUNCTION__);

   old = [context setTraceFile:stderr];
   [super renderInContext:context];
   [context setTraceFile:old];
   mulle_fprintf( stderr, "\n");
}


//
// will not be called if backgroundColor is transparent
// use frame not canvas
//
- (void) drawBackgroundInContext:(CGContext *) context
{
   mulle_fprintf( stderr, "%s\n", __FUNCTION__);


   CGContextFillRectWithColor( context, [self frame], [self backgroundColor]);
}


//
// will not be called if border is 0.0 or transparent
// use frame not canvas
//
- (void) drawBorderInContext:(CGContext *) context
{
   CGFloat           borderWidth;
   MulleEdgeInsets   insets;
   CGRect            rect;

   mulle_fprintf( stderr, "%s\n", __FUNCTION__);

   borderWidth = [self borderWidth];
   rect        = [self frame];
   insets      = MulleEdgeInsetsMake( borderWidth / 2,
                                      borderWidth / 2,
                                      borderWidth / 2,
                                      borderWidth / 2);
   rect        = MulleEdgeInsetsInsetRect( insets, rect);

   CGContextStrokeRectWithColor( context, rect, borderWidth, [self borderColor]);
}


- (BOOL) willDrawInContext:(CGContext *) context
{
   BOOL   flag;

   mulle_fprintf( stderr, "%s\n", __FUNCTION__);
   flag = [super willDrawInContext:context];
   return( flag);
}


- (void) didDrawInContext:(CGContext *) context
{
   mulle_fprintf( stderr, "%s\n", __FUNCTION__);
   [super didDrawInContext:context];
}


- (BOOL) drawInContext:(CGContext *) context
{
   CGRect   rect;

   mulle_fprintf( stderr, "%s\n", __FUNCTION__);
   // call super to execute the draw callback
   if( ! [super drawInContext:context])
      return( NO);

   rect = CGRectInset( [self canvas], 16, 16);
   CGContextStrokeRectWithColor( context, rect, 8.0, CGColorMakeGreen());
   return( YES);
}

@end


static void   setupSceneInWindow( UIWindow *window)
{
   DemoLayer   *layer;
   CGRect      frame;
   UIView      *view;
   UIView      *contentView;

   contentView = [window contentView];

   frame = CGRectInset( [contentView contentRect], 20, 20);
   layer = [DemoLayer layerWithFrame:frame];
   view  = [UIView viewWithLayer:layer];
   [layer setBorderWidth:4.0];
   [layer setBorderColor:CGColorMakeRed()];
   [layer setBackgroundColor:CGColorMakeYellow()];

   // the sublayer test that the origin is properly translated for
   // the canvas
   layer = [DemoLayer layerWithFrame:CGRectMake( 50, 50, 80, 80)];
   [layer setBorderColor:CGColorMakeBlue()];
   [layer setBorderWidth:2.0];
   [layer setBackgroundColor:CGColorMakeOrange()];
   [view addLayer:layer];

   [contentView addSubview:view];
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   NSUInteger      styleMask;

   app = [UIApplication sharedInstance];
   {
      styleMask = UIWindowStyleMaskDefault;
      styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStylePlanes, NO);
      styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleRetained, NO);
      window    = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 400.0, 300.0)
                            titleUTF8String:"Demo"
                                  styleMask:styleMask];
      [window setBackgroundColor:CGColorMakeMintCream()];
      setupSceneInWindow( window);
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

