#ifdef __has_include
# if __has_include( "CALayer.h")
#  import "CALayer.h"
# endif
#endif

#import "import.h"


@interface CAShadowLayer : CALayer

@property( observable, assign) CGFloat          shadowBlur;
@property( observable, assign) CGColor          shadowColor;

//
// the shadowLayer draws the shadow in its canvas. The shadowInsets define
// a "hole" that appears in the shadow. This hole will be occupied by the
// contents of what's throwing the shadow.
//
@property( observable, assign) MulleEdgeInsets  shadowInsets;

// this is an additional hole in the shadow, the usage here is for a
// UIPopUpButton to cut through the menu shadow, its a bit hacky hack
@property( observable, assign) CGRect           shadowHole;

- (CGRect) shadowedRect;

@end
