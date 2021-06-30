# 🌠 MulleGraphics

#### 🌠 MulleGraphics provides CALayers

This ties MulleCA and MulleCG together. It provides CALayer and an
image layer and a text drawing layer.

It's not nanovg agnostic (yet) as the layers use nanovg for drawing.

There is no event handling.
There is no window setup.
There is no image file writing

Based on MulleObjC. The MulleFoundation (e.g. NSString, or NSArray) is not yet
available.


### You are here

```
  .--------------------------------.
  | MulleUIFoundation              |
  '--------------------------------'
  .--------------------------------.
  | MulleUIViews                   |
  '--------------------------------'
  .--------------. .---------------.
  | MulleUIImage | | MulleUICore   |
  '--------------' '---------------'

  .================================.
  | MulleGraphics                  |
  '================================'

  .--------------. .---------------.
  | MulleCG      | | MulleCA       |
  '--------------' '---------------'
  .--------------------------------.
  | MulleLayout                    |
  '--------------------------------'

```


## Add

Use [mulle-sde](//github.com/mulle-sde) to add MulleGraphics to your project:

``` console
mulle-sde dependency add --c --github <|GITHUB_USER|> MulleGraphics
```

## Install

### mulle-sde

Use [mulle-sde](//github.com/mulle-sde) to build and install MulleGraphics
and all its dependencies:

```
mulle-sde install --prefix /usr/local \
   https://github.com/<|GITHUB_USER|>/MulleGraphics/archive/latest.tar.gz
```

### Manual Installation


Install the requirements:

Requirements                                      | Description
--------------------------------------------------|-----------------------
[some-requirement](//github.com/some/requirement) | Some requirement

Install into `/usr/local`:

```
mkdir build 2> /dev/null
(
   cd build ;
   cmake -DCMAKE_INSTALL_PREFIX=/usr/local \
         -DCMAKE_PREFIX_PATH=/usr/local \
         -DCMAKE_BUILD_TYPE=Release .. ;
   make install
)
```

### Steal

Read [STEAL.md](//github.com/mulle-c11/dox/STEAL.md) on how to steal the
source code and incorporate it in your own projects.
