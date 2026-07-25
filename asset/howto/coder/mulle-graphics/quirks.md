<!-- keywords: mulle-graphics, quirks, catextlayer, caimagelayer, cashapelayer, caaccumulationlayer, animation -->

# Quirks

## `CGGraphicsLayer`

- `renderInContext:` skips hidden layers, fully transparent effective alpha, and near-zero frame sizes. If a layer seems inert, check those first.
- Background and border are frame-space drawing. They do **not** rotate or scale with canvas content; `src/CGGraphicsLayer+MulleGraphics.h` and `.m` call that out explicitly.
- If you override `-drawInContext:` and skip `[super drawInContext:context]`, still call `CGGraphicsLayerExecuteDrawCallback( self, context )` if you want C callbacks to remain patchable.
- `sizeThatFits:context:` delegates to the layouter when present; otherwise it just returns canvas size.

## `CATextLayer` and `CATextLayerLayouter`

- `setTextUTF8Data:` and `setTextUTF8String:` wipe all rows. Until rows are rebuilt, the layer draws nothing.
- `CATextLayer` is for short text only. The public header says it is not suitable for more than about a screenful of lines.
- Baseline math is local and intentional: row y positions are baseline-relative, not top-left text boxes. `textVerticalAlignment` and `useVisualBounds` both change how origin gets computed.
- `useVisualBounds` is stricter than font metrics mode. With `aliasPixelVisible == NO` the layouter shrinks visual bounds by one pixel on each side to exclude anti-aliasing pixels.
- ClearType has hard prerequisites in `src/CATextLayer.m`: text paint, text background paint, and selection paint must all be monochrome, and the text background must be opaque.
- `textPaint` uses a small font image colorized with a monochrome color. Gradients are not possible for text fills per `src/CATextLayer.h`.
- Text properties marked `observable` (`fontPixelSize`, `textLineHeight`, `textLetterSpacing`, etc.) increment `textPropertiesGenerationCount` but it is read-only. The layouter checks this count to decide whether glyphs need recomputation.
- Selection ranges are character ranges in UTF-32 offsets, but `CATextLayerLayouter.h` warns that the layouter does **not** prevent splitting graphemes or combined emoji for you.
- `fontNameUTF8String` is declared `assign` but `src/CATextLayer.m` internally duplicates the C string via `MulleObjCObjectSetDuplicatedUTF8String`. The caller may free the original pointer after setting.

## `CAImageLayer`, `CACPUImageLayer`, and `CAShapeLayer`

- `CAImageLayer` selection is not just state: `src/CAImageLayer.m` lowers image alpha to `0.5` and then paints the selection overlay.
- `displayedRect` only affects drawables that implement `drawRect:fromRect:options:context:`. Do not assume every `CGDrawable` supports cropping.
- Infinite drawable dimensions are special-cased in `src/CAImageLayer.m`; generated paints/images can bypass the usual placed-rect sizing path.
- `CAShapeLayer` owns its `CGPath` by default and will destroy it unless you set `ownsPath` to `NO`.
- `CACPUImageLayer` uploads on draw. Mutating a kept CPU texture alone is not enough to refresh the GPU image.

## `CAShadowLayer`, `CAGradientLayer`, and `CAAccumulationLayer`

- `CAGradientLayer` is very narrow: it mainly replaces background filling with its `paint`.
- `CAShadowLayer` draws the shadow around a hole computed from `shadowInsets` and `shadowHole`. If `shadowedRect` already equals the canvas, `drawInContext:` returns `NO` and nothing useful is painted.
- `CAAccumulationLayer` only accumulates the subclassed layer's own output. It is not a general scene-history layer for siblings.
- `previousFramebufferInsets` uses `INFINITY` as a sticky sentinel in `src/CAAccumulationLayer.m`; do not treat those values as ordinary geometry.
- `decay` is applied when the previous framebuffer is replayed, not when your current draw code runs.

## Paint and animation helpers

- `CAAnimation+CGPaint` dispatches by runtime type. Two gradients get gradient interpolation; anything else goes through blended paint animation.
- Mixed paint animations can legitimately change stop count and locations mid-flight; `test/30-animation/animate-gradient-complex.stdout` shows that behavior.
- Copy semantics matter here. `test/20-paint/paint-copy.m` exists just to ensure paint copies are safe, so keep paint properties copy-based like the public headers do.
