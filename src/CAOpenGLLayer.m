#import "CAOpenGLLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"

#ifndef MULLE_CG_GLVERSION
# error "MULLE_CG_GLVERSION is undefined"
#endif

#if ! defined( MULLE_CG_HAVE_DEPRECATED_OPENGL) && ! defined( MULLE_CG_HAVE_MODERN_OPENGL)
# warning "Neither MULLE_CG_HAVE_DEPRECATED_OPENGL nor MULLE_CG_HAVE_MODERN_OPENGL is defined, CAOpenGLLayer will not be functional"
#endif



// so ur ""
//#ifdef __APPLE__
//# pragma clang diagnostic ignored "-W#warnings"
//# include <OpenGL/gl.h>
//#endif

@implementation CAOpenGLLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   self = [super initWithFrame:frame];

   [self setCanvas:CGRectMake( -1.0, 1.0, 2.0, -2.0)];

   return( self);
}


#ifdef MULLE_CG_HAVE_MODERN_OPENGL

- (void) finalize
{
    if( _program)
    {
        glDeleteProgram( _program);
        _program = 0;
    }

    if( _vbo)
    {
        glDeleteBuffers( 1, &_vbo);
        _vbo = 0;
    }
    [super finalize];
}


// nothing to copy, yet we need to implement this otherwise we are
// in world of pain ;)
- (id) copy
{
   return( [super copy]);
}



- (void) compileDefaultShaders
{
    GLint   success;
    GLchar  infoLog[512];

    const char *vertexShaderSource =
#if MULLE_CG_GLVERSION == MULLE_CG_GL3
      "#version 150 core\n"
      "layout (location = 0) in vec3 aPos;\n"
      "layout (location = 1) in vec3 aColor;\n"
      "out vec3 fragColor;\n"
      "void main()\n"
      "{\n"
      "    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
      "    fragColor = aColor;\n"
      "}\n";
#elif MULLE_CG_GLVERSION == MULLE_CG_GLES2
      "#version 100\n"
      "attribute vec3 aPos;\n"
      "attribute vec3 aColor;\n"
      "varying vec3 fragColor;\n"
      "void main()\n"
      "{\n"
      "    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
      "    fragColor = aColor;\n"
      "}\n";
#else // if MULLE_CG_GLVERSION == MULLE_CG_GLES3
      "#version 300 es\n"
      "layout (location = 0) in vec3 aPos;\n"
      "layout (location = 1) in vec3 aColor;\n"
      "out vec3 fragColor;\n"
      "void main()\n"
      "{\n"
      "    gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n"
      "    fragColor = aColor;\n"
      "}\n";
#endif

    const char *fragmentShaderSource =
#if MULLE_CG_GLVERSION == MULLE_CG_GL3
      "#version 150 core\n"
      "precision mediump float;\n"
      "in vec3 fragColor;\n"
      "out vec4 FragColor;\n"
      "void main()\n"
      "{\n"
      "    FragColor = vec4(fragColor, 1.0);\n"
      "}\n";
#elif MULLE_CG_GLVERSION == MULLE_CG_GLES2
      "#version 100\n"
      "precision mediump float;\n"
      "varying vec3 fragColor;\n"
      "void main()\n"
      "{\n"
      "    gl_FragColor = vec4(fragColor, 1.0);\n"
      "}\n";
#else // if MULLE_CG_GLVERSION == MULLE_CG_GLES3
      "#version 300 es\n"
      "in vec3 fragColor;\n"
      "out vec4 FragColor;\n"
      "void main()\n"
      "{\n"
      "    FragColor = vec4(fragColor, 1.0);\n"
      "}\n";
#endif

    GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource( vertexShader, 1, &vertexShaderSource, NULL);
    glCompileShader( vertexShader);
    glGetShaderiv( vertexShader, GL_COMPILE_STATUS, &success);
    if( ! success)
    {
       glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
       MulleUILog( "Vertex shader compilation failed: %s", infoLog);
    }

    GLuint fragmentShader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource( fragmentShader, 1, &fragmentShaderSource, NULL);
    glCompileShader( fragmentShader);
    glGetShaderiv( vertexShader, GL_COMPILE_STATUS, &success);
    if( ! success)
    {
       glGetShaderInfoLog(vertexShader, 512, NULL, infoLog);
       MulleUILog( "Vertex shader compilation failed: %s", infoLog);
    }

    _program = glCreateProgram();
    glAttachShader( _program, vertexShader);
    glAttachShader( _program, fragmentShader);
    glLinkProgram( _program);

    glDeleteShader( vertexShader);
    glDeleteShader( fragmentShader);
}


