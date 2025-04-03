#import "CAAnimation+CGPaint.h"

#import "import-private.h"

#import "CABasicAnimation+CGGradient.h"
#import "CABasicAnimation+CGPaint.h"



// this gets called from CAAnimation in "animate_object_property", it will
// eventually call the constructor above 

@implementation CGPaint( CAAnimation)

+ (CAAnimation *) createAnimationFrom:(id) startObject
                                   to:(id) endObject
                             property:(struct _mulle_objc_property *) property
                              options:(struct CABasicAnimationOptions *) options
{
   if( ! startObject && ! endObject)
      return( nil);

   startObject = MULLE_OBJC_CLASS_CAST( CGPaint, startObject);
   endObject   = MULLE_OBJC_CLASS_CAST( CGPaint, endObject);

   // this will also catch monoColor as it is a CGGradient subclass
   if( (! startObject || [startObject __isCGGradient]) &&
       (! endObject   || [endObject __isCGGradient]))
   {
      return( [CABasicAnimation animationWithProperty:property
                                      startCGGradient:startObject
                                        endCGGradient:endObject
                                              options:options]);
   }

   return( [CABasicAnimation animationWithProperty:property
                                      startCGPaint:startObject
                                        endCGPaint:endObject
                                           options:options]);

}

@end

