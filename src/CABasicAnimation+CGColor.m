//
//  CABasicAnimation+CGColor.m
//  MulleGraphics
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
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
   animation = [CABasicAnimation animationWithProperty:property
                                       startColorValue:startColor
                                         endColorValue:endColor
                                               options:&ctx->animationOptions];
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


+ (instancetype) animationWithProperty:(struct _mulle_objc_property *) property
                       startColorValue:(CGColor) start
                         endColorValue:(CGColor) end
                               options:(struct CABasicAnimationOptions *) options
{
   return( [[[self alloc] initWithProperty:property
                           startColorValue:start
                             endColorValue:end
                                   options:options] autorelease]);
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
