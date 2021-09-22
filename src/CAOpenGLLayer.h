#ifdef __has_include
# if __has_include( "CALayer.h")
#  import "CALayer.h"
# endif
#endif

#import "import.h"


@interface CAOpenGLLayer : CALayer
{
   CGRect   _viewPort;
   CGRect   _scissor;
}

// setup viewport and scissor
- (void) beginOpenGLWithContext:(CGContext *) context;

// actual openGL drawing
- (void) drawOpenGLWithContext:(CGContext *) context;
// this flushes
- (void) endOpenGLWithContext:(CGContext *) context;

@end 
