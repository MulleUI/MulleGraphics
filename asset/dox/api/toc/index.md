# MulleGraphics Library Documentation for AI
<!-- Keywords: graphics, layers, rendering, animation, text, shapes, images -->

## 1. Introduction & Purpose

MulleGraphics is a graphics layer library that provides CALayer subclasses with drawing functionality. It bridges MulleCA (the animation framework) and MulleCG (a CoreGraphics-compatible API) to enable renderable, animatable layers for shapes, images, text, gradients, frame accumulation, and custom drawings.

MulleGraphics solves the problem of providing a structured graphics layer system similar to CoreAnimation on macOS/iOS but built on the MulleUI stack. Its key features include:

- Multiple specialized layer types for different rendering needs (text, images, shapes, gradients, shadows, frame accumulation)
- Integration with the MulleCA animation system for smooth property interpolation
- Baseline-relative text rendering with proper font metrics, selection, and cursor support
- Transform-based coordinate systems and hierarchical layer trees
- CPU texture rendering for pixel-level effects
- C function draw callbacks for custom rendering

MulleGraphics is a foundational part of the MulleUI stack, sitting above MulleCA and MulleCG, and is designed to work without MulleFoundation (NSString, NSArray, etc. are not yet available in this layer).

## 2. Key Concepts & Design Philosophy

### 2.1. Layer Architecture

The library follows a hierarchical layer model where **CGGraphicsLayer** is the base class providing geometry, transforms, and basic drawing capabilities. All specialized layers inherit from this base:

- Layers contain only the necessary information to draw what they represent
- Layers should be serializable (designed to be sent over a wire and rendered identically elsewhere)
- Layout logic and user interaction should be handled by UIView, not layers
- Layers draw in their `-drawInContext:` method; layout happens separately

### 2.2. Separation of Concerns

**Drawing vs. Layout**: CGGraphicsLayer handles rendering, while layouters (implementing `CGGraphicsLayerLayouter` protocol) handle positioning and sizing logic. This separation allows:

- Reusable layout logic across different layer types
- Complex text layout without cluttering the rendering layer
- Easier testing and maintenance

**Layer vs. View**: Layers are purely for drawing; views handle events, hit-testing, and user interaction. This mimics the CoreAnimation model.

### 2.3. Baseline-Relative Text Rendering

CATextLayer uses a baseline-relative coordinate system for text:

- Y=0 is always at the text baseline (not top or bottom)
- Selection and cursor rectangles are calculated from baseline using font metrics (ascender/descender)
- Vertical positioning uses `CGContextTranslate()` with accumulated transforms
- This provides typographically correct rendering and stable alignment

### 2.4. Property Animation Integration

Observable properties can be animated via MulleCA:

- Properties marked `observable` can be animated with `CABasicAnimation`
- Custom interpolation for paint types (CGPaint, CGGradient, CGColor)
- Transaction-based animation recording (`CATransaction`)

### 2.5. Drawing Callbacks

Layers support C function callbacks for custom drawing:

- Set via `drawCallback` property
- Callback receives layer and context
- Return YES to allow layer to draw underneath, NO to preempt

### 2.6. CGContext-Based Drawing Pipeline

Drawing is done via CGContext objects, which provide a CoreGraphics-compatible API:

- `CGGraphicsLayer+MulleGraphics` conforms to `<CGRenderObject>` and optionally imports `<MulleCG/CGContext+Render.h>`
- Subclasses render via `-drawInContext:` which receives a CGContext prepared with the correct transform and alpha
- A `drawCallTracer` property (FILE*) enables per-layer tracing — set to stdout/stderr for debug, NULL (default) will not disrupt a CGContext trace

### 2.7. Memory Management

- Uses mulle_allocator for internal data structures
- MulleObjC automatic memory management for objects (no explicit retain/release)
- Proper cleanup with `_done()` functions for C structs

## 3. Core API & Data Structures

### 3.1. `CGGraphicsLayer.h` / `CGGraphicsLayer+MulleGraphics.h` - Base Graphics Layer

#### `@interface CGGraphicsLayer : CALayer`

**Purpose**: The foundational layer class providing drawing capabilities, geometry, transforms, and basic visual properties. All specialized layers inherit from this.

**Key Properties**:
- `cornerInsets`: Per-corner insets for rounded corners (MulleCornerInsets, observable)
- `borderWidth`: Border thickness (observable)
- `borderPaint`: Border stroke paint (observable, copy)
- `backgroundPaint`: Background fill (observable, copy)
- `borderColor`: Convenience for monochrome border (observable, dynamic)
- `backgroundColor`: Convenience for monochrome background (observable, dynamic)
- `rotation`: Rotation transform (CARotation, observable, assign)
- `anchorPoint`: Point within bounds used as transform origin (observable, assign)
- `pose`: Combined position and rotation (dynamic, assign)
- `position`: Computed from frame and anchorPoint (dynamic)
- `drawCallback`: C function pointer for custom drawing
- `drawCallTracer`: FILE* for tracing draw calls — set to stdout/stderr for debug, NULL (default) will not disrupt a CGContext trace
- `cornerRadius`: Uniform corner radius (dynamic, assign)
- `layouter`: Object implementing `CGGraphicsLayerLayouter` protocol (retain, nonserializable)

**Category: `CGGraphicsLayer(MulleGraphics) < CGRenderObject >`** — defines the main rendering pipeline:

