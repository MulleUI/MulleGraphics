#define _GNU_SOURCE

#import "import.h"

#include <float.h>
#include <math.h>
#include <stdlib.h>

//#define DEBUG_WITH_FEW_LARGE_BALLS

// kynd.info 2014
// Code "inspired" by paper.js demos
// http://paperjs.org/examples/candy-crash/
//
#ifndef DEBUG_WITH_FEW_LARGE_BALLS
# define      MIN_RADIUS      40
# define      MAX_RADIUS      40
# define      numBalls        32
# define      maxVec          15
# define      overlapFactor   0.015  // bounce back over framerate 66.6 Hz ?
# define      smoothness      1.5      // > 0 < min radius
# define      maxSegments     INT_MAX
#else
# define      MIN_RADIUS      140
# define      MAX_RADIUS      200
# define      numBalls        2
# define      maxVec          15
# define      overlapFactor   0.015  // bounce back over framerate 66.6 Hz ?
# define      smoothness      1.5      // > 0 < min radius
# define      maxSegments     8
#endif


@interface Ball : NSObject
{
   NSUInteger        _numSegment;
   CGFloat          *_boundOffset;
   CGFloat          *_boundOffsetBuff;
   struct CGPoint   *_sidePoints;
   CGColor           _fillColor;
}

@property( assign) CGPoint       point;
@property( assign) CGFloat       radius;
@property( assign) CAPolarPoint  vector;

@end


@implementation Ball

- (id) initWithRadius:(CGFloat) r
             position:(CGPoint) p
               vector:(struct CAPolarPoint) v
                hue:(CGFloat) hue
{
   NSUInteger       i;
   CAPolarPoint     x;
   CGFloat          hue;

   _radius          = r;
   _point           = p;
   _vector          = v;
   _numSegment      = (NSUInteger) floorf( r / smoothness) + 2;
   if( _numSegment > maxSegments)
      _numSegment = maxSegments;

   _boundOffset     = mulle_calloc( _numSegment, sizeof( CGFloat));
   _boundOffsetBuff = mulle_calloc( _numSegment, sizeof( CGFloat));
   _sidePoints      = mulle_calloc( _numSegment, sizeof( CGPoint));


// Cody sez:
//    0.00: Red
//    0.17: Yellow-orange
//    0.33: Green
//    0.50: Cyan
//    0.67: Blue
//    0.83: Magenta
//    1.00: Red (cycles back)

   _fillColor       = CGColorMakeWithHSL( hue, 1, 0.33);
   printf( "hue: %.2f color: %s\n", hue, CGColorUTF8String( _fillColor));

   for( i = 0; i < _numSegment; i++)
   {
      _boundOffset[ i]     = r;
      _boundOffsetBuff[ i] = r;
//      _path.add(new Point());
      x                    = CAPolarPointMakeWithRotation( 1.0f, (double) i / _numSegment);
      _sidePoints[ i]      = CGPointMakeWithPolarPoint( x);
   }
   return( self);
}


/*
 * Ball collision
 */

- (CGPoint) getSidePoint:(NSUInteger) index
{
   CGPoint   p;

   p    = _sidePoints[ index];
   p.x *= _boundOffset[ index];
   p.y *= _boundOffset[ index];
   p    = CGPointAdd( _point, p);
   return( p);
}


- (CGFloat) getBoundOffset:(CGPoint) b
{
   CGPoint          diff;
   CGFloat          angle;
   CGFloat   deg;
   NSUInteger       i;

   diff  = CGPointSubtract( _point, b);
   deg   = CARadiansToDegrees( CGPointGetPolarRadians( diff));
   angle = fmodf( deg + 180.0, 360.0f);
   angle = CADegreesNormalize( angle);
   i     = (NSUInteger) (floor( angle / 360.0) * _numSegment);
   assert( i < _numSegment);
   return( _boundOffset[ i]);
}


