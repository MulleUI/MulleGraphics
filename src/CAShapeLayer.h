//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "CALayer.h")
#  import "CALayer.h"
# endif
#endif

#import "import.h"


@interface CAShapeLayer : CALayer

@property( observable) CGColor   strokeColor;
@property( observable) CGColor   fillColor;

//
// Ownership of CGPath is transferred to CALayer and CALayer will call
// CGPathDestroy on
// it!
//
@property( assign) struct CGPath  *path;

@end
