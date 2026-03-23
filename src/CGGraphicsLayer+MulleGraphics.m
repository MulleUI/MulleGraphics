#import "CGGraphicsLayer+MulleGraphics.h"

#import "import-private.h"

#define USE_SCISSOR

@implementation CGGraphicsLayer ( MulleGraphics)

- (void) fillBackgroundInContext:(CGContext *) context
                           paint:(CGPaint *) paint
{
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

   // calc border out from fill, but don't draw
   borderWidth = [self borderWidth];
   if( borderWidth >= 0.1)
   {
      insets = MulleEdgeInsetsMake( borderWidth / 2,
                                    borderWidth / 2,
                                    borderWidth / 2,
                                    borderWidth / 2);
      rect  = MulleEdgeInsetsInsetRect( insets, rect);
      CGContextShapeAntiAlias( context, 0);
   }

   // fill
   CGContextFillRoundedRectVaryingWithPaintable( context, rect,
                                                          _cornerInsets,
                                                          paint);
   CGContextShapeAntiAlias( context, 1);
}


- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha
{
   CGFloat   bgAlpha;

   bgAlpha = [_backgroundPaint alpha];
   return( ! CGAlphaIsTransparent( bgAlpha * alpha));
}


- (void) drawBackgroundInContext:(CGContext *) context
{
   [self fillBackgroundInContext:context
                           paint:_backgroundPaint];
}



- (BOOL) drawsBorderWithAlpha:(CGFloat) alpha
{
   CGFloat   borderAlpha;

   if( _borderWidth < 0.1)
      return( NO);

   borderAlpha = [_borderPaint alpha];
   return( ! CGAlphaIsTransparent( borderAlpha * alpha));
}

//
// the border is not extending outside of the layer
// this would break too much stuff, if we need a highlight, either but
// a highlighter view below or use insets and leave space around
//
- (void) drawBorderInContext:(CGContext *) context
{
   CGFloat   halfBorderWidth;
   CGPoint   tl;
   CGPoint   br;
   CGRect    rect;

   //
   // the strokeWidth isn't scaled in nvg, so we do this now ourselves
   //
   assert( _borderWidth >= 0.1);

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

   //
   // the _cornerRadius is computed for a stroke of width 1 (or 0 ?)
   // the strokeWidth is just scaling it out
   //
   rect = CGRectMake( tl.x, tl.y, br.x - tl.x, br.y - tl.y);

   CGContextStrokeRoundedRectVaryingWithPaintable( context, rect,
                                                            _cornerInsets,
                                                            _borderWidth,
                                                            _borderPaint);
   // CGContextStrokeWidth( context, 1.0);  // need to reset ? why ?
}




//static char  *currentTransformUTF8String( CGContext *context)
//{
//   CGAffineTransform   transform;
//   char                *s;
//
//   transform = CGContextCurrentTransform( context);
//   s         = CGAffineTransformUTF8String( &transform);
//   return( s);
//}



- (void) setupContext:(CGContext *) context
            transform:(CGAffineTransform *) xform
                alpha:(CGFloat) alpha
{
   //
   // reset from previous CGGraphicsLayer having done renderInContext:
   //
   CGContextReset( context);
   CGContextGlobalAlpha( context, alpha);

   // set UIView clipping rect in "framebuffer" space
#ifdef USE_SCISSOR
   if( _clipRect.size.width != INFINITY)
      CGContextScissor( context, _clipRect);
#endif

   //
   // Apply our "origin" transform to get the basic drawing in the right
   // position
   //
   CGContextTransform( context, xform);
}



void  CGGraphicsLayerSetupDrawTransform( CGGraphicsLayer *self,
                                         CGContext *context,
                                         CGRect bounds)
{
   union // a union for fun
   {
      CGAffineTransform   bounds;
      CGAffineTransform   origin;
      CGAffineTransform   rotation;
   } transform;
   CGRect              canvas;

   bounds = [self bounds];
   if( ! CGSizeEqualToSize( self->_frame.size, bounds.size) ||
       ! CGPointEqualToPoint( bounds.origin, CGPointZero))
   {
      transform.bounds = CGGraphicsLayerMakeBoundsTransform( self->_frame, bounds);
      CGContextTransform( context, &transform.bounds);
   }
   else
   {
      transform.origin = CGAffineTransformMakeTranslationInline( self->_frame.origin);
      CGContextTransform( context, &transform.origin);
   }

   if( self->_rotation != 0.0)
   {
      canvas             = [self canvas];
      transform.rotation = CGGraphicsLayerMakeRotationTransform( canvas,
                                                                self->_anchorPoint,
                                                                self->_rotation);
      CGContextTransform( context, &transform.rotation);
   }
}


