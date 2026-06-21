<!-- keywords: debugger, mulle-graphics, cggraphicslayer, catextlayer, caimagelayer, caaccumulationlayer, animation -->

# mulle-graphics

Use this topic when you are debugging MulleGraphics layer rendering, text layout, image/path helpers, retained framebuffer effects, or paint-backed animation. The local delta is that many bugs split cleanly by family: `CGGraphicsLayer` separates frame-space background/border from canvas-space content, `CATextLayer` only renders rows that a layouter populated, and paint animation dispatches by runtime type.

## Understand first

```bash
mulle-sde code map
mulle-sde code search CGGraphicsLayer
mulle-sde code search CATextLayer
mulle-sde code search CAImageLayer
mulle-sde api apropos "CGPaint animation"
mulle-sde api apropos "text layout"
```

## Main local references

- `README.md`
- `asset/dox/TOC.md`
- `src/MulleGraphics.h`
- `src/CGGraphicsLayer.h`
- `src/CGGraphicsLayer+MulleGraphics.h`
- `src/CATextLayer.h`
- `src/CATextLayerLayouter.h`
- `src/CAImageLayer.h`
- `src/CACPUImageLayer.h`
- `src/CAShapeLayer.h`
- `src/CAGradientLayer.h`
- `src/CAShadowLayer.h`
- `src/CAAccumulationLayer.h`
- `src/CAAnimation+CGPaint.h`
- `demo/src/main-animate-circles.m`
- `test/10-first/calayerleak.m`
- `test/10-first/cashapelayerleak.m`
- `test/10-first/catextlayerleak.m`
- `test/20-paint/paint-copy.m`
- `test/30-animation/animate-gradient.m`
- `test/30-animation/animate-gradient-complex.m`

## Symptom map

| Symptom | Start here | Local rule |
| --- | --- | --- |
| Background or border still appears, but custom content vanished | `src/CGGraphicsLayer.h`, `src/CGGraphicsLayer+MulleGraphics.h`, `demo/src/main-animate-circles.m` | `renderInContext:` draws background, then content, then border; background and border stay in frame space while content draws canvas space. |
| Text layer is blank, misaligned, or has wrong selection/cursor | `src/CATextLayer.h`, `src/CATextLayerLayouter.h`, `src/CATextLayerLayouter+CGGraphicsLayerLayouter.m` | Setting text clears all rows, and the layouter later rebuilds rows and sets `origin`. Missing either side means no visible text. |
| Image crop, selection overlay, CPU pixels, or shape geometry look wrong | `src/CAImageLayer.h`, `src/CACPUImageLayer.h`, `src/CAShapeLayer.h`, `test/10-first/cashapelayerleak.m` | `selected` halves image alpha and adds `selectionPaint`, `displayedRect` only crops drawables with the bitmap-style selector, and `CAShapeLayer` owns its `CGPath` by default. |
| Shadow or trail effect looks wrong | `src/CAShadowLayer.h`, `src/CAAccumulationLayer.h` | `CAShadowLayer` paints around a hole, while `CAAccumulationLayer` only replays the previous framebuffer of that same subclassed layer. |
| Paint or gradient animation shape is wrong | `src/CAAnimation+CGPaint.h`, `test/30-animation/animate-gradient.m`, `test/30-animation/animate-gradient-complex.m` | Two gradients use gradient interpolation; mixed paint types fall back to blended paint and may change stop count and stop locations mid-flight. |

## Local workflow

1. Reproduce with the smallest local case first: `test/10-first/*` for lifetime/basic setup, `demo/src/main-animate-circles.m` for draw callback and observable-property animation, `test/30-animation/*` for paint interpolation.
2. For rendering bugs, decide whether the failure is in frame-space background/border or in canvas-space content before reading deeper.
3. For text bugs, inspect text storage, row generation, `origin`, selection, and editing state together; this codebase intentionally spreads those concerns across `CATextLayer` and `CATextLayerLayouter`.
4. For animation bugs, compare the generated paint/gradient sequence with the checked-in `.stdout` fixtures instead of assuming a simple color lerp.

## Verify/report

- Name the family you traced (`CGGraphicsLayer`, text, image/shape, shadow/accumulation, or paint animation).
- Say whether the failure is before drawing, during row generation, during framebuffer replay, or during interpolated property writes.
- When output differs, include which local fixture or demo you matched against.
