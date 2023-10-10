// prefer a local CALayer over one in import.h
#ifdef __has_include
# if __has_include( "CALayer.h")
#  import "CALayer.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"


@interface CALayer( MulleGraphics) < CGRenderObject>

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
// CALayerExecuteDrawCallback, so that your code can be patched out from C:
//
// if( ! CALayerExecuteDrawCallback( self, context))
//    return( NO);
//
- (BOOL) drawInContext:(CGContext *) context;

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

static inline BOOL   CALayerExecuteDrawCallback( CALayer *self,
                                                 CGContext *context)
{
   if( ! self)
      return( NO);
   return( ((struct { @defs( CALayer); } *) self)->_drawCallback
           ? (*((struct { @defs( CALayer); } *) self)->_drawCallback)( self, context)
           : YES);
}

