#import "import-private.h"

#include <math.h>


struct hexagon_options
{
   NSUInteger   len;
   NSUInteger   count;
   CGFloat      baseTime;
   CGFloat      addedTime;
   CGFloat      dieChance;
   CGFloat      spawnChance;
   CGFloat      sparkChance;
   CGFloat      sparkDist;
   CGFloat      sparkSize;
   float        hslcomponents[ 3];
   CGFloat      baseLight;
   CGFloat      addedLight;
   CGFloat      shadowToTimePropMult;
   CGFloat      baseLightInputMultiplier;
   CGFloat      addedLightInputMultiplier;
   CGFloat      repaintAlpha;
   CGFloat      hueChange;
};


struct hexagon_options  opts =
{

   .len                       = 20,
   .count                     = 50,
   .baseTime                  = 10,
   .addedTime                 = 10,
   .dieChance                 = 0.05,
   .spawnChance               = 1,
   .sparkChance               = 0.1,
   .sparkDist                 = 10,
   .sparkSize                 = 2,

   .hslcomponents             = { 0.0, 1.0, 1.0 },
   .baseLight                 = 50,
   .addedLight                = 10, // [50-10,50+10]
   .shadowToTimePropMult      = 6,
   .baseLightInputMultiplier  = 0.01,
   .addedLightInputMultiplier = 0.02,

   .repaintAlpha              = 0.04,
   .hueChange                 = 0.1
};



@interface Line : NSObject
{
   CGPoint   position;
   CGVector  added;
   CGFloat   rad;
   CGFloat   lightInputMultiplier;
   float     hslcomponents[ 3];
   CGFloat   time;
   CGFloat   targetTime;
   CGFloat   cumulativeTime;
}

@end


@interface HexagonLayer : CALayer
{
   NSMutableArray  *lines;
}

@property( assign) NSUInteger   tick;

@end


@implementation Line

- (instancetype) initWithHexagonLayer:(HexagonLayer *) layer
{
   [self resetInHexagonLayer:layer];
   return( self);
}


- (void) resetInHexagonLayer:(HexagonLayer *) layer
{
   self->position             = CGPointZero;
   self->added                = CGVectorZero;

   self->rad                  = 0;
   self->cumulativeTime       = 0;

   self->lightInputMultiplier = opts.baseLightInputMultiplier +
                                opts.addedLightInputMultiplier * CGFloatMakeRandom();
   self->hslcomponents[ 0]    = fmod( [layer tick] * opts.hueChange, 1.0);
   self->hslcomponents[ 1]    = opts.hslcomponents[ 1];
   self->hslcomponents[ 2]    = opts.hslcomponents[ 2];


   [self beginPhaseInHexagonLayer:layer];
}


- (void) beginPhaseInHexagonLayer:(HexagonLayer *) layer
{
   CGPoint   die;
   CGFloat   baseRad;
   CGRect    canvas;

   self->position   = CGPointAddVector( self->position, self->added);

   self->time       = 0;
   self->targetTime = (opts.baseTime + opts.addedTime * CGFloatMakeRandom());

   baseRad          = M_PI_f * 2 / 6;
   self->rad       += baseRad * (CGFloatMakeRandom() < .5 ? 1 : -1);
   self->added      = CGVectorMake( cosf( self->rad), sinf( self->rad));

   canvas = [layer canvas];
   die    = CGRectGetCenterPoint( canvas);
   die    = CGPointScale( die, 1.0 / opts.len);

   if( CGFloatMakeRandom() < opts.dieChance || self->position.x > die.x
                                            || self->position.x < -die.x
                                            || self->position.y > die.y
                                            || self->position.y < -die.y)
  {
     [self resetInHexagonLayer:layer];
  }
}



static void   drawBoxWithDropShadow( CGContext *context,
                                     CGRect rect,
                                     CGColor color,
                                     CGFloat cornerRadius,
                                     CGFloat shadowBlur)
{
   struct NVGcontext    *vg;
   struct CGShadow   shadow;
   CGColor              innerColor;

   innerColor       = color;
   innerColor.a     = 0.15;
   shadow           = CGShadowMake( CGPointMake( 0, 0), shadowBlur, innerColor);
   shadow.hole      = NO;

   vg = CGContextGetNVGContext( context);
   mvgFillRoundedShadow( vg, rect, cornerRadius, &shadow);
   mvgFillRoundedRectWithColor( vg, rect, cornerRadius, color);
}