- (void) setupDefaultVertexData
{
    static const GLfloat vertices[] =
    {
        // positions         // colors
        -0.9f, -0.9f, 0.0f,  0.0f, 0.9f, 0.0f,
         0.0f,  0.9f, 0.0f,  0.9f, 0.0f, 0.0f,
         0.9f, -0.9f, 0.0f,  0.0f, 0.0f, 0.9f
    };

#if MULLE_CG_GLVERSION != MULLE_CG_GLES2
    glGenVertexArrays(1, &_vao);
    glBindVertexArray(_vao);
#endif

    glGenBuffers(1, &_vbo);
    glBindBuffer(GL_ARRAY_BUFFER, _vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (void*)0);
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 6 * sizeof(GLfloat), (void*)(3 * sizeof(GLfloat)));
    glEnableVertexAttribArray(1);

#if MULLE_CG_GLVERSION != MULLE_CG_GLES2
    glBindVertexArray(0);
#endif

    glBindBuffer(GL_ARRAY_BUFFER, 0);
}



#endif

// default draw implementation
- (void) drawOpenGLInContext:(CGContext *) context
{
#ifdef MULLE_CG_HAVE_DEPRECATED_OPENGL
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
   else
#endif
#ifdef MULLE_CG_HAVE_MODERN_OPENGL
   {
      if( ! _program)
      {
         [self compileDefaultShaders];
         [self setupDefaultVertexData];
      }

      glUseProgram( _program);
#if MULLE_CG_GLVERSION != MULLE_CG_GLES2
      glBindVertexArray( _vao);
#endif
      glDrawArrays(GL_TRIANGLES, 0, 3);
   }
#endif
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
#if defined( MULLE_CG_HAVE_DEPRECATED_OPENGL) || defined( MULLE_CG_HAVE_MODERN_OPENGL)
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
#endif

#if defined( MULLE_CG_HAVE_DEPRECATED_OPENGL)
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
#endif
}


- (void) drawNonOpenGLInContext:(CGContext *) context
{
   CGRect   canvas;

   // our "canvas" is kinda weird
   canvas = CGRectMakeWithOriginAndSize( CGPointZero, [self frame].size);
   CGContextFillRectWithColor( context, canvas, CGColorMakeDarkGray());
   CGContextTextColor( context, CGColorMakeWhite());
   CGContextTextBackgroundColor( context, CGColorMakeDarkGray());
   CGContextClearType( context, 1);

   [context useDefaultFont];
   CGContextFontSize( context, 16.0);
   CGContextTextInRect( context, "No compatible GL version available",
                                 (size_t) -1,
                                 canvas,
                                 CGContentModeCenterPoint,
                                 0);
}


- (void) endOpenGLWithContext:(CGContext *) context
{
#if defined( MULLE_CG_HAVE_DEPRECATED_OPENGL) || defined( MULLE_CG_HAVE_MODERN_OPENGL)

   CGContextCheckBackendError( context, "before glFlush");
   glFlush();
   CGContextCheckBackendError( context, "after glFlush");

   // needed otherwise, we get funky clippings in nvg
   glDisable( GL_SCISSOR_TEST);
#endif
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


- (void) viewPortDidChange:(CGContext *) context
{
   if( _viewPortDidChangeCallback)
      (*_viewPortDidChangeCallback)( self, context);
}

@end