- (BOOL) willDrawInContext:(CGContext *) context
{
   CGRect   bounds;

   bounds = [self bounds];
   if( bounds.size.width == 0.0 || bounds.size.height == 0.0)
      return( NO);

   CGGraphicsLayerSetupDrawTransform( self, context, bounds);
#ifdef USE_SCISSOR
   if( _masksToBounds)
      CGContextIntersectScissor( context, bounds);
#endif
   return( YES);
}


- (BOOL) drawInContext:(CGContext *) context
{
   return( CGGraphicsLayerExecuteDrawCallback( self, context));
}


- (void) didDrawInContext:(CGContext *) context
{
}



/* So here is a little essay on what is what. A CGGraphicsLayer is supposed
   to be setup by the UIView so it is ready to be rendered on the UIWindow
   framebuffer. There is conceptually no transformation we are inheriting from
   a context. The layers _transform will have been setup for the accumulated
   transformation by the UIView hierarchy.

   What our local transform is doing is applying the frame.origin as a
   translation and the frame vs bounds as another scale and translation step.

   Finally the drawing is rotated with _rotation.

   The clipRect is the clipping rectangle of the view, its in the _transform
   space.

   So points to remember:

   1) The layer frame, bounds.size / frame.size and bounds.origin are all
      handled in a local transform.
   2) The UIView translation and scalings are in _transform
   3) The drawInContext: draws into canvas. The rotation rotates around
      the center of the canvas (or some other place if anchorPoint is not
      0.5, 0.5).
   4) The background and the border are not rotated or scaled. They render
      the frame, not the canvas.
 */
- (void) renderInContext:(CGContext *) context
{
   CGFloat   alpha;
   BOOL      isDrawing;
   FILE      *oldtrace;

   assert( context);

#if defined( RENDER_DEBUG)
   mulle_fprintf( stderr, "%s %s (f:%s b:%s a: %s)\n",
                        __PRETTY_FUNCTION__,
                        [self UTF8String],
                        CGRectUTF8String( _frame),
                        CGRectUTF8String( [self bounds]),
                        CGPointUTF8String( _anchorPoint));
#endif

   if( _hidden == YES)
      return;

   alpha = _opacity * _alpha;
   // this is the "inherited" alpha from UIVIew
   // cull layers which are invisible
   if( CGAlphaIsTransparent( alpha))
      return;

   //
   // if any dimension is zero size (or very close) nothing gets painted
   // anyway...
   //
   if( _frame.size.width < 0.1 || _frame.size.height < 0.1)
      return;

   //
   // MEMO: unfortunately we have to reset the context quite a bit, because
   // drawing code is free to use nvgBeginFrame for its own nefarious purposes
   // but that will waste the save/restore stack, so we need to run from a
   // clean slate for background, then content, and then border
   //

   oldtrace = [context setTraceFile:_drawCallTracer];

   // this draws with _frame coordinates w/o bounds and rotation
   if( [self drawsBackgroundWithAlpha:alpha])
   {
      [self setupContext:context
               transform:&_transform
                   alpha:alpha];
      [self drawBackgroundInContext:context];
   }

   //
   // bounds are dynamically calculated.
   // we still draw border and background, even if the content is zoomed to nil
   //
   [self setupContext:context
            transform:&_transform
                alpha:alpha];

   isDrawing = [self willDrawInContext:context];
   if( isDrawing)
   {
      [self drawInContext:context];
      [self didDrawInContext:context];
   }

   if( [self drawsBorderWithAlpha:alpha])
   {
      // need to reset ?
      if( isDrawing)
         [self setupContext:context
                  transform:&_transform
                      alpha:alpha];
      [self drawBorderInContext:context];
   }

   [context setTraceFile:oldtrace];
}


- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context
{
   if( _layouter)
      return( [_layouter layer:self
                  sizeThatFits:size
                       context:context]);
   return( [self canvas].size);
}


@end
