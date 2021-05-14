#import "import.h"


@class CGContext;
@class CAAnimation;
@class MullePaint;


//
// Drawing in a layer.
//
// A layer draws content in its "canvas". A part or all
// of this drawing is displayed in the "frame". The piece of the "canvas" that
// is drawn in the "frame" is specified by the "bounds". As the geometries can
// be different, there can be scaling. The content is provided by subclasses
// or the drawCallback function. There is no default way to draw an image or
// a text, like in the Apple CALayer.
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
enum
{
   CALayerCanvasSizeTracksFrameSize = 0x1,
   CALayerBoundsSizeTracksFrameSize = 0x2
};

//
@interface CALayer : NSObject < NSCopying, CGRenderObject>
{
   CALayer                     *_snapshot;
   struct mulle_pointerarray   _animations;
}

// animatable properties
@property( observable) CGFloat         cornerRadius;
@property( observable) CGFloat         borderWidth;
@property( observable) CGFloat         opacity;
@property( observable) CGColorRef      borderColor;
@property( observable) CGColorRef      backgroundColor;
@property( observable) CGPoint         pixelCenter;
@property( observable) BOOL            masksToBounds;

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

// these properies are set by UIView, don't touch as they will get overwritten
// on the next layout. They are also not animatable.. use opacity or
// frame bounds for that
@property( assign) CGAffineTransform   transform;
@property( assign) CGRect              clipRect;
@property( assign) CGFloat             alpha;

@property( assign) NSUInteger          frameTracking;


// non-observable why ?
@property BOOL                         hidden;
@property char                         *debugNameCString;  // useful for debugging

// draw [layer canvas]
// clip [layer bounds]
@property void                         (*drawCallback)( CALayer *layer, CGContext *ctxt);


+ (instancetype) layerWithFrame:(CGRect) frame;
+ (instancetype) layer;

- (instancetype) init; // designated
- (instancetype) initWithFrame:(CGRect) frame;

//
// renderInContext resets the drawing context with transform and global alpha
// then calls (in this order):
//
//    -drawBackgroundInContext:  // will not be called if backgroundColor * opacity * alpha is transparent
//    [CGContext saveState];     // or similiar :)
//    -drawInContext:            // if bounds.size != zero
//    [CGContext restoreState];  // or similiar :)
//    -drawBorderInContext:      // will not be called if borderColor * opacity * alpha is transparent
//
// If you do drawing afterwards, its best to nvgReset( vg); If you are
// calling this from your own drawCallBack() then wrap it in nvgSave()
// nvgRestore()
//
- (void) renderInContext:(CGContext *) ctx;


//
// Subclasses do their drawing in this method. The default implementation
// calls the drawCallback if one is set, otherwise it does nothing.
//
// This method draws "canvas", the transformation has been setup for
// frame/bounds projection already by renderInContext:
//
// The drawing context will have been saved before
// the call and restored afterwards. You may assume the state is setup
// as if nvgReset() has been called with the following exceptions:
//
// fillColor is random
// strokeColor is random
// transform is setup already
// alpha is setup already
//
- (void) drawInContext:(CGContext *) context;

//
// these two methods draw "frame". Bounds and canvas are to be ignored.
// therefore a border doesn't scale with bounds!
//
// Ensure that the drawing context remains unchanged except for
// fillColor and strokeColor.
//
- (void) drawBackgroundInContext:(CGContext *) context;
- (void) drawBorderInContext:(CGContext *) context;

// only use this method in drawBackgroundInContext
- (void) fillBackgroundInContext:(CGContext *) context
                           color:(CGColorRef) color
                           paint:(MullePaint *) paint;

// Returns canvas.size. Subclasses may want to compute actual used space
// and return it. Used for layouting by UIView
- (CGSize) sizeThatFits:(CGSize) size
                context:(CGContext *) context;

- (BOOL) hasAnimations;

@end


@protocol CGImage;


@protocol CAImageLayer

@property( retain) NSObject <CGImage>   *image;

@end