```c
- (void) renderInContext:(CGContext *) ctx;
- (BOOL) drawInContext:(CGContext *) context;
- (BOOL) willDrawInContext:(CGContext *) context;
- (void) didDrawInContext:(CGContext *) context;
- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha;
- (void) drawBackgroundInContext:(CGContext *) context;
- (void) drawBorderInContext:(CGContext *) context;
- (void) fillBackgroundInContext:(CGContext *) context paint:(CGPaint *) paint;
- (CGSize) sizeThatFits:(CGSize) size context:(id <UILayoutContext>) context;
```

**Drawing Order** (in `renderInContext:`):
1. Background (if backgroundColor × opacity × alpha is not transparent)
2. `[CGContext saveState]`
3. Custom drawing via `-drawInContext:` (if bounds.size != zero)
4. `[CGContext restoreState]`
5. Border (if borderColor × opacity × alpha is not transparent)

**Global C Helpers**:
```c
void  CGGraphicsLayerSetupDrawTransform( CGGraphicsLayer *self, CGContext *context, CGRect bounds);
```

**Static inline transforms**:
```c
CGAffineTransform  CGGraphicsLayerMakeBoundsTransform( CGRect frame, CGRect bounds);
CGAffineTransform  CGGraphicsLayerMakeRotationTransform( CGRect canvas, CGPoint anchorPoint, CARotation rotation);
```

#### `CGGraphicsLayerDrawCallback_t`

```c
typedef BOOL CGGraphicsLayerDrawCallback_t( CGGraphicsLayer *layer, CGContext *context);
```
- Return YES: Layer draws underneath callback's drawing
- Return NO: Callback preempts layer's drawing

#### `CGGraphicsLayerExecuteDrawCallback` (static inline)

```c
static inline BOOL  CGGraphicsLayerExecuteDrawCallback( CGGraphicsLayer *self, CGContext *context);
```
Handles NULL-self and NULL-callback checks. Must be called from subclasses that override `drawInContext:` without calling super.

#### `@protocol CGGraphicsLayerLayouter`

```c
- (void) layoutLayer:(CGGraphicsLayer *) layer info:(struct UILayoutInfo *) info;
- (CGSize) layer:(CGGraphicsLayer *) layer sizeThatFits:(CGSize) size context:(id <UILayoutContext>) context;
- (void) dumpWithIndent:(NSUInteger) indent FILE:(FILE *) fp;
```

### 3.2. `CATextLayer.h` - Text Rendering Layer

#### `@interface CATextLayer : CGGraphicsLayer`

**Purpose**: Specialized layer for rendering short, multi-line text with selection and cursor support. Designed for labels, buttons, and text fields (not suitable for large documents with more than a screenful of lines).

**Internal ivars**:
- `_textData`: struct mulle_utf8data containing UTF-8 text buffer
- `_rowArray`: struct mulle_structarray containing CATextLayerRow structs

**Text Content Properties**:
- `textUTF8Data` / `textUTF8String`: The text to render
- `textPropertiesGenerationCount`: Cache invalidation counter (readonly)

**Font & Layout Properties** (all invalidate layout when changed):
- `fontNameUTF8String`: Font name, alphanumeric characters only (assign)
- `fontPixelSize`: Font size in pixels — INFINITY = use canvas height (observable)
- `textLineHeight`: Distance between baselines — INFINITY tracks fontPixelSize, 0 overlaps lines (observable, assign)
- `textLetterSpacing`: Horizontal spacing between characters (observable, assign, float)
- `textAlignment`: Horizontal text alignment, UITextAlignment enum (assign)
- `lineBreakMode`: How lines break, NSLineBreakMode enum — used by editor, stored here for UI setup (assign)
- `textVerticalAlignment`: Vertical positioning, UITextVerticalAlignment enum — used by editor (assign)
- `useVisualBounds`: Use actual rendered bounds (YES) vs font metrics (NO) for vertical alignment (assign, BOOL)
- `insets`: Padding insets, UIEdgeInsets (observable, assign)
- `origin`: Drawing starting point, CGPoint (observable, assign)

**Visual Properties** (observable, animatable copy):
- `textPaint`: Text color/paint, CGPaint* — drawn with colorized font image, so gradients aren't possible
- `textBackgroundPaint`: Background for ClearType — only painted if `drawsTextBackground` is YES (CGPaint*)
- `selectionPaint`: Selection highlight color (CGPaint*)
- `cursorPaint`: Cursor color (CGPaint*)
- `clearTypeEnabled`: Enable ClearType anti-aliasing (assign, getter=isClearTypeEnabled)
- `aliasPixelVisible`: Include anti-aliasing pixels in visualBounds (assign, getter=isAliasPixelVisible)
- `drawsTextBackground`: Actually paint text background (assign, BOOL)

**State Properties**:
- `selectable`: Enables selection rectangle drawing (assign, getter=isSelectable)
- `editable`: Enables editing features, used by layouter (assign, getter=isEditable)
- `editing`: Currently showing cursor (assign, getter=isEditing)
- `sizeToFitMaxSize`: Temporary constraint for sizeToFit: only — ignore in normal usage (assign, CGSize)
- `renderedFontMetrics`: Current font metrics, struct CATextLayerFontMetrics (readonly)

**Lifecycle & Core Operations**:

Text Setup (setting wipes all rows!):
```c
- (void) setTextUTF8Data:(struct mulle_utf8data) data;
- (void) setTextUTF8String:(char *) s;
- (struct mulle_utf8data) textUTF8Data;      // returns _textData, or {.characters=""} if nil
- (char *) textUTF8String;                    // returns copy if internal data has no trailing zero byte
```

Row Management:
```c
- (void) addTextLayerRows:(struct CATextLayerRow *) row count:(NSUInteger) count;
- (void) addTextLayerRow:(struct CATextLayerRow *) row;
- (NSUInteger) numberOfRows;
- (void) removeAllTextLayerRows;
```

