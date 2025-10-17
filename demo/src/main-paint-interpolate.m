#define _GNU_SOURCE

#import "import-private.h"

#include "bitmap2.inc"

#undef R
#undef G
#undef B
#undef Y
#undef W
#undef _
#undef BITMAP_NAME

#define R   0x7F, 0x7F, 0x00, 0xFF
#define G   0x7F, 0x00, 0x7F, 0xFF
#define B   0x00, 0x7F, 0x7F, 0xFF
#define Y   0xFF, 0xFF, 0xFF, 0xFF
#define W   0x7F, 0x7F, 0x00, 0xFF
#define _   0x00, 0x00, 0x00, 0xFF

#define BITMAP_NAME  bitmap1

#include "bitmap2.inc"



#define COLS  4
#define ROWS  4


@interface Foo : NSObject

@property( retain) CGPaint   *value;

@end


@implementation Foo
@end


static BOOL   drawStuff( CGGraphicsLayer *layer, CGContext *context)
{
   CABasicAnimation              *animation;
   CGPaint                       *paint[ 2];
   CGRect                        canvas;
   CGRect                        rect;
   CGRect                        rects[ ROWS][ COLS];
   Foo                           *foo;
   NSUInteger                    i, j;
   struct _mulle_objc_property   *property;
   CGPaint                       *value;
   double                        x;
   NSUInteger                    frames;

   canvas = [layer canvas];
   canvas = CGRectInset( canvas, 5.0, 5.0);

   CGRectPartitionIntoRowsAndColumns( canvas, CGSizeMake( 5, 5), ROWS, COLS, (CGRect *) rects);

   frames = [context numberOfFrames] % 240;
   if( frames >= 120)
      frames = 240 - frames;
   x = frames / 120.0;

   foo      = [Foo instance];
   property = MulleObjCInstanceSearchProperty( foo, @selector( value));

   for( j = 0; j < ROWS; j++)
   {
      paint[ 0] = nil;
      switch( j)
      {
      case 2 :
         paint[ 0] = [CGGradient gradientWithStartColor:CGColorMakeYellow()
                                               endColor:CGColorMakeBlue()];
         break;

      case 3 :
         paint[ 0] = [CGImage imageWithRGBABytes:bitmap2
                                      bitmapSize:CGPixelSizeMake( 32, 32)
                                    textureFlags:0  // NVG_IMAGE_REPEATX
                                         context:context];
         break;

      case 1 :
         paint[ 0] = [CGPaint paintWithColor:CGColorMakeGray()];
         break;
      }

      for( i = 0; i < COLS; i++)
      {
         paint[ 1] = nil;
         switch( i)
         {
         case 2 :
            paint[ 1] = [CGGradient gradientWithStartColor:CGColorMakeGreen()
                                                  endColor:CGColorMakeOrange()];
            break;

         case 3 :
            paint[ 1] = [CGImage imageWithRGBABytes:bitmap1
                                         bitmapSize:CGPixelSizeMake( 32, 32)
                                       textureFlags:0  // NVG_IMAGE_REPEATX
                                            context:context];
            break;

         case 1 :
            paint[ 1] = [CGPaint paintWithColor:CGColorMakeBlack()];
            break;
         }

         //
         // MEMO: using CABasicAnimation here instead of CAIntepolatableValue
         //       because it deals more gracefully with nil paints.
         //       (also tests more code)
         //
         animation = MULLE_OBJC_CLASS_CAST( CABasicAnimation,
                                           [CGPaint createAnimationFrom:paint[ 0]
                                                                     to:paint[ 1]
                                                               property:property
                                                                options:NULL]);
         [foo setValue:nil];
         CABasicAnimationAnimateObject( animation, foo, (j == 0)
                                                        ? 1.0
                                                        : (i == 0 ? 0.0 : x));
         value = [foo value];

         CGContextBeginPath( context);
         CGContextRect( context, rects[ j][ i]);
         [value fillWithBounds:rects[ j][ i]
                         alpha:1.0
                       context:context];
      }
   }
   return( YES);
}



int   main( int argc, char *argv[])
{
   UIApplication   *app;
   UIWindow        *window;

   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 200, 200)];
   [window setDrawCallback:drawStuff];
   [window setBackgroundColor:CGColorMakeWhite()];
   [window setFrameRateHz:60.0];
   [app addWindow:window];

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