- (void) stepInHexagonLayer:(HexagonLayer *) layer
                    context:(CGContext *) context
{
   NVGcontext   *vg;
   NVGpaint     paint;
   CGColor      color;
   CGFloat      prop;
   CGFloat      shadowBlur;
   CGPoint      spark;
   CGFloat      wavea;
   CGVector     wave;

   ++self->time;
   ++self->cumulativeTime;

   if( self->time >= self->targetTime)
     [self beginPhaseInHexagonLayer:layer];

   prop                    = self->time / self->targetTime;
   self->hslcomponents[ 2] = (opts.baseLight + opts.addedLight *
                             sinf( self->cumulativeTime * self->lightInputMultiplier)) / 100.0;
   shadowBlur              = prop * opts.shadowToTimePropMult;
   color                   = CGColorMakeWithHSLComponents( self->hslcomponents);

   wavea = sinf( prop * M_PI_f / 2);
   wave  = CGVectorMake( self->added.dx * wavea, self->added.dy * wavea);

   spark = CGPointAddVector( self->position, wave);
   spark = CGPointScale( spark, opts.len);

   drawBoxWithDropShadow( context,
                          CGRectMake( spark.x, spark.y, opts.sparkSize, opts.sparkSize),
                          color,
                          2.0,
                          shadowBlur);

   if( CGFloatMakeRandom() < opts.sparkChance)
   {
      spark.x += CGFloatMakeRandom() * opts.sparkDist *
          (CGFloatMakeRandom() < .5 ? 1 : -1 ) - opts.sparkSize / 2;
      spark.y += CGFloatMakeRandom() * opts.sparkDist *
          (CGFloatMakeRandom() < .5 ? 1 : -1 ) - opts.sparkSize / 2,

      drawBoxWithDropShadow( context,
                             CGRectMake( spark.x, spark.y, opts.sparkSize, opts.sparkSize),
                             color,
                             2.0,
                             shadowBlur);
   }
}

@end


@implementation HexagonLayer

- (instancetype) init
{
   [super init];
   self->lines = [NSMutableArray new];
   return( self);
}


- (void) dealloc
{
   [self->lines release];
   [super dealloc];
}


- (BOOL) drawInContext:(CGContext *) context
{
   Line         *line;
   NVGcontext   *vg;
   CGRect       canvas;
   CGPoint      die;
   CGColor      fillColor;

   ++self->_tick;

   canvas = [self canvas];
   if( [lines count] < opts.count && CGFloatMakeRandom() < opts.spawnChance)
      [lines addObject:[[[Line alloc] initWithHexagonLayer:self] autorelease]];

   vg = CGContextGetNVGContext( context);
   nvgSave( vg);
   {
      nvgGlobalCompositeOperation( vg, NVG_SOURCE_OVER);
      fillColor = CGColorMakeWithRGBA( 0, 0, 0, self->_tick == 1
                                                ? 1.0
                                                : opts.repaintAlpha);
      mvgFillRectWithColor( vg, canvas, fillColor);

      nvgGlobalCompositeOperation( vg, NVG_LIGHTER);
      nvgTranslate( vg, canvas.size.width / 2.0, canvas.size.height / 2.0);
      for( line in lines)
         [line stepInHexagonLayer:self
                          context:context];
   }
   nvgRestore( vg);
   return( YES);
}

@end



int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   UIView          *view;
   UIWindowPlane   *contentPlane;
   MulleUIPerf     *perf;
   HexagonLayer    *layer;
   CGRect          frame;
   NSUInteger      styleMask;

   app = [UIApplication sharedInstance];
   {
      styleMask = UIWindowStyleMaskDefault; // & ~UIWindowStyleRetained;
      window    = [UIWindow windowWithFrame:CGRectMake( 0, 0, 800, 600)
                            titleUTF8String:"Demo"
                                  styleMask:styleMask];

      //window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      assert( window);

      [window setFrameRateHz:60.0];
      [window setBackgroundColor:CGColorMakeBlack()]; // this avoids the window contents being cleared
      [window setOpaque:YES]; // this avoids the window contents being cleared

      contentPlane = [window contentView];
      frame        = [contentPlane contentRect];
      layer        = [HexagonLayer layerWithFrame:frame];
      view         = [UIView viewWithLayer:layer];
      [view setAutoresizingMask:UIViewAutoresizingScaleToFill];
      [contentPlane addSubview:view];

      [app addWindow:window];
   }

   perf = [MulleUIPerf object];
   [window setFrameDelegate:perf];

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




