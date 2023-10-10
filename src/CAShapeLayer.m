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


- (void) setStrokeColor:(CGColor) color
{
   [self setStrokePaint:[CGPaint paintWithColor:color]];
}


- (void) setFillColor:(CGColor) color;
{
   [self setFillPaint:[CGPaint paintWithColor:color]];
}

@end
