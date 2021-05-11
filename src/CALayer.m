#import "import-private.h"

#import "CALayer.h"

#import "CGAffineTransform.h"
#import "CGAffineTransform+CString.h"
#import "CGGeometry.h"
#import "CGGeometry+CString.h"
#import "CGContext.h"
#import "nanovg+CString.h"
#import "UIView+CAAnimation.h"
#import "MulleEdgeInsets.h"
#import "MullePaint.h"


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
   struct mulle_allocator               *allocator;
   struct mulle_pointerarrayenumerator   rover;
   CAAnimation                           *animation;

   allocator = MulleObjCInstanceGetAllocator( self);
   mulle_allocator_free( allocator, _debugNameCString);

   rover = mulle_pointerarray_enumerate( &_animations);
   while( _mulle_pointerarrayenumerator_next( &rover, (void **) &animation))
      [animation release];
   mulle_pointerarrayenumerator_done( &rover);

   mulle_pointerarray_done( &_animations);

   [_snapshot release];

   [super dealloc];
}


+ (instancetype) layer
{
   return( [self object]);
}


- (id) copy
{
   CALayer   *copy;

   // this does a memcpy
   copy = NSCopyObject( self, 0, NULL);

   // nil out references to outside memory
   copy->_snapshot    = nil;
   _mulle_pointerarray_init( &copy->_animations, 0, NULL);
   copy->_debugNameCString = NULL;

   return( copy);
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
   _canvas.origin = canvas.origin;
   if( (_frameTracking & CALayerCanvasSizeTracksFrameSize) &&
         CGSizeEqualToSize( _frame.size, canvas.size))
      _canvas.size.width = INFINITY;
   else
      _canvas.size = canvas.size;
}


- (void) fillBackgroundInContext:(CGContext *) context
                           color:(CGColorRef) color
                           paint:(MullePaint *) paint
{
   NVGcontext        *vg;
   CGPoint           tl;
   CGPoint           br;
   CGFloat           borderWidth;
   MulleEdgeInsets   insets;
   CGRect            rect;

   rect = _frame;

   //
   // fill and border are drawn as frame
   //
   // if there is a border to be drawn, then we use antialias
   // otherwise we don't and only draw to the middle of the border
   //
   // if the stroke is alpha, it will have to render over pixels
   // otherwise reduce the size of the shape we draw ?
   //
   tl.x = rect.origin.x;
   tl.y = rect.origin.y;
   br.x = tl.x + rect.size.width;
   br.y = tl.y + rect.size.height;

   if( tl.x > br.x && tl.y > br.y)
      return;

   vg = MulleContextGetNVGContext( context);

   // calc border out from fill, but don't draw
   borderWidth = [self borderWidth];
   if( borderWidth >= 0.1)
   {
      insets = MulleEdgeInsetsMake( borderWidth / 2,
                                    borderWidth / 2,
                                    borderWidth / 2,
                                    borderWidth / 2);
      rect  = MulleEdgeInsetsInsetRect( insets, rect);
      nvgShapeAntiAlias( vg, 0);
   }
   // fill
   nvgBeginPath( vg);
   nvgRoundedRect( vg, rect.origin.x,
                       rect.origin.y,
                       rect.size.width,
                       rect.size.height,
                       _cornerRadius);
   if( paint)
      nvgFillPaint(vg, [paint nvgPaint]);
   else
      nvgFillColor(vg, color);
   nvgFill( vg);

   nvgShapeAntiAlias( vg, 1);
}


- (void) drawBackgroundInContext:(CGContext *) context
{
   [self fillBackgroundInContext:context
                           color:_backgroundColor
                           paint:nil];
}

- (void) drawInContext:(CGContext *) context
{
   if( _drawCallback)
      (*_drawCallback)( self, context);
}


//
// the border is not extending outside of the layer
// this would break too much stuff, if we need a highlight, either but
// a highlighter view below or use insets and leave space around
//
- (void) drawBorderInContext:(CGContext *) context
{
   NVGcontext  *vg;
   CGRect      frame;
   CGFloat     halfBorderWidth;
   CGPoint     tl;
   CGPoint     br;

   //
   // the strokeWidth isn't scaled in nvg, so we do this now ourselves
   //
   if( _borderWidth < 0.1)
      return;

   //
   // if the stroke is alpha, it will have to render over pixels
   // otherwise reduce the size of the shape we draw ?
   //
   halfBorderWidth = _borderWidth / 2.0;

   tl.x = halfBorderWidth + _frame.origin.x;
   tl.y = halfBorderWidth + _frame.origin.y;
   br.x = tl.x + _frame.size.width - halfBorderWidth * 2;
   br.y = tl.y + _frame.size.height - halfBorderWidth * 2;

   if( ! (tl.x <= br.x || tl.y <= br.y))
      return;

   vg = MulleContextGetNVGContext( context);

   //
   // the _cornerRadius is computed for a stroke of width 1 (or 0 ?)
   // the strokeWidth is just scaling it out
   //
   nvgBeginPath( vg);
   nvgRoundedRect( vg, tl.x,
                       tl.y,
                       br.x - tl.x,
                       br.y - tl.y,
                       _cornerRadius);
   nvgStrokeWidth( vg, (int) _borderWidth);
   nvgStrokeColor( vg, _borderColor);
   nvgStroke( vg);

//      nvgMoveTo( vg, tl.x, tl.y);
//      nvgLineTo( vg, br.x, tl.y);
//      nvgLineTo( vg, br.x, br.y);
//      nvgLineTo( vg, tl.x, br.y);
//      nvgLineTo( vg, tl.x, tl.y);

   nvgStrokeWidth( vg, 1.0);  // need to reset to
}


