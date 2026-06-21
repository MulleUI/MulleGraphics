<!-- keywords: drawcalltracer, dumpwithindent, cleartype, selection, framebuffer, gradient -->

# mulle-graphics

Use this topic when you are verifying or debugging app code that uses MulleGraphics layers, text layouters, image/path helpers, retained framebuffer effects, or paint-backed animation. The local delta is that MulleGraphics exposes its diagnostics mostly as per-family APIs and tiny repro tests; no repository-specific runtime `MULLE_*` tracing knobs showed up in the public headers, docs, or demos.

## Understand first

```bash
mulle-sde craft --debug
mulle-sde api cat CGGraphicsLayer
mulle-sde api cat CATextLayer
mulle-sde api cat CAImageLayer
mulle-sde code search drawCallTracer
mulle-sde code search dumpWithIndent
mulle-sde api apropos "CGPaint animation"
```

## Main local references

- `README.md`
- `asset/dox/TOC.md`
- `src/CGGraphicsLayer.h`
- `src/CGGraphicsLayer+MulleGraphics.h`
- `src/CATextLayer.h`
- `src/CATextLayerLayouter.h`
- `src/CAImageLayer.h`
- `src/CACPUImageLayer.h`
- `src/CAShapeLayer.h`
- `src/CAShadowLayer.h`
- `src/CAAccumulationLayer.h`
- `src/CAAnimation+CGPaint.h`
- `demo/src/main-animate-circles.m`
- `test/10-first/calayerleak.m`
- `test/10-first/catextlayerleak.m`
- `test/10-first/cgpath-simple.m`
- `test/10-first/cashapelayerleak.m`
- `test/20-paint/paint-copy.m`
- `test/30-animation/animate-gradient.m`
- `test/30-animation/animate-gradient.stdout`
- `test/30-animation/animate-gradient-complex.m`
- `test/30-animation/animate-gradient-complex.stdout`

## Symptom map

| Symptom | Probe first | Local rule |
| --- | --- | --- |
| Custom content vanished but background or border still shows | `drawCallTracer`, `demo/src/main-animate-circles.m`, `test/10-first/calayerleak.m` | `renderInContext:` draws background, then canvas content, then border. Background and border stay in frame space while custom drawing uses canvas space. |
| Text is blank, misaligned, or the cursor/selection is wrong | `dumpWithIndent:FILE:`, `glyphRectAtPoint:`, `characterOffsetAtPoint:`, `visualBoundsWithContext:`, `suggestedTextPaint`, `test/10-first/catextlayerleak.m` | Setting text wipes all rows. The layouter later rebuilds rows and sets `origin`. `clearTypeEnabled` only takes effect when text, selection, and text-background paints are monochrome and the text background is opaque. |
| Image crop, CPU pixels, or path lifetime looks wrong | `selected`, `displayedRect`, `keepsCPUTexture`, `ownsPath`, `test/10-first/cgpath-simple.m`, `test/10-first/cashapelayerleak.m` | Selected images render dimmed and then paint `selectionPaint`; CPU texture edits only appear after another draw; `CAShapeLayer` owns its `CGPath` by default. |
| Shadow or accumulation trail looks wrong | `shadowedRect`, `rectForPreviousFramebuffer:canvas:`, `alphaForPreviousFramebuffer:inRect:canvas:` | `CAShadowLayer` paints around a hole, and `CAAccumulationLayer` only replays that subclassed layer's own previous framebuffer. |
| Paint or gradient animation looks unlike a simple lerp | `test/20-paint/paint-copy.m`, `test/30-animation/animate-gradient.stdout`, `test/30-animation/animate-gradient-complex.stdout` | Animation dispatches by runtime paint type. Gradient-to-gradient uses gradient interpolation; mixed paint types legitimately produce synthetic stop counts and locations mid-flight. |

## Local workflow

1. Start with a debug craft, but expect the useful signal to come from object APIs and fixture-style tests, not environment variables.
2. Reduce the failure to the narrowest family first: `test/10-first/*` for setup and lifetime, `demo/src/main-animate-circles.m` for draw callbacks plus observable animation, `test/30-animation/*` for paint interpolation.
3. For render-path bugs, split frame-space background/border from canvas-space content before chasing transforms or animation.
4. For text bugs, inspect text bytes, row generation, `origin`, selection, and cursor together; this repository intentionally spreads those concerns across `CATextLayer` and `CATextLayerLayouter`.
5. For animation bugs, compare actual stop output with the checked-in `.stdout` fixtures before calling the interpolation wrong.

## Verify/report

- Name the family you traced: base layer drawing, text, image/CPU/path, shadow/accumulation, or paint animation.
- Say which local hook proved it: `drawCallTracer`, layouter dump, text geometry accessor, framebuffer helper, or fixture output.
- Call out the violated invariant directly when you find it: rows were never rebuilt, a path was destroyed twice, a kept CPU texture was never redrawn, accumulation was expected to include siblings, or mixed paint types were compared as if they were plain colors.
