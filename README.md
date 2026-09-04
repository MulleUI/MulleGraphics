# MulleGraphics

Part of [MulleUI](https://github.com/MulleUI) — UIKit-shaped modular GUI libraries for mulle-objc.

#### 🌠 MulleGraphics provides CALayer subclasses

This library ties MulleCA and MulleCG together. It adds the drawing
functionality to **CALayer** and adds several useful subclasses for drawing
images and text.

To create your own drawings, it's easiest to use a CALayer and do a
`-setDrawCallback:` to your C drawing code function. If you need to keep state
between frames, subclass CALayer and override the `-drawInContext:` method.

MulleGraphics provides the layers only. The view and window that host them
come from [MulleUIView](//github.com/MulleUI/MulleUIView) and
[MulleUIWindow](//github.com/MulleUI/MulleUIWindow), and writing image files
to disk is the job of [MulleImage](//github.com/MulleUI/MulleImage).

The window drives the frame loop: it creates the layers and their `CGContext`s
for you and calls each layer's draw callback once per frame. See
[MulleCG's usage](//github.com/MulleUI/MulleCG#usage) for the drawing model,
and [pixel-perfect rectangles](//github.com/MulleUI/MulleCG#how-to-draw-pixel-perfect-rectangles)
for exact fills and strokes.

## CALayer Subclasses

`CGGraphicsLayer` is the base layer for custom drawing: subclass it and
override `-drawInContext:`, or set a draw callback. The ready-made `CA*`
layers all subclass it:

Class               | Description
--------------------|-----------------------------------------
`CGGraphicsLayer`   | Base layer that draws your custom content
`CACPUImageLayer`   | A bitmap drawn by the CPU.
`CAGradientLayer`   | A gradient drawing layer
`CAImageLayer`      | A layer that draws a vector image or a bitmap image
`CAShadowLayer`     | A layer that draws a shadow
`CAAccumulationLayer` | A layer that keeps the previous frames' drawing, shifted and decayed
`CAShapeLayer`      | A layer for simple drawings
`CATextLayer`       | A layer for rendering short texts

The drawing APIs take C strings and plain C structures; MulleFoundation
classes (NSString, NSArray, ...) are not used here yet.

> #### Note
>
> MulleCG and MulleCA both pull in the CGColor typedef. MulleGraphics lists
> MulleCG before MulleCA, which is the required order. See MulleCG's README
> if you include both libraries directly.



| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleGraphics.svg) [![Build Status](https://github.com/MulleUI/MulleGraphics/workflows/CI/badge.svg)](//github.com/MulleUI/MulleGraphics/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for MulleGraphics](https://deepwiki.com/MulleUI/MulleGraphics)




## Documentation & Guides

* [API Summary](asset/dox/api/toc)
* [Coder Guide](asset/howto/coder/mulle-graphics)
* [Debugger Guide](asset/howto/debugger/mulle-graphics)
* [Verifier Guide](asset/howto/verifier/mulle-graphics)

## Usage

The easiest way to draw your own content is a `CGGraphicsLayer` with a draw
callback. The callback gets the layer and the `CGContext` you can draw into.
Return `NO` to preempt the layer's own `-drawInContext:` so only your drawing
shows; return `YES` to have your drawing appear underneath the layer's own
content:

``` objc
#import <MulleGraphics/MulleGraphics.h>
#import <MulleUIView/MulleUIView.h>   // UIView

static BOOL   drawStuff( CGGraphicsLayer *layer, CGContext *context)
{
   CGRect   rect;

   rect = CGRectInset( [layer canvas], 16, 16);
   CGContextStrokeRectWithColor( context, rect, 8.0, CGColorMakeGreen());
   return( NO);
}


static void   setupSceneInWindow( UIWindow *window)
{
   CGGraphicsLayer  *layer;
   UIView           *view;

   layer = [CGGraphicsLayer layerWithFrame:CGRectMake( 0.0, 0.0, 200.0, 200.0)];
   [layer setDrawCallback:drawStuff];
   [layer setBorderColor:CGColorMakeBlue()];
   [layer setBorderWidth:2.0];

   view = [UIView viewWithLayer:layer];
   [[window contentView] addSubview:view];
}
```

If you need to keep state between frames, subclass `CGGraphicsLayer` and
override `-drawInContext:` instead of using a callback.

## Build the demo

The `demo/` folder is a [mulle-sde](//github.com/mulle-sde) project:

``` sh
cd demo
mulle-sde craft
```


### You are here

![Overview](overview.dot.svg)





## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleGraphics to your project:

``` sh
mulle-sde add github:MulleUI/MulleGraphics
```

To only add the sources of MulleGraphics with dependency
sources use [clib](https://github.com/clibs/clib):


``` sh
clib install --out src/MulleUI MulleUI/MulleGraphics
```

Add `-isystem src/MulleUI` to your `CFLAGS` and compile all the sources that were downloaded with your project.


## Install

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleGraphics and all dependencies:

``` sh
mulle-sde install --prefix /usr/local \
   https://github.com/MulleUI/MulleGraphics/archive/latest.tar.gz
```

### Legacy Installation

Install the requirements:

| Requirements                                 | Description
|----------------------------------------------|-----------------------
| [MulleCG](https://github.com/MulleUI/MulleCG)             | 💫 MulleCG Coregraphics for MulleUI
| [MulleCA](https://github.com/MulleUI/MulleCA)             | 🫧 Animate properties in real time with mulle-objc
| [mulle-objc-list](https://github.com/mulle-objc/mulle-objc-list)             | 📒 Lists mulle-objc runtime information contained in executables.

Download the latest [tar](https://github.com/MulleUI/MulleGraphics/archive/refs/tags/latest.tar.gz) or [zip](https://github.com/MulleUI/MulleGraphics/archive/refs/tags/latest.zip) archive and unpack it.

Install **MulleGraphics** into `/usr/local` with [cmake](https://cmake.org):

``` sh
PREFIX_DIR="/usr/local"
cmake -B build                               \
      -DMULLE_SDK_PATH="${PREFIX_DIR}"       \
      -DCMAKE_INSTALL_PREFIX="${PREFIX_DIR}" \
      -DCMAKE_PREFIX_PATH="${PREFIX_DIR}"    \
      -DCMAKE_BUILD_TYPE=Release &&
cmake --build build --config Release &&
cmake --install build --config Release
```


## Author

[Nat!](https://mulle-kybernetik.com/weblog) for Mulle kybernetiK  