Color Conveniences:
```c
- (void) setTextColor:(CGColor) color;
- (void) setSelectionColor:(CGColor) color;
- (void) setTextBackgroundColor:(CGColor) color;
- (void) setCursorColor:(CGColor) color;
- (CGPaint *) suggestedTextPaint;
```

Metrics & Layout:
```c
- (struct CATextLayerFontMetrics) fontMetricsWithLayoutContext:(id <UILayoutContext>) context;
- (struct CATextLayerFontMetrics) prepareLayoutContext:(id <UILayoutContext>) context;
- (CGRect) insetCanvas;
- (CGFloat) suggestedFontPixelSizeWithContext:(id <UILayoutContext>) context;
- (CGFloat) suggestedFontPixelSizeToFitTextWithContext:(id <UILayoutContext>) context;
```

Coordinate Conversion:
```c
- (NSUInteger) textOffsetForCharacterOffset:(NSUInteger) offset;    // UTF-8 byte -> UTF-32
- (NSUInteger) characterOffsetForTextOffset:(NSUInteger) offset;    // UTF-32 -> UTF-8 byte
```

Hit Testing:
```c
- (CGRect) glyphRectAtPoint:(CGPoint) point;
- (NSUInteger) characterOffsetAtPoint:(CGPoint) point;
```

Visual Bounds:
```c
- (CGRect) visualBoundsWithContext:(id <UILayoutContext>) context;
```

**Important**: The layer only displays what's in its row array. After setting text, you must populate rows (typically via layouter).

#### `struct CATextLayerRow`

```c
struct CATextLayerRow {
   NSRange                     textRange;        // Range into UTF-8 textData
   CGFloat                     selectionX;       // X position from baseline origin
   CGFloat                     selectionWidth;   // Selection width
   NSRange                     selectionRange;   // Byte range of selected text (within textData)
   CATextLayerSelectionStyle   selectionStyle;   // None or Rect
   CGFloat                     cursorX;          // X position from baseline origin
   CATextLayerCursorStyle      cursorStyle;      // None or Line
};
```

**Coordinate System**: Y=0 is at the baseline. Selection/cursor rectangles are calculated at render time:
```c
CGRect selectionRect = CGRectMake(selectionX, -ascender, selectionWidth, ascender + descender);
CGRect cursorRect = CGRectMake(cursorX, -ascender, 2.0, ascender + descender);
```

#### `enum CATextLayerCursorStyle`
- `CATextLayerCursorStyleNone`: No cursor
- `CATextLayerCursorStyleLine`: Vertical line cursor

#### `enum CATextLayerSelectionStyle`
- `CATextLayerSelectionStyleNone`: No selection
- `CATextLayerSelectionStyleRect`: Rectangular selection highlight

#### `struct CATextLayerFontMetrics`
```c
struct CATextLayerFontMetrics {
   CGFloat   fontPixelSize;
   CGFloat   textLineHeight;
};
```

### 3.3. `CATextLayerLayouter.h` - Text Layout Engine

#### `@interface CATextLayerLayouter : MulleObject`

**Purpose**: Handles complex text layout logic including line breaking, glyph positioning, selection rectangles, and cursor positioning. Separates layout concerns from rendering. Methods are forwarded to CATextLayer via `CATextLayer(CATextLayerLayouter_Forward)`.

**Protected ivars**:
- `_startSelection`: NSUInteger — selection start position
- `_debuggingFlags`: NSUInteger — bitmask for debug logging
- `_generationCount`: NSUInteger — tracks when layout needs updating
- `_rowArray`: struct mulle_structarray of CATextLayerLayouterRow
- `_rowArrayValid`: BOOL
- `_glyphArray`: struct mulle_structarray of UIGlyphPosition
- `_glyphArrayValid`: BOOL
- `_metrics`: struct CGTextMetrics — font metrics
- `_visualMetrics`: struct CGTextMetrics — visual bounds metrics (when useVisualBounds enabled)

**Properties**:
- `textLayer`: CATextLayer* — assigned, not retained (generally layer retains layouter)
- `textOffset`: CGPoint — layout tweak factor in pixels (assign)
- `textRange`: NSRange — range within UTF-8 text. location=NSNotFound for full text. Observes UTF-8 boundaries (assign)
- `selection`: NSRange — selected character range in UTF-32 offsets (assign)
- `cursorPosition`: CGPixelPoint — cursor as {x=column, y=row} (assign)

**Core Methods on CATextLayerLayouter**:
```c
- (struct mulle_utf8data) textUTF8DataInTextRange;    // Get text in textRange, zero-terminated
- (void) invalidate;                                   // Mark layout as stale (_generationCount=0)
- (CGFloat) fontAscender;                              // Valid after updateRowsAndGlyphsWithContextIfNeeded:
- (CGFloat) fontDescender;
- (CGFloat) fontLineHeight;
```

**Debug Logging** — configure via `_debuggingFlags` bitmask or the `CATextLayerLayouterDebuggingFlags` environment variable:
```c
enum {
   CATextLayerLayouterDebugCursor    = 0x01,
   CATextLayerLayouterDebugSelection = 0x02,
   CATextLayerLayouterDebugVerbose   = 0x04
};

#define CATextLayerLayouterLog( flag, format, ...) \
   do { if( self->_debuggingFlags & (flag)) \
      mulle_fprintf( stderr, "%s: " format "\n", __PRETTY_FUNCTION__, ## __VA_ARGS__); } while( 0)
```

#### `CATextLayerLayouter+Layout` — Text Layout & Origin

