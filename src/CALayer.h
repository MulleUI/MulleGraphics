#import "import.h"



@class CAAnimation;
@class CAAnimationStorage;
@class CALayer;
@class CGPaint;


//
// Drawing in a layer.
//
// A layer draws content in its "canvas". A part or all
// of this drawing is displayed in the "frame". The piece of the "canvas" that
// is drawn in the "frame" is specified by the "bounds". The content is
// provided by subclasses or the drawCallback function. There is no default
// way to draw an image or a text, like in the Apple CALayer.
//
// canvas.origin (0,0)
//       .----------------------.
//       |                      | frame.origin
//       | bounds.origin        |      .---------------.
//       |       .--------.     |      |               |
//       |       |        |----------->|               |
//       |       '--------'     |      |               |
//       |          bounds.size |      '---------------'
//       |                      |                 frame.size
//       '----------------------'
//                        canvas.size
//
//
// An example with actual numbers. Here the canvas draws rows of pixels 0-9,
// just to make it easier to follow.
//
//       canvas
//   .------------.   canvas = { { 0, 0 }, { 10, 8 } }
//   | 0123456789 |   bounds = { { 2, 3 }, {  4, 3 } }
//   | 0 bounds 9 |   frame  = { { x, y }, {  8, 6 } }
//   | 0.------.9 |
//   | 0| 2345 |9 |
//   | 0| 2345 |9 |
//   | 0| 2345 |9 |
//   | 0'------'9 |
//   | 01234|6789 |
//   '------|-----'      frame
//          |         .----------.
//          |         | 22334455 |
//          |         | 22334455 |
//          |         | 22334455 |
//          '-------->| 22334455 |
//                    | 22334455 |
//                    | 22334455 |
//                    '----------'
//
// See example: main-layout-bounds.m
//
// This is simple as long as there is no scaling involved. If there is scaling
// then bounds can't track frame, as bounds are in canvas space. So everytime
// frame.size is changed, the bounds may need to be adjusted manually.
//
// TODO: maybe add some more trackers, for stable bounds center, stable bounds
//       origin or so...
enum
{
   CALayerCanvasSizeTracksFrameSize = 0x1,
   CALayerBoundsSizeTracksFrameSize = 0x2
};


// return NO, it you want to preempt actual drawing of the layer.
//            i.e. if you use a predefined layer like CATextLayer
//            and return NO, the CATextLayer will not draw (except for
//            border and background). So you usually return YES.
typedef BOOL  CALayerDrawCallback_t( CALayer *layer, void *ctxt);


//
// The CALayer "private" animations are not stored or handled in a CAAnimator
// object. They are triggered as part of the renderQueue creation. These
// animations will run, separately from any "CAAnimator" animations. Therefore
// making those animations "additive" should be good.

@interface CALayer : CAImplicitlyAnimatableObject <CAAnimationStorageObject>
{
   struct CAAnimationStorage   _animationStorage;
}

// animatable properties
@property( observable) MulleCornerInsets   cornerInsets;

@property( observable) CGFloat         borderWidth;
@property( observable) CGFloat         opacity;
@property( observable, copy) CGPaint   *borderPaint;
@property( observable, copy) CGPaint   *backgroundPaint;
@property( observable) CGPoint         pixelCenter;
@property( assign) BOOL                masksToBounds;

@property( observable) CGRect          frame;

//
// The bounds property is local to each layer and not inherited. If not set
// it's the same as { 0, 0, frame.size.width, frame.size.height }. If the
// bounds are not set manually, the bounds.size tracks the frame.size.
//
@property( observable) CGRect          bounds;

//
// The canvas property is usually fixed at the beginning and doesn't change
// except if the content changes.. If the canvas is not set manually, the
// canvas.size tracks the bounds.size.
//
@property( observable) CGRect          canvas;

// These properies are set by the UIView only! Don't touch them, as they will
// get overwritten on the next render. Use opacity or frame/bounds for
// Layer animation.

@property( assign) CGAffineTransform   transform;
@property( assign) CGRect              clipRect;
@property( assign) CGFloat             alpha;

// this is a bitfield that controls bounds/frame canvas/frame tracking
@property( assign) NSUInteger          frameTracking;

@property( assign) NSInteger           tag;

// hidden is non-observable why ?
@property BOOL                         hidden;
@property char                         *debugNameUTF8String;  // useful for debugging

// draw [layer canvas]
// clip [layer bounds]
@property CALayerDrawCallback_t        *drawCallback;


- (void) setCornerRadius:(CGFloat) cornerRadius;

+ (instancetype) layerWithFrame:(CGRect) frame;
+ (instancetype) layer;

- (instancetype) init; // designated
- (instancetype) initWithFrame:(CGRect) frame;

- (void) setBorderColor:(CGColor) color;
- (void) setBackgroundColor:(CGColor) color;

@end


