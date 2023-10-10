#import "CAAnimation+CGPaint.h"

#import "import-private.h"

#import "CABasicAnimation+CGImage.h"
#import "CABasicAnimation+CGGradient.h"



// this gets called from CAAnimation in "animate_object_property", it will
// eventually call the constructor above 

@implementation CGPaint( CAAnimation)

+ (CAAnimation *) createAnimationFrom:(id) startObject
                                   to:(id) endObject
                             property:(struct _mulle_objc_property *) property
                              options:(struct CABasicAnimationOptions *) options
{
   Class   gradientClass;

   assert( ! startObject || [startObject isKindOfClass:[CGPaint class]]);
   assert( ! endObject   || [endObject isKindOfClass:[CGPaint class]]);
   assert( startObject || endObject);

   // this will also catch monoColor as it is a CGGradient subclass
   gradientClass = [CGGradient class];
   if( (! startObject || [startObject isKindOfClass:gradientClass]) &&
       (! endObject   || [endObject isKindOfClass:gradientClass]))
   {
      return( [CABasicAnimation animationWithProperty:property
                                      startCGGradient:startObject
                                        endCGGradient:endObject
                                              options:options]);
   }

   // could also be two textures (or nil), which is fine
   if( (! startObject || [startObject isTexture]) && (! endObject || [endObject isTexture]))
      return( [CABasicAnimation animationWithProperty:property
                                         startCGImage:startObject
                                           endCGImage:endObject
                                              options:options]);

   // we could do nice fades here, if we could (see above)
   return( nil);
}

@end

