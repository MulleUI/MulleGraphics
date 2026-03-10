// prefer a local CALayer over one in import.h
#ifdef __has_include
# if __has_include( "CGGraphicsLayer.h")
#  import "CGGraphicsLayer.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@interface CGGraphicsLayer( MulleGraphics) < CGRenderObject>

//
// renderInContext resets the drawing context with transform and global alpha
// then calls (in this order):
//
//    -drawBackgroundInContext:  // will not be called if backgroundColor * opacity * alpha is transparent
//    [CGContext saveState];     // or similiar :)
//    -drawInContext:            // if bounds.size != zero
//    [CGContext restoreState];  // or similiar :)
//    -drawBorderInContext:      // will not be called if borderColor * opacity * alpha is transparent
//
// If you do drawing afterwards, its best to nvgReset( vg); If you are
// calling this from your own drawCallBack() then wrap it in nvgSave()
// nvgRestore()
//
- (void) renderInContext:(CGContext *) ctx;

//
// Subclasses do their drawing in -drawInContext. The default implementation
// calls the drawCallback if one is set, otherwise it does nothing.
//
// This method should draw "canvas". The transformation has been setup for
// frame/bounds projection already by renderInContext:
//
// The drawing context will have been saved before
// the call and restored afterwards. You may assume the state is setup
// as if nvgReset() has been called with the following exceptions:
//
// fillColor is random
// strokeColor is random
// transform is setup already
// alpha is setup already
//
// if [super drawInContext:] returns NO, do not continue drawing
//
// if you don't want do call [super drawInContext:], you should call
// CGGraphicsLayerExecuteDrawCallback, so that your code can be patched out
// from C:
//
// if( ! CGGraphicsLayerExecuteDrawCallback( self, context))
//    return( NO);
//
- (BOOL) drawInContext:(CGContext *) context;


// immediately called before and after drawInContext
// return YES, to draw. call super in willDrawInContext to setup the
// proper transforms
- (BOOL) willDrawInContext:(CGContext *) context;
- (void) didDrawInContext:(CGContext *) context;

//
// these two methods draw "frame". Bounds and canvas are to be ignored.
// therefore a border doesn't scale with bounds!
//
// Ensure that the drawing context remains unchanged except for
// fillColor and strokeColor.
//

// default impl. says NO, if alpha time background color alpha is transparent
- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha;

- (void) drawBackgroundInContext:(CGContext *) context;
- (void) drawBorderInContext:(CGContext *) context;

// only use this method in drawBackgroundInContext
- (void) fillBackgroundInContext:(CGContext *) context
                           paint:(CGPaint *) paint;

// Returns canvas.size. Subclasses may want to compute actual used space
// and return it. Used for layouting by UIView
- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context;

@end


MULLE_GRAPHICS_GLOBAL
void  CGGraphicsLayerSetupDrawTransform( CGGraphicsLayer *self,
                                         CGContext *context,
                                         CGRect bounds);



static inline
CGAffineTransform  CGGraphicsLayerMakeBoundsTransform( CGRect frame,
                                                       CGRect bounds)
{
   CGAffineTransform   originTransform;
   CGAffineTransform   boundsTransform;
   CGAffineTransform   scaleTransform;
   CGVector            scale;

   originTransform = CGAffineTransformMakeTranslationInline( frame.origin);
   boundsTransform = CGAffineTransformMakeTranslationInline( CGPointNegate( bounds.origin));
   scale           = CGVectorMake(frame.size.width / bounds.size.width,
                                  frame.size.height / bounds.size.height);
   scaleTransform  = CGAffineTransformMakeScaleInline( scale);

   boundsTransform = CGAffineTransformConcatInline( originTransform, boundsTransform);
   boundsTransform = CGAffineTransformConcatInline( boundsTransform, scaleTransform);
   return( boundsTransform);
}


static inline
CGAffineTransform  CGGraphicsLayerMakeRotationTransform( CGRect canvas,
                                                         CGPoint anchorPoint,
                                                         CARotation rotation)
{
   CGAffineTransform   rotationTransform;
   CGPoint             center;

   center            = CGRectGetCenterWithAnchorPoint( canvas, anchorPoint);
   rotationTransform = CGAffineTransformMakeRotationAroundPoint( center, rotation);
   return( rotationTransform);
}
