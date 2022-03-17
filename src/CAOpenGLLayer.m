#import "CAOpenGLLayer.h"

#import "import-private.h"

// TODO: move/marry with nanovg ?
#include <GL/gl.h>


static void  checkGLError( const char* str)
{
#ifdef DEBUG   
	GLenum err;

	err = glGetError();
	if (err != GL_NO_ERROR) {
		printf("Error %08x after %s\n", err, str);
      assert( err == GL_NO_ERROR);
		return;
	}
#endif   
}


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

   glBegin( GL_TRIANGLES );
      glColor3f( 0.0f, 0.9f, 0.0f ); // green color
      glVertex3f( -0.9f, -0.9f, 0.0f );

      glColor3f( 0.9f, 0.0f, 0.0f ); // red color
      glVertex3f( 0.0f, 0.9f, 0.0f );

      glColor3f( 0.0f, 0.0f, 0.9f ); // blue color
      glVertex3f( 0.9f, -0.9f, 0.0f );
   glEnd();

   checkGLError( "after draw triangle");
}

//
// using the viewport is simpler than using glTranslate and glScale calls
// but we obstruct the future use of rotations. Sill it is kind of the simplest
// way to do this 
//
- (void) beginOpenGLWithContext:(CGContext *) context
{
   glViewport( (int) _viewPort.origin.x, 
               (int) _viewPort.origin.y, 
               (int) _viewPort.size.width, 
               (int) _viewPort.size.height);
   checkGLError( "after glViewport");

   glEnable( GL_SCISSOR_TEST);
   glScissor( (int) _scissor.origin.x, 
              (int) _scissor.origin.y, 
              (int) _scissor.size.width, 
              (int) _scissor.size.height);

   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();
   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();
}


- (void) endOpenGLWithContext:(CGContext *) context
{
   glDisable( GL_SCISSOR_TEST); //hmm..
   glFlush();   
   checkGLError( "after glFlush");
}


- (void) drawInContext:(CGContext *) context
{
   CGRect        bounds;
   CGRect        viewPort;
   CGRect        scissor;
   CGFrameInfo   *info;

   // flush current draw state, so that it appears beneath the OpenGL
   // drawing
   checkGLError( "-[CAOpenGLLayer drawInContext:] before suspendRender");
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

   checkGLError( "-[CAOpenGLLayer drawInContext:] before beginOpenGLWithContext:");
   [self beginOpenGLWithContext:context];
   checkGLError( "-[CAOpenGLLayer drawInContext:] before drawOpenGLWithContext:");
   [self drawOpenGLWithContext:context];
   checkGLError( "-[CAOpenGLLayer drawInContext:] before endOpenGLWithContext:");
   [self endOpenGLWithContext:context];
   checkGLError( "-[CAOpenGLLayer drawInContext:] before resumeRender:");

   [context resumeRender];
   checkGLError( "-[CAOpenGLLayer drawInContext:] after suspendRender");
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
