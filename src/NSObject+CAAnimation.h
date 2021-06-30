#import "import.h"


@class CAAnimationGroup;


@interface NSObject( CAAnimation)

- (void) animatePropertiesWithSnapshot:(id) snapshot
                        animationGroup:(CAAnimationGroup *) group;

@end

