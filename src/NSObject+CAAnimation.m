#import "NSObject+CAAnimation.h"

#import "import-private.h"

#import "CABasicAnimation+CGColor.h"
#import "CGGeometry+MulleObjC.h"
#import "MulleEdgeInsets+MulleObjC.h"


enum
{
   add_to_self            = 0x1,  // experimental, unused
   add_to_animation_group = 0x2
};


struct property_animation_context
{
   id                               self;
   id                               snapshot;
   CAAnimationGroup                 *animationGroup;
   struct CABasicAnimationOptions   animationOptions;
   NSUInteger                       flags;
};


static void  animation_add( struct property_animation_context *ctx,
                            CAAnimation *animation)
{
   if( ctx->flags & add_to_self)
      [ctx->self addAnimation:animation];
   else
      [animation setAnimationObject:ctx->self];

   if( ctx->flags & add_to_animation_group)
      [ctx->animationGroup addAnimation:animation];
}


// returns 0 on match
static inline int   string_matcher( char *s, char *other, size_t other_len)
{
   if( strlen( s) != other_len)
      return( 1);
   return( strncmp( s, other, other_len));
}


static void   animate_bool_property( struct _mulle_objc_property *property,
                                     struct property_animation_context  *ctx)
{
   CAAnimation   *animation;
   NSInteger     startValue;
   NSInteger     endValue;
   SEL           getter;
   SEL           setter;

   getter     = mulle_objc_property_get_getter( property);
   startValue = MulleObjectGetBOOL( ctx->snapshot, getter);
   endValue   = MulleObjectGetBOOL( ctx->self, getter);
   if( startValue == endValue)
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:startValue
                                           endIntegerValue:endValue
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      animation_add( ctx, animation);
      // reset to start position
      MulleObjectSetBOOL( ctx->self, setter, startValue);
   }
}


static void   animate_integer_property( struct _mulle_objc_property *property,
                                        struct property_animation_context  *ctx)
{
   CAAnimation   *animation;
   NSInteger     startValue;
   NSInteger     endValue;
   SEL           getter;
   SEL           setter;

   getter     = mulle_objc_property_get_getter( property);
   startValue = MulleObjectGetNSInteger( ctx->snapshot, getter);
   endValue   = MulleObjectGetNSInteger( ctx->self, getter);;
   if( startValue == endValue)
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                         startIntegerValue:startValue
                                           endIntegerValue:endValue
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      animation_add( ctx, animation);

      // reset to start position
      MulleObjectSetNSInteger( ctx->self, setter, startValue);
   }
}


static void   animate_range_property( struct _mulle_objc_property *property,
                                      struct property_animation_context *ctx)
{
   CAAnimation  *animation;
   NSRange      startRange;
   NSRange      endRange;
   SEL          getter;
   SEL          setter;

   getter     = mulle_objc_property_get_getter( property);
   startRange = MulleObjectGetNSRange( ctx->snapshot, getter);
   endRange   = MulleObjectGetNSRange( ctx->self, getter);
   if( NSEqualRanges( startRange, endRange))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startRangeValue:startRange
                                             endRangeValue:endRange
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      // can not be additive
      animation_add( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetNSRange( ctx->self, setter, startRange);
   }
}


static void   animate_float_property( struct _mulle_objc_property *property,
                                      struct property_animation_context  *ctx)
{
   CAAnimation   *animation;
   CGFloat       startValue;
   CGFloat       endValue;
   SEL           getter;
   SEL           setter;

   getter     = mulle_objc_property_get_getter( property);
   startValue = MulleObjectGetCGFloat( ctx->snapshot, getter);
   endValue   = MulleObjectGetCGFloat( ctx->self, getter);;
   if( startValue == endValue)
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startFloatValue:startValue
                                             endFloatValue:endValue
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      animation_add( ctx, animation);

      // reset to start position
      MulleObjectSetCGFloat( ctx->self, setter, startValue);
   }
}

