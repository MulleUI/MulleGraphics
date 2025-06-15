#import "import-private.h"

#include <math.h>


struct ribbons_options
{
   NSUInteger   tickSpeed;
   NSUInteger   numPoints;
   NSUInteger   maxTicks;
} opts =
{
   .tickSpeed  = 10,
   .numPoints  = 10,
   .maxTicks   = 3000
};


@interface Ribbon : NSObject

@property( assign) CGPoint   origin;
@property( assign) Ribbon    *neighbor;
@property( assign) CGPoint   d;
@property( assign) CGFloat   hue;
@property( assign) CGColor   color;

@end


@implementation Ribbon

- (instancetype) initWithCanvas:(CGRect) canvas
                           base:(CGFloat) base
{
   CGFloat  x = CGFloatMakeRandomMinMax( 0, canvas.size.width);
   CGFloat  y = CGFloatMakeRandomMinMax( 0, canvas.size.height);
   CGFloat  a = CGFloatMakeRandomMinMax( 0, M_PI_f);

   self->_origin.x = x;
   self->_origin.y = y;

   self->_d.x      = cos(a);
   self->_d.y      = sin(a);
   self->_hue      = fmod( CGFloatMakeRandomMinMax(0, 100) + base, 360.0);
   self->_color    = CGColorMakeWithHSBA( CADegreesToRotation( self->_hue), 1.0, 2.0, 0.01);

   return( self);
}


- (BOOL) drawInContext:(CGContext *) context
{
   CGContextStrokeLineWithColor( context, self->_origin, [self->_neighbor origin], -1.0, self->_color);
   return( YES);
}


- (void) updateInCanvas:(CGRect ) canvas
{
   self->_origin.x += self->_d.x;
   self->_origin.y += self->_d.y;

   if( self->_origin.x < 0 || self->_origin.x >= canvas.size.width)
      self->_d.x *= -1;
   if( self->_origin.y < 0 || self->_origin.y >= canvas.size.height)
      self->_d.y *= -1;
}

@end


@interface RibbonLayer : CGGraphicsLayer
{
   NSMutableArray  *_ribbons;
}

@property( assign) NSUInteger   ticks;

@end




@implementation RibbonLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   NSUInteger   i, j;
   CGRect       canvas;
   Ribbon       *ribbon;
   CGFloat      base;

   [super initWithFrame:frame];

   self->_ribbons = [NSMutableArray new];
   [self->_ribbons mulleSetThreadSafe:YES];
   canvas = [self canvas];
   base   = CGFloatMakeRandomMinMax( 0, 360);
   for( i = 0; i < opts.numPoints; i++)
   {
      ribbon = [[[Ribbon alloc] initWithCanvas:canvas
                                          base:base] autorelease];
      [self->_ribbons addObject:ribbon];

      // as the ribbon is private to our "locked" Ribbonlayer, make it 
      // inherit threadsafeness dynamically
      [ribbon mulleSetThreadSafe:YES];
   }

   for( i = 0; i < opts.numPoints; i++)
   {
      j = i;
      while(j == i)
         j = rand() % opts.numPoints;
      [[self->_ribbons :i] setNeighbor:[self->_ribbons :j]];
   }
   return( self);
}


- (void) dealloc
{
   [self->_ribbons release];
   [super dealloc];
}


- (BOOL) drawInContext:(CGContext *) context
{
   CGColor      fillColor;
   CGRect       canvas;
   NSUInteger   i;
   Ribbon       *ribbon;

    canvas = [self canvas];

   fillColor = CGColorMakeWithRGBA( 0, 0, 0, 5.0 / 255.0);
   CGContextFillRectWithColor( context, canvas, fillColor);

   if( opts.maxTicks && _ticks > opts.maxTicks)
      return( YES);

   CGContextStrokeWidth( context, 3.5);

   for( i = 0; i < opts.tickSpeed; i++)
   {
      for( ribbon in _ribbons)
      {
         [ribbon updateInCanvas:canvas];  // location in Window!
         [ribbon drawInContext:context];
      }
   }
   ++_ticks;
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
   RibbonLayer     *layer;
   CGRect          contentRect;
   CGRect          frame;
   NSUInteger      styleMask;

   app = [UIApplication sharedInstance];
   {
      styleMask = UIWindowStyleMaskDefault; //  & ~UIWindowStyleRetained;
      window    = [UIWindow windowWithFrame:CGRectMake( 0, 0, 800, 600)
                            titleUTF8String:"Demo"
                                  styleMask:styleMask];

      //window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      assert( window);

      [window setFrameRateHz:60.0];
      [window setBackgroundColor:CGColorMakeBlack()]; // this avoids the window contents being cleared
      [window setOpaque:YES]; // this avoids the window contents being cleared

      contentPlane = [window contentView];
      contentRect  = [contentPlane contentRect];
      frame        = contentRect;
      layer        = [RibbonLayer layerWithFrame:frame];
      view         = [UIView viewWithLayer:layer];
      [view setAutoresizingMask:UIViewAutoresizingScaleToFill];
      [contentPlane addSubview:view];

      perf = [MulleUIPerf object];
      [window setFrameDelegate:perf];

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




/*
let points = [];
let tickSpeed = 10;
let base = 180;
let numPoints = 10;
let maxTicks = 3000;
let ticks = 0;

function Point(x = random(width), y = random(height), a = random(PI)){
  this.x = x;
  this.y = y;
  this.a = a;
  this.dx = cos(a);
  this.dy = sin(a);
  this.hue = (random(100) + base)%360;
  this.color = color(this.hue, 100, 100, .01);
}

Point.prototype.update = function(){
  this.x += this.dx;
  this.y += this.dy;
  if (this.x < 0 || this.x >= width) this.dx *= -1;
  if (this.y < 0 || this.y >= height) this.dy *= -1;
  stroke(this.color);
  line(this.x, this.y, this.neighbor.x, this.neighbor.y);
}

function setup(){
  createCanvas();
  colorMode(HSB);
  windowResized();
  blendMode(ADD);
  strokeWeight(1.5);
}

function init(){
  points = [];
  base = random(360);
  ticks = 0;

  for (var i = 0; i < numPoints; i++) points.push(new Point());

  for (var i = 0; i < points.length; i++){
    let j = i;
    while(j == i) j = floor(random(points.length));
    points[i].neighbor = points[j];
  }
}

function draw(){
  if (ticks > maxTicks) return;
  for (var n = 0; n < tickSpeed; n++){
    for (var i = 0; i < points.length; i++){
      points[i].update();
    }
    ticks++;
  }
}

function mouseClicked(){
  windowResized();
}

function windowResized() {
  resizeCanvas(windowWidth, windowHeight);
  pixelDensity(1);
  clear();
  background(0);
  init();
}
*/

