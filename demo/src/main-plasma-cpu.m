#import "import-private.h"


#define FRAMERATE_HZ      120.0


// This demo shows how you can fairly easily convert C code into
// a CACPUImagelayer subclass.



/*
 * Plasma "inspired" by
 * https://lodev.org/cgtutor/plasma.html
 */
#define W                 128
#define H                 128
#define N_PALETTE_COLORS  256
#define PLASMA_SIZE       8.0
#define JITTER            0.4

static inline NSUInteger   plasma_function( NSUInteger x, NSUInteger y)
{
   CGPoint   jitter;

   jitter.x = 1.0;
   jitter.y = 1.0;
   if( JITTER != 0.0)
   {
      jitter.x = jitter.x - fmod( (double) rand() / RAND_MAX, JITTER);
      jitter.y = jitter.x - fmod( (double) rand() / RAND_MAX, JITTER);
   }
   return( 128.0 + (128.0 * sin( x / PLASMA_SIZE) * jitter.x)
           + 128.0 + (128.0 * sin( y / PLASMA_SIZE) * jitter.y) / 2);
}


@interface PlasmaLayer : CACPUImageLayer
{
   uint32_t   _plasma[ H][W];
   uint32_t   _palette[ N_PALETTE_COLORS];
}
@end


@implementation PlasmaLayer

- (void) initPalette
{
   CGColor      color;
   NSUInteger   x;

   for( x = 0; x < N_PALETTE_COLORS; x++)
   {
      color       = CGColorMakeWithHSV( x / 255.0, 1.0, 1.0);
      _palette[x] = CGColorGetHexColor( color);
   }
}


- (void) initPlasma
{
   NSUInteger   x, y;

   for( y = 0; y < H; y++)
      for( x = 0; x < W; x++)
         _plasma[ y][ x] = plasma_function( x, y);
}


- (id) initWithFrame:(CGRect) frame
{
   CGRect  rect;

   [super initWithFrame:frame];

   rect = CGRectMake( 0, 0, W, H);

   [self setCanvas:rect]; // set "CPU" screen
   [self setBounds:rect]; // we want it scaled...

   [self initPalette];
   [self initPlasma];

   return( self);
}


- (void) drawInBytes:(void *) texture
          bitmapInfo:(struct CGBitmapInfo) bitmapInfo
{
   uint32_t      *pixels;
   NSUInteger    paletteShift;
   NSUInteger    x, y;

   assert( CGBitmapInfoGetEncoding( bitmapInfo) == CGBitmapEncodingRGBABytes);
   assert( MulleIntegerSizeEqualToIntegerSize( CGBitmapInfoGetSize( bitmapInfo), MulleIntegerSizeMake( W, H)));

   // the parameter to shift the palette varies with time
   paletteShift = (NSUInteger) (mulle_absolutetime_now() * FRAMERATE_HZ);
   pixels       = texture;
    //draw every pixel again, with the shifted palette color

   for( y = 0; y < H; y++)
      for( x = 0; x < W; x++)
         pixels[ y  * W + x] = _palette[ (_plasma[ y][ x] + paletteShift) % N_PALETTE_COLORS];
}

@end


static void   drawGrid( CALayer *layer, void *_context)
{
   CGContext    *context = _context;
   CGRect       canvas;
   CGFloat      xf, yf;
   CGFloat      xstep, ystep;
   NVGcontext   *vg;
   NSUInteger   x, y;

   canvas = [layer canvas];

   vg = CGContextGetNVGContext( context);

   nvgBeginPath( vg);

   xstep = canvas.size.width  / W;
   ystep = canvas.size.height / H;

   for( y = 1; y < H; y++)
   {
      yf = (y * ystep) + ystep / 2.0;
      nvgMoveTo( vg, 0, yf);
      nvgLineTo( vg, canvas.size.width, yf);
   }

   for( x = 1; x < W; x++)
   {
      xf = (x * xstep) + xstep / 2.0;
      nvgMoveTo( vg, xf, 0);
      nvgLineTo( vg, xf, canvas.size.height);
   }

   nvgStrokeWidth( vg, 0.2);
   nvgStrokeColor( vg, [UIColor darkGrayColor]);
   nvgStroke( vg);
}

//
// here we use a custom View to react to changes in the view size
// to pass it onto the layer
//
@interface PlasmaView : UIView
{
   CALayer   *_gridLayer;
}
@end


@implementation PlasmaView

+ (Class) layerClass
{
   return( [PlasmaLayer class]);
}

- (instancetype) initWithLayer:(CALayer *) layer
                         frame:(CGRect) frame
{
   CGRect    rect;

   [super initWithLayer:layer
                  frame:frame];

   _gridLayer = [CALayer layerWithFrame:CGRectZero];

   rect = CGRectMake( 0, 0, W , H);
   [_gridLayer setCanvas:rect];
   [_gridLayer setBounds:rect]; // we want it scaled...
   [_gridLayer setDrawCallback:drawGrid];
   [self addLayer:_gridLayer];

   return( self);
}

- (void) layoutLayers
{
   CGRect    gridFrame;

   [super layoutLayers];

   gridFrame = [self contentRect];
   [_gridLayer setFrame:gridFrame];
}

@end



static PlasmaView   *setupPlasmaView( UIWindow *window, CGColor color)
{
   PlasmaView   *view;

   view  = [PlasmaView viewWithFrame:CGRectZero];
   [view setBackgroundColor:[UIColor darkGrayColor]];
   [view setBorderColor:color];
   [view setBorderWidth:6.0];

   return( view);
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   PlasmaView      *plasmaView;
   UIWindowPlane   *contentPlane;
   /*
    * window and app
    */

   app = [UIApplication sharedInstance];
   // before creating windows
   [CGContext setDebugEnabled:YES];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0f, 0.0f, 640.0f, 400.0f)];
   [window setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.0, 0.0, 1.0)];
   {
      contentPlane = [window contentPlane];

      plasmaView = setupPlasmaView( window, [UIColor darkGrayColor]);
      [plasmaView setMargins:UIEdgeInsetsMake( 40, 40, 40, 40)];
      [plasmaView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
      [contentPlane addSubview:plasmaView];

      plasmaView = setupPlasmaView( window, [UIColor darkGrayColor]);
      [plasmaView setMargins:UIEdgeInsetsMake( 120, 120, 120, 220)];
      [plasmaView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
      [contentPlane addSubview:plasmaView];
   }

   [app addWindow:window];
   [window setFrameRateHz:FRAMERATE_HZ];

   return( [app run]);
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

