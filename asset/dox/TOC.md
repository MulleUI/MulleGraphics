# MulleGraphics Library Documentation for AI
<!-- Keywords: graphics, layers, rendering, nanovg, animation, text -->

## 1. Introduction & Purpose

MulleGraphics is a graphics layer library that provides CALayer subclasses with drawing functionality. It acts as a bridge between MulleCA (the animation framework) and MulleCG (a CoreGraphics-compatible API backed by nanovg vector graphics). The library enables rendering of shapes, images, text, gradients, and custom drawings with hardware-accelerated graphics.

MulleGraphics solves the problem of providing a structured, animatable graphics layer system similar to CoreAnimation on macOS/iOS but built on the MulleUI stack. Its key features include:

- Multiple specialized layer types for different rendering needs (text, images, shapes, gradients, OpenGL)
- Integration with the MulleCA animation system for smooth property interpolation
- Hardware-accelerated rendering via nanovg and OpenGL
- Baseline-relative text rendering with proper font metrics
- Transform-based coordinate systems and hierarchical layer trees
- CPU texture rendering for pixel-level effects

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

### 2.6. Memory Management

- Uses mulle_allocator for internal data structures (typically NULL allocator)
- MulleObjC automatic memory management for objects (no explicit retain/release)
- Proper cleanup with `_done()` functions for C structs

## 3. Core API & Data Structures

### 3.1. `CGGraphicsLayer.h` - Base Graphics Layer

#### `@interface CGGraphicsLayer : CALayer`

**Purpose**: The foundational layer class providing drawing capabilities, geometry, transforms, and basic visual properties. All specialized layers inherit from this.

**Key Properties**:
- `frame` / `bounds` (inherited from CALayer): Position and size
- `anchorPoint`: Point within bounds used as transform origin (default {0.5, 0.5})
- `position`: Computed from frame and anchorPoint
- `rotation`: Rotation transform (CARotation type)
- `pose`: Combined position and rotation (dynamic property)
- `backgroundPaint`: Background fill (CGPaint or gradient)
- `backgroundColor`: Convenience for monochrome background (observable, animatable)
- `borderPaint`: Border stroke paint
- `borderColor`: Convenience for monochrome border (observable, animatable)
- `borderWidth`: Border thickness
- `cornerInsets`: Per-corner insets for rounded corners
- `cornerRadius`: Uniform corner radius (dynamic property)
- `layouter`: Object implementing `CGGraphicsLayerLayouter` protocol
- `drawCallback`: C function pointer for custom drawing
- `drawCallTracer`: FILE* for tracing draw calls (set to stdout/stderr for debugging)

**Lifecycle**:
- `+layerWithFrame:` / `+instance`: Factory methods (preferred over alloc/init)
- `-initWithFrame:`: Designated initializer

**Core Operations**:
- `-renderInContext:`: Main rendering method (sets up transforms, calls draw methods in order)
- `-drawInContext:`: Override point for custom drawing (default calls drawCallback)
- `-drawBackgroundInContext:`: Draws background (called by renderInContext)
- `-drawBorderInContext:`: Draws border (called by renderInContext)

**Drawing Order** (in renderInContext):
1. Background (if backgroundColor * opacity * alpha is not transparent)
2. [CGContext saveState]
3. Custom drawing via `-drawInContext:` (if bounds.size != zero)
4. [CGContext restoreState]
5. Border (if borderColor * opacity * alpha is not transparent)

**Usage Pattern**:
```c
CGGraphicsLayer *layer = [CGGraphicsLayer layerWithFrame:CGRectMake(0, 0, 100, 100)];
[layer setBackgroundColor:CGColorMakeRed()];
[layer setBorderWidth:2.0];
[layer setBorderColor:CGColorMakeBlack()];
[layer renderInContext:context];
```

#### `CGGraphicsLayerDrawCallback_t`

**Purpose**: C function pointer type for custom drawing callbacks.

```c
typedef BOOL CGGraphicsLayerDrawCallback_t(CGGraphicsLayer *layer, CGContext *context);
```

- Return YES: Layer draws underneath callback's drawing
- Return NO: Callback preempts layer's drawing

#### `@protocol CGGraphicsLayerLayouter`

**Purpose**: Protocol for objects that handle layer layout logic.

**Methods**:
- `-layoutLayer:info:`: Perform layout on layer with given UILayoutInfo
- `-layer:sizeThatFits:context:`: Calculate appropriate size for content
- `-dumpWithIndent:FILE:`: Debug output