static void   animate_point_property( struct _mulle_objc_property *property,
                                      struct property_animation_context  *ctx)
{
   CAAnimation   *animation;
   CGPoint       startPoint;
   CGPoint       endPoint;
   SEL           getter;
   SEL           setter;

   getter     = mulle_objc_property_get_getter( property);
   startPoint = MulleObjectGetCGPoint( ctx->snapshot, getter);
   endPoint   = MulleObjectGetCGPoint( ctx->self, getter);
   if( CGPointEqualToPoint( startPoint, endPoint))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                           startPointValue:startPoint
                                             endPointValue:endPoint
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      animation_add( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetCGPoint( ctx->self, setter, startPoint);
   }
}


static void   animate_size_property( struct _mulle_objc_property *property,
                                     struct property_animation_context  *ctx)
{
   CAAnimation  *animation;
   CGSize        startSize;
   CGSize        endSize;
   SEL           getter;
   SEL           setter;

   getter    = mulle_objc_property_get_getter( property);
   startSize = MulleObjectGetCGSize( ctx->snapshot, getter);
   endSize   = MulleObjectGetCGSize( ctx->self, getter);
   if( CGSizeEqualToSize( startSize, endSize))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                            startSizeValue:startSize
                                              endSizeValue:endSize
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      animation_add( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetCGSize( ctx->self, setter, startSize);
   }
}


static void   animate_rect_property( struct _mulle_objc_property *property,
                                     struct property_animation_context *ctx)
{
   CAAnimation  *animation;
   CGRect        startRect;
   CGRect        endRect;
   SEL           getter;
   SEL           setter;

   getter    = mulle_objc_property_get_getter( property);
   startRect = MulleObjectGetCGRect( ctx->snapshot, getter);
   endRect   = MulleObjectGetCGRect( ctx->self, getter);
   if( CGRectEqualToRect( startRect, endRect))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                            startRectValue:startRect
                                              endRectValue:endRect
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      animation_add( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetCGRect( ctx->self, setter, startRect);
   }
}


static void   animate_insets_property( struct _mulle_objc_property *property,
                                       struct property_animation_context *ctx)
{
   CAAnimation       *animation;
   MulleEdgeInsets   startInsets;
   MulleEdgeInsets   endInsets;
   SEL               getter;
   SEL               setter;

   getter      = mulle_objc_property_get_getter( property);
   startInsets = MulleObjectGetEdgeInsets( ctx->snapshot, getter);
   endInsets   = MulleObjectGetEdgeInsets( ctx->self, getter);
   if( MulleEdgeInsetsEqualToEdgeInsets( startInsets, endInsets))
      return;

   setter    = mulle_objc_property_get_setter( property);
   animation = [[[CABasicAnimation alloc] initWithProperty:property
                                      startEdgeInsetsValue:startInsets
                                        endEdgeInsetsValue:endInsets
                                                   options:&ctx->animationOptions] autorelease];
   if( animation)
   {
      animation_add( ctx, animation);

      // reset to start position
      // this should work and not trigger another willChange action, as willChange
      // will see the existing snapshot in the layer and do nothing
      // STILL it would be nicer to do this more stealthily by setting the ivar
      // directly
      MulleObjectSetEdgeInsets( ctx->self, setter, startInsets);
   }
}



static void   animate_color_property( struct _mulle_objc_property *property,
                                      struct property_animation_context *ctx)
{
   CAAnimation   *animation;
   CGColor    startColor;
   CGColor    endColor;
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
      animation_add( ctx, animation);

      // reset to start position
      MulleObjectSetCGColor( ctx->self, setter, startColor);
   }
}


@implementation NSObject( CAAnimation)


