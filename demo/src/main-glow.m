#import "import-private.h"

#include <MulleCG/nanovg_gl_utils.h>


#define USE_BUFFERED_LAYER  

// lifted straight from nanovg demo:
// https://github.com/memononen/nanovg/blob/master/example/demo.c
//
void drawGraph(NVGcontext* vg, float x, float y, float w, float h, float t)
{
	NVGpaint bg;
	float samples[6];
	float sx[6], sy[6];
	float dx = w/5.0f;
	int i;

	samples[0] = (1+sinf(t*1.2345f+cosf(t*0.33457f)*0.44f))*0.5f;
	samples[1] = (1+sinf(t*0.68363f+cosf(t*1.3f)*1.55f))*0.5f;
	samples[2] = (1+sinf(t*1.1642f+cosf(t*0.33457)*1.24f))*0.5f;
	samples[3] = (1+sinf(t*0.56345f+cosf(t*1.63f)*0.14f))*0.5f;
	samples[4] = (1+sinf(t*1.6245f+cosf(t*0.254f)*0.3f))*0.5f;
	samples[5] = (1+sinf(t*0.345f+cosf(t*0.03f)*0.6f))*0.5f;

	for (i = 0; i < 6; i++) {
		sx[i] = x+i*dx;
		sy[i] = y+h*samples[i]*0.8f;
	}

	// Graph background
	bg = nvgLinearGradient(vg, x,y,x,y+h, nvgRGBA(0,160,192,0), nvgRGBA(0,160,192,64));
	nvgBeginPath(vg);
	nvgMoveTo(vg, sx[0], sy[0]);
	for (i = 1; i < 6; i++)
		nvgBezierTo(vg, sx[i-1]+dx*0.5f,sy[i-1], sx[i]-dx*0.5f,sy[i], sx[i],sy[i]);
	nvgLineTo(vg, x+w, y+h);
	nvgLineTo(vg, x, y+h);
	nvgFillPaint(vg, bg);
	nvgFill(vg);

	// Graph line
	nvgBeginPath(vg);
	nvgMoveTo(vg, sx[0], sy[0]+2);
	for (i = 1; i < 6; i++)
		nvgBezierTo(vg, sx[i-1]+dx*0.5f,sy[i-1]+2, sx[i]-dx*0.5f,sy[i]+2, sx[i],sy[i]+2);
	nvgStrokeColor(vg, nvgRGBA(0,0,0,32));
	nvgStrokeWidth(vg, 3.0f);
	nvgStroke(vg);

	nvgBeginPath(vg);
	nvgMoveTo(vg, sx[0], sy[0]);
	for (i = 1; i < 6; i++)
		nvgBezierTo(vg, sx[i-1]+dx*0.5f,sy[i-1], sx[i]-dx*0.5f,sy[i], sx[i],sy[i]);
	nvgStrokeColor(vg, nvgRGBA(0,160,192,255));
	nvgStrokeWidth(vg, 3.0f);
	nvgStroke(vg);

	// Graph sample pos
	for (i = 0; i < 6; i++) {
		bg = nvgRadialGradient(vg, sx[i],sy[i]+2, 3.0f,8.0f, nvgRGBA(0,0,0,32), nvgRGBA(0,0,0,0));
		nvgBeginPath(vg);
		nvgRect(vg, sx[i]-10, sy[i]-10+2, 20,20);
		nvgFillPaint(vg, bg);
		nvgFill(vg);
	}

	nvgBeginPath(vg);
	for (i = 0; i < 6; i++)
		nvgCircle(vg, sx[i], sy[i], 4.0f);
	nvgFillColor(vg, nvgRGBA(0,160,192,255));
	nvgFill(vg);
	nvgBeginPath(vg);
	for (i = 0; i < 6; i++)
		nvgCircle(vg, sx[i], sy[i], 2.0f);
	nvgFillColor(vg, nvgRGBA(220,220,220,255));
	nvgFill(vg);

	nvgStrokeWidth(vg, 1.0f);
}


void  drawLine( CALayer *layer, CGContext *context)
{
   CGRect         canvas;
   NVGcontext     *vg;
   double         now;
   UIEdgeInsets   insets;
   CGFloat        borderExtent;

   canvas       = [layer canvas];
   borderExtent = [layer borderWidth]; // / 2.0;
   canvas       = CGRectInset( canvas, borderExtent, borderExtent);

   vg  = CGContextGetNVGContext( context); 
   now = [context renderStartTime];
   now = fmod( now, 1000);  // don't want to overflow the float
   drawGraph( vg, canvas.origin.x, canvas.origin.y, canvas.size.width, canvas.size.height, now);

//   drawGraph( vg, canvas.origin.x +  canvas.size.width / 4, canvas.origin.y+  canvas.size.height / 4, canvas.size.width / 2, canvas.size.height /2, now);
}


@interface CABufferedLayer : CALayer 
@end 


