// prefer a local CABasicAnimation over one in import.h
#ifdef __has_include
# if __has_include( "CABasicAnimation.h")
#  import "CABasicAnimation.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"



@interface CGPaint( CAInterpolatableValue) < CAInterpolatableValue>
@end 


@interface CGPaint( CAAnimation)

+ (CAAnimation *) createAnimationFrom:(id) startObject
                                   to:(id) endObject
                             property:(struct _mulle_objc_property *) property
                              options:(struct CABasicAnimationOptions *) options;
@end
                              