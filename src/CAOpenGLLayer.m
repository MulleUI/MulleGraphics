#import "CAOpenGLLayer.h"

#import "import-private.h"

// TODO: move/marry with nanovg ?
#include <GL/gl.h>
#import "CALayer+MulleGraphics.h"


@implementation CAOpenGLLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   [super initWithFrame:frame];

   // this is not really used
   [self setCanvas:CGRectMake( -1.0, 1.0, 2.0, -2.0)];

   return( self);
}


// default draw implementation
- (void) drawOpenGLInContext:(CGContext *) context
{
   if( UIGraphicsBackendSupportsDeprecatedOpenGL( [context backend]))
   {
      glBegin( GL_TRIANGLES);
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
// no worky in GLES
//   CGContextCheckBackendError( context, "before glPushAttrib");
//   glPushAttrib( GL_COLOR_BUFFER_BIT);
//   CGContextCheckBackendError( context, "after glPushAttrib");

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

   if( UIGraphicsBackendSupportsDeprecatedOpenGL( [context backend]))
   {
      // GL_INVALID_OPERATION is generated if glMatrixMode is executed between
      // the execution of glBegin and the corresponding execution of glEnd.
      glMatrixMode( GL_MODELVIEW);
      CGContextCheckBackendError( context, "after glMatrixMode GL_MODELVIEW");
      glLoadIdentity();
      CGContextCheckBackendError( context, "after glLoadIdentity GL_MODELVIEW");

      glMatrixMode( GL_PROJECTION);
      CGContextCheckBackendError( context, "after glMatrixMode GL_PROJECTION");
      glLoadIdentity();
      CGContextCheckBackendError( context, "after glLoadIdentity GL_PROJECTION");
   }
}


- (void) drawNonOpenGLInContext:(CGContext *) context
{
   NVGcontext   *vg;
   CGRect       canvas;

   vg     = CGContextGetNVGContext( context);

   // our "canvas" is kinda weird
   canvas = CGRectMakeWithOriginAndSize( CGPointZero, [self frame].size);
   mvgFillRectWithColor( vg, canvas, CGColorMakeDarkGray());
   mvgTextColor( vg, CGColorMakeWhite());
   mvgTextBackgroundColor( vg, CGColorMakeDarkGray());
   mvgClearType( vg, 1);

   [context useDefaultFont];
   mvgFontSize( vg, 16.0);
   mvgTextInRect( vg, "No compatible GL version available",
                      (size_t) -1,
                      canvas,
                      CGContentModeCenterPoint,
                      0);
}


- (void) endOpenGLWithContext:(CGContext *) context
{
   CGContextCheckBackendError( context, "before glFlush");
   glFlush();
   CGContextCheckBackendError( context, "after glFlush");

   // needed otherwise, we get funky clippings in nvg
   glDisable( GL_SCISSOR_TEST);
//   glPopAttrib();
//   CGContextCheckBackendError( context, "after glPopAttrib");
}


- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha
{
   //
   // we always draw a background even if its clear color
   // otherwise textured elements don't show up. Stencil
   // buffer ?
   //
   return( YES);
}


- (BOOL) drawInContext:(CGContext *) context
{
   CGRect        bounds;
   CGFrameInfo   *info;

   if( ! [super drawInContext:context])
      return( NO);

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

   if( ! UIGraphicsBackendSupportsOpenGL( [context backend]))
   {
      [self drawNonOpenGLInContext:context];
      return( YES);
   }

   // flush current draw state, so that it appears beneath the OpenGL
   // drawing
   [context suspendRender];
   {
      CGContextCheckBackendError( context, "-[CAOpenGLLayer drawInContext:] before beginOpenGLWithContext:");
      [self beginOpenGLWithContext:context];
      CGContextCheckBackendError( context, "There were OpenGL errors in beginOpenGLWithContext. Is the OpenGL version compatible with your code?");

      if( ! CGRectEqualToRect( _viewPort, _previousViewPort))
      {
         [self viewPortDidChange:context];
         _previousViewPort = _viewPort;
      }

      [self drawOpenGLInContext:context];
      CGContextCheckBackendError( context, "There were OpenGL errors in drawOpenGLInContext. Is the OpenGL version compatible with your code?");
      [self endOpenGLWithContext:context];
      CGContextCheckBackendError( context, "There were OpenGL errors in endOpenGLWithContext. Is the OpenGL version compatible with your code?");
   }
   [context resumeRender];

   return( YES);
}


- (CGRect) viewPort
{
   return( _viewPort);
}


- (CGRect) scissor
{
   return( _scissor);
}


- (void) viewPortDidChange:(CGContext *) context
{
   if( _viewPortDidChangeCallback)
      (*_viewPortDidChangeCallback)( self, context);
}

@end
