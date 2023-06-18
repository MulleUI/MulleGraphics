//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#import "CABasicAnimation+CGColor.h"

#import "import.h"

#import "CGColor+MulleObjC.h"



// Interpolating non-additive is nicer, as we can keep values internally
// as HSBA
//

@implementation CABasicAnimation( CGColor)


CGColor   CGColorMakeWithInterpolateHSBAComponents( float hsba_start[ 4],
                                                    float hsba_end[ 4],
                                                    double x)
{
   float   hsba[ 4];

   assert( x >= 0 && x <= 1.0);

   hsba[ 0] = CAInterpolate( hsba_start[ 0], hsba_end[ 0], x);
   hsba[ 1] = CAInterpolate( hsba_start[ 1], hsba_end[ 1], x);
   hsba[ 2] = CAInterpolate( hsba_start[ 2], hsba_end[ 2], x);
   hsba[ 3] = CAInterpolate( hsba_start[ 3], hsba_end[ 3], x);

   return( CGColorMakeWithHSBA( hsba[ 0], hsba[ 1], hsba[ 2], hsba[ 3]));
}


CGColor   CGColorInterpolate( CGColor start, CGColor end, double x)
{
   float   startHSBA[ 4];
   float   endHSBA[ 4];

   CGColorGetHSBAComponents( start, startHSBA);
   CGColorGetHSBAComponents( end, endHSBA);
   return( CGColorMakeWithInterpolateHSBAComponents( startHSBA, endHSBA, x));
}


CGColorDiff   CGColorInterpolateAdditive( CGColor start, CGColor end, double x)
{
   float         startHSBA[ 4];
   float         endHSBA[ 4];
   CGColorDiff   diff;

   CGColorGetHSBAComponents( start, startHSBA);
   CGColorGetHSBAComponents( end, endHSBA);

   diff.v[ 0] = CAInterpolateAdditive( startHSBA[ 0], endHSBA[ 0], x);
   diff.v[ 1] = CAInterpolateAdditive( startHSBA[ 1], endHSBA[ 1], x);
   diff.v[ 2] = CAInterpolateAdditive( startHSBA[ 2], endHSBA[ 2], x);
   diff.v[ 3] = CAInterpolateAdditive( startHSBA[ 3], endHSBA[ 3], x);

   return( diff);
}


CGColor   CGColorAddDiff( CGColor color, CGColorDiff diff)
{
   float   hsba[ 4];

   CGColorGetHSBAComponents( color, hsba);

   hsba[ 0] += diff.v[ 0];
   hsba[ 1] += diff.v[ 1];
   hsba[ 2] += diff.v[ 2];
   hsba[ 3] += diff.v[ 3];

   return( CGColorMakeWithHSBAComponents( hsba));
}



static void   CABasicAnimationSetInterpolatedColor( CABasicAnimation *self,
                                                    id object,
                                                    double x)
{
   CGColor   color;

   color = CGColorMakeWithInterpolateHSBAComponents( self->_start.float4Value.v,
                                                     self->_end.float4Value.v,
                                                     x);
   {
      mulle_metaabi_union_void_return( CGColor)   param;

      param.p = color;
      mulle_objc_object_call_variablemethodid( object,
                                               self->_property->setter,
                                               &param);
   }
}


