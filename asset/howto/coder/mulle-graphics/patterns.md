<!-- keywords: mulle-graphics, patterns, cggraphicslayer, catextlayer, caimagelayer, cagradientlayer, cgpaint -->

# Patterns

## Custom layer drawing with `CGGraphicsLayer`

- Prefer `+layerWithFrame:` or `+instance`, then set a C draw callback or override `-drawInContext:`.
- Draw against `[self canvas]`, not `[self frame]`. `renderInContext:` already installs the frame/bounds transform.
- Use this when the layer is just a renderer; keep layout and interaction elsewhere.

```objective-c
static BOOL   DrawStuff( CGGraphicsLayer *layer, CGContext *context)
{
   CGRect   canvas;

   canvas = [layer canvas];
   CGContextBeginPath( context);
   CGContextRect( context, canvas);
   CGContextStrokeColor( context, CGColorMakeRed());
   CGContextStrokeWidth( context, 2.0);
   CGContextStroke( context);
   return( YES);
}

layer = [CGGraphicsLayer layerWithFrame:CGRectMake( 0, 0, 120, 80)];
[layer setDrawCallback:DrawStuff];
```

`demo/src/main-animate-circles.m` is the canonical local example: observable properties live on the layer, the callback reads them back, and animation mutates the layer directly.

## Text layers go through a layouter

- Treat `CATextLayer` as text storage plus render state.
- Treat `CATextLayerLayouter` as the thing that computes rows, selection, cursor, and final origin.
- The happy path is: set text/font/paint on the layer, attach a layouter, then let layout rebuild rows.

```objective-c
CATextLayer           *layer;
CATextLayerLayouter   *layouter;

layer    = [CATextLayer layerWithFrame:CGRectMake( 0, 0, 220, 48)];
layouter = [CATextLayerLayouter instance];

[layer setLayouter:layouter];
[layer setTextUTF8String:"VfL Bochum 1848"];
[layer setFontNameUTF8String:"sansibar"];
[layer setTextColor:CGColorMakeOliveDrab()];
[layer setSelectable:YES];
```

Local rule from `src/CATextLayerLayouter+CGGraphicsLayerLayouter.m`: `layoutLayer:info:` clears all existing `CATextLayerRow` entries, repopulates them from the layouter state, and then sets `[layer origin]`. If you bypass the layouter, you must provide both text and rows yourself.

## Image, bitmap, and path authoring

- `CAImageLayer` is the stock image surface. `+layerWithImage:` starts with the image size as the frame.
- `displayedRect` is the local crop knob for bitmap-capable drawables.
- `CAShapeLayer` is the stock path surface: set paints plus a `CGPath`, then let the layer own it.

```objective-c
CAImageLayer   *imageLayer;
CAShapeLayer   *shapeLayer;
CGPath         *path;

imageLayer = [CAImageLayer layerWithImage:image];
[imageLayer setContentMode:CGContentModeScaleAspectFit];
[imageLayer setDisplayedRect:CGRectMake( 32, 32, 128, 128)];

path = CGPathCreate( NULL);
CGPathMoveToPoint( path, CGPointMake( 0, 0));
CGPathAddLineToPoint( path, CGPointMake( 100, 0));
CGPathCloseSubpath( path);

shapeLayer = [CAShapeLayer layerWithFrame:CGRectMake( 0, 0, 100, 100)];
[shapeLayer setPath:path];
[shapeLayer setStrokeColor:CGColorMakeBlack()];
[shapeLayer setFillColor:CGColorMakeClear()];
```

`test/10-first/cgpath-simple.m` is the minimal local path shape. `src/CAImageLayer.m` adds one important local detail: selected image layers render the image at half alpha and then paint `selectionPaint` over the canvas.

## CPU textures and retained effects

- Use `CACPUImageLayer` for old-school software rendering or per-pixel effects.
- Override `-drawInBytes:bitmapInfo:`; the layer uploads that CPU buffer each draw.
- Use canvas as the logical pixel grid. If you also want visible scaling, mirror that size into bounds.

```objective-c
@interface DemoPixels : CACPUImageLayer
@end

@implementation DemoPixels

- (void) drawInBytes:(void *) texture
          bitmapInfo:(struct CGBitmapInfo) bitmapInfo
{
   /* fill RGBA pixels here */
}

@end
```

`src/CACPUImageLayer.h` is explicit: keeping the CPU texture only preserves the buffer for incremental updates; it does not make edits visible until the layer draws again.

## Paint and gradient animation

- Use object-valued paint properties and animate them with the paint categories.
- If both endpoints are gradients, `CAAnimation+CGPaint.m` routes to gradient interpolation.
- If the endpoints are mixed paint types, the runtime builds a blended paint instead.

```objective-c
CABasicAnimation   *animation;

animation = [CABasicAnimation animationWithProperty:MulleObjCInstanceSearchProperty( layer, @selector( backgroundPaint))
                                       startCGPaint:startPaint
                                         endCGPaint:endPaint
                                            options:NULL];
```

`test/30-animation/animate-gradient.m` shows plain gradient-to-gradient interpolation. `test/30-animation/animate-gradient-complex.m` shows the mixed case: a solid paint animating toward a three-stop gradient yields intermediate synthetic stop lists instead of a simple color lerp.
