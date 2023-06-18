//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#import "import.h"


#define CAAnimationValueCGColor     10


static inline union CAAnimationValue
   CAAnimationValueMakeWithCGColor( CGColor color)
{
   union CAAnimationValue   value;

   CGColorGetHSBAComponents( color, (float *) &value.float4Value);
   return( value);
}

// this must be exactly as large as CGColor, it's only here to provide
// a bit more readability, instead of storing diffs into fake CGColors
typedef struct CGColorDiff
{
   float    v[ 4];
} CGColorDiff;


#define CGColorDiffZero   ((CGColorDiff) { 0 })


static inline CGColorDiff   CGColorDiffMake( float v0, float v1, float v2, float v3)
{
   MULLE_C_ASSERT( sizeof( CGColor) == sizeof( CGColorDiff));
   return( (CGColorDiff) { .v = { v0, v1, v2, v3 } });
}


static inline CGColorDiff   CGColorDiffMakeWithComponents( float value[ 4])
{
   return( (CGColorDiff) { .v = {
                                  value[ 0],
                                  value[ 1],
                                  value[ 2],
                                  value[ 3]
                                 }
                         });
}


static inline CGColorDiff   CGColorDiffAdd( CGColorDiff a, CGColorDiff b)
{
   return( (CGColorDiff) { .v = {
                                  a.v[ 0] + b.v[ 0],
                                  a.v[ 1] + b.v[ 1],
                                  a.v[ 2] + b.v[ 2],
                                  a.v[ 3] + b.v[ 3]
                                }
                         });
}


static inline CGColorDiff   CGColorDiffSubtract( CGColorDiff a, CGColorDiff b)
{
   return( (CGColorDiff) { .v = {
                                  a.v[ 0] - b.v[ 0],
                                  a.v[ 1] - b.v[ 1],
                                  a.v[ 2] - b.v[ 2],
                                  a.v[ 3] - b.v[ 3]
                                }
                         });
}


MULLE_CG_EXTERN_GLOBAL
CGColor   CGColorAddDiff( CGColor a, CGColorDiff b);


MULLE_CG_EXTERN_GLOBAL
CGColor   CGColorMakeWithInterpolateHSBAComponents( float hsba_start[4], float hsba_end[4], double x);

MULLE_CG_EXTERN_GLOBAL
CGColor   CGColorInterpolate( CGColor start, CGColor end, double x);

MULLE_CG_EXTERN_GLOBAL
CGColorDiff   CGColorInterpolateAdditive( CGColor start, CGColor end, double x);

MULLE_CG_EXTERN_GLOBAL
CGColor   CAInterpolatedColorWithDiffAndPreviousDiff( CGColor color,
                                                      CGColorDiff diff,
                                                      CGColorDiff previous);


@interface CABasicAnimation( CGColor)

- (id) initWithProperty:(struct _mulle_objc_property *) property
        startColorValue:(CGColor) start
          endColorValue:(CGColor) end
                options:(struct CABasicAnimationOptions *) options;

@end