static void   CABasicAnimationSetInterpolatedColorAdditive( CABasicAnimation *self,
                                                            id object,
                                                            double x)
{
   CGColor       newColor;
   CGColor       color;
   CGColorDiff   diff;
   CGColorDiff   step;
   CGColorDiff   previous;

   diff.v[ 0] = CAInterpolateAdditive( self->_start.float4Value.v[ 0], self->_end.float4Value.v[ 0], x);
   diff.v[ 1] = CAInterpolateAdditive( self->_start.float4Value.v[ 1], self->_end.float4Value.v[ 1], x);
   diff.v[ 2] = CAInterpolateAdditive( self->_start.float4Value.v[ 2], self->_end.float4Value.v[ 2], x);
   diff.v[ 3] = CAInterpolateAdditive( self->_start.float4Value.v[ 3], self->_end.float4Value.v[ 3], x);

   {
      mulle_metaabi_union_void_parameter( CGColor)   param;

      mulle_objc_object_call_variablemethodid( object, self->_property->getter, &param);
      color = param.r;
   }

   previous = CGColorDiffMakeWithComponents( self->_previous.float4Value.v);
   step     = CGColorDiffSubtract( diff, previous);
   newColor = CGColorAddDiff( color, step);

   self->_previous.float4Value.v[ 0] = diff.v[ 0];
   self->_previous.float4Value.v[ 1] = diff.v[ 1];
   self->_previous.float4Value.v[ 2] = diff.v[ 2];
   self->_previous.float4Value.v[ 3] = diff.v[ 3];

   {
      mulle_metaabi_union_void_return( CGColor)   param;

#ifdef ANIMATION_DEBUG
   MulleUILog( "%#@ %s -> %s", object,
                               mulle_objc_property_get_name( self->_property),
                               CGColorUTF8String( newColor));
#endif

      param.p = newColor;
      mulle_objc_object_call_variablemethodid( object, self->_property->setter, &param);
   }
}


char  *CAAnimationValueCGColorUTF8String( union CAAnimationValue value)
{
   return( MulleObjC_asprintf( "[rgba=%g,%g,%g,%g]", value.float4Value.v[ 0],
                                                     value.float4Value.v[ 1],
                                                     value.float4Value.v[ 2],
                                                     value.float4Value.v[ 3]));
}


static void   animate_color_property( struct _mulle_objc_property *property,
                                      struct CAPropertyAnimationContext *ctx)
{
   CAAnimation   *animation;
   CGColor       startColor;
   CGColor       endColor;
   SEL           getter;
   SEL           setter;

   getter     = mulle_objc_property_get_getter( property);
   startColor = MulleObjectGetCGColor( ctx->snapshot, getter);
   endColor   = MulleObjectGetCGColor( ctx->self, getter);

   if( CGColorEqualToColor( startColor,  endColor))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startColorValue:startColor
                                             endColorValue:endColor
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      CAPropertyAnimationContextAddAnimation( ctx, animation);

      // reset to start position
      MulleObjectSetCGColor( ctx->self, setter, startColor);
   }
}


static BOOL   matchCGColor( char *s, NSUInteger len)
{
   // encodeName looks like this "{NVGcolor=(?=[4f]{?=ffff})}}"
   // skip leading '{'
   static char  *encodeName = @encode( CGColor);

   char   *p;
   char   *q;
   char   *p_sentinel;
   char   c;
   char   d;

   p          = s;
   p_sentinel = &p[ len];
   q          = encodeName + 1;

   while( p < p_sentinel)
   {
      c = *p++;
      d = *q++;
      c = c == '=' ? 0 : c;
      d = d == '=' ? 0 : d;

      if( ! c)
         return( d ? NO : YES);
      if( ! d)
         return( NO);
      if( d != c)
         return( NO);
   }
   return( *q == '0' || *q == '=');
}


static struct CAAnimationPropertyDefinition   CGColorPropertyType =
{
   matchCGColor,
   animate_color_property
};


static struct CABasicAnimationTypeDefinition  CGColorAnimationType =
{
   CAAnimationValueCGColor,
   "CAAnimationValueCGColor",
   CABasicAnimationSetInterpolatedColor,
   CABasicAnimationSetInterpolatedColorAdditive,
   CAAnimationValueCGColorUTF8String
};


+ (void) load
{
   CABasicAnimationTypeDefinitionRegister( &CGColorAnimationType);
   CAAnimationPropertyDefinitionRegister( &CGColorPropertyType);
}


- (id) initWithProperty:(struct _mulle_objc_property *) property
        startColorValue:(CGColor) start
          endColorValue:(CGColor) end
                options:(struct CABasicAnimationOptions *) options
{
   struct CAAnimationValueRange  range;

   range.start = CAAnimationValueMakeWithCGColor( start);
   range.end   = CAAnimationValueMakeWithCGColor( end);
   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGColor
                       valueRange:&range
                          options:options]);
}

@end