```c
@interface CATextLayerLayouter( Layout)
- (CGPoint) textOriginInRect:(CGRect) rect context:(id <UILayoutContext>) context;
- (CGPoint) textOriginWithContext:(id <UILayoutContext>) context;
@end
```
Forwarded to CATextLayer via `CATextLayer(CATextLayerLayouter_LayoutForward) < MulleObjCForwarding>`.

#### `CATextLayerLayouter+RowsAndGlyphs` — Glyph Positioning

```c
@interface CATextLayerLayouter( RowsAndGlyphs)
- (void) updateRowsWithContextIfNeeded:(id <UILayoutContext>) context;
- (void) updateGlyphsWithContextIfNeeded:(id <UILayoutContext>) context;
- (void) updateRowsAndGlyphsWithContextIfNeeded:(id <UILayoutContext>) context;
- (CGRect) visualBoundsWithContext:(id <UILayoutContext>) context;
- (NSUInteger) characterOffsetOfGlyphAtPoint:(CGPoint) point;
- (CAGlyphSeating) getGlyphPosition:(struct UIGlyphPosition *) glyphPosition atPoint:(CGPoint) point;
- (void) dumpRowsAndGlyphsToFILE:(FILE *) fp;
@end
```

Additional structs:
```c
typedef struct CAGlyphSeating { NSUInteger seat; NSUInteger row; } CAGlyphSeating;
#define CAGlyphSeatingNull   CAGlyphSeatingMake( NSNotFound, NSNotFound)
```

Forwarded to CATextLayer via `CATextLayer(CATextLayerLayouter_RowsAndGlyphs_Forward)`.

#### `CATextLayerLayouter+Selection` — Selection Handling

```c
@interface CATextLayerLayouter( Selection)
- (void) startSelectionAtPoint:(CGPoint) point;
- (void) adjustSelectionToPoint:(CGPoint) point;
- (void) selectAll;
- (void) deselectAll;
- (void) deleteSelection;    // removes selected text and clears selection
- (void) selectionInRow:(NSUInteger) i
              textRange:(NSRange) textRange
             selectionX:(CGFloat *) outX
          selectionWidth:(CGFloat *) outWidth;
@end
```

Forwarded to CATextLayer via `CATextLayer(CATextLayerLayouter_Selection_Forward)`.

#### `CATextLayerLayouter+Cursor` — Cursor Positioning & Editing

```c
@interface CATextLayerLayouter( Cursor)
- (CGFloat) cursorXInRow:(NSUInteger) i;
- (CGFloat) offsetNeededToMakeCursorVisible;
- (MulleCursorPosition) cursorPositionForPoint:(CGPoint) point;
- (NSUInteger) characterOffsetForCursorPosition:(MulleCursorPosition) cursor;
- (CGPoint) pointAboveCursorPosition:(MulleCursorPosition) cursor;
- (CGPoint) pointBelowCursorPosition:(MulleCursorPosition) cursor;
- (MulleCursorPosition) cursorPositionForCharacterOffset:(NSUInteger) offset;
- (MulleCursorPosition) cursorPositionForTextOffset:(NSUInteger) offset;
- (void) setCursorPositionToPoint:(CGPoint) point;
- (MulleCursorPosition) maxCursorPosition;
- (void) insertUTF32Character:(int32_t) c;    // inserts at cursor, handles selection
- (void) backspaceCharacter;                  // deletes before cursor, handles selection
- (struct MulleCursorUTF8Data) cursorUTF8Data; // splits text at cursor
@end
```

```c
struct MulleCursorUTF8Data {
   struct mulle_utf8data    dataUpToCursor;
   struct mulle_utf8data    dataAfterCursor;
};
```

Forwarded to CATextLayer via `CATextLayer(CATextLayerLayouter_Cursor_Forward)`.

#### `CATextLayerLayouter+CGGraphicsLayerLayouter` — Protocol Conformance

```c
@interface CATextLayerLayouter( CGGraphicsLayerLayouter) < CGGraphicsLayerLayouter>
- (CGSize) layer:(CGGraphicsLayer *) layer sizeThatFits:(CGSize) max context:(id <UILayoutContext>) context;
@end
```

#### `struct CATextLayerLayouterRow`
```c
struct CATextLayerLayouterRow {
   struct UITextRow   textRow;    // Text range and metrics
   NSRange            glyphRange; // Range into _glyphArray
};
```

### 3.4. `CAImageLayer.h` / `CAImageLayer+Cursor.h` - Image Rendering Layer

#### `@interface CAImageLayer : CGGraphicsLayer`

**Purpose**: Layer for displaying bitmap images or vector drawings. Supports selection, content modes, and cursor positioning.

**Ivars/Macros**: `MulleCursorIvars`, `MulleCursorProperties`, `MulleCursorInterface` — cursor mixin from MulleUIBase.

**Properties**:
- `selected`: Whether image shows selection (assign, getter=isSelected, BOOL)
- `selectionPaint`: Selection highlight color (observable, copy, CGPaint*)
- `image`: Object conforming to CGDrawable protocol (retain, NSObject<CGDrawable>*)
- `displayedRect`: Portion of image to display (assign, CGRect)
- `contentMode`: How image scales/positions within layer bounds (assign, CGContentMode)

**Lifecycle**:
```c
+ (instancetype) layerWithImage:(NSObject <CGDrawable> *) image;
- (instancetype) initWithImage:(NSObject <CGDrawable> *) image;
- (void) setSelectionColor:(CGColor) color;
```

**Future Category** (declared but not yet implemented):
```c
@interface CAImageLayer( Future) < MulleObjCFuture>
- (void) drawSelectionRect:(CGRect) canvas inContext:(CGContext *) context;
@end
```

