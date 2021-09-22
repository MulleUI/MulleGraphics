#import "CAOpenGLLayer.h"

#import "import-private.h"

// TODO: move/marry with nanovg ?
#include <GL/gl.h>

@implementation CAOpenGLLayer 

// our OpenGL canvas is this, not used currently though
- (CGRect) canvas
{
   return( CGRectMake( -1.0, 1.0, 2.0, -2.0));
}


// default draw implementation
- (void) drawOpenGLWithContext:(CGContext *) context
{
   CGRect   canvas;

   glColor3f( 1.0f, 1.0f, 0.0f ); // yellow color

   glLineWidth( 3.0);
   glBegin( GL_LINE_LOOP );
      glVertex3f( -1.0f, 0.0f, 0.0f );
      glVertex3f( 0.0f, -1.0f, 0.0f );
      glVertex3f( 1.0f, 0.0f, 0.0f );
      glVertex3f( 0.0f, 1.0f, 0.0f );
   glEnd();
}


////
//// this doesn't use viewport, not decided yet if useful later on.
//// Teapot doesn't appear correctly though (probably because it resets 
//// matrix)
////
//- (void) xxxbeginOpenGLWithContext:(CGContext *) context
//{
//   CGRect              rect;
//   CGAffineTransform   localTransform;
//   CGFrameInfo         *info;
//   CGPoint             t;
//   CGPoint             s;
//   CGRect              frame;
//   CGRect              scissor;
//
//   // set up transform for OpenGL (again, because nanovg doesn't use OpenGL
//   // transforms. OpenGL draws to the whole screen. We use translate and scale
//   // to place this into our layer. A problem is, that this doesn't scale 
//   // things like linewidth so or does it ?
//   //
//   info  = [context currentFrameInfo];
//   frame = [self frame];
//
//   // we move the drawing to 0/0 
//   t.x  = -1.0;
//   t.y  = 1.0;
////   t.x += (_transform.tx + (frame.size.width / 2.0)) / (info->framebufferSize.width * 2.0);
////   t.y -= (_transform.ty + (frame.size.height / 2.0)) / (info->framebufferSize.height * 2.0);
//
//   glTranslatef( t.x, t.y, 0.0f);
//
//   // scale so it fits layer
//   s.x = frame.size.width / info->framebufferSize.width;
//   s.y = frame.size.height / info->framebufferSize.height;
//
//   glScalef( s.x, s.y, 1.0f);
//
//   // translate center point to our centerpoint
//   t.x = (_transform.tx + (frame.size.width / 2.0)) / (frame.size.width / 2.0);
//   t.y = -(_transform.ty + (frame.size.height / 2.0)) / (frame.size.height / 2.0);
//
//   glTranslatef( t.x, t.y, 0.0f);
//
//   glEnable( GL_SCISSOR_TEST);
//   scissor          = [self clipRect]; // already in screen coordinates
//   scissor.origin.y = info->framebufferSize.height - scissor.size.height - scissor.origin.y;
//   scissor          = CGRectIntegral( scissor);
//   glScissor( (int) scissor.origin.x, 
//              (int) scissor.origin.y, 
//              (int) scissor.size.width, 
//              (int) scissor.size.height);
//
//}
//
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

   glEnable( GL_SCISSOR_TEST);
   glScissor( (int) _scissor.origin.x, 
              (int) _scissor.origin.y, 
              (int) _scissor.size.width, 
              (int) _scissor.size.height);
}

- (void) endOpenGLWithContext:(CGContext *) context
{
   glFlush();   
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
   _viewPort.origin.y = info->framebufferSize.height - _viewPort.size.height - _viewPort.origin.y;
   _viewPort          = CGRectIntegral( _viewPort);

   _scissor          = [self clipRect]; // already in screen coordinates
   _scissor.origin.y = info->framebufferSize.height - _scissor.size.height - _scissor.origin.y;
   _scissor          = CGRectIntegral( _scissor);

   [self beginOpenGLWithContext:context];
   [self drawOpenGLWithContext:context];
   [self endOpenGLWithContext:context];

   [context resumeRender];
}

@end 