/*
 *
 */
- (NVGcontext *) setupContext:(CGContext *) context
               localTransform:(CGAffineTransform *) localTransform
                        alpha:(CGFloat) alpha
{
   NVGcontext   *vg;
   CGRect        bounds;
   CGRect        localClipRect;

   // this is the "inherited" alpha from UIVIew
   // cull layers which are invisible
   if( MulleAlphaIsTransparent( alpha))
      return( NULL);

   if( _frame.size.width == 0.0 || _frame.size.height == 0.0)
      return( NULL);

   vg = MulleContextGetNVGContext( context);

   //
   // as we reset here and set alpha global, we don't need to save state
   // since each layer will do this.
   //
   nvgReset( vg);

   // these are the bounds in global screen space
   if( _clipRect.size.width != INFINITY)  // transform set by UIView during layout
      nvgScissor( vg, _clipRect.origin.x,
                      _clipRect.origin.y,
                      _clipRect.size.width,
                      _clipRect.size.height);

   // this is the "inherited" transform from UIVIew
   nvgTransform( vg, _transform.a,
                     _transform.b,
                     _transform.c,
                     _transform.d,
                     _transform.tx,
                     _transform.ty);

   // we are still in frame space, here so calculate the bounds scissor
   // somewhat inconveniently
   if( _masksToBounds)
   {
      bounds        = [self bounds];
      localClipRect = CGRectApplyAffineTransform( bounds, *localTransform);

      nvgIntersectScissor( vg, localClipRect.origin.x,
                               localClipRect.origin.y,
                               localClipRect.size.width,
                               localClipRect.size.height);
   }
   nvgGlobalAlpha( vg, alpha);
   return( vg);
}

- (BOOL) hasAnimations
{
   return( _mulle_pointerarray_get_count( &_animations) != 0);
}

- (void) renderInContext:(CGContext *) context
{
   CGAffineTransform   localTransform;
   CGFloat             alpha;
   CGPoint             scale;
   CGRect              bounds;
   NVGcontext          *vg;

   assert( context);

   bounds = [self bounds];
#ifdef RENDER_DEBUG
   fprintf( stderr, "%s %s (f:%s b:%s)\n",
                        __PRETTY_FUNCTION__,
                        [self cStringDescription],
                        CGRectCStringDescription( _frame),
                        CGRectCStringDescription( bounds));
#endif

   if( _hidden == YES)
      return;

   //
   // if any dimension is zero size, nothing gets painted anyway...
   //
   localTransform = MulleAffineTransformMakeProjection( _frame, bounds);
   alpha           = _opacity * _alpha;
   vg              = [self setupContext:context
                         localTransform:&localTransform
                                  alpha:alpha];
   if( ! vg)
      return;

   if( ! MulleAlphaIsTransparent( CGColorGetAlpha( _backgroundColor) * alpha))
      [self drawBackgroundInContext:context];

   // bounds are dynamically calculated, if there is nothing to snip from
   // what does it mean ?
   if( bounds.size.width != 0.0 && bounds.size.height != 0.0)
   {
      // now do the frame/bounds transform on top of it. It can't be part of
      // _transform as the values are animatable and the _transform may not be
      // set again until the next layout, which hopefully doesn't run every
      // frame
      nvgTransform( vg, localTransform.a,
                        localTransform.b,
                        localTransform.c,
                        localTransform.d,
                        localTransform.tx,
                        localTransform.ty);

      // Now we have the transform set up for the draw into "global" space
      // we don't have a scissor yet though
      // if( _masksToBounds)
      //    nvgIntersectScissor( vg, bounds.origin.x,
      //                             bounds.origin.y,
      //                             bounds.size.width,
      //                             bounds.size.height);

      // implementers should restore scissor/transform changes themselves
      [self drawInContext:context];
   }

   //
   // we want to draw the border on top
   //
   if( ! MulleAlphaIsTransparent( CGColorGetAlpha( _borderColor) * alpha))
   {
      // just setup the context again, to recover the "frame" transform
      vg = [self setupContext:context
               localTransform:&localTransform
                        alpha:alpha];
      [self drawBorderInContext:context];
   }
}


- (CGSize) sizeThatFits:(CGSize) size
                context:(CGContext *) context
{
   return( [self canvas].size);
}


- (void) setDebugNameCString:(char *) s
{
   struct mulle_allocator  *allocator;

   allocator = MulleObjCInstanceGetAllocator( self);
   if( s)
      s = mulle_allocator_strdup( allocator, s);

   mulle_allocator_free( allocator, _debugNameCString);
   _debugNameCString = s;
}


- (char *) cStringDescription
{
   char        *result;
   char        *s;
   auto char   buf[ 64];
   size_t      len;
   char        *format;

   s = class_getName( object_getClass( self));
   sprintf( buf, "%p",  self);

   format = "<%s %s>";
   len    = _debugNameCString ? strlen( _debugNameCString) : 0;
   if( len)
   {
      format = "<%s %s \"%s\">";
      len   += 3; // < "">\0"
   }
   len    += strlen( s) + strlen( buf) + 4; // < "">\0"
   result  = mulle_malloc( len);
   sprintf( result, format, s, buf, _debugNameCString);
   MulleObjCAutoreleaseAllocation( result, NULL);

   return( result);
}

@end

