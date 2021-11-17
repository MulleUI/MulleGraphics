#import "import-private.h"

// stolen and adapted from paper.js JavaScript
// http://paperjs.org/examples/radial-rainbows/

#define HZ                  120.0
#define N_COLORSTOPS        40
#define COLOR_CYCLES        2           // number of rainbows on screen at same time
#define HOLE                0.0         // create hole in middle
#define COLOR_CHANGE_SPEED  (0.7/HZ)    // manual fudge factor
#define RIDGE               0.0 // 1.5         // try 1.5 - 3.0
#define BRIGHTNESS_DIP      1.1         // undefine to turn off


static void   circleWithHolePath( NVGcontext *vg,
                                  CGPoint center,
                                  CGFloat innerRadius,   // hole
                                  CGFloat outerRadius)
{
   nvgBeginPath( vg);
   nvgPathWinding( vg, NVG_SOLID);
   nvgCircle( vg, center.x, center.y, outerRadius);
   nvgPathWinding( vg, NVG_HOLE);
   nvgCircle( vg, center.x, center.y, innerRadius);
}


//
// ColorStop color components are kept in HSBA to avoid loss of information,
// that would be suffered during back and forth conversion (makes the
// demo unusable!)
//
struct ColorStop
{
   CGFloat      components[ 4];
   CGFloat      radius;
};


static inline struct ColorStop   ColorStopMake( CGFloat *components, CGFloat r)
{
   return( (struct ColorStop) {
                                 .components[ 0] = components[ 0],
                                 .components[ 1] = components[ 1],
                                 .components[ 2] = components[ 2],
                                 .components[ 3] = components[ 3],
                                 .radius = r
                              });
}

static inline CGColor   ColorStopGetColor( struct ColorStop *c)
{
   return( CGColorMakeHSBA( c->components[ 0],
                               c->components[ 1],
                               c->components[ 2],
                               c->components[ 3]));
}



@interface RadialGradientCircle : NSObject <CGVectorDrawable>
{
   struct mulle_structarray  _stops;
}

@property( assign) CGSize   size;

- (void) drawRect:(CGRect) rect
          options:(CGDrawableOptions *) options
          context:(CGContext *) context;

@end


@implementation RadialGradientCircle

- (instancetype) init
{
   mulle_structarray_init( &_stops,
                           sizeof( struct ColorStop),
                           alignof( struct ColorStop),
                           0,
                           MulleObjCInstanceGetAllocator( self));
   return( self);
}


- (void) dealloc
{
   mulle_structarray_done( &_stops);
   [super dealloc];
}

- (NSUInteger) numberOfColorStops
{
   return( mulle_structarray_get_count( &_stops));
}


- (void) addColorStop:(struct ColorStop) stop
{
   mulle_structarray_add( &_stops, &stop);
}


- (void) setColorStop:(struct ColorStop) stop
              atIndex:(NSUInteger) i
{
   struct ColorStop   *p;

   p = mulle_structarray_get( &_stops, i);
   *p = stop;
}


- (struct ColorStop) colorStopAtIndex:(NSUInteger) i
{
   struct ColorStop   *p;

   p = mulle_structarray_get( &_stops, i);
   return( *p);
}


static void   fillCircleWithHoleAndColorStops( NVGcontext *vg,
                                               CGPoint center,
                                               struct ColorStop *inner,
                                               struct ColorStop *outer)
{
   NVGpaint   paint;

   circleWithHolePath( vg, center, outer->radius, inner->radius);

//   paint = nvgBoxGradient( vg, center.x - outer->radius, center.y - outer->radius,
//                               outer->radius * 2, outer->radius * 2,
//                               outer->radius, inner->radius,
//                               ColorStopGetColor( inner), ColorStopGetColor( outer));

//   paint = nvgLinearGradient( vg, center.x - outer->radius, center.y - outer->radius,
//                                  center.x + outer->radius, center.y + outer->radius,
//                                  ColorStopGetColor( inner), ColorStopGetColor( outer));
//
   paint = nvgRadialGradient( vg, center.x, center.y,
                                  inner->radius, outer->radius,
                                  ColorStopGetColor( inner), ColorStopGetColor( outer));
   nvgFillPaint( vg, paint);
   nvgFill( vg);
}


