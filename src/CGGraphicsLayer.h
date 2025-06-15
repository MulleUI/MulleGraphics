#import "import.h"


@class CGContext;
@class CGGraphicsLayer;


//
// if the callback returns NO, then the drawInContext: method preempts.
// If you return YES, then the drawing will be underneath whatever the
// CGGraphicsLayer will draw. YES should be the default.
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
// colors are "conveniences" for borderPaint and backgroundPaint
// they are properties, so we can animate them
@property( observable, dynamic) CGColor    borderColor;
@property( observable, dynamic) CGColor    backgroundColor;

@property( observable, assign) CGPoint     anchorPoint;
@property( observable, assign) CARotation  rotation;

// draw [layer canvas]
// clip [layer bounds]
@property CGGraphicsLayerDrawCallback_t    *drawCallback;



@property( dynamic, assign) CAPose         pose;
@property( dynamic) CGPoint                position;

@property( dynamic, assign) CGFloat        cornerRadius;


// MEMO: initNoLock is actually the designated initializer funneled into by
// _initWithFrame which is hidden. Subclasses generally want to override
// initWithFrame: though
// - (instancetype) initNoLock;                    // designated
// - (instancetype) initWithFrame:(CGRect) frame;

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


