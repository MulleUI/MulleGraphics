//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CAGradientLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"


@implementation CAGradientLayer

- (void) drawBackgroundInContext:(CGContext *) context
{
   [self fillBackgroundInContext:context
                           paint:_paint];
}

@end