**Category** `CAImageLayer(Cursor) <MulleCursor>`:
```c
- (MulleCursorPosition) cursorPosition;
- (NSUInteger) characterOffsetAtPoint:(CGPoint) point;
- (MulleCursorPosition) cursorPositionForPoint:(CGPoint) mouseLocation;
- (CGFloat) offsetNeededToMakeCursorVisible;
- (MulleCursorPosition) maxCursorPosition;
@end
```

### 3.5. `CAShapeLayer.h` - Shape Drawing Layer

#### `@interface CAShapeLayer : CGGraphicsLayer`

**Purpose**: Layer for rendering vector shapes using CGPath. Supports stroke and fill.

**Properties**:
- `path`: CGPath defining the shape (assign, struct CGPath*) — ownership transfers to layer
- `ownsPath`: Whether layer calls CGPathDestroy on path, default YES (assign, getter=isOwningPath)
- `strokePaint`: Stroke paint (observable, copy, CGPaint*)
- `fillPaint`: Fill paint (observable, copy, CGPaint*)
- `strokeColor`: Convenience for monochrome stroke (dynamic, CGColor)
- `fillColor`: Convenience for monochrome fill (dynamic, CGColor)
- `strokeWidth`: Stroke thickness (observable, assign, CGFloat)

**Path Ownership**: When you set `path`, ownership transfers to the layer. The layer will call `CGPathDestroy()` unless you set `ownsPath = NO`.

### 3.6. `CAGradientLayer.h` - Gradient Layer

#### `@interface CAGradientLayer : CGGraphicsLayer`

**Purpose**: Layer for rendering gradient fills. May become obsolete as backgroundPaint gains gradient support.

**Properties**:
- `paint`: CGGradient defining colors and stops (observable, copy, CGGradient*)

### 3.7. `CACPUImageLayer.h` - CPU Texture Layer

#### `@interface CACPUImageLayer : CAImageLayer`

**Purpose**: Layer for CPU-based pixel manipulation. Useful for demo effects, procedural generation, and quick prototypes. Draws to CPU memory then uploads to GPU each frame (expensive!).

**Ivars**: `_texture`: void* — CPU-side pixel buffer.

**Properties**:
- `keepsCPUTexture`: Retain CPU texture between frames (assign, BOOL)

**Core Operation** (subclass override point):
```c
- (void) drawInBytes:(void *) texture bitmapInfo:(struct CGBitmapInfo) bitmapInfo;
```
Currently the texture is always RGBA — assert bitmapInfo encoding nevertheless. Default implementation fills texture with white.

**Canvas vs Bounds**:
- `setCanvas:CGRectMake(0,0,63,32)`: Sets pixel resolution (not scaled)
- `setBounds:CGRectMake(0,0,63,32)`: Makes drawing scale to match frame

### 3.8. `CAShadowLayer.h` - Shadow Effect Layer

#### `@interface CAShadowLayer : CGGraphicsLayer`

**Purpose**: Layer that renders a shadow with configurable blur and insets. Has a "hole" where content appears.

**Properties**:
- `shadowBlur`: Blur radius (observable, assign, CGFloat)
- `shadowColor`: Shadow color (observable, assign, CGColor)
- `shadowInsets`: Defines hole in shadow (observable, assign, MulleEdgeInsets)
- `shadowHole`: Additional rectangular hole, used for UIPopUpButton menu cut-through (observable, assign, CGRect)

**Core Operations**:
```c
- (CGRect) shadowedRect;
```

### 3.9. `CAAccumulationLayer.h` - Frame Accumulation Layer

#### `@interface CAAccumulationLayer : CGGraphicsLayer`

**Purpose**: Layer that accumulates drawings over multiple frames with decay and shift effects. Useful for motion blur, trails, and demo effects.

**Ivars**:
- `_framebuffer[2]`: CGFramebuffer* — double-buffered framebuffers
- `_currentFramebufferIndex`: NSUInteger
- `_memo`: struct CGFramebufferRenderInfo

**Properties**:
- `currentFramebuffer`: CGFramebuffer* (retain, dynamic)
- `previousFramebuffer`: CGFramebuffer* (retain, dynamic)
- `previousFramebufferInsets`: Shift previous frame (assign, MulleEdgeInsets)
- `decay`: Fade factor for previous frame (assign, float)

**Core Operations**:
```c
- (void) swapFramebuffers;
- (CGRect) rectForPreviousFramebuffer:(CGFramebuffer *) layer canvas:(CGRect) canvas;
- (float) alphaForPreviousFramebuffer:(CGFramebuffer *) layer inRect:(CGRect) rect canvas:(CGRect) canvas;
- (void) drawPreviousFramebuffer:(CGFramebuffer *) layer inContext:(CGContext *) context canvas:(CGRect) canvas;
```

**Usage**: Subclass and draw normally in `-drawInContext:`. Each frame is composited with the previous frame using decay and insets.

### 3.10. Animation Categories

#### `CAAnimation+CGPaint.h` — CGPaint as interpolatable value

```c
@interface CGPaint( CAInterpolatableValue) < CAInterpolatableValue>
@end

@interface CGPaint( CAAnimation)
+ (CAAnimation *) animationFrom:(id) startObject
                                   to:(id) endObject
                             property:(struct _mulle_objc_property *) property
                              options:(struct CABasicAnimationOptions *) options;
@end
```

#### `CABasicAnimation+CGPaint.h` — Animation factory

```c
@interface CABasicAnimation( CGPaint)
+ (CABasicAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                                startCGPaint:(CGPaint *) startPaint
                                  endCGPaint:(CGPaint *) endPaint
                                     options:(struct CABasicAnimationOptions *) options;
+ (CABasicAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                                startCGImage:(CGImage *) startImage
                                  endCGImage:(CGImage *) endImage
                                     options:(struct CABasicAnimationOptions *) options;
@end
```

