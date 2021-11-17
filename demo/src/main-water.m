#import "import-private.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// A demo that shows how you can change a texture by drawing into
// (CPU) memory by "hand".



@interface Water : NSObject
{
   uint8_t   *_cells;

}

@property( assign) struct CGBitmapSize   bitmapSize;

@end


//
// The "Water" class is MulleUI independent and performs its water effect in
// memory. The whole affair is not very fast. It's just for illustration
// purposes.
//
// our water grows from top (0) to bottom (height)
//
@implementation Water


#define FIRE_PERCENT    66


static uint8_t   palette[][ 4] =
{
   { 0x00, 0x00, 0x00, 0xFF },

   { 0x07, 0x07, 0x07, 0xFF },
   { 0x07, 0x07, 0x1F, 0xFF },
   { 0x07, 0x0F, 0x2F, 0xFF },
   { 0x07, 0x0F, 0x47, 0xFF },

   { 0x07, 0x17, 0x57, 0xFF },
   { 0x07, 0x1F, 0x67, 0xFF },
   { 0x07, 0x1F, 0x77, 0xFF },
   { 0x07, 0x27, 0x8F, 0xFF },

   { 0x07, 0x2F, 0x9F, 0xFF },
   { 0x07, 0x3F, 0xAF, 0xFF },
   { 0x07, 0x47, 0xBF, 0xFF },
   { 0x07, 0x47, 0xC7, 0xFF },

   { 0x07, 0x47, 0xDF, 0xFF },
   { 0x07, 0x57, 0xDF, 0xFF },
   { 0x07, 0x57, 0xDF, 0xFF },
   { 0x07, 0x5F, 0xD7, 0xFF },

   { 0x07, 0x5F, 0xD7, 0xFF },
   { 0x0F, 0x67, 0xD7, 0xFF },
   { 0x0F, 0x6F, 0xCF, 0xFF },
   { 0x0F, 0x77, 0xCF, 0xFF },

   { 0x0F, 0x7F, 0xCF, 0xFF },
   { 0x17, 0x87, 0xCF, 0xFF },
   { 0x17, 0x87, 0xC7, 0xFF },
   { 0x17, 0x8F, 0xC7, 0xFF },

   { 0x1F, 0x97, 0xC7, 0xFF },
   { 0x1F, 0x9F, 0xBF, 0xFF },
   { 0x1F, 0x9F, 0xBF, 0xFF },
   { 0x27, 0xA7, 0xBF, 0xFF },

   { 0x27, 0xA7, 0xBF, 0xFF },
   { 0x2F, 0xAF, 0xBF, 0xFF },
   { 0x2F, 0xAF, 0xB7, 0xFF },
   { 0x2F, 0xB7, 0xB7, 0xFF },

   { 0x37, 0xB7, 0xB7, 0xFF },
   { 0x6F, 0xCF, 0xCF, 0xFF },
   { 0x9F, 0xDF, 0xDF, 0xFF },
   { 0xC7, 0xEF, 0xEF, 0xFF },

   { 0x2F, 0x2F, 0x6F, 0xFF }
};

#define N_PALETTE_COLORS  (sizeof( palette) / 4)


- (instancetype) initWithBitmapSize:(struct CGBitmapSize) size
{
   if( size.width < 2 || size.height < 2)
   {
      [self release];
      return( nil);
   }

   _cells = mulle_allocator_calloc( MulleObjCInstanceGetAllocator( self),
                                    size.width,
                                    size.height);
   _bitmapSize = size;

   return( self);
}


- (void) dealloc
{
   mulle_allocator_free( MulleObjCInstanceGetAllocator( self), _cells);
   [super dealloc];
}


static inline uint8_t   effect( uint8_t left, uint8_t middle, uint8_t right, int decay_propability)
{
   uint32_t   value;
   int32_t    chance;
   int32_t    left_chance;
   int32_t    right_chance;
   int32_t    middle_chance;
   int32_t    decay_chance;
   int32_t    div;

   chance        = rand();
   decay_chance  = chance & 0xFFFF;
   left_chance   = (chance >> 16) & 0xF;
   right_chance  = (chance >> 20) & 0xF;
   middle_chance = (chance >> 24) & 0xFF;

   value = middle;
   div   = 1;

   if( left_chance >= 0xC) // 75% chance
   {
      value += left;
      div++;
   }
   if( right >= 0x8)      // 50% chance
   {
      value += right;
      div++;
   }
//   if( middle_chance >= 0x10)
//   {
//      value += middle;
//      div++;
//   }
   value /= div;

   if( value && decay_propability >= decay_chance)
   {
      value = value - 1;
   }

   assert( value >= 0 && value < N_PALETTE_COLORS);
   return( value);
}


- (void) seedWater
{
   NSUInteger  i;

   for( i = 0; i < _bitmapSize.width; i++)
      _cells[ i] = (rand() <= FIRE_PERCENT * (RAND_MAX / 100) ) ? (N_PALETTE_COLORS - 1) : 0;
}


