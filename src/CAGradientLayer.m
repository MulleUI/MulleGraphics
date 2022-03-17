//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CAGradientLayer.h"

#import "import-private.h"

#import "CALayer+MulleGraphics.h"


@implementation CAGradientLayer

- (void) drawBackgroundInContext:(CGContext *) context
{
   [self fillBackgroundInContext:context
                           color:_backgroundColor
                           paint:_paint];
}

@end
