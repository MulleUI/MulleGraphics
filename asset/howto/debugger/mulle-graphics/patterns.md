<!-- keywords: debugger, mulle-graphics, patterns, cggraphicslayer, catextlayer, caimagelayer, animation -->

# Patterns

## Split render-path bugs at `CGGraphicsLayer`

- Start by deciding whether background/border still render. `src/CGGraphicsLayer+MulleGraphics.h` documents the actual order: background, saved-state content draw, border.
- If only content is missing, stay in `-drawInContext:` or the draw callback path. If everything is missing, inspect hidden state, effective alpha, frame size, and frame-space paints first.
- `drawCallTracer` exists for this class specifically; use it when you need the layer to tell you when it draws.

```bash
mulle-sde test run test/10-first/calayerleak.m
```

`demo/src/main-animate-circles.m` is the local reference for this family: observable layer properties mutate, the callback reads them back, and drawing uses `[layer canvas]`.

## Debug text as `text + rows + origin`

- Treat `CATextLayer` as storage plus paint state. Treat `CATextLayerLayouter` as the thing that computes rows, selection, cursor, and final `origin`.
- `setTextUTF8String:` and `setTextUTF8Data:` intentionally wipe all rows. A blank text layer after a text mutation usually means the layouter never rebuilt them.
- `src/CATextLayerLayouter+CGGraphicsLayerLayouter.m` is the key handoff: it clears rows, repopulates them, then calls `[textLayer setOrigin:origin]`.
- Use `test/10-first/catextlayerleak.m` as the smallest setup that proves text storage, paint, and font naming are sane before you chase selection or vertical-alignment details.

```bash
mulle-sde test run test/10-first/catextlayerleak.m
```

## Reproduce image, path, and CPU-surface issues with the narrowest layer

- For `CAImageLayer`, check `selected`, `selectionPaint`, `displayedRect`, and `contentMode` together. The implementation intentionally drops image alpha to `0.5` when selected and then paints the selection overlay.
- For `CACPUImageLayer`, debug the upload boundary, not just the memory buffer. `keepsCPUTexture` keeps the CPU storage around, but pixels do not change onscreen until the layer draws again.
- For `CAShapeLayer`, reduce the case to a trivial `CGPath` first; `test/10-first/cgpath-simple.m` and `test/10-first/cashapelayerleak.m` are the local sanity checks.

```bash
mulle-sde test run test/10-first/cgpath-simple.m
mulle-sde test run test/10-first/cashapelayerleak.m
```

## Compare paint animation against the checked-in fixtures

- Use `test/30-animation/animate-gradient.m` when both endpoints are gradients.
- Use `test/30-animation/animate-gradient-complex.m` when one endpoint is a plain paint and the other is a gradient; that fixture shows the expected blended-stop behavior.
- If a property suddenly mutates or shares state, bring in `test/20-paint/paint-copy.m` before blaming interpolation logic. The public paint properties in this repo are copy-oriented on purpose.

```bash
mulle-sde test run test/30-animation/animate-gradient.m
mulle-sde test run test/30-animation/animate-gradient-complex.m
mulle-sde test run test/20-paint/paint-copy.m
```

## Treat shadow and accumulation bugs as geometry problems

- `CAShadowLayer` computes a hole from `shadowInsets` and `shadowHole`; debug the rect math before touching blur or color.
- `CAAccumulationLayer` replays its previous framebuffer, then draws current content normally. If you expected sibling history or whole-scene feedback, you are in the wrong model.
- When the trail drifts or fades incorrectly, inspect `previousFramebufferInsets` and `decay` first; those are the local knobs that shape replay.