- (void) flow
{
   uint8_t      *src;
   uint8_t      *dst;
   uint8_t      *sentinel;
   NSUInteger   y;
   NSInteger    n;
   NSInteger    h;
   NSInteger    decay;
   int          decay_probability;
   int          decay_rate;
   double       percent;

   [self seedWater];

   // We want to have the water pretty much reaching the top. Therefore we need
   // to have a variable decay. Unfortunately we need some logarithm for
   // this and my math is not good enough

   h                 = _bitmapSize.height;
   percent           = 2.5 / (h / 100.0);
   decay_probability = (percent / 100.0) * 65536;

   //
   // so we pull the water from below up into a higher line
   // our water is top down, for ease of addressing so
   //
   // we know _cells is at least 2 wide and 2 high
   //
   //   iiiiiiii   seed line (0)
   //   ssssssss   src line
   //   dddddddd   dst line
   //
   for( y = _bitmapSize.height; y >= 2;)
   {
      --y;
      src = &_cells[ (y - 1) * _bitmapSize.width];
      dst = &_cells[ y * _bitmapSize.width];

      // pixel 0, n = 8
      //
      // v
      // i.iiiiii.i
      // 0.123456.7

      *dst++ = effect( src[ _bitmapSize.width - 1], src[ 0], src[ 1], decay_probability);
      ++src;

      // pixel 1-6 (n-2)
      //   v----v
      // i.iiiiii.i
      // 0.123456.7
      //   ^      ^
      //   src    sentinel (src+6)
      sentinel = &src[ _bitmapSize.width - 2];

      while( src < sentinel)
      {
         *dst++ = effect( src[ -1], src[ 0], src[ 1], decay_probability);
         ++src;
      }

      // pixel 7 (n-1)
      //
      //          v
      // i.iiiiii.i
      // 0.123456.7
      //
      *dst++ = effect( src[ -1], src[ 0], src[ - (_bitmapSize.width - 1)], decay_probability);
      ++src;
   }
}

@end


//
// This category bridges the gap between "Water" and "MulleUI". It fills the
// CPU texture
//
@implementation Water( CGBitmap)

- (void) renderToRGBA:(void *) bytes
           bitmapInfo:(struct CGBitmapInfo) info
{
   struct CGBitmapPoint   point;
   uint8_t                *dst;
   uint8_t                *src;
   uint8_t                *dst_sentinel;
   uint8_t                *sentinel;
   NSInteger              y;
   NSInteger              step;
   NSInteger              start_y;
   NSInteger              end_y;

   assert( info.size.width == _bitmapSize.width);
   assert( info.size.height == _bitmapSize.height);
   assert( info.encoding = CGBitmapEncodingRGBABytes);

   dst_sentinel = &((uint8_t *) bytes)[ CGBitmapInfoGetLineByteOffset( info, _bitmapSize.height)];

   if( CGBitmapEncodingIsFlipped( info.encoding))
   {
      start_y = 0;
      end_y   = CGBitmapInfoGetSize( info).height;
      step    = 1;
   }
   else
   {
      start_y = CGBitmapInfoGetSize( info).height - 1;
      end_y   = -1;
      step    = -1;
   }

   // walk down water from start to finish (bottom to top)
   src = _cells;

   for( y = start_y; y != end_y; y += step)
   {
      dst      = &((uint8_t *) bytes)[ CGBitmapInfoGetLineByteOffset( info, y)];
      sentinel = &src[ _bitmapSize.width];
      assert( sentinel <= &_cells[ _bitmapSize.width * _bitmapSize.height]);

      while( src < sentinel)
      {
         assert( dst >= (uint8_t *) bytes);
         assert( dst < dst_sentinel);

         memcpy( dst, &palette[ *src], 4);
         src += 1;
         dst += 4;
      }
   }
}

@end


//
// To keep the the water effect around between frames, we create a
// new layer class. Subclass from CACPUImageLayer for the actual technical
// management.
//
@interface WaterLayer : CACPUImageLayer
{
   Water  *_water;
}
@end


@implementation WaterLayer

- (void) dealloc
{
   [_water release];
   [super dealloc];
}


//
// this is called from CACPUImageLayer drawInContext:
//
- (void) drawInBytes:(void *) texture
          bitmapInfo:(struct CGBitmapInfo) bitmapInfo
{
   CGRect   canvas;

   if( ! _water)
   {
      canvas = [self canvas];
      _water = [[Water alloc] initWithBitmapSize:CGSizeGetBitmapSize( canvas.size)];
   }

   // perform the water flow animation. We could run this elsewhere...
   [_water flow];

   // Get the drawing into our texture memory
   [_water renderToRGBA:texture
             bitmapInfo:bitmapInfo];
}


// react to changes in the layout
- (void) setFrame:(CGRect) frame
{
   CGRect   canvas;

   [super setFrame:frame];

   canvas = [self canvas];

   // need a new water effect with a different size
   [_water autorelease];
   _water = [[Water alloc] initWithBitmapSize:CGSizeGetBitmapSize( canvas.size)];
}

@end



static void   setupSceneInWindow( UIWindow *window)
{
   WaterLayer      *layer;
   CGRect          frame;
   UIView          *view;
   UIWindowPlane   *contentPlane;

   // create a waterlayer stuff it into a UIView, that's resizable
   layer  = [WaterLayer layerWithFrame:CGRectZero];
   view   = [UIView viewWithLayer:layer];
   [view setMargins:UIEdgeInsetsMake( 10, 10, 10, 10)];
   [view setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];

   // place view into window and done
   contentPlane = [window contentPlane];
   [contentPlane addSubview:view];
}



int   main( int argc, char *argv[])
{
   UIWindow       *window;
   UIApplication  *app;

   /*
    * window and app
    */
   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0.0f, 0.0f, 320.0f, 200.0f)];

   [window setBackgroundColor:CGColorMakeRGBA( 0.0, 0.0, 0.0, 1.0)];
   [window setFrameRateHz:30.0];
   [app addWindow:window];

   setupSceneInWindow( window);

   [window renderLoop];

   [app terminate];

   return( 0);
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