### 3.2. `CATextLayer.h` - Text Rendering Layer

#### `@interface CATextLayer : CGGraphicsLayer`

**Purpose**: Specialized layer for rendering short, multi-line text with selection and cursor support. Designed for labels, buttons, and text fields (not suitable for large documents with more than a screenful of lines).

**Internal Storage**:
- `_textData`: mulle_utf8data containing UTF-8 text buffer
- `_rowArray`: mulle_structarray containing CATextLayerRow structs

**Text Content Properties**:
- `textUTF8Data` / `textUTF8String`: The text to render
- `textPropertiesGenerationCount`: Cache invalidation counter (readonly)

**Font & Layout Properties** (all invalidate layout when changed):
- `fontNameUTF8String`: Font name (alphanumeric characters only)
- `fontPixelSize`: Font size in pixels (INFINITY = use canvas height)
- `textLineHeight`: Distance between baselines (INFINITY = track fontPixelSize)
- `textLetterSpacing`: Horizontal spacing between characters
- `textAlignment`: Horizontal text alignment (UITextAlignment enum)
- `lineBreakMode`: How lines break (NSLineBreakMode enum)
- `textVerticalAlignment`: Vertical positioning mode (UITextVerticalAlignment enum)
- `useVisualBounds`: Use actual rendered bounds (YES) vs font metrics (NO) for vertical alignment
- `insets`: Padding insets (UIEdgeInsets)
- `origin`: Drawing starting point (CGPoint)

**Visual Properties** (observable, animatable):
- `textPaint`: Text color/paint (CGPaint)
- `textBackgroundPaint`: Background for ClearType (CGPaint)
- `selectionPaint`: Selection highlight color (CGPaint)
- `cursorPaint`: Cursor color (CGPaint)
- `clearTypeEnabled`: Enable ClearType anti-aliasing (BOOL)
- `aliasPixelVisible`: Include anti-aliasing pixels in visualBounds (BOOL)
- `drawsTextBackground`: Actually paint text background (BOOL)

**State Properties**:
- `selectable`: Enables selection rectangle drawing
- `editable`: Enables editing features (used by layouter)
- `editing`: Currently showing cursor
- `sizeToFitMaxSize`: Temporary constraint for sizeToFit: (ignore in normal usage)
- `renderedFontMetrics`: Current font metrics (CATextLayerFontMetrics, readonly)

**Lifecycle & Core Operations**:

Text Setup:
```c
// Set text content (wipes all rows!)
- (void) setTextUTF8Data:(struct mulle_utf8data) data;
- (void) setTextUTF8String:(char *) s;  // convenience
- (struct mulle_utf8data) textUTF8Data;
- (char *) textUTF8String;  // returns copy if internal data has no trailing zero
```

Row Management:
```c
- (void) addTextLayerRows:(struct CATextLayerRow *) row count:(NSUInteger) count;
- (void) addTextLayerRow:(struct CATextLayerRow *) row;
- (NSUInteger) numberOfRows;
- (void) removeAllTextLayerRows;
```

**Important**: The layer only displays what's in its row array. After setting text, you must populate rows (typically via layouter).

Color Conveniences:
```c
- (void) setTextColor:(CGColor) color;
- (void) setSelectionColor:(CGColor) color;
- (void) setTextBackgroundColor:(CGColor) color;
- (void) setCursorColor:(CGColor) color;
- (CGPaint *) suggestedTextPaint;  // Suggests visible color based on background
```

Metrics & Layout:
```c
- (struct CATextLayerFontMetrics) fontMetricsWithLayoutContext:(id <UILayoutContext>) context;
- (struct CATextLayerFontMetrics) prepareLayoutContext:(id <UILayoutContext>) context;
- (CGRect) insetCanvas;  // Canvas minus insets
- (CGFloat) suggestedFontPixelSizeWithContext:(id <UILayoutContext>) context;
- (CGFloat) suggestedFontPixelSizeToFitTextWithContext:(id <UILayoutContext>) context;
```

Coordinate Conversion:
```c
// UTF-8 byte offset ↔ UTF-32 character offset
- (NSUInteger) textOffsetForCharacterOffset:(NSUInteger) offset;
- (NSUInteger) characterOffsetForTextOffset:(NSUInteger) offset;
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

#### `struct CATextLayerRow`

**Purpose**: Represents one line of text with selection and cursor information. Coordinates are baseline-relative.

```c
struct CATextLayerRow {
   NSRange                     textRange;        // Range into UTF-8 textData
   