#define USE_IMAGE


@implementation CABufferedLayer  


NSUInteger  checkForGLErrors( void) 
{
	NSUInteger   n;

	for( n = 0;; n++) 
   {
      switch( glGetError())
      {
      case GL_INVALID_ENUM      : fprintf( stderr, "An unacceptable value was specified for an enumerated argument\n"); break;
      case GL_INVALID_VALUE     : fprintf( stderr, "A numeric argument was out of range\n"); break;
      case GL_INVALID_OPERATION : fprintf( stderr, "The specified operation is not allowed in the current state.\n"); break;
      case GL_NO_ERROR          : return( n);
      case GL_STACK_OVERFLOW    : fprintf( stderr, "This function caused a stack overflow.\n"); break;
      case GL_STACK_UNDERFLOW   : fprintf( stderr, "This function caused a stack underflow.\n"); break;
      case GL_OUT_OF_MEMORY     : fprintf( stderr, "There is not enough memory left to execute the function.\n"); break;
      default                   : abort();
      }
   }
}

- (void) drawInContext:(CGContext *) context 
{
   CGRect                canvas;
   CGRect                rect;
   NVGcontext            *vg;
   NVGpaint              paint;
   NVGLUframebuffer      *fbo;
   CGFloat               oldAlpha;
   struct CGFrameInfo    oldInfo;
   struct CGFrameInfo    frameInfo;
   struct CGBitmapInfo   bitmapInfo;

   canvas = [self canvas]; // we draw to frame or canvas ?

   // we draw our scene into the canvas, This canvas at the end is used
   // as the paint in a simple fill

   vg = CGContextGetNVGContext( context);

   oldAlpha = [context alpha];
   oldInfo  = *[context currentFrameInfo];

   checkForGLErrors();

   nvgSave( vg);
   {
      bitmapInfo = CGBitmapInfoMake( CGBitmapSizeMake( canvas.size.width, canvas.size.height),
                                     0,
                                     CGBitmapEncodingRGBABytes);
      fbo = nvgluCreateFramebuffer( vg,
                                    bitmapInfo.size.width,
                                    bitmapInfo.size.height,
                                    0);
      assert( fbo);
      nvgluBindFramebuffer( fbo);
      assert( ! checkForGLErrors());

      frameInfo = CGFrameInfoFBMake( bitmapInfo.size, oldInfo.pixelRatio, 1.0);
      [context changeRender:&frameInfo
                      alpha:1.0];
      {
         glClearColor( 0.0, 0.0, 0.0, 0.0);
         glClear( GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT|GL_STENCIL_BUFFER_BIT);
      }
#if 0      
      nvgBeginPath( vg);
      nvgRoundedRect( vg, canvas.origin.x,
                          canvas.origin.y,
                          canvas.size.width,
                          canvas.size.height, 
                          20.0);
      nvgFillColor( vg, [UIColor blueColor]); 
      nvgFill( vg);      
#else
      drawLine( self, context);
#endif
      [context changeRender:&oldInfo
                      alpha:oldAlpha];
      [context bindDefaultFramebuffer];
   }
   nvgRestore( vg);

   // rotation some time in the future
   nvgBeginPath( vg);
   nvgRoundedRect( vg, canvas.origin.x,
                       canvas.origin.y,
                       canvas.size.width,
                       canvas.size.height,
                       [self cornerRadius]);
#if 1
   paint  = nvgImagePattern( vg, canvas.origin.x,
                                 canvas.origin.y,
                                 canvas.size.width,
                                 canvas.size.height,
                                 0.0,
                                 fbo->image,
                                 1.0);
   nvgFillPaint( vg, paint);
#else                                 
   nvgFillColor( vg, [UIColor blueColor]); 
#endif   
   nvgFill( vg);

#if 0
   // flush current, so that we can safely delete the framebuffer
   // if we don't want to do this, we should put the framebuffer into
   // a CGImage
   [context suspendRender];
   [context resumeRender];

	nvgluDeleteFramebuffer( fbo);
#endif   
}

@end 




int   main( void)
{
   UIWindow        *window;
   UIApplication   *app;
   CALayer         *layer;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];
   {
#ifdef USE_BUFFERED_LAYER      
      layer = [CABufferedLayer layer];
#else
      layer = [CALayer layer];
#endif      
      [layer setFrame:CGRectMake( 40, 40, 460, 320)];
      [layer setBackgroundColor:CGColorMakeRGB( 0.0, 0.2, 0.0)];
      [layer setBorderColor:CGColorMakeRGBA( 0.5, 0.3, 0.0, 1.0)];
      [layer setCornerRadius:20];
      [layer setBorderWidth:1.5];
      [layer setDrawCallback:drawLine];

      window = [UIWindow windowWithLayer:layer
                         titleUTF8String:NULL];

      [window dump];

      [app addWindow:window];
      [window renderLoop];
   }
   [app terminate];
}

