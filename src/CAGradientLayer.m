//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CAGradientLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"


@implementation CAGradientLayer

//
// - (id) initNoLock
// {
//   self = [super initNoLock];
//   if( self)
//      _paint = [[CGGradient paintWithStartColor:CGColorMakePapaya()
//                                       endColor:CGColorMakePurple()
//                                       rotation:0.333] copy];
//   return( self);
// }


- (id) copy
{
   CAGradientLayer  *copy;

   copy = [super copy];

   copy->_paint = [self->_paint copy];

   return( copy);
}


// MEMO: never do this for paints
//
// - (void) mulleGainAccess
// {
//    [super mulleGainAccess];
//    [self->_paint mulleGainAccess];
// }
//
//
// - (void) mulleRelinquishAccess
// {
//    [self->_paint mulleRelinquishAccess];
//    [super mulleRelinquishAccess];
// }


- (void) drawBackgroundInContext:(CGContext *) context
{
   [self fillBackgroundInContext:context
                           paint:_paint];
}

@end
