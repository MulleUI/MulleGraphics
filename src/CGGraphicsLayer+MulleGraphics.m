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
   CGContextFillRoundedRectVaryingWithPaintable( context, rect, _cornerInsets, paint);
   CGContextShapeAntiAlias( context, 1);
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

   CGContextStrokeRoundedRectVaryingWithPaintable( context, rect, _cornerInsets, _borderWidth, _borderPaint);
   CGContextStrokeWidth( context, 1.0);  // need to reset
}



- (void) willDrawInContext:(CGContext *) context
{
}


- (void) didDrawInContext:(CGContext *) context
{
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
   4) The background and the border are not rotated or scaled.
 */
- (void) renderInContext:(CGContext *) context
{
   CGFloat             alpha;
   CGRect              bounds;
   CGRect              canvas;
   CGPoint             center;
   CGVector            scale;
   CGAffineTransform   originTransform;
   CGAffineTransform   boundsTransform;
   CGAffineTransform   rotationTransform;
   CGAffineTransform   scaleTransform;
   unsigned int        drawBits;

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


   bounds   = [self bounds];
   //
   // Figure out what we want to draw, so we don't need to save and restore
   // graphics state willy nilly. This is a central method and so why not.
   //
   drawBits  = [self drawsBackgroundWithAlpha:alpha] ? 0x1 : 0;
   drawBits |= ( bounds.size.width != 0.0 && bounds.size.height != 0.0) ? 0x2 : 0;
   drawBits |= (_borderWidth >= 0.1 && ! CGAlphaIsTransparent( [_borderPaint alpha] * alpha)) ? 0x4 : 0;
   if( ! drawBits)
      return;

   // once for sure
   [self setupContext:context
            transform:&_transform
                alpha:alpha];

   // this draws with _frame coordinates w/o bounds and rotation
   if( drawBits & 0x1)
   {
      if( drawBits & (0x2|0x4))
         CGContextSave( context);

      [self drawBackgroundInContext:context];
   }

   //
   // bounds are dynamically calculated.
   // we still draw border and background, even if the content is zoomed to nil
   //
   if( drawBits & 0x2)
   {
      if( drawBits & 0x1)
         CGContextRestore( context);
      if( drawBits & 0x4)
         CGContextSave( context);

      originTransform = CGAffineTransformMakeTranslationInline( _frame.origin);
      boundsTransform = CGAffineTransformMakeTranslationInline( CGPointNegate( bounds.origin));
      scale           = CGVectorMake( _frame.size.width / bounds.size.width,
                                      _frame.size.height / bounds.size.height);
      scaleTransform  = CGAffineTransformMakeScaleInline( scale);

      boundsTransform = CGAffineTransformConcatInline( originTransform, boundsTransform);
      boundsTransform = CGAffineTransformConcatInline( boundsTransform, scaleTransform);
      CGContextTransform( context, &boundsTransform);

      if( _masksToBounds)
         CGContextIntersectScissor( context, bounds);

      if( _rotation != 0.0)
      {
         canvas            = [self canvas];
         center            = CGRectGetCenterWithAnchorPoint( canvas, _anchorPoint);
         rotationTransform = CGAffineTransformMakeRotationAroundPoint( center, _rotation);
         CGContextTransform( context, &rotationTransform);
      }

      [self willDrawInContext:context];
      [self drawInContext:context];
      [self didDrawInContext:context];
   }

   // this draws with _frame coordinates w/o bounds and rotation again like
   // background
   if( drawBits & 0x4)
   {
      // "just" setup the context again, to recover the "frame" transform
      // we dont want frame/bounds messing with the border width
      // Second setupContext inline
      if( drawBits & (0x1|0x2))
         CGContextRestore( context);

      [self drawBorderInContext:context];
   }
}


- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context
{
   return( [self canvas].size);
}


@end