#### `CABasicAnimation+CGColor.h` — CGColor interpolation

```c
#define CAAnimationValueCGColor 10
static inline union CAAnimationValue CAAnimationValueMakeWithCGColor( CGColor color);

@interface CABasicAnimation( CGColor)
- (id) initWithProperty:(struct _mulle_objc_property *) property
        startColorValue:(CGColor) start
          endColorValue:(CGColor) end
                options:(struct CABasicAnimationOptions *) options;
@end

void CABasicAnimationSetInterpolatedColorAdditive( CABasicAnimation *self, id object, double x);
```

#### `CABasicAnimation+CGGradient.h` — CGGradient interpolation

```c
@interface CGGradient( CAInterpolatableValue) < CAInterpolatableValue>
@end

@interface CABasicAnimation( CGGradient)
+ (CABasicAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                             startCGGradient:(CGGradient *) startGradient
                               endCGGradient:(CGGradient *) endGradient
                                     options:(struct CABasicAnimationOptions *) options;
@end
```

### 3.11. `MulleEdgeInsets+UTF8String.h` — Debug Utility

```c
MULLE_GRAPHICS_GLOBAL
char   *MulleEdgeInsetsUTF8String( MulleEdgeInsets insets);
```

### 3.12. `MulleGraphics.h` — Umbrella Header & Version

```c
#define MULLE_GRAPHICS_VERSION  ((0UL << 20) | (8 << 8) | 1)
static inline unsigned int   MulleGraphics_get_version_major( void);
static inline unsigned int   MulleGraphics_get_version_minor( void);
static inline unsigned int   MulleGraphics_get_version_patch( void);
MULLE_GRAPHICS_GLOBAL
uint32_t   MulleGraphics_get_version( void);
```

## 4. Performance Characteristics

### 4.1. CATextLayer

**Text Layout**: O(n) where n = text length. Layout recalculates all glyphs when text or layout properties change. Not suitable for large documents.

**Rendering**: O(m) where m = number of visible rows. Uses GPU-accelerated glyph rendering.

**Cache Invalidation**: Generation counter tracks when layout must be recalculated. Properties like `fontPixelSize`, `fontNameUTF8String`, `textLetterSpacing`, `textLineHeight`, `textAlignment`, and `textUTF8Data` increment `textPropertiesGenerationCount`.

**Thread Safety**: Not thread-safe. All rendering must happen on the graphics thread.

### 4.2. CGGraphicsLayer

**Rendering**: O(1) for background/border drawing. Custom drawing performance depends on `drawInContext:` implementation.

**Transform Calculations**: O(1) for position, rotation, and scale transforms.

**Hierarchy Traversal**: O(depth) when rendering layer trees.

**Thread Safety**: Not thread-safe. Rendering must occur on graphics thread.

### 4.3. CAShapeLayer

**Path Rendering**: Depends on path complexity. Typically O(vertices).

**Thread Safety**: Not thread-safe.

### 4.4. CACPUImageLayer

**Pixel Drawing**: O(width × height) every frame. CPU to GPU upload is expensive.

**Performance Warning**: Not suitable for realtime rendering of large textures. Best for small effects or prototypes.

### 4.5. CAAccumulationLayer

**Frame Accumulation**: Double-buffered, O(pixels) per frame for compositing.

**Memory**: Requires 2× framebuffer memory.

## 5. AI Usage Recommendations & Patterns

### 5.1. Best Practices

#### Always Use Factory Methods
```c
CATextLayer *layer = [CATextLayer instance];  // ✓ Good
// NOT: [[CATextLayer alloc] init]            // ✗ Bad
```

#### Set Text Before Layout
CATextLayer requires text data before rows can be generated:
```c
[layer setTextUTF8String:"Hello"];
[layouter layoutLayer:layer info:&info];  // Generates rows
```

#### Use Layouters for Complex Text
```c
CATextLayerLayouter *layouter = [CATextLayerLayouter instance];
[layer setLayouter:layouter];
[layouter layoutLayer:layer info:&layoutInfo];
```

#### Check Generation Counts
```c
if (layouter->_generationCount != [layer textPropertiesGenerationCount])
   [layouter updateRowsAndGlyphsWithContext:context];
```

#### Use Observable Properties for Animation
Properties marked `observable` are animatable. Wrap animated changes in transactions:
```c
CATransaction *transaction = [CATransaction instance];
[transaction begin];
{
   [layer setBackgroundColor:newColor];  // Animated
}
[transaction commit];
```

#### Always Call CGGraphicsLayerExecuteDrawCallback in Subclass drawInContext:
```c
- (BOOL) drawInContext:(CGContext *) context
{
   if( ! CGGraphicsLayerExecuteDrawCallback( self, context))
      return( NO);
   // custom drawing...
   return( YES);
}
```

#### Set Drawing Callbacks in C
```c
static BOOL myDrawCallback( CGGraphicsLayer *layer, CGContext *ctx) { ... return( YES); }
[layer setDrawCallback:myDrawCallback];
```

### 5.2. Common Pitfalls

#### Don't Access Internal Fields Directly
Fields prefixed with `_` are private. Use accessor methods.

#### Don't Modify Returned Pointers
Many methods return borrowed pointers — do not free or modify them.

#### Remember Baseline-Relative Coordinates
CATextLayerRow coordinates are relative to baseline (Y=0). Selection/cursor rects use ascender/descender offsets.

#### Be Aware of Property Side Effects
Setting `textUTF8Data` wipes all rows. Repopulate via layouter.

