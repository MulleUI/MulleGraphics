# MulleGraphics

#### 🌠 MulleGraphics provides CALayer subclasses


# 🌠 MulleGraphics

#### 🌠 MulleGraphics provides CALayer subclasses

This library ties MulleCA and MulleCG together. It adds the drawing
functionality to **CALayer** and adds several useful subclasses for drawing
images and text.

It's not nanovg agnostic (yet) as the layers use nanovg for drawing.

To create your own drawings, it's easiest to use a CALayer and do a
`-setDrawCallback:` to your C drawing code function. If you need to keep state
between frames, subclass CALayer and override the `-drawInContext:` method.


### CALayer Subclasses

Class             | Description
------------------|-----------------------------------------
`CACPUImageLayer` | A bitmap drawn by the CPU.
`CAGradientLayer` | A gradient drawing layer
`CAImageLayer`    | A layer that draws a vector image or a bitmap image
`CAOpenGLLayer`   | A layer to draw with OpenGL graphic commands.
`CAShapeLayer`    | A layer for simple drawings with nanovg
`CATextLayer`     | A layer for rendering short texts



There is no event handling.
There is no window setup.
There is no image file writing

Based on MulleObjC. The MulleFoundation (e.g. NSString, or NSArray) is not yet
available.





| Release Version                                       | Release Notes  | AI Documentation
|-------------------------------------------------------|----------------|---------------
| ![Mulle kybernetiK tag](https://img.shields.io/github/tag/MulleUI/MulleGraphics.svg) [![Build Status](https://github.com/MulleUI/MulleGraphics/workflows/CI/badge.svg)](//github.com/MulleUI/MulleGraphics/actions) | [RELEASENOTES](RELEASENOTES.md) | [DeepWiki for MulleGraphics](https://deepwiki.com/MulleUI/MulleGraphics)






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
| [MulleCA](https://github.com/MulleUI/MulleCA)             | 🍃 Animate properties in real time with mulle-objc
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



