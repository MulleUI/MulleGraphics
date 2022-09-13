#import "CAOpenGLLayer.h"

#import "import-private.h"

// TODO: move/marry with nanovg ?
#include <GL/gl.h>


@implementation CAOpenGLLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   [super initWithFrame:frame];

   // this is not really used
   [self setCanvas:CGRectMake( -1.0, 1.0, 2.0, -2.0)];

   return( self);
}

//
// we always draw a background even if its clear color
// otherwise textured elements dont't show up. Stencil
// buffer ?
//
- (BOOL) drawsBackground
{
   return( YES);
}


// default draw implementation
- (void) drawOpenGLWithContext:(CGContext *) context
{
   CGRect   canvas;

   if( UIGraphicsBackendSupportsDeprecatedOpenGL( [context backend]))
   {
      glBegin( GL_TRIANGLES );
         glColor3f( 0.0f, 0.9f, 0.0f ); // green color
         glVertex3f( -0.9f, -0.9f, 0.0f );
 
         glColor3f( 0.9f, 0.0f, 0.0f ); // red color
         glVertex3f( 0.0f, 0.9f, 0.0f );
 
         glColor3f( 0.0f, 0.0f, 0.9f ); // blue color
         glVertex3f( 0.9f, -0.9f, 0.0f );
      glEnd();
      CGContextCheckBackendError( context, "after draw triangle");
   }
}

//
// using the viewport is simpler than using glTranslate and glScale calls
// but we obstruct the future use of rotations. Sill it is kind of the simplest
// way to do this
//
- (void) beginOpenGLWithContext:(CGContext *) context
{
   if( UIGraphicsBackendSupportsOpenGLES( [context backend]))
   {
      glViewport( (int) _viewPort.origin.x,
                  (int) _viewPort.origin.y,
                  (int) _viewPort.size.width,
                  (int) _viewPort.size.height);
      CGContextCheckBackendError( context, "after glViewport");

      glEnable( GL_SCISSOR_TEST);
      CGContextCheckBackendError( context, "after glEnable( GL_SCISSOR_TEST)");

      glScissor( (int) _scissor.origin.x,
                 (int) _scissor.origin.y,
                 (int) _scissor.size.width,
                 (int) _scissor.size.height);
      CGContextCheckBackendError( context, "after glScissor");

      glMatrixMode(GL_PROJECTION);
      glLoadIdentity();
      glMatrixMode(GL_MODELVIEW);
      glLoadIdentity();
      CGContextCheckBackendError( context, "after glLoadIdentity");
   }
 }


- (void) endOpenGLWithContext:(CGContext *) context
{
   if( UIGraphicsBackendSupportsOpenGLES( [context backend]))
   {
      glDisable( GL_SCISSOR_TEST); //hmm..
      CGContextCheckBackendError( context, "after glDisable( GL_SCISSOR_TEST)");
      glFlush();
      CGContextCheckBackendError( context, "after glFlush");
   }
}


- (void) drawInContext:(CGContext *) context
{
   CGRect        bounds;
   CGRect        viewPort;
   CGRect        scissor;
   CGFrameInfo   *info;

   // flush current draw state, so that it appears beneath the OpenGL
   // drawing
   [context suspendRender];

   // set up transform for OpenGL (again, because nanovg doesn't use OpenGL
   // transforms. OpenGL draws to the whole screen. We use translate and scale
   // to place this into our layer. A problem is, that this doesn't scale
   // things like linewidth so or does it ?
   //
   info      = [context currentFrameInfo];
   bounds    = [self bounds];
   _viewPort = CGRectApplyAffineTransform( bounds, _transform);

   // 1. need position on screen
   // 2. transform already has this, tx and ty are easy to extract
   // 3. how to get width and frame (use bounds.size!)
   // 4. simplest way, apply current transform to bounds

   // flip for OpenGL, remember y is on the bottom!
   // as OpenGL view/scissor is integer based use CGRectIntegral..
   //
   _viewPort.origin.y = info->window.framebufferSize.height - _viewPort.size.height - _viewPort.origin.y;
   _viewPort          = CGRectIntegral( _viewPort);

   _scissor          = [self clipRect]; // already in screen coordinates
   _scissor.origin.y = info->window.framebufferSize.height - _scissor.size.height - _scissor.origin.y;
   _scissor          = CGRectIntegral( _scissor);

   CGContextCheckBackendError( context, "-[CAOpenGLLayer drawInContext:] before beginOpenGLWithContext:");
   [self beginOpenGLWithContext:context];
   CGContextCheckBackendError( context, "There were OpenGL errors in beginOpenGLWithContext. Is the OpenGL version compatible with your code?");
   [self drawOpenGLWithContext:context];
   CGContextCheckBackendError( context, "There were OpenGL errors in drawOpenGLWithContext. Is the OpenGL version compatible with your code?");
   [self endOpenGLWithContext:context];
   CGContextCheckBackendError( context, "There were OpenGL errors in endOpenGLWithContext. Is the OpenGL version compatible with your code?");

   [context resumeRender];
}

- (CGRect) viewPort
{
   return( _viewPort);
}

- (CGRect) scissor
{
   return( _scissor);
}

@end
