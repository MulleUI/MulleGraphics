#ifdef __has_include
# if __has_include( "CALayer.h")
#  import "CALayer.h"
# endif
#endif

#import "import.h"

@class CAOpenGLLayer;


typedef void   CAOpenGLLayerViewPortCallback_t( CAOpenGLLayer *layer, CGContext *context);

@interface CAOpenGLLayer : CALayer
{
   CGRect   _viewPort;
   CGRect   _scissor;
@private
   CGRect   _previousViewPort;
}

@property( assign) CAOpenGLLayerViewPortCallback_t  *viewPortDidChangeCallback;

// setup viewport and scissor
- (void) beginOpenGLWithContext:(CGContext *) context;


// will always return YES for proper texture mapping(sic!)
- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha;

// actual openGL drawing. if you are doing texture mapping the background
// needs to be cleared, otherwise the stencil buffer
- (void) drawOpenGLInContext:(CGContext *) context;
// this flushes
- (void) endOpenGLWithContext:(CGContext *) context;

- (CGRect) viewPort;
- (CGRect) scissor;

// call callback, if you didn't override it
// this is called from beginOpenGLWithContext, when the viewport and
// scissor as well as the projections have been set up
- (void) viewPortDidChange:(CGContext *) context;

@end 
