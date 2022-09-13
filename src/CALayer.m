#import "import-private.h"

#import "CALayer.h"


#pragma clang diagnostic ignored "-Wparentheses"
// #define RENDER_DEBUG
// #define CALAYER_DEBUG

@implementation CALayer


+ (instancetype) layerWithFrame:(CGRect) frame
{
   return( [[[self alloc] initWithFrame:frame] autorelease]);
}


- (id) init
{
   struct mulle_allocator   *allocator;

   self = [super init];
   if( ! self)
      return( self);

   _bounds.size.width   = INFINITY;
   _canvas.size.width   = INFINITY;
   _clipRect.size.width = INFINITY; // means no clipRect

   // by default only track bounds
   _frameTracking     = CALayerBoundsSizeTracksFrameSize;
   _opacity           = 1.0;
   _alpha             = 1.0;
   _transform         = CGAffineTransformMakeIdentity();
   _masksToBounds     = YES;

    //_pixelCenter     = CGPointMake( 0.5, 0.5);
   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   self = [self init];
   if( self)
      _frame = frame;
   return( self);
}


- (void) dealloc
{
   [self removeAllAnimations];

   MulleObjCObjectSetDuplicatedUTF8String( self, &_debugNameUTF8String, NULL);

   [super dealloc];
}


- (id) copy
{
   CALayer   *clone;

   clone = [super copy];

   memset( &clone->_animationStorage, 0, sizeof( _animationStorage));
   clone->_debugNameUTF8String = NULL;

   return( clone);
}


- (struct CAAnimationStorage *) animationStorage
{
   return( &_animationStorage);
}


+ (instancetype) layer
{
   return( [self object]);
}


static inline CGRect   getBounds( CALayer *self)
{
   CGRect  bounds;

   bounds.origin = self->_bounds.origin;
   bounds.size   = self->_bounds.size.width == INFINITY
                     ? self->_frame.size
                     : self->_bounds.size;
   return( bounds);
}


- (CGRect) bounds
{
   return( getBounds( self));
}


- (void) setBounds:(CGRect) bounds
{
   [self willChange];    // seems needed

   _bounds.origin = bounds.origin;
   if( (_frameTracking & CALayerBoundsSizeTracksFrameSize) &&
         CGSizeEqualToSize( _frame.size, bounds.size))
      _bounds.size.width = INFINITY;
   else
      _bounds.size = bounds.size;
}


static inline CGRect   getCanvas( CALayer *self)
{
   CGRect  canvas;

   canvas.origin = self->_canvas.origin;
   canvas.size   = self->_canvas.size.width == INFINITY
                     ? self->_frame.size
                     : self->_canvas.size;
   return( canvas);
}


- (CGRect) canvas
{
   return( getCanvas( self));
}


- (void) setCanvas:(CGRect) canvas
{
   [self willChange]; // seems needed

   _canvas.origin = canvas.origin;
   if( (_frameTracking & CALayerCanvasSizeTracksFrameSize) &&
         CGSizeEqualToSize( _frame.size, canvas.size))
      _canvas.size.width = INFINITY;
   else
      _canvas.size = canvas.size;
}


- (void) setDebugNameUTF8String:(char *) s
{
   MulleObjCObjectSetDuplicatedUTF8String( self, &_debugNameUTF8String, s);
}


- (char *) UTF8String
{
   char        *result;
   char        *s;
   auto char   buf[ 64];
   size_t      len;
   char        *format;

   s = MulleObjCClassGetNameUTF8String( NSClassFromObject( self));
   sprintf( buf, "%p",  self);

   format = "<%s %s>";
   len    = _debugNameUTF8String ? strlen( _debugNameUTF8String) : 0;
   if( len)
   {
      format = "<%s %s \"%s\">";
      len   += 3; // < "">\0"
   }
   len    += strlen( s) + strlen( buf) + 4; // < "">\0"
   result  = mulle_malloc( len);
   sprintf( result, format, s, buf, _debugNameUTF8String);
   return( MulleObjCAutoreleaseAllocation( result, NULL));
}


- (NSUInteger) windowStyleMaskBits
{
   return( 0);
}

@end