- (void) calcBounds:(Ball *) b
{
   NSUInteger   i;
   CGPoint      tp;
   CGFloat      bLen;
   CGFloat      td;
   CGFloat      offset;

   for( i = 0; i < _numSegment; i++)
   {
      tp   = [self getSidePoint:i];
      bLen = [b getBoundOffset:tp];
      td   = CGPointDistanceToPoint( tp, [b point]);
      if(td < bLen)
      {
         offset = (bLen - td) / 2;
         _boundOffsetBuff[ i] -= offset;
         assert( _boundOffsetBuff[ i] >= -1000 && _boundOffsetBuff[ i] <= 1000);
      }
   }
}


- (void) updateBounds
{
   NSUInteger   i;

   for( i = 0; i < _numSegment; i++)
      _boundOffset[i] = _boundOffsetBuff[i];
}


- (void) react:(Ball *) b
{
   CGFloat        dist;
   CGFloat        overlap;
   CAPolarPoint   direc;
   CGPoint        diff;

   dist = CGPointDistanceToPoint( _point, [b point]);
   assert( dist >= 0.0);
   if( (dist < _radius + [b radius]) && (dist != 0.0))
   {
      overlap = _radius + [b radius] - dist;

      diff    = CGPointSubtract( _point, [b point]);
      direc   = CAPolarPointMakeWithRadians( overlap * overlapFactor,
                                             CGPointGetPolarRadians( diff));
      _vector = CAPolarPointAdd( _vector, direc);
      [b setVector:CAPolarPointSubtract( [b vector], direc)];

      [self calcBounds:b];
      [b calcBounds:self];
      [self updateBounds];
      [b updateBounds];
   }
}

/*
 * Ball movement
 */

- (void) checkBorders:(CGSize) size
{
   if( _point.x < -_radius)
      _point.x = size.width + _radius;
   if( _point.x > size.width + _radius)
      _point.x = -_radius;
   if( _point.y < -_radius)
      _point.y = size.height + _radius;
   if( _point.y > size.height + _radius)
      _point.y = -_radius;
}


- (void) updateShape
{
   NSUInteger   i;
   NSUInteger   next;
   NSUInteger   prev;
   CGFloat      offset;
   CGPoint      p;

   for( i = 0; i < _numSegment; i++)
   {
      if( _boundOffset[ i] < _radius / 4)
         _boundOffset[ i] = _radius / 4;

      next    = (i + 1) % _numSegment;
      prev    = (i > 0) ? i - 1 : _numSegment - 1;

      offset  = _boundOffset[ i];
      offset += (_radius - offset) / maxVec;
      offset += ((_boundOffset[ next] + _boundOffset[ prev]) / 2 - offset) / 3;

      // sanity check
      assert( offset >= -1000 && offset <= 1000);

      _boundOffsetBuff[ i] = _boundOffset[ i] = offset;
   }
}


- (void) iterate:(CGSize) size
{
   [self checkBorders:size];

   _vector.radius = fmodf( _vector.radius, maxVec);
   _point         = CGPointAddPolarPoint( _point, _vector);

   [self updateShape];
}


/*
 * Ball drawing
 */
- (BOOL) drawInContext:(CGContext *) context
{
   NVGcontext   *vg;
   NSUInteger   i;
   CGPoint      p;

   vg = CGContextGetNVGContext( context);

   nvgBeginPath( vg);
   nvgGlobalCompositeOperation( vg, NVG_LIGHTER);
   for( i = 0; i < _numSegment; i++)
   {
      p = [self getSidePoint:i];
      if( ! i)
         nvgMoveTo( vg, p.x, p.y);
      else
         nvgLineTo( vg, p.x, p.y);
   }
   nvgClosePath( vg);

   // TODO: need to smooth
   nvgFillColor( vg, _fillColor);
   nvgFill( vg);
   return( YES);
}

@end


@interface CandySmearLayer : CAAccumulationLayer
{
   id    balls[ numBalls];
}
@end