#### CACPUImageLayer is Slow
CPU rendering uploads pixels every frame. Use sparingly for small effects only.

#### Path Ownership Matters
CAShapeLayer takes ownership of CGPath by default. Use `setOwnsPath:NO` to retain ownership.

#### Don't Skip Context Setup
Layers expect context transforms set up by `renderInContext:`. Don't call `-drawInContext:` directly unless you know what you're doing.

#### Debug Tracer Doesn't Disrupt
Setting `drawCallTracer` to NULL will not disrupt a CGContext trace — only non-NULL values enable per-layer tracing.

### 5.3. Idiomatic Usage

#### Layer Creation Pattern
```c
CATextLayer *layer = [CATextLayer instance];
[layer setFrame:CGRectMake( 10, 10, 200, 50)];
[layer setTextUTF8String:"VfL Bochum 1848"];
[layer setFontPixelSize:16.0];
[layer setTextColor:CGColorMakeBlack()];
[layer setBackgroundColor:CGColorMakeWhite()];
CATextLayerLayouter *layouter = [CATextLayerLayouter instance];
[layer setLayouter:layouter];
[layouter layoutLayer:layer info:&layoutInfo];
[layer renderInContext:context];
```

#### Text with Selection Pattern
```c
CATextLayer *layer = [CATextLayer instance];
[layer setFrame:CGRectMake( 0, 0, 200, 100)];
[layer setTextUTF8String:"Hello\nWorld"];
[layer setSelectable:YES];
[layer setSelectionColor:CGColorMakeBlue()];
CATextLayerLayouter *layouter = [CATextLayerLayouter instance];
[layer setLayouter:layouter];
[layouter setSelection:NSMakeRange( 0, 5)];
[layouter layoutLayer:layer info:&info];
```

#### Cursor & Editing Pattern
```c
CATextLayerLayouter *layouter = [CATextLayerLayouter instance];
[layer setLayouter:layouter];
[layer setEditable:YES];
[layer setEditing:YES];
// Insert text
[layouter insertUTF32Character:'A'];
[layouter insertUTF32Character:'B'];
// Delete
[layouter backspaceCharacter];
// Selection
[layouter selectAll];
[layouter deselectAll];
[layouter deleteSelection];
```

#### Shape Drawing Pattern
```c
CAShapeLayer *layer = [CAShapeLayer instance];
[layer setFrame:CGRectMake( 0, 0, 100, 100)];
CGPath *path = CGPathCreate( NULL);
CGPathMoveToPoint( path, CGPointMake( 10, 10));
CGPathAddLineToPoint( path, CGPointMake( 90, 90));
CGPathCloseSubpath( path);
[layer setPath:path];  // ownership transferred
[layer setFillColor:CGColorMakeRed()];
[layer setStrokeColor:CGColorMakeBlack()];
[layer setStrokeWidth:2.0];
[layer renderInContext:context];
```

#### Image Layer Pattern
```c
CAImageLayer *layer = [CAImageLayer layerWithImage:image];
[layer setFrame:CGRectMake( 0, 0, 200, 200)];
[layer setContentMode:CGContentModeScaleAspectFit];
[layer renderInContext:context];
```

#### Debugging Pattern
```c
[layer setDrawCallTracer:stdout];
[layer renderInContext:context];
[layer setDrawCallTracer:NULL];  // Turn off
// For text layout debugging:
// Set environment: CATextLayerLayouterDebuggingFlags=7
```

## 6. Integration Examples

### Example 1: Basic Text Rendering with Layout

```c
#import <MulleGraphics/MulleGraphics.h>

int   main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGContext            *context;
   CGRect               rect;
   struct UILayoutInfo  info;

   rect    = CGRectMake( 0, 0, 300, 100);
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];

   [layer setFrame:rect];
   [layer setFontPixelSize:24.0];
   [layer setTextAlignment:UITextAlignmentCenter];
   [layer setTextVerticalAlignment:UITextAlignmentMiddle];
   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setTextColor:CGColorMakeBlack()];
   [layer setBackgroundColor:CGColorMakeWhite()];

   layouter = [CATextLayerLayouter instance];
   [layer setLayouter:layouter];

   memset( &info, 0, sizeof( info));
   info.context = context;
   [layouter layoutLayer:layer info:&info];

   [layer renderInContext:context];

   return( 0);
}
```

### Example 2: Multi-Line Text with Selection

```c
#import <MulleGraphics/MulleGraphics.h>

int   main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGContext            *context;
   struct UILayoutInfo  info;

   context = getGraphicsContext();

   layer = [CATextLayer instance];
   [layer setFrame:CGRectMake( 50, 50, 200, 100)];
   [layer setFontPixelSize:16.0];
   [layer setLineBreakMode:NSLineBreakByWordWrapping];
   [layer setTextAlignment:UITextAlignmentLeft];
   [layer setTextUTF8String:"Line one\nLine two\nLine three"];
   [layer setSelectable:YES];
   [layer setSelectionColor:CGColorMakeRGBA( 0.3, 0.5, 1.0, 0.4)];

   layouter = [CATextLayerLayouter instance];
   [layer setLayouter:layouter];
   [layouter setSelection:NSMakeRange( 5, 12)];

   memset( &info, 0, sizeof( info));
   info.context = context;
   [layouter layoutLayer:layer info:&info];
   [layer renderInContext:context];

   return( 0);
}
```

### Example 3: Custom Shape Drawing

