#import "import-private.h"

#include <unistd.h>



static CATextLayer   *textLayer( CGPaint *textPaint,
                                 CGPaint *textBackgroundPaint,
                                 CGPaint *backgroundPaint,
                                 BOOL clearType)
{
   CATextLayer   *layer;

   layer = [CATextLayer object];
   [layer setFontPixelSize:20.0f];
   [layer setTextUTF8String:"VfL Bochum 1848"];

   [layer setTextPaint:textPaint];
   [layer setTextBackgroundPaint:textBackgroundPaint];
   [layer setBackgroundPaint:backgroundPaint];
   [layer setClearTypeEnabled:clearType];

   return( layer);
}


static void   positionLayerInView( CALayer *layer, UIView *contentView, CGPoint origin)
{
   CGRect   frame;
   UIView   *view;

   frame.origin = origin;
   frame.size   = [layer sizeThatFits:CGSizeMake( INFINITY, INFINITY)
                              context:[contentView layoutContext]];
   [layer setFrame:frame];

   view  = [UIView viewWithLayer:layer];
   [contentView addSubview:view];
}


static CGColor   colors[ 13] = 
{
   CGColorDataAlizarinCrimson,
   CGColorDataBrightRed,    
   CGColorDataCadmiumYellow, 
   CGColorDataDarkSienna,   

   CGColorDataIndianYellow,   
   CGColorDataMidnightBlack,  
   CGColorDataPhthaloBlue,    
   CGColorDataPhthaloGreen,   

   CGColorDataPrussianBlue,   
   CGColorDataSapGreen,       
   CGColorDataTitaniumWhite,  
   CGColorDataVanDykeBrown,   

   CGColorDataYellowOchre       
};


static void   setupSceneInWindow( UIWindow *window)
{
   CATextLayer     *layer;
   CGRect          frame;
   UIWindowPlane   *contentView;
   CGPaint         *windowBackgroundPaint;
   CGPaint         *grayPaints[ 5];
   CGPaint         *gradientPaints[ 5];
   NSUInteger      i;
   NSUInteger      j;
   NSUInteger      k;

   contentView           = [window contentView];
   windowBackgroundPaint = [window backgroundPaint];

   for( i = 0; i < 5; i++)
      grayPaints[ i] = [CGPaint paintWithColor:CGColorMakeWithGray( i / 4.0f)];

#if 0
   for( k = 0; k < 2; k++)
      for( j = 0; j < 2; j++)
         for( i = 0; i < 5; i++)
         {
            layer = textLayer( grayPaints[ i], 
                               k ? windowBackgroundPaint 
                                 : grayPaints[ 4], 
                               windowBackgroundPaint, 
                               j ? YES : NO);
            positionLayerInView( layer, 
                                 contentView, 
                                 CGPointMake( k * 400 + j * 200 + 20, i * 30 + 20));
         }
#endif
   
   for( i = 0; i < 5; i++)
      gradientPaints[ i] = [CGPaint paintWithStartColor:colors[ i]
                                               endColor:colors[ 12 - i]];

   contentView           = [window contentView];
   windowBackgroundPaint = [window backgroundPaint];

   for( k = 0; k < 2; k++)
      for( j = 0; j < 2; j++)
         for( i = 0; i < 5; i++)
         {
            layer = textLayer( gradientPaints[ i], 
                               k ? windowBackgroundPaint 
                                 : grayPaints[ 4], 
                               windowBackgroundPaint, 
                               j ? YES : NO);
            positionLayerInView( layer, 
                                 contentView, 
                                 CGPointMake( k * 400 + j * 200 + 20, 200 + i * 30 + 20));
         }

}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   NSUInteger      styleMask;

   app = [UIApplication sharedInstance];
   {
      styleMask = UIWindowStyleMaskDefault & ~UIWindowStyleRetained;
      window    = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 800.0)
                            titleUTF8String:"Demo"
                                  styleMask:styleMask];
      [window setBackgroundColor:CGColorMakeWithRGBA( 0.33, 0.33, 0.33, 1.0)];
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

