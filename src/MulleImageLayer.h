#import "CALayer.h"

#import "MulleCursorProtocol.h"


@interface MulleImageLayer : CALayer <CAImageLayer, MulleCursor>
{
	NSObject <CGImage>   *_image;
}

// hack for textStorage, so it can be inlined in text
MULLE_CURSOR_PROPERTIES;


// currently only MulleBitmapImage supported (use MulleSVGLayer for SVG)
- (instancetype) initWithImage:(NSObject <CGImage> *) image;

@property( assign, getter=isSelected) BOOL   selected;
@property( observable) CGColorRef            selectionColor;

// contentMode is not in UIView, because only UIImageView supports it (for now)
@property MulleLayoutContentMode   contentMode;

@end