```c
#import <MulleGraphics/MulleGraphics.h>

int   main( void)
{
   CAShapeLayer   *layer;
   CGContext      *context;
   CGPath         *path;

   context = getGraphicsContext();

   layer = [CAShapeLayer instance];
   [layer setFrame:CGRectMake( 100, 100, 200, 200)];

   path = CGPathCreate( NULL);
   CGPathMoveToPoint( path, CGPointMake( 100, 20));
   CGPathAddLineToPoint( path, CGPointMake( 180, 180));
   CGPathAddLineToPoint( path, CGPointMake( 20, 180));
   CGPathCloseSubpath( path);

   [layer setPath:path];
   [layer setFillColor:CGColorMakeRed()];
   [layer setStrokeColor:CGColorMakeBlack()];
   [layer setStrokeWidth:3.0];

   [layer renderInContext:context];

   return( 0);
}
```

### Example 4: Animating Paint Color

```c
#import <MulleGraphics/MulleGraphics.h>

int   main( void)
{
   CATextLayer        *layer;
   CATransaction      *transaction;
   CAAnimationGroup   *group;
   CGColor            startColor;
   CGColor            endColor;

   layer = [CATextLayer instance];
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"Animated Text"];
   [layer setFontPixelSize:24.0];

   startColor = CGColorMakeBlack();
   endColor   = CGColorMakeRed();
   [layer setTextColor:startColor];

   transaction = [CATransaction instance];
   [transaction begin];
   {
      [layer setTextColor:endColor];
   }
   group = [transaction commit];

   for( NSInteger i = 0; i <= 10; i++)
   {
      [group animateObject:layer
              absoluteTime:i / 10.0
             animationRate:0.0];
   }

   return( 0);
}
```

### Example 5: CPU Texture Effect Layer

```c
#import <MulleGraphics/MulleGraphics.h>

@interface PlasmaLayer : CACPUImageLayer
{
   NSUInteger   _frame;
}
@end

@implementation PlasmaLayer
- (void) drawInBytes:(void *) texture
          bitmapInfo:(struct CGBitmapInfo) bitmapInfo
{
   CGFloat      t;
   CGRect       canvas;
   CGSize       size;
   NSUInteger   height, width, x, y;
   uint32_t     *pixels;

   pixels = texture;
   canvas = [self canvas];
   size   = canvas.size;
   width  = size.width;
   height = size.height;
   t      = _frame * 0.1;

   for( y = 0; y < height; y++)
   {
      for( x = 0; x < width; x++)
      {
         CGFloat r, g, b;
         uint8_t red, green, blue;

         r     = sin( x * 0.1 + t) * 0.5 + 0.5;
         g     = sin( y * 0.1 + t) * 0.5 + 0.5;
         b     = sin( (x + y) * 0.1 + t) * 0.5 + 0.5;
         red   = r * 255;
         green = g * 255;
         blue  = b * 255;
         pixels[ y * width + x] = (red << 0) | (green << 8) | (blue << 16) | (0xFF << 24);
      }
   }
   _frame++;
}
@end

int   main( void)
{
   CGContext     *context;
   PlasmaLayer   *layer;

   context = getGraphicsContext();

   layer = [PlasmaLayer instance];
   [layer setFrame:CGRectMake( 0, 0, 128, 128)];
   [layer setCanvas:CGRectMake( 0, 0, 128, 128)];

   for( int i = 0; i < 60; i++)
      [layer renderInContext:context];

   return( 0);
}
```

### Example 6: Custom Drawing Callback with CGImage

```c
#import <MulleGraphics/MulleGraphics.h>

static BOOL   drawCheckerboard( CGGraphicsLayer *layer, CGContext *context)
{
   CAImageLayer  *imageLayer = (CAImageLayer *) layer;
   CGImage       *image;
   uint8_t       imagedata[ 8][ 8][ 4];
   int           i, j;

   if( [imageLayer image])
      return( YES);

   for( i = 0; i < 8; i++)
   {
      for( j = 0; j < 8; j++)
      {
         uint8_t  c = ((i + j) % 2 == 0) ? 0xF8 : 0xB2;
         imagedata[ i][ j][ 0] = c;
         imagedata[ i][ j][ 1] = c;
         imagedata[ i][ j][ 2] = c;
         imagedata[ i][ j][ 3] = 0xFF;
      }
   }

   image = [[[CGImage alloc] initWithRGBABytes:imagedata
                                     bitmapSize:CGPixelSizeMake( 8, 8)
                                   textureFlags:CGImageFlagRepeatX|CGImageFlagRepeatY
                                        context:context] autorelease];
   [imageLayer setImage:image];
   return( YES);
}

int   main( void)
{
   CGContext         *context;
   CAImageLayer      *layer;

   context = getGraphicsContext();

   layer = [CAImageLayer layerWithFrame:CGRectMake( 50, 50, 200, 200)];
   [layer setDrawCallback:drawCheckerboard];
   [layer setBorderWidth:2.0];
   [layer setBorderColor:CGColorMakeBlack()];

   [layer renderInContext:context];

   return( 0);
}
```

## 7. Dependencies

MulleGraphics has the following direct dependencies (from `.mulle/etc/sourcetree/config`):

- **MulleCG**: CoreGraphics-compatible drawing API
- **MulleCA**: CoreAnimation-compatible animation framework (property interpolation, transactions)
- **mulle-objc-list**: Build system support for Objective-C class lists (no-singlephase, no-link, no-header)

### Transitive Dependencies

Through MulleCG and MulleCA, MulleGraphics indirectly depends on:

- **MulleObjC**: Objective-C runtime
- **mulle-core**: Core C libraries (container, thread, allocator, buffer, etc.)

MulleGraphics is positioned in the MulleUI stack as the drawing layer, above animation and graphics primitives, and below UI widgets and view controllers.