/*
var w = c.width = window.innerWidth,
    h = c.height = window.innerHeight,
    ctx = c.getContext( '2d' ),

    opts = {

      len: 20,
      count: 50,
      baseTime: 10,
      addedTime: 10,
      dieChance: .05,
      spawnChance: 1,
      sparkChance: .1,
      sparkDist: 10,
      sparkSize: 2,

      color: 'hsl(hue,100%,light%)',
      baseLight: 50,
      addedLight: 10, // [50-10,50+10]
      shadowToTimePropMult: 6,
      baseLightInputMultiplier: .01,
      addedLightInputMultiplier: .02,

      cx: w / 2,
      cy: h / 2,
      repaintAlpha: .04,
      hueChange: .1
    },

    tick = 0,
    lines = [],
    dieX = w / 2 / opts.len,
    dieY = h / 2 / opts.len,

    baseRad = Math.PI * 2 / 6;

ctx.fillStyle = 'black';
ctx.fillRect( 0, 0, w, h );

function loop() {

  window.requestAnimationFrame( loop );

  ++tick;

  ctx.globalCompositeOperation = 'source-over';
  ctx.shadowBlur = 0;
  ctx.fillStyle = 'rgba(0,0,0,alp)'.replace( 'alp', opts.repaintAlpha );
  ctx.fillRect( 0, 0, w, h );
  ctx.globalCompositeOperation = 'lighter';

  if( lines.length < opts.count && Math.random() < opts.spawnChance )
    lines.push( new Line );

  lines.map( function( line ){ line.step(); } );
}
function Line(){

  this.reset();
}
Line.prototype.reset = function(){

  this.x = 0;
  this.y = 0;
  this.addedX = 0;
  this.addedY = 0;

  this.rad = 0;

  this.lightInputMultiplier = opts.baseLightInputMultiplier + opts.addedLightInputMultiplier * Math.random();

  this.color = opts.color.replace( 'hue', tick * opts.hueChange );
  this.cumulativeTime = 0;

  this.beginPhase();
}
Line.prototype.beginPhase = function(){

  this.x += this.addedX;
  this.y += this.addedY;

  this.time = 0;
  this.targetTime = ( opts.baseTime + opts.addedTime * Math.random() ) |0;

  this.rad += baseRad * ( Math.random() < .5 ? 1 : -1 );
  this.addedX = Math.cos( this.rad );
  this.addedY = Math.sin( this.rad );

  if( Math.random() < opts.dieChance || this.x > dieX || this.x < -dieX || this.y > dieY || this.y < -dieY )
    this.reset();
}
Line.prototype.step = function(){

  ++this.time;
  ++this.cumulativeTime;

  if( this.time >= this.targetTime )
    this.beginPhase();

  var prop = this.time / this.targetTime,
      wave = Math.sin( prop * Math.PI / 2  ),
      x = this.addedX * wave,
      y = this.addedY * wave;

  ctx.shadowBlur = prop * opts.shadowToTimePropMult;
  ctx.fillStyle = ctx.shadowColor = this.color.replace( 'light', opts.baseLight + opts.addedLight * Math.sin( this.cumulativeTime * this.lightInputMultiplier ) );
  ctx.fillRect( opts.cx + ( this.x + x ) * opts.len, opts.cy + ( this.y + y ) * opts.len, 2, 2 );

  if( Math.random() < opts.sparkChance )
    ctx.fillRect( opts.cx + ( this.x + x ) * opts.len + Math.random() * opts.sparkDist * ( Math.random() < .5 ? 1 : -1 ) - opts.sparkSize / 2, opts.cy + ( this.y + y ) * opts.len + Math.random() * opts.sparkDist * ( Math.random() < .5 ? 1 : -1 ) - opts.sparkSize / 2, opts.sparkSize, opts.sparkSize )
}
loop();

window.addEventListener( 'resize', function(){

  w = c.width = window.innerWidth;
  h = c.height = window.innerHeight;
  ctx.fillStyle = 'black';
  ctx.fillRect( 0, 0, w, h );

  opts.cx = w / 2;
  opts.cy = h / 2;

  dieX = w / 2 / opts.len;
  dieY = h / 2 / opts.len;
});


*/