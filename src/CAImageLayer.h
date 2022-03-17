#ifdef __has_include
# if __has_include( "CALayer.h")
#  import "CALayer.h"
# endif
#endif

#import "import.h"

#import "MulleCursorProtocol.h"


@interface CAImageLayer : CALayer

// hack for textStorage, so it can be inlined in text
MULLE_CURSOR_PROPERTIES;


@property( assign, getter=isSelected) BOOL   selected;
@property( observable) CGColor               selectionColor;
@property( retain) NSObject <CGDrawable> *   image;

// contentMode is not in UIView, because only UIImageView supports it (for now)
@property CGContentMode   contentMode;

@end


@interface CAImageLayer( Future)

- (void) drawSelectionRect:(CGRect) canvas
                 inContext:(CGContext *) context;
                 
@end