@implementation CandySmearLayer

- (instancetype) initWithFrame:(CGRect) rect
{
   NSUInteger     i;
   CGFloat        r;
   CGPoint        p;
   CAPolarPoint   v;
   float          base;
   float          variation;
   // Track previously used hues
   float          hues[ 6]  = {0.0f, 0.17f, 0.33f, 0.5f, 0.67f, 0.83f}; // Color wheel basics
   int            hue_index = 0;
   CGFloat        hue;

   self = [super initWithFrame:rect];
   if( ! self)
      return( self);

   for( i = 0; i < numBalls; i++)
   {
      r = CGFloatMakeRandom() * (MAX_RADIUS - MIN_RADIUS) + MIN_RADIUS;
      p = CGPointMakeRandomInRect( rect);
      v = CAPolarPointMakeWithRadians( CGFloatMakeRandom(),
                                       CADegreesToRadians( CGFloatMakeRandom() * 360));

      base = hues[ hue_index % 6];
      hue_index++;

       // Add a small random variation
      variation = (double) rand() / (double) RAND_MAX * 0.15 - 0.075;
      hue        = fmodf( base + variation + 1.0f, 1.0f); // Ensure 0-1 range

      balls[ i] = [[Ball alloc] initWithRadius:r
                                      position:p
                                        vector:v
                                           hue:hue];
   }
   return( self);
}


- (void) dealloc
{
   NSUInteger   i;

   for( i = 0; i < numBalls; i++)
      [balls[ i] release];

   [super dealloc];
}


- (void) mulleRelinquishAccess
{
   NSUInteger   i;

   for( i = 0; i < numBalls; i++)
      [balls[ i] mulleRelinquishAccess];

   [super mulleRelinquishAccess];
}


- (void) mulleGainAccess
{
   NSUInteger   i;

   [super mulleGainAccess];

   for( i = 0; i < numBalls; i++)
      [balls[ i] mulleGainAccess];

}

- (void) renderInContext:(CGContext *) context
{
   [super renderInContext:context];
}


- (BOOL) drawInContext:(CGContext *) context
{
   CGRect       canvas;
   NSUInteger   i;
   NSUInteger   j;

   canvas = [self canvas];

   for( i = 0; i < numBalls - 1; i++)
      for( j = i + 1; j < numBalls; j++)
         [balls[ i] react:balls[ j]];

   for( i = 0; i < numBalls; i++)
      [balls[i] iterate:canvas.size];

   for( i = 0; i < numBalls; i++)
      [balls[ i] drawInContext:context];

   return( YES);
}

- (float) alphaForPreviousFramebuffer:(CGFramebuffer *) layer
                               inRect:(CGRect) rect
                               canvas:(CGRect) canvas
{
   return( 0.75);
}

@end



static void   setupSceneInView( UIView *contentView)
{
   CandySmearLayer   *layer;
   CGRect            contentRect;
   UIView            *view;

   assert( contentView);

   contentRect = [contentView contentRect];
   layer       = [CandySmearLayer layerWithFrame:contentRect];
   [layer setDecay:0.99995];
   view        = [UIView viewWithLayer:layer];
   assert( view);
   [contentView addSubview:view];
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   MulleUIPerf     *perf;
   CGRect          frame;

   srand( time( NULL));

   app = [UIApplication sharedInstance];
   {
      frame  = CGRectMake( 0.0, 0.0, 800.0, 600.0);
      window = [UIWindow windowWithFrame:frame
                         titleUTF8String:"Demo"
                               styleMask:UIWindowStyleMaskDefault]; // & ~UIWindowStyleRetained];

//      window = [UIWindow windowWithFrame:CGRectMake( frame)];
      assert( window);

      // If alpha is 0.0 balls lose contour ?
      // If color is white, nothing is shown
      [window setBackgroundColor:CGColorMakeBlack()];
      [window setFrameRateHz:120.0];
      setupSceneInView( [window contentView]);

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

