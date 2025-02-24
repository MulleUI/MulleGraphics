#import "import.h"


@class CGContext;
@class CGGraphicsLayer;


//
// if the callback returns NO, then the drawInContext: method preempts
// if you return YES, then the drawing will be underneath whatever the
// CGGraphicsLayer will draw
//
typedef BOOL   CGGraphicsLayerDrawCallback_t( CGGraphicsLayer *layer,
                                              CGContext *context);

//
// inherit all the geometry smarts from CALayer.
//
@interface CGGraphicsLayer : CALayer


// animatable properties
@property( observable) MulleCornerInsets   cornerInsets;

@property( observable) CGFloat             borderWidth;
@property( observable, copy) CGPaint       *borderPaint;
@property( observable, copy) CGPaint       *backgroundPaint;
@property( observable) CGPoint             pixelCenter;

// draw [layer canvas]
// clip [layer bounds]
@property CGGraphicsLayerDrawCallback_t    *drawCallback;

- (void) setCornerRadius:(CGFloat) cornerRadius;

- (void) setBorderColor:(CGColor) color;
- (void) setBackgroundColor:(CGColor) color;

@end


static inline BOOL   CGGraphicsLayerExecuteDrawCallback( CGGraphicsLayer *self,
                                                         CGContext *context)
{
   if( ! self)
      return( NO);
   return( ((struct { @defs( CGGraphicsLayer); } *) self)->_drawCallback
           ? (*((struct { @defs( CGGraphicsLayer); } *) self)->_drawCallback)( self, context)
           : YES);
}


