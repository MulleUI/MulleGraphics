//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "CALayer.h")
#  import "CALayer.h"
# endif
#endif

#import "import.h"



//
// this class is probably soon obsolete, as we make backgroundColor a
// CGPaint ?
//
@interface CAGradientLayer : CALayer

@property( observable, copy) CGGradient   *paint;

@end
