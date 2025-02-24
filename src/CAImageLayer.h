#ifdef __has_include
# if __has_include( "CGGraphicsLayer.h")
#  import "CGGraphicsLayer.h"
# endif
#endif

#import "import.h"


@interface CAImageLayer : CGGraphicsLayer

// hack for textStorage, so it can be inlined in text
MULLE_CURSOR_PROPERTIES;


@property( assign, getter=isSelected) BOOL   selected;
@property( observable, copy) CGPaint *       selectionPaint;
@property( retain) NSObject <CGDrawable> *   image;
@property( assign) CGRect                    displayedRect;

// contentMode is not in UIView, because only UIImageView supports it (for now)
@property CGContentMode   contentMode;

+ (instancetype) layerWithImage:(NSObject <CGDrawable> *)  image;
- (instancetype) initWithImage:(NSObject <CGDrawable> *)  image;

- (void) setSelectionColor:(CGColor) color;

@end


@interface CAImageLayer( Future)

- (void) drawSelectionRect:(CGRect) canvas
                 inContext:(CGContext *) context;
                 
@end