static mulle_objc_walkcommand_t
   walkproperties_callback( struct _mulle_objc_property *property,
                            struct _mulle_objc_infraclass *infra,
                            void *userinfo)
{
   struct property_animation_context  *ctx = userinfo;
   char                               *signature;
   char                               *name_b;
   char                               *name_e;
   size_t                             name_len;

   if( ! (_mulle_objc_property_get_bits( property) & _mulle_objc_property_observable))
      return( mulle_objc_walk_ok);

   signature = mulle_objc_property_get_signature( property);


//   printf( "%s @property %s = %s\n", _mulle_objc_infraclass_get_name( infra),
//                                      mulle_objc_property_get_name( property),
//                                      signature);

   switch( *signature)
   {
   default           : return( mulle_objc_walk_ok); // warn ????

   case _C_BOOL      : animate_bool_property( property, ctx);
                       return( mulle_objc_walk_ok);
   case _C_LNG       : if( sizeof( long) == sizeof( NSInteger))
                          animate_integer_property( property, ctx);
                       return( mulle_objc_walk_ok);
   case _C_LNG_LNG   : if( sizeof( long long) == sizeof( NSInteger))
                          animate_integer_property( property, ctx);
                       return( mulle_objc_walk_ok);

   case _C_FLT       : if( sizeof( float) == sizeof( CGFloat))
                          animate_float_property( property, ctx);
                       return( mulle_objc_walk_ok);
   case _C_DBL       : if( sizeof( double) == sizeof( CGFloat))
                          animate_float_property( property, ctx);
                       return( mulle_objc_walk_ok);
   case _C_STRUCT_B  : // default code
      break;
   }

   // struct code
   name_b = signature + 1;
   name_e = strchr( name_b, '=');
   assert( name_e && strchr( name_b, ',') > name_e);
   name_len = name_e - name_b;

   // Mulle[E]dgeInsets
   // CGSiz[e]
   // NSRan[g]e is actually mulle_range though
   // NVGCo[l]or
   // CGPoi[n]t
   // mulle[_]range
   // CGRec[t]

   if( name_len < 6)
      return( mulle_objc_walk_ok);

   switch( name_b[ 5])
   {
   // soon to be CGEdgeInsets ?
   case 'E' : if( ! string_matcher( "MulleEdgeInsets", name_b, name_len))
                  animate_insets_property( property, ctx);
              return( mulle_objc_walk_ok);
   case 'e' : if( ! string_matcher( "CGSize", name_b, name_len))
                  animate_size_property( property, ctx);
              return( mulle_objc_walk_ok);
   case 'g' : if( ! string_matcher( "NSRange", name_b, name_len))
                 animate_range_property( property, ctx);
              return( mulle_objc_walk_ok);
   case 'l' : if( ! string_matcher( "NVGcolor", name_b, name_len))
                  animate_color_property( property, ctx);
              return( mulle_objc_walk_ok);
   case 'n' : if( ! string_matcher( "CGPoint", name_b, name_len))
                  animate_point_property( property, ctx);
              return( mulle_objc_walk_ok);
   case '_' : if( ! string_matcher( "mulle_range", name_b, name_len))
                  animate_range_property( property, ctx);
              return( mulle_objc_walk_ok);
   case 't' : if( ! string_matcher( "CGRect", name_b, name_len))
                  animate_rect_property( property, ctx);
              return( mulle_objc_walk_ok);
   }

   return( mulle_objc_walk_ok);
}


- (void) animatePropertiesWithSnapshot:(id) snapshot
                        animationGroup:(CAAnimationGroup *) animationGroup
{
   struct property_animation_context   ctxt;
   struct _mulle_objc_infraclass       *infra;

   if( ! snapshot || ! animationGroup)
      return;

   infra               = mulle_objc_object_get_infraclass( snapshot);
   ctxt.snapshot       = snapshot;
   ctxt.animationGroup = animationGroup;
   ctxt.flags          = add_to_animation_group;
   ctxt.self           = self;

   [animationGroup setupBasicAnimationOptions:&ctxt.animationOptions];
   [animationGroup setAnimationObject:(id <CAAnimatableObject>) self];
	_mulle_objc_infraclass_walk_properties( infra,
                                           _mulle_objc_infraclass_get_inheritance( infra),
                                           walkproperties_callback,
                                           &ctxt);
}

@end
