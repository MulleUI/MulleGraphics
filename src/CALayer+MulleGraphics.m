#import "CALayer+MulleGraphics.h"

#import "import-private.h"



@implementation CALayer ( MulleGraphics)


- (void) fillBackgroundInContext:(CGContext *) context
                           color:(CGColor) color
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

   vg = CGContextGetNVGContext( context);

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
   if( CGAlphaIsTransparent( alpha))
      return( NULL);

   if( _frame.size.width == 0.0 || _frame.size.height == 0.0)
      return( NULL);

   vg = CGContextGetNVGContext( context);

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
                        [self UTF8String],
                        CGRectUTF8String( _frame),
                        CGRectUTF8String( bounds));
#endif

   if( _hidden == YES)
      return;

   //
   // if any dimension is zero size, nothing gets painted anyway...
   //
   localTransform = CGAffineTransformMakeProjection( _frame, bounds);
   alpha           = _opacity * _alpha;
   vg              = [self setupContext:context
                         localTransform:&localTransform
                                  alpha:alpha];
   if( ! vg)
      return;

   // TODO: should we use context alpha here ?
   if( ! CGAlphaIsTransparent( CGColorGetAlpha( _backgroundColor) * alpha))
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
   if( ! CGAlphaIsTransparent( CGColorGetAlpha( _borderColor) * alpha))
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

@end