   CGFloat                     selectionX;       // X position from baseline origin
   CGFloat                     selectionWidth;   // Selection width
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

**Purpose**: Font sizing information.

```c
struct CATextLayerFontMetrics {
   CGFloat fontPixelSize;
   CGFloat textLineHeight;
};
```

### 3.3. `CATextLayerLayouter.h` - Text Layout Engine

#### `@interface CATextLayerLayouter : MulleObject`

**Purpose**: Handles complex text layout logic including line breaking, glyph positioning, selection rectangles, and cursor positioning. Separates layout concerns from rendering.

**Internal State**:
- `_rowArray`: mulle_structarray of CATextLayerLayouterRow (layout-side rows with glyphs)
- `_glyphArray`: mulle_structarray of glyph position data
- `_rowArrayValid` / `_glyphArrayValid`: Cache validity flags
- `_generationCount`: Tracks when layout needs updating
- `_metrics` / `_visualMetrics`: Font and visual bounds metrics
- `_startSelection`: Selection start position

**Properties**:
- `textLayer`: The CATextLayer being laid out (assign, not retained)
- `textOffset`: Layout offset tweak in pixels (CGPoint)
- `textRange`: Range within UTF-8 data to layout (NSRange, location=NSNotFound for full text)
- `selection`: Selected character range in UTF-32 offsets (NSRange)
- `cursorPosition`: Cursor location as {x=column, y=row} (CGPixelPoint)

**Core Operations**:

```c
- (struct mulle_utf8data) textUTF8DataInTextRange;  // Get text in textRange
- (void) invalidate;  // Mark layout as stale

// Font metrics (valid after updateRowsAndGlyphsWithContextIfNeeded:)
- (CGFloat) fontAscender;
- (CGFloat) fontDescender;
- (CGFloat) fontLineHeight;
```

**Layouter Categories** (methods defined in separate files):

**CATextLayerLayouter+Layout**: Text layout and origin calculation
- `-textOriginInRect:context:`: Calculate drawing origin for text
- `-textOriginWithContext:`: Convenience using layer's inset canvas

**CATextLayerLayouter+RowsAndGlyphs**: Glyph positioning and row generation
- `-updateRowsAndGlyphsWithContext:`: Main layout method, populates layer rows
- `-updateRowsAndGlyphsWithContextIfNeeded:`: Cached version

**CATextLayerLayouter+Selection**: Selection rectangle calculation
- Methods for computing selection spans across multiple rows

**CATextLayerLayouter+Cursor**: Cursor positioning
- Methods for placing cursor at character offsets

**CATextLayerLayouter+CGGraphicsLayerLayouter**: Protocol conformance
- Implements `CGGraphicsLayerLayouter` protocol

**Usage Pattern**:
```c
CATextLayer *layer = [CATextLayer instance];
CATextLayerLayouter *layouter = [CATextLayerLayouter instance];
[layer setLayouter:layouter];
[layer setTextUTF8String:"Multi\nLine\nText"];
[layouter layoutLayer:layer info:&layoutInfo];
// Now layer has populated rows and is ready to render
```

#### `struct CATextLayerLayouterRow`

**Purpose**: Internal layout-side row structure with glyph information.

```c
struct CATextLayerLayouterRow {
   struct UITextRow textRow;  // Text range and metrics
   NSRange glyphRange;        // Range into _glyphArray
};
```

### 3.4. `CAImageLayer.h` - Image Rendering Layer

#### `@interface CAImageLayer : CGGraphicsLayer`

**Purpose**: Layer for displaying bitmap images or vector drawings. Supports selection, content modes, and cursor positioning.

**Properties**:
- `image`: Object conforming to CGDrawable protocol (CGImage or CGImage wrapper)
- `displayedRect`: Portion of image to display (CGRect)
- `contentMode`: How image scales/positions within layer bounds (CGContentMode enum)
- `selected`: Whether image shows selection (BOOL)
- `selectionPaint`: Selection highlight color (CGPaint)

**Lifecycle**:
```c
+ (instancetype) layerWithImage:(NSObject <CGDrawable> *) image;
- (instancetype) initWithImage:(NSObject <CGDrawable> *) image;
```

**Conveniences**:
```c
- (void) setSelectionColor:(CGColor) color;
```

**Cursor Support**: CAImageLayer includes cursor mixin:
- `MulleCursorIvars` / `MulleCursorProperties` / `MulleCursorInterface`: Macros providing cursor behavior (see MulleUIBase)

**Future Methods** (category):
```c
- (void) drawSelectionRect:(CGRect) canvas inContext:(CGContext *) context;
```

### 3.5. `CAShapeLayer.h` - Shape Drawing Layer

#### `@interface CAShapeLayer : CGGraphicsLayer`

**Purpose**: Layer for rendering vector shapes using CGPath. Supports stroke and fill.

**Properties**:
- `path`: CGPath defining the shape (struct CGPath *)
- `ownsPath`: Whether layer calls CGPathDestroy on path (default YES)
- `strokePaint` / `strokeColor`: Stroke paint (observable, animatable)
- `fillPaint` / `fillColor`: Fill paint (observable, animatable)
- `strokeWidth`: Stroke thickness (observable)

**Path Ownership**: When you set `path`, ownership transfers to the layer. The layer will call `CGPathDestroy()` unless you set `ownsPath = NO`.

**Usage Pattern**:
```c
CAShapeLayer *layer = [CAShapeLayer layerWithFrame:CGRectMake(0, 0, 100, 100)];
CGPath *path = CGPathCreate(NULL);
CGPathMoveToPoint(path, CGPointMake(10, 10));
CGPathAddLineToPoint(path, CGPointMake(90, 90));
CGPathCloseSubpath(path);
[layer setPath:path];  // ownership transferred
[layer setStrokeColor:CGColorMakeBlue()];
[layer setStrokeWidth:2.0];
[layer setFillColor:CGColorMakeRed()];
```

### 3.6. `CAGradientLayer.h` - Gradient Layer

#### `@interface CAGradientLayer : CGGraphicsLayer`

**Purpose**: Layer for rendering gradient fills. May become obsolete as backgroundPaint gains gradient support.

**Properties**:
- `paint`: CGGradient defining colors and stops (observable, animatable)

**Usage Pattern**:
```c
CAGradientLayer *layer = [CAGradientLayer layerWithFrame:CGRectMake(0, 0, 200, 200)];
CGGradient *gradient = [CGGradient gradientWithStartColor:CGColorMakeRed()
                                                 endColor:CGColorMakeBlue()];
[layer setPaint:gradient];
```

### 3.7. `CAOpenGLLayer.h` - OpenGL Drawing Layer

#### `@interface CAOpenGLLayer : CGGraphicsLayer`

**Purpose**: Layer for custom OpenGL ES rendering. Handles viewport setup and provides hooks for raw OpenGL commands.

**Properties**:
- `viewPort`: Current OpenGL viewport (CGRect, readonly)
- `scissor`: Current scissor rectangle (CGRect, readonly)
- `viewPortDidChangeCallback`: C function called when viewport changes

**Core Operations**:
```c
- (void) beginOpenGLWithContext:(CGContext *) context;   // Setup viewport/scissor
- (void) drawOpenGLInContext:(CGContext *) context;      // Override for OpenGL drawing
- (void) endOpenGLWithContext:(CGContext *) context;     // Flush
- (void) viewPortDidChange:(CGContext *) context;        // Called after viewport setup
```

**Background Behavior**:
```c
- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha;  // Always YES for texture mapping
```

**Usage Pattern**: Subclass and override `-drawOpenGLInContext:` for custom OpenGL rendering. The layer manages viewport and projection setup.

### 3.8. `CACPUImageLayer.h` - CPU Texture Layer

#### `@interface CACPUImageLayer : CAImageLayer`

**Purpose**: Layer for CPU-based pixel manipulation. Useful for demo effects, procedural generation, and quick prototypes. Draws to CPU memory then uploads to GPU each frame (expensive!).

**Properties**:
- `keepsCPUTexture`: Retain CPU texture between frames (BOOL)

**Core Operations**:
```c
// Override this to do pixel-level drawing
- (void) drawInBytes:(void *) texture bitmapInfo:(struct CGBitmapInfo) bitmapInfo;
```

**Canvas vs Bounds**:
- `setCanvas:CGRectMake(0,0,63,32)`: Sets pixel resolution (not scaled)
- `setBounds:CGRectMake(0,0,63,32)`: Makes drawing scale to match frame

**Usage Pattern**:
```c
@interface MyEffectLayer : CACPUImageLayer
@end

@implementation MyEffectLayer

- (void) drawInBytes:(void *) texture bitmapInfo:(struct CGBitmapInfo) bitmapInfo
{
   uint32_t *pixels = texture;
   // Assert bitmapInfo.encoding == CGBitmapInfoRGBA (currently always true)
   
   for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
         pixels[y * width + x] = 0xFF0000FF;  // Red
      }
   }
}

@end
```

### 3.9. `CAShadowLayer.h` - Shadow Effect Layer

#### `@interface CAShadowLayer : CGGraphicsLayer`

**Purpose**: Layer that renders a shadow with configurable blur and insets. The shadow has a "hole" for content.

**Properties**:
- `shadowBlur`: Blur radius (observable)
- `shadowColor`: Shadow color (observable)
- `shadowInsets`: Defines hole in shadow (MulleEdgeInsets, observable)
- `shadowHole`: Additional rectangular hole (CGRect, observable)

**Core Operations**:
```c
- (CGRect) shadowedRect;  // Calculate rectangle being shadowed
```

**Usage**: Place shadow layer behind content layer. The `shadowInsets` define where content appears through the shadow.

### 3.10. `CAAccumulationLayer.h` - Frame Accumulation Layer

#### `@interface CAAccumulationLayer : CGGraphicsLayer`

**Purpose**: Layer that accumulates drawings over multiple frames with decay and shift effects. Useful for motion blur, trails, and demo effects.

**Properties**:
- `currentFramebuffer` / `previousFramebuffer`: Double-buffered framebuffers (dynamic)
- `previousFramebufferInsets`: Shift previous frame (MulleEdgeInsets)
- `decay`: Fade factor for previous frame (float)

**Core Operations**:
```c
- (void) swapFramebuffers;
- (CGRect) rectForPreviousFramebuffer:(CGFramebuffer *) layer canvas:(CGRect) canvas;
- (float) alphaForPreviousFramebuffer:(CGFramebuffer *) layer inRect:(CGRect) rect canvas:(CGRect) canvas;
- (void) drawPreviousFramebuffer:(CGFramebuffer *) layer inContext:(CGContext *) context canvas:(CGRect) canvas;
```

**Usage Pattern**: Subclass and draw normally in `-drawInContext:`. Each frame is composited with the previous frame using decay and insets.

### 3.11. Animation Categories

#### `CAAnimation+CGPaint.h`, `CABasicAnimation+CGPaint.h`

**Purpose**: Enable animation of CGPaint, CGColor, and CGGradient properties.

**Protocol Conformance**:
```c
@interface CGPaint (CAInterpolatableValue) <CAInterpolatableValue>
@end
```

**Animation Creation**:
```c
@interface CGPaint (CAAnimation)
+ (CAAnimation *) createAnimationFrom:(id) startObject
                                   to:(id) endObject
                             property:(struct _mulle_objc_property *) property
                              options:(struct CABasicAnimationOptions *) options;
@end
```

**Similar categories exist for**:
- `CABasicAnimation+CGColor.h`
- `CABasicAnimation+CGGradient.h`

**Usage Pattern**:
```c
CATextLayer *layer = [CATextLayer instance];
CGPaint *start = [CGPaint paintWithColor:CGColorMakeBlack()];
CGPaint *end = [CGPaint paintWithColor:CGColorMakeRed()];

CATransaction *transaction = [CATransaction instance];
[transaction begin];
{
   [layer setTextColor:end];  // Creates animation from current to end
}
CAAnimationGroup *group = [transaction commit];
```

### 3.12. `MulleEdgeInsets+UTF8String.h`

**Purpose**: Utility for debug output of insets.

```c
char *MulleEdgeInsetsUTF8String(MulleEdgeInsets insets);
```

## 4. Performance Characteristics

### 4.1. CATextLayer

**Text Layout**: O(n) where n = text length. Layout recalculates all glyphs when text or layout properties change. Not suitable for large documents.

**Rendering**: O(m) where m = number of visible rows. Uses nanovg for GPU-accelerated glyph rendering.

**Cache Invalidation**: Generation counter tracks when layout must be recalculated. Properties like `fontPixelSize`, `fontNameUTF8String`, `textLetterSpacing`, `textLineHeight`, `textAlignment`, and `textUTF8Data` increment `textPropertiesGenerationCount`.

**Thread Safety**: Not thread-safe. All rendering must happen on the graphics thread.

### 4.2. CGGraphicsLayer

**Rendering**: O(1) for background/border drawing. Custom drawing performance depends on `drawInContext:` implementation.

**Transform Calculations**: O(1) for position, rotation, and scale transforms.

**Hierarchy Traversal**: O(depth) when rendering layer trees.

**Thread Safety**: Not thread-safe. Rendering must occur on graphics thread.

### 4.3. CAShapeLayer

**Path Rendering**: Depends on path complexity. Nanovg uses tessellation for GPU rendering, typically O(vertices).

**Thread Safety**: Not thread-safe.

### 4.4. CACPUImageLayer

**Pixel Drawing**: O(width × height) every frame. CPU to GPU upload is expensive.

**Performance Warning**: Not suitable for realtime rendering of large textures. Best for small effects or prototypes.

### 4.5. CAOpenGLLayer

**Rendering**: Performance depends entirely on OpenGL code. Direct GPU rendering can be very fast.

**Thread Safety**: OpenGL context must be current on calling thread.

### 4.6. CAAccumulationLayer

**Frame Accumulation**: Double-buffered, O(pixels) per frame for compositing.

**Memory**: Requires 2× framebuffer memory.

## 5. AI Usage Recommendations & Patterns

### 5.1. Best Practices

#### Always Use Factory Methods
Prefer `+instance` or specific factory methods over `+alloc`/`-init`:
```c
CATextLayer *layer = [CATextLayer instance];  // ✓ Good
// NOT: [[CATextLayer alloc] init]  // ✗ Bad
```

#### Set Text Before Layout
CATextLayer requires text data before rows can be generated:
```c
[layer setTextUTF8String:"Hello"];
[layouter layoutLayer:layer info:&info];  // Generates rows
// Now layer can render
```

#### Use Layouters for Complex Text
Don't manually calculate glyph positions. Use CATextLayerLayouter:
```c
CATextLayerLayouter *layouter = [CATextLayerLayouter instance];
[layer setLayouter:layouter];
[layouter layoutLayer:layer info:&layoutInfo];
```

#### Check Generation Counts
Avoid redundant layout by checking generation counts:
```c
if (layouter->_generationCount != [layer textPropertiesGenerationCount]) {
   [layouter updateRowsAndGlyphsWithContext:context];
}
```

#### Use Observable Properties for Animation
Mark properties `observable` if they should be animatable:
```c
@property (observable, assign) CGFloat borderWidth;
```

#### Wrap OpenGL in Save/Restore
When calling `renderInContext:` from custom code, wrap in state save:
```c
CGContextSave(context);
[layer renderInContext:context];
CGContextRestore(context);
```

#### Set Drawing Callbacks in C
For maximum performance, use C callbacks instead of overriding:
```c
static BOOL myDrawCallback(CGGraphicsLayer *layer, CGContext *ctx) {
   // Custom drawing
   return YES;  // Let layer draw underneath
}

[layer setDrawCallback:myDrawCallback];
```

### 5.2. Common Pitfalls

#### Don't Access Internal Fields Directly
Fields prefixed with `_` are private. Use accessor methods:
```c
char *text = [layer textUTF8String];  // ✓ Good
// NOT: char *text = layer->_textData.characters;  // ✗ Bad
```

#### Don't Modify Returned Pointers
Many methods return borrowed pointers. Don't free or modify:
```c
char *text = [layer textUTF8String];
// Don't free(text) or modify it!
```

#### Remember Baseline-Relative Coordinates
CATextLayerRow coordinates are relative to baseline (Y=0):
```c
// Selection rect must account for ascender/descender
CGRect rect = CGRectMake(row->selectionX, -ascender, 
                        row->selectionWidth, ascender + descender);
```

#### Don't Skip Context Setup
Layers expect context transforms to be set up by `renderInContext:`. Don't call `-drawInContext:` directly unless you know what you're doing.

#### Be Aware of Property Side Effects
Setting `textUTF8Data` wipes all rows:
```c
[layer setTextUTF8String:"New text"];
// All rows are gone! Must repopulate via layouter
```

#### CACPUImageLayer is Slow
CPU rendering uploads pixels every frame. Use sparingly:
```c
// OK for 64x32 demo effects
// NOT OK for 1920x1080 realtime rendering
```

#### Path Ownership Matters
CAShapeLayer takes ownership of CGPath:
```c
CGPath *path = CGPathCreate(NULL);
CGPathAddLineToPoint(path, CGPointMake(100, 100));
[layer setPath:path];
// Don't call CGPathDestroy(path)! Layer owns it now.
```

To keep ownership:
```c
[layer setOwnsPath:NO];
[layer setPath:path];
// Now you must CGPathDestroy(path) yourself
```

#### Animation Transaction Pattern
Always wrap animated property changes in transactions:
```c
CATransaction *transaction = [CATransaction instance];
[transaction begin];
{
   [layer setBackgroundColor:newColor];  // Animated
}
CAAnimationGroup *group = [transaction commit];
```

### 5.3. Idiomatic Usage

#### Layer Creation Pattern
```c
// Create with frame
CATextLayer *layer = [CATextLayer instance];
[layer setFrame:CGRectMake(10, 10, 200, 50)];

// Configure visual properties
[layer setTextUTF8String:"VfL Bochum 1848"];
[layer setFontPixelSize:16.0];
[layer setTextColor:CGColorMakeBlack()];
[layer setBackgroundColor:CGColorMakeWhite()];

// Add layouter
CATextLayerLayouter *layouter = [CATextLayerLayouter instance];
[layer setLayouter:layouter];

// Layout and render
[layouter layoutLayer:layer info:&layoutInfo];
[layer renderInContext:context];
```

#### Text with Selection Pattern
```c
CATextLayer *layer = [CATextLayer instance];
[layer setFrame:CGRectMake(0, 0, 200, 100)];
[layer setTextUTF8String:"Hello\nWorld"];
[layer setSelectable:YES];
[layer setSelectionColor:CGColorMakeBlue()];

CATextLayerLayouter *layouter = [CATextLayerLayouter instance];
[layer setLayouter:layouter];
[layouter setSelection:NSMakeRange(0, 5)];  // Select "Hello"

[layouter layoutLayer:layer info:&info];
// Selection rectangles are now in layer rows
```

#### Custom Drawing Pattern
```c
static BOOL customDraw(CGGraphicsLayer *layer, CGContext *ctx) {
   NVGcontext *vg = CGContextGetNVGContext(ctx);
   
   nvgBeginPath(vg);
   nvgCircle(vg, 50, 50, 40);
   nvgFillColor(vg, nvgRGBA(255, 0, 0, 255));
   nvgFill(vg);
   
   return YES;  // Let layer draw background/border
}

CGGraphicsLayer *layer = [CGGraphicsLayer instance];
[layer setDrawCallback:customDraw];
[layer setBackgroundColor:CGColorMakeWhite()];
[layer renderInContext:context];
```

#### Shape Drawing Pattern
```c
CAShapeLayer *layer = [CAShapeLayer instance];
[layer setFrame:CGRectMake(0, 0, 100, 100)];

CGPath *path = CGPathCreate(NULL);
CGPathMoveToPoint(path, CGPointMake(10, 10));
CGPathAddLineToPoint(path, CGPointMake(90, 10));
CGPathAddLineToPoint(path, CGPointMake(50, 90));
CGPathCloseSubpath(path);
[layer setPath:path];

[layer setFillColor:CGColorMakeRed()];
[layer setStrokeColor:CGColorMakeBlack()];
[layer setStrokeWidth:2.0];

[layer renderInContext:context];
```

#### Image Layer Pattern
```c
CGImage *image = CGImageCreateWithContentsOfFile("image.png");
CAImageLayer *layer = [CAImageLayer layerWithImage:image];
[layer setFrame:CGRectMake(0, 0, 200, 200)];
[layer setContentMode:CGContentModeScaleAspectFit];
[layer renderInContext:context];
```

#### Debugging Pattern
```c
// Enable draw call tracing
[layer setDrawCallTracer:stdout];
[layer renderInContext:context];
[layer setDrawCallTracer:NULL];  // Turn off
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
   
   // Setup
   rect    = CGRectMake( 0, 0, 300, 100);
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];
   
   // Configure text layer
   [layer setFrame:rect];
   [layer setFontPixelSize:24.0];
   [layer setTextAlignment:UITextAlignmentCenter];
   [layer setTextVerticalAlignment:UITextAlignmentMiddle];
   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setTextColor:CGColorMakeBlack()];
   [layer setBackgroundColor:CGColorMakeWhite()];
   
   // Attach layouter
   layouter = [CATextLayerLayouter instance];
   [layer setLayouter:layouter];
   
   // Layout
   memset( &info, 0, sizeof( info));
   info.context = context;
   [layouter layoutLayer:layer info:&info];
   
   // Render
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
   
   // Create context (assume CGContext is properly initialized)
   context = getGraphicsContext();
   
   layer = [CATextLayer instance];
   [layer setFrame:CGRectMake( 50, 50, 200, 100)];
   [layer setFontPixelSize:16.0];
   [layer setLineBreakMode:NSLineBreakByWordWrapping];
   [layer setTextAlignment:UITextAlignmentLeft];
   [layer setTextVerticalAlignment:UITextAlignmentTop];
   
   // Multi-line text
   [layer setTextUTF8String:"Line one\nLine two\nLine three"];
   
   // Enable selection
   [layer setSelectable:YES];
   [layer setSelectionColor:CGColorMakeRGBA( 0.3, 0.5, 1.0, 0.4)];
   
   // Setup layouter with selection
   layouter = [CATextLayerLayouter instance];
   [layer setLayouter:layouter];
   [layouter setSelection:NSMakeRange( 5, 12)];  // Select across lines
   
   // Layout and render
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
   
   // Create triangle path
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
   
   // Begin animation transaction
   transaction = [CATransaction instance];
   [transaction begin];
   {
      [layer setTextColor:endColor];  // Animates from current to end
   }
   group = [transaction commit];
   
   // Now animate over time
   for( NSInteger i = 0; i <= 10; i++)
   {
      [group animateObject:layer 
              absoluteTime:i / 10.0
             animationRate:0.0];
      // Render at this frame...
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
   NSUInteger   height;
   NSUInteger   width;
   NSUInteger   x;
   NSUInteger   y;
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
         CGFloat r;
         CGFloat g;
         CGFloat b;
         uint8_t red;
         uint8_t green;
         uint8_t blue;
         
         r     = sin( x * 0.1 + t) * 0.5 + 0.5;
         g     = sin( y * 0.1 + t) * 0.5 + 0.5;
         b     = sin( (x + y) * 0.1 + t) * 0.5 + 0.5;
         red   = r * 255;
         green = g * 255;
         blue  = b * 255;
         
         pixels[ y * width + x] = (red << 0) | (green << 8) | 
                                 (blue << 16) | (0xFF << 24);
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
   
   // Render animation loop
   for( int i = 0; i < 60; i++)
   {
      [layer renderInContext:context];
   }
   
   return( 0);
}
```

### Example 6: Custom Drawing Callback

```c
#import <MulleGraphics/MulleGraphics.h>

static BOOL   drawCheckerboard( CGGraphicsLayer *layer, CGContext *context)
{
   CGRect       bounds;
   CGSize       size;
   NVGcontext   *vg;
   int          i;
   int          j;
   int          nx;
   int          ny;
   
   vg     = CGContextGetNVGContext( context);
   bounds = [layer bounds];
   size   = bounds.size;
   nx     = 8;
   ny     = 8;
   
   for( i = 0; i < nx; i++)
   {
      for( j = 0; j < ny; j++)
      {
         CGFloat   x;
         CGFloat   y;
         CGFloat   w;
         CGFloat   h;
         
         x = i * size.width / nx;
         y = j * size.height / ny;
         w = size.width / nx;
         h = size.height / ny;
         
         nvgBeginPath( vg);
         nvgRect( vg, x, y, w, h);
         
         if( (i + j) % 2 == 0)
            nvgFillColor( vg, nvgRGBA( 200, 200, 200, 255));
         else
            nvgFillColor( vg, nvgRGBA( 100, 100, 100, 255));
         
         nvgFill( vg);
      }
   }
   
   return( YES);  // Allow layer to draw border if set
}

int   main( void)
{
   CGContext         *context;
   CGGraphicsLayer   *layer;
   
   context = getGraphicsContext();
   
   layer = [CGGraphicsLayer instance];
   [layer setFrame:CGRectMake( 50, 50, 200, 200)];
   [layer setDrawCallback:drawCheckerboard];
   [layer setBorderWidth:2.0];
   [layer setBorderColor:CGColorMakeBlack()];
   
   [layer renderInContext:context];
   
   return( 0);
}
```

## 7. Dependencies

MulleGraphics has the following direct dependencies in the mulle-sde project tree:

- **MulleCG**: CoreGraphics-compatible drawing API backed by nanovg (vector graphics rendering)
- **MulleCA**: CoreAnimation-compatible animation framework (property interpolation, transactions)
- **mulle-objc-list**: Build system support for Objective-C class lists

### Transitive Dependencies

Through MulleCG and MulleCA, MulleGraphics indirectly depends on:

- **MulleObjC**: Objective-C runtime
- **mulle-core**: Core C libraries (container, thread, allocator, buffer, etc.)
- **nanovg**: Vector graphics library (OpenGL-based)
- **freetype**: Font rendering
- **glfw**: Window and OpenGL context management (for standalone testing)

MulleGraphics is positioned in the MulleUI stack as the drawing layer, above animation and graphics primitives, and below UI widgets and view controllers.
