#import "import.h"


@class CGContext;
@class CGGraphicsLayer;



@protocol CGGraphicsLayerLayouter

- (void) layoutLayer:(CGGraphicsLayer *) layer
                info:(struct UILayoutInfo *) info;

- (CGSize) layer:(CGGraphicsLayer *) layer
    sizeThatFits:(CGSize) size
         context:(id <UILayoutContext>) context;

- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp;
@end

//
// if the callback returns NO, then the drawInContext: method preempts.
// If you return YES, then the drawing will be underneath whatever the
// CGGraphicsLayer will draw. YES should be the default.
//
typedef BOOL   CGGraphicsLayerDrawCallback_t( CGGraphicsLayer *layer,
                                              CGContext *context);

// A CGGraphicsLayer ideally only contains the necessary information to
// draw what its supposed to draw and no more. Ideally the CGGraphicsLayer
// can be serialized, send over a wire, then get deserialized on the other
// side of the planet and then it draws the same it would draw in this
// process.
//
// Try to offload as much as possible especially in regards to layouting
// and user interaction to UIView. A CGGraphicsLayer should just draw.
//
// inherits all the geometry smarts from CALayer.
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

@property( observable, assign) CARotation  rotation;

// anchorPoint is used to determine the position from frame
@property( observable, assign) CGPoint     anchorPoint;

// pose is position and rotation (its dynamically calculated)
@property( dynamic, assign) CAPose         pose;
// position is based on frame and anchorPoint (its dynamically calculated)
@property( dynamic) CGPoint                position;

// draw [layer canvas]
// clip [layer bounds]
@property CGGraphicsLayerDrawCallback_t    *drawCallback;

// set to stderr or stdout turn off with NULL (default)
@property( assign) FILE                    *drawCallTracer;
@property( dynamic, assign) CGFloat        cornerRadius;

@property( retain, nonserializable) id <CGGraphicsLayerLayouter>  layouter;

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


