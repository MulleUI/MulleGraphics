//
// Copyright (c) 2023 Nat!, Mulle kybernetiK
//
#import "CABasicAnimation+CGColor.h"

#import "import.h"


//#define ANIMATION_DEBUG


// Interpolating non-additive is nicer, as we can keep values internally
// as HSBA
//

@implementation CABasicAnimation( CGColor)

static void   CABasicAnimationSetInterpolatedColor( CABasicAnimation *self,
                                                    id object,
                                                    double x)
{
   CGColor   color;

   color = CGColorMakeWithInterpolatedHSBAComponents( (float *) &self->_start.float4Value,
                                                      (float *) &self->_end.float4Value,
                                                      x);
   {
      mulle_metaabi_union_void_return( CGColor)   param;

      param.p = color;
      mulle_objc_object_call_variable( object,
                                               self->_property->setter,
                                               &param);
   }
}


void   CABasicAnimationSetInterpolatedColorAdditive( CABasicAnimation *self,
                                                     id object,
                                                     double x)
{
   CGColor       newColor;
   CGColor       color;
   CGColorDiff   diff;
   CGColorDiff   step;
   CGColorDiff   previous;

   diff.v[ 0] = CAInterpolateAdditive( self->_start.float4Value.v0, self->_end.float4Value.v0, x);
   diff.v[ 1] = CAInterpolateAdditive( self->_start.float4Value.v1, self->_end.float4Value.v1, x);
   diff.v[ 2] = CAInterpolateAdditive( self->_start.float4Value.v2, self->_end.float4Value.v2, x);
   diff.v[ 3] = CAInterpolateAdditive( self->_start.float4Value.v3, self->_end.float4Value.v3, x);

   {
      mulle_metaabi_union_void_parameter( CGColor)   param;

      mulle_objc_object_call_variable( object, self->_property->getter, &param);
      color = param.r;
   }

   previous = CGColorDiffMakeWithComponents( (float *) &self->_previous.float4Value);
   step     = CGColorDiffSubtract( diff, previous);
   newColor = CGColorAddDiff( color, step);

   self->_previous.float4Value.v0 = diff.v[ 0];
   self->_previous.float4Value.v1 = diff.v[ 1];
   self->_previous.float4Value.v2 = diff.v[ 2];
   self->_previous.float4Value.v3 = diff.v[ 3];

   {
      mulle_metaabi_union_void_return( CGColor)   param;

#ifdef ANIMATION_DEBUG
   MulleUILog( "%#@ %s -> %s", object,
                               mulle_objc_property_get_name( self->_property),
                               CGColorUTF8String( newColor));
#endif

      param.p = newColor;
      mulle_objc_object_call_variable( object, self->_property->setter, &param);
   }
}


char  *CAAnimationValueCGColorUTF8String( union CAAnimationValue value)
{
   return( MulleObjC_asprintf( "[rgba=%g,%g,%g,%g]", value.float4Value.v0,
                                                     value.float4Value.v1,
                                                     value.float4Value.v2,
                                                     value.float4Value.v3));
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
   struct CAAnimationValueRange   range;

   // here we make a few changes: if the saturation of one color is basically
   // none we set its hue to the hue of the other (or a scale ?)
   // also since the hue can wrap around, we may use a higher or lower 
   // value to shorten the distance

   range.start = CAAnimationValueMakeWithCGColor( start);
   range.end   = CAAnimationValueMakeWithCGColor( end);

   CGHSBAComponentsPrepareForInterpolation( (float *) &range.start.float4Value,
                                            (float *) &range.end.float4Value);

   return( [self initWithProperty:property
                        valueType:CAAnimationValueCGColor
                       valueRange:&range
                          options:options]);
}

@end
