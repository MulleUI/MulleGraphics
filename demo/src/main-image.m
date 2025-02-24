#import "import-private.h"

#include <unistd.h>


static char    *filenames[ 2] =
{
   "tardbeaver.png",
   "parrot.png"
};


static CGContentMode   contentModes[ 12] =
{
   CGContentModeScaleToFill,
   CGContentModeScaleAspectFit,
   CGContentModeScaleAspectFill,
   CGContentModeCenterPoint,

   CGContentModeTop,
   CGContentModeBottom,
   CGContentModeLeft,
   CGContentModeRight,

   CGContentModeTopLeft,
   CGContentModeTopRight,
   CGContentModeBottomLeft,
   CGContentModeBottomRight
};

#define N_CGContentModes  (sizeof( contentModes) / sizeof( contentModes[ 0]))



//
// we need to be rendering to create CGImages. "Real" code that uses
// CAImageLayer will likely use UIImages.
//
static BOOL   drawStuff( CGGraphicsLayer *aLayer, CGContext *_context)
{
   CGContext       *context = _context;
   CGImage         *image;
   CAImageLayer    *imageLayer = (CAImageLayer *) aLayer;
   CGFrameInfo     *info;
   NSUInteger      modeIndex;
   char            *filename;
   NSUInteger      frameNumber;

   info        = [context currentFrameInfo];
   frameNumber = [context numberOfFrames];
   image       = (CGImage *) [imageLayer image] ;
   modeIndex   = (frameNumber / 100) % N_CGContentModes;

   if( ! image || modeIndex == 0)
   {
      filename = filenames[ frameNumber / (100 * N_CGContentModes) & 1];
      image    = [[[CGImage alloc] initWithContentsOfFileCString:filename
                                                   textureFlags:0
                                                        context:context] autorelease];
      if( ! image)
      {
         fprintf( stderr, "image \"%s\" not found\n", filename);
         _exit( 1);
      }
      [imageLayer setImage:image];
   }

   [imageLayer setContentMode:contentModes[ modeIndex]];
   return( YES);
}


static void   setupSceneInWindow( UIWindow *window)
{
   CAImageLayer    *layer;
   CGImage         *image;
   CGRect          frame;
   UIView          *view;
   UIWindowPlane   *contentPlane;

   contentPlane = [window contentView];
   frame        = [contentPlane contentRect];
   frame        = UIEdgeInsetsInsetRect( frame, UIEdgeInsetsMake( 10, 10, 10, 10));

   // this works in one-window scenarios well, where there is only one
   // context.
   layer = [CAImageLayer layerWithFrame:frame];
   [layer setDrawCallback:drawStuff];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 0.33, 0.33, 0.33, 1.0)];

   view = [UIView viewWithLayer:layer];
   [contentPlane addSubview:view];
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      [window setBackgroundColor:CGColorMakeWithRGBA( 0.5, 0.5, 0.5, 1.0)];
      [window setFrameRateHz:100];
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

