<!-- keywords: mulle-graphics, cggraphicslayer, catextlayer, caimagelayer, cashapelayer, cagradientlayer, animation -->

# mulle-graphics

Use this topic when you are touching MulleGraphics drawing layers, text layouters, image/shape/gradient helpers, or paint-backed animation glue. The local delta is that most work starts from `CGGraphicsLayer`, but text layout and paint interpolation each have their own repository-specific rules.

## Understand first

```bash
mulle-sde code map
mulle-sde code symbol CGGraphicsLayer
mulle-sde code symbol CATextLayer
mulle-sde code symbol CAImageLayer
mulle-sde api apropos CGPaint
```

## Main local references

- `README.md`
- `asset/dox/TOC.md`
- `src/reflect/_MulleGraphics-export.h`
- `src/CGGraphicsLayer.h`
- `src/CGGraphicsLayer+MulleGraphics.h`
- `src/CATextLayer.h`
- `src/CATextLayerLayouter.h`
- `src/CATextLayerLayouter+CGGraphicsLayerLayouter.h`
- `src/CAImageLayer.h`
- `src/CACPUImageLayer.h`
- `src/CAShapeLayer.h`
- `src/CAGradientLayer.h`
- `src/CAShadowLayer.h`
- `src/CAAccumulationLayer.h`
- `src/CAAnimation+CGPaint.h`
- `src/CABasicAnimation+CGColor.h`
- `src/CABasicAnimation+CGGradient.h`
- `src/CABasicAnimation+CGPaint.h`
- `demo/src/main-animate-circles.m`
- `demo/README.md`
- `test/20-paint/paint-copy.m`
- `test/30-animation/animate-gradient.m`
- `test/30-animation/animate-gradient-complex.m`

## Family map

| Scenario | Start here | Local rule |
| --- | --- | --- |
| Custom vector or retained drawing | `CGGraphicsLayer`, `src/CGGraphicsLayer+MulleGraphics.h`, `demo/src/main-animate-circles.m` | Draw in canvas space; background and border still render in frame space. |
| Labels, buttons, short editable text | `CATextLayer`, `CATextLayerLayouter`, `CATextLayerLayouter+CGGraphicsLayerLayouter` | The layouter owns row generation and origin placement; raw text alone is not enough to draw. |
| Images, bitmap slices, CPU textures | `CAImageLayer`, `CACPUImageLayer` | `layerWithImage:` seeds frame from image size; CPU layers use canvas as the logical pixel grid. |
| Shapes, gradients, shadows | `CAShapeLayer`, `CAGradientLayer`, `CAShadowLayer` | Shape layers own their path by default; gradient and shadow layers are specialized background/content drawers. |
| Paint/color/gradient animation | `CAAnimation+CGPaint`, `CABasicAnimation+CGColor`, `CABasicAnimation+CGGradient`, `CABasicAnimation+CGPaint` | Runtime type matters: gradient-to-gradient uses gradient interpolation, mixed paint types fall back to blended paint. |
| Trail or feedback effects | `CAAccumulationLayer` | Only the subclassed layer accumulates; you still implement normal layer drawing on top of the previous framebuffer. |

## Local workflow

1. Pick the smallest exported layer family that already matches the surface: `CGGraphicsLayer` for custom drawing, `CATextLayer` for text, `CAImageLayer` for images, `CAShapeLayer` for paths, `CAGradientLayer` or `CAShadowLayer` for specialized fills.
2. Keep layer classes draw-focused. `CGGraphicsLayer.h` explicitly pushes layout and interaction out to views or layouters.
3. For text, wire a `CATextLayerLayouter` early. `CATextLayer` stores text plus row data, and the layouter repopulates rows, selection, cursor, and origin during layout.
4. For animated paints, follow the test shape in `test/30-animation/animate-gradient.m` and `test/30-animation/animate-gradient-complex.m`: animate object-valued properties, not ad-hoc scalars, and let the category helpers pick the interpolation strategy.

## Verify/report

- Recheck the closest demo or test path for the family you changed.
- Call out family-specific caveats explicitly in your summary when you touch text rows/origin, path ownership, CPU textures, or mixed paint animation.
