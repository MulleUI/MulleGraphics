<!-- keywords: debugger, mulle-graphics, quirks, cggraphicslayer, catextlayer, caimagelayer, caaccumulationlayer, cgpaint -->

# Quirks

## `CGGraphicsLayer`

- Background and border are frame-space drawing. They do not rotate or scale with bounds the way canvas content does.
- The draw callback is part of the normal content path. If code bypasses `[super drawInContext:context]` and also skips `CGGraphicsLayerExecuteDrawCallback`, callback-driven drawings disappear even though the layer still renders.
- `sizeThatFits:context:` may come from the layouter instead of raw canvas size, so layout regressions can surface as drawing regressions.

## `CATextLayer` and `CATextLayerLayouter`

- Setting text clears all `CATextLayerRow` state. Until rows are rebuilt, the layer has text bytes but nothing to draw.
- `CATextLayer` is intentionally short-text machinery. Once debugging drifts into long-document behavior, expect expensive full glyph recalculation instead of editor-style scrolling smarts.
- Coordinates are baseline-relative, not top-left text-box coordinates. Misread baseline math will look like an origin bug.
- `clearTypeEnabled` is not enough by itself. `src/CATextLayer.m` only enables ClearType when text paint, text background paint, and selection paint are monochrome and the text background is opaque.
- `aliasPixelVisible == NO` shrinks visual bounds by a pixel to drop anti-alias fringe. Small centering diffs can be intentional.
- Selection ranges must not split graphemes or combined emoji. The layouter header warns that this is the caller's job.

## `CAImageLayer`, `CACPUImageLayer`, and `CAShapeLayer`

- `CAImageLayer` selection is a rendering effect, not metadata only: selected images draw dimmed and then receive `selectionPaint`.
- `displayedRect` only works when the drawable responds to `drawRect:fromRect:options:context:`. Cropping failures can come from the drawable type, not the rect value.
- `+layerWithImage:` seeds the frame from image size. If the visible size seems wrong, check whether you are really looking at the original image dimensions.
- `CACPUImageLayer` uploads on draw. Writing into a kept texture without another draw pass does not refresh the GPU-side image.
- `CAShapeLayer` owns its `CGPath` by default and destroys it unless `ownsPath` is set to `NO`. That is the first place to look for double-destroy or leak-shaped path bugs.

## `CAShadowLayer` and `CAAccumulationLayer`

- `CAShadowLayer` paints around a hole. If the computed `shadowedRect` already matches the canvas, there is no useful shadow shape left to render.
- `CAAccumulationLayer` only accumulates the subclassed layer's own output. It is not a history buffer for siblings or the whole scene.
- `previousFramebufferInsets` uses `INFINITY` as a sticky sentinel in `src/CAAccumulationLayer.m`; those values are control markers, not ordinary geometry.
- `decay` is applied while replaying the previous framebuffer, not while current-frame drawing runs.

## Paint and animation helpers

- `CAAnimation+CGPaint` dispatches by runtime type. Two gradients go through gradient interpolation; mixed paint types do not.
- Mixed paint animation can legitimately produce intermediate stop counts and stop locations that never existed in either endpoint. `test/30-animation/animate-gradient-complex.stdout` is the local proof.
- Paint properties are copy-based in this API family. If animated state looks aliased or mutated from the outside, verify copy behavior before changing the interpolator.
