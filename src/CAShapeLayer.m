//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CAShapeLayer.h"

#import "import-private.h"


@implementation CAShapeLayer

- (void) setCGPath:(CGPath *) path
{
   CGPathDestroy( _path);
   _path = path;
}


- (void) dealloc
{
   CGPathDestroy( _path);
   [super dealloc];
}

@end
