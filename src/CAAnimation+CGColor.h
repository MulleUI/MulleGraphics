//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#import "import.h"


#define CAAnimationValueCGColor  10

static inline union CAAnimationValue
   CGAnimationValueMakeWithCGColor( CGColor color)
{
   union CAAnimationValue   value;

   CGColorGetHSBAComponents( color, (float *) &value.float4Value);
   return( value);
}


@interface CABasicAnimation( CGColor)

- (id) initWithProperty:(struct _mulle_objc_property *) property
        startColorValue:(CGColor) start
          endColorValue:(CGColor) end
                options:(struct CABasicAnimationOptions *) options;

@end