- (void) drawRect:(CGRect) rect
          options:(CGDrawableOptions *) options
          context:(CGContext *) context
{
   struct mulle_structarrayreverseenumerator   rover;
   NVGcontext                                  *vg;
   struct ColorStop                            *inner;
   struct ColorStop                            *outer;
   struct ColorStop                            hack;
   CGPoint                                     center;
   NSUInteger                                  i, n;

   vg     = CGContextGetNVGContext( context);
   center = CGRectGetCenterPoint( rect);

   nvgShapeAntiAlias( vg, RIDGE != 0.0);

   n     = mulle_structarray_get_count( &_stops);
   i     = 0;
   outer = NULL;

   // draw from the outside in. rings on the inside overlap by a pixel to
   // avoid ugliness. Only antialias the outer ring to avoid aliasing pixels
   // in the middle of the ring.
   rover = mulle_structarray_reverseenumerate( &_stops);
   while( mulle_structarrayreverseenumerator_next( &rover, (void **) &inner))
   {
      ++i;
//      if( (i & 1) != 0)
      {
         if( outer)
         {
            if( RIDGE == 0.0)
            {
               if( i == 2 || i == n - 1)
                  nvgShapeAntiAlias( vg, 1);
               else
                  nvgShapeAntiAlias( vg, 0);
            }

            hack = *outer;
            if( i != 2)
               hack.radius += 1.0 - RIDGE;

            fillCircleWithHoleAndColorStops( vg, center, inner, &hack);
         }
      }
      outer = inner;
   }
   mulle_structarrayreverseenumerator_done( &rover);
}

@end


@interface RadialGradientCircleAnimation : CAAnimation
@end

@implementation RadialGradientCircleAnimation

- (void) animateObject:(id) object
normalizedRelativeTime:(double) t
           elapsedTime:(CARelativeTime) time
{
   CAImageLayer           *imageLayer = object;
   RadialGradientCircle   *circle;
   CGFloat                factor;
   NSInteger              i, n;
   struct ColorStop       c;

   circle = (RadialGradientCircle *) [imageLayer image];
   assert( [circle isKindOfClass:[RadialGradientCircle class]]);

   // animation values are calcuated for 60Hz framerate, check how
   // much we need to multiply with for the elapsed time to make it
   // look natural
   factor = time / (1.0 / HZ);  // expected elapsedTime
  //  fprintf( stderr, "%.3f\n", factor);

   n = [circle numberOfColorStops];
   for( i = 0; i < n; i++)
   {
      c = [circle colorStopAtIndex:i];

      c.components[ 0] = c.components[ 0] - COLOR_CHANGE_SPEED * factor;
      if( c.components[ 0] < 0.0)
         c.components[ 0] = 1.0 + c.components[ 0];
      c.components[ 0] = fmodf( c.components[ 0], 1.0);

      [circle setColorStop:c
                   atIndex:i];
   }
}

@end





static void   setupCircle( RadialGradientCircle *circle, CGFloat r)
{
   NSInteger          i;
   CGFloat            brightness;
   CGFloat            hue;
   struct ColorStop   c;
   CGFloat            components[ 4];

   for( i = 0; i < N_COLORSTOPS; i++)
   {
#ifdef BRIGHTNESS_DIP
      brightness = 1 - ((CGFloat) i / N_COLORSTOPS) * BRIGHTNESS_DIP;
      if( brightness < 0.0)
         brightness = 0.0;
#else
      brightness = 0.5;
#endif
      hue            = fmodf( ((CGFloat) i / N_COLORSTOPS) * COLOR_CYCLES, 1.0);
      components[ 0] = hue;
      components[ 1] = 1.0;
      components[ 2] = brightness;
      components[ 3] = 1.0;
      c              = ColorStopMake( components, i * r + HOLE);
      [circle addColorStop:c];
   }
}


static void   setupScene( UIWindow *window)
{
   CGRect                      contentRect;
   CGRect                      frame;
   UIView                      *view;
   CAImageLayer                *layer;
   RadialGradientCircle        *circle;
   struct CAAnimationOptions   options;
   CAAnimation                 *animation;

   contentRect = [[window contentPlane] contentRect];

   circle = [RadialGradientCircle object];
   setupCircle( circle, 900 / 2.0 / N_COLORSTOPS);

   layer = [CAImageLayer layerWithFrame:contentRect];
   [layer setImage:circle];

   view  = [UIView viewWithLayer:layer];
   [[window contentPlane] addSubview:view];

   options   = CAAnimationOptionsMake( CARelativeTimeRangeMake( 0, INFINITY), 0.0, 0);
   animation = [RadialGradientCircleAnimation animationWithAnimationOptions:&options];
   [layer addAnimation:animation];
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   MulleUIPerf     *perf;

   app = [UIApplication sharedInstance];
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      assert( window);

      perf = [MulleUIPerf object];
      [window setRenderDelegate:perf];
      [window setFrameRateHz:HZ];

      setupScene( window);

      [app addWindow:window];
      [window renderLoop];
   }
   return( [app terminate]);
}

