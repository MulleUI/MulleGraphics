#import "import-private.h"


#define FRAMERATE_HZ      120.0


// This demo shows how you can fairly easily convert C code into
// a CACPUImagelayer subclass.
// From:

// texture from Unreal Tournament 2003 used w/o permission
static char  tunnelstonetex_png_data[] =
#include "tunnelstonetex.inc"
;

#define s_tunnelstonetex_png_data  (sizeof( tunnelstonetex_png_data) - 1)


/*
 * Tunnel "inspired" by
 * https://lodev.org/cgtutor/tunnel.html
 */
#define TEX_W   256
#define TEX_H   256

#define W   320
#define H   200


 // TODO: as a shader, create a second texture for reading distance and
 //       angle.

@interface TunnelLayer : CACPUImageLayer
{
   UIBitmapImage   *_textureImage;
   int             _distanceTable[ H][ W];
   int             _angleTable[ H][ W];

}
@end


@implementation TunnelLayer

- (void) _initTables
{
   NSUInteger    x, y;
   NSInteger     angle, distance;
   float         ratio;

  //generate non-linear transformation table
  // w, h is screen
   ratio = 32.0;
   for( y = 0; y < H; y++)
      for( x = 0; x < W; x++)
      {
         distance = (NSInteger) (ratio * TEX_H / sqrt( (x - W / 2.0) * (x - W / 2.0) + (y - H / 2.0) * (y - H / 2.0))) % TEX_H;
         angle    = (NSUInteger) (0.5 * TEX_W * atan2(y - H / 2.0, x - W / 2.0) / 3.1416);

         _distanceTable[ y][ x] = distance;
         _angleTable[ y][ x]    = angle;
      }
}


 - (id) initWithFrame:(CGRect) frame
 {
   CGRect                rect;
   struct CGBitmapInfo   bitmapInfo;

   [super initWithFrame:frame];

   _textureImage = [[UIBitmapImage alloc] initWithFileCData:mulle_data_make( tunnelstonetex_png_data,
                                                                            s_tunnelstonetex_png_data)
                                   allocator:NULL];
   if( ! _textureImage)
      abort();

   bitmapInfo = [_textureImage bitmapInfo];
   assert( CGPixelSizeEqualToPixelSize( CGBitmapInfoGetSize( bitmapInfo), CGPixelSizeMake( TEX_W, TEX_H)));

   rect = CGRectMake( 0, 0, W, H);

   [self setCanvas:rect]; // set "CPU" screen
   [self setBounds:rect]; // we want it scaled...

   [self _initTables];

   return( self);
}



- (void) drawInBytes:(void *) texture
          bitmapInfo:(struct CGBitmapInfo) bitmapInfo
{
   NSUInteger    x, y;
   NSUInteger    mapped_x, mapped_y;
#if DRAW_TEXTURE
   NSUInteger    w, h;
#endif
   uint32_t      *dst_pixels;
   uint32_t      *src_pixels;
   double        animation;
   NSInteger     shiftX;
   NSInteger     shiftY;

   assert( CGBitmapInfoGetEncoding( bitmapInfo) == CGBitmapEncodingRGBABytes);
   assert( CGPixelSizeEqualToPixelSize( CGBitmapInfoGetSize( bitmapInfo), CGPixelSizeMake( W, H)));

   dst_pixels = texture;
   src_pixels = [_textureImage bytes];

#if DRAW_TEXTURE
   w = TEX_W > W ? W : TEX_W;
   h = TEX_H > H ? H : TEX_H;

   for( y = 0; y < h; y++)
      for( x = 0; x < w; x++)
         dst_pixels[ y * W + x] = src_pixels[ y * TEX_W + x];
#endif

   animation = mulle_absolutetime_now();

    //calculate the shift values out of the animation value
   shiftX = (NSInteger) (TEX_W * 1.0 * animation);
   shiftY = (NSInteger) (TEX_H * 0.25 * animation);

   for( y = 0; y < H; y++)
      for( x = 0; x < W; x++)
      {
         mapped_x = (NSUInteger) (_distanceTable[ y][ x] + shiftX) % TEX_W;
         mapped_y = (NSUInteger) (_angleTable[ y][ x] + shiftY) % TEX_H;

         dst_pixels[ y * W + x] = src_pixels[ mapped_y * TEX_W + mapped_x];
      }
}

@end



//
// here we use a custom View to react to changes in the view size
// to pass it onto the layer
//
@interface TunnelView : UIView
@end


@implementation TunnelView

+ (Class) layerClass
{
   return( [TunnelLayer class]);
}

@end


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   TunnelView      *tunnelView;
   UIView          *contentView;

   /*
    * window and app
    */

   app = [UIApplication sharedInstance];
   // before creating windows
   //[CGContext setDebuggingFlags:YES];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0f, 0.0f, 640.0f, 400.0f)];
   [window setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.0, 0.0, 1.0)];
   {
      contentView = [window contentView];

      tunnelView  = [TunnelView viewWithFrame:CGRectZero];
      [tunnelView setAutoresizingMask:UIViewAutoresizingScaleToFill];
      [tunnelView setBackgroundColor:[UIColor darkGrayColor]];
      [tunnelView setBorderColor:[UIColor whiteColor]];
      [tunnelView setBorderWidth:6.0];

      [contentView addSubview:tunnelView];
   }

   [app addWindow:window];
   [window setFrameRateHz:FRAMERATE_HZ];

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

