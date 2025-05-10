#import "CGGraphicsLayer+MulleGraphics.h"

#import "import-private.h"

#define USE_SCISSOR 

@implementation CGGraphicsLayer ( MulleGraphics)

- (void) fillBackgroundInContext:(CGContext *) context
                           paint:(CGPaint *) paint
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

   vg = CGContextGetNVGContext( context);

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
   mvgFillRoundedRectVaryingWithPaint( vg, rect, _cornerInsets, paint);

   nvgShapeAntiAlias( vg, 1);
}


- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha
{
   return( ! CGAlphaIsTransparent( [_backgroundPaint alpha] * alpha));
}


- (void) drawBackgroundInContext:(CGContext *) context
{
   [self fillBackgroundInContext:context
                           paint:_backgroundPaint];
}


- (BOOL) drawInContext:(CGContext *) context
{
   return( CGGraphicsLayerExecuteDrawCallback( self, context));
}


//
// the border is not extending outside of the layer
// this would break too much stuff, if we need a highlight, either but
// a highlighter view below or use insets and leave space around
//
- (void) drawBorderInContext:(CGContext *) context
{
   NVGcontext  *vg;
   CGFloat     halfBorderWidth;
   CGPoint     tl;
   CGPoint     br;
   CGRect      rect;

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

   vg = CGContextGetNVGContext( context);

   //
   // the _cornerRadius is computed for a stroke of width 1 (or 0 ?)
   // the strokeWidth is just scaling it out
   //
   rect = CGRectMake( tl.x, tl.y, br.x - tl.x, br.y - tl.y);

   mvgStrokeRoundedRectVaryingWithPaint( vg, rect, _cornerInsets, _borderWidth, _borderPaint);

//      nvgMoveTo( vg, tl.x, tl.y);
//      nvgLineTo( vg, br.x, tl.y);
//      nvgLineTo( vg, br.x, br.y);
//      nvgLineTo( vg, tl.x, br.y);
//      nvgLineTo( vg, tl.x, tl.y);

   nvgStrokeWidth( vg, 1.0);  // need to reset
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

   vg = CGContextGetNVGContext( context);

   //
   // as we reset here and set alpha global, we don't need to save state
   // since each layer will do this.
   //
   nvgReset( vg);

#ifdef USE_SCISSOR
   // these are the bounds in global screen space
   if( _clipRect.size.width != INFINITY)  // transform set by UIView during layout
      nvgScissor( vg, _clipRect.origin.x,
                      _clipRect.origin.y,
                      _clipRect.size.width,
                      _clipRect.size.height);
#endif

   // this is the "inherited" transform from UIView
   nvgTransform( vg, _transform.a,
                     _transform.b,
                     _transform.c,
                     _transform.d,
                     _transform.tx,
                     _transform.ty);

   // we are still in frame space, here so calculate the bounds scissor
   // somewhat inconveniently
#ifdef USE_SCISSOR
   if( _masksToBounds)
   {
      bounds        = [self bounds];
      localClipRect = CGRectApplyAffineTransform( bounds, *localTransform);

      nvgIntersectScissor( vg, localClipRect.origin.x,
                               localClipRect.origin.y,
                               localClipRect.size.width,
                               localClipRect.size.height);
   }
#endif
   nvgGlobalAlpha( vg, alpha);
   return( vg);
}


- (void) willDrawInContext:(CGContext *) context
{
}


- (void) didDrawInContext:(CGContext *) context
{
}


- (void) renderInContext:(CGContext *) context
{
   CGAffineTransform   localTransform;
   CGFloat             alpha;
   CGRect              bounds;
   NVGcontext          *vg;

   assert( context);

#ifdef RENDER_DEBUG
   fprintf( stderr, "%s %s (f:%s b:%s)\n",
                        __PRETTY_FUNCTION__,
                        [self UTF8String],
                        CGRectUTF8String( _frame),
                        CGRectUTF8String( [self bounds]));
#endif

   if( _hidden == YES)
      return;

   alpha = _opacity * _alpha;

   // this is the "inherited" alpha from UIVIew
   // cull layers which are invisible
   if( CGAlphaIsTransparent( alpha))
      return;

   //
   // if any dimension is zero size, nothing gets painted anyway...
   //
   if( _frame.size.width == 0.0 || _frame.size.height == 0.0)
      return;

   bounds         = [self bounds];
   localTransform = CGAffineTransformMakeProjection( _frame, bounds);

   vg  = [self setupContext:context
             localTransform:&localTransform
                      alpha:alpha];

   // TODO: should we use context alpha here ?
   if( [self drawsBackgroundWithAlpha:alpha])
      [self drawBackgroundInContext:context];

   // bounds are dynamically calculated, if there is nothing to snip from
   // what does it mean ?
   if( bounds.size.width != 0.0 && bounds.size.height != 0.0)
   {
      // now do the frame/bounds transform on top of it. It can't be part of
      // _transform as the values are animatable and the _transform may not be
      // set again until the next layout, which hopefully doesn't run every
      // frame
      // Is this true: the transform is set by the drawingQueue:
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
      [self willDrawInContext:context];
      [self drawInContext:context];
      [self didDrawInContext:context];
   }

   //
   // we want to draw the border on top
   //
   if( ! CGAlphaIsTransparent( [_borderPaint alpha] * alpha))
   {
      // "just" setup the context again, to recover the "frame" transform
      vg = [self setupContext:context
               localTransform:&localTransform
                        alpha:alpha];
      [self drawBorderInContext:context];
   }
}


- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context
{
   return( [self canvas].size);
}


@end
