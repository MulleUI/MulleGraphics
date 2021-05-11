#import "CALayer.h"

#import "CAAnimation.h"
#import "CATime.h"
#import "CATransaction.h"


@interface CALayer( CAAnimation) <CAAnimatableObject, CAImplicitlyAnimatableObject>

//
// Animations should not be shared with other layers as they have state.
// If you did, one or many of the other layers would sometimes fail to do the
// last animation step
//
- (void) addAnimation:(CAAnimation *) animation;
- (void) removeAllAnimations;
- (NSUInteger) numberOfAnimations;

- (void) animateWithAbsoluteTime:(CAAbsoluteTime) time;

- (void) animatePropertiesWithSnapshotlayer:(CALayer *) snapshot
                          animationDelegate:(MulleAnimationDelegate *) animationDelegate
                           animationOptions:(struct CAAnimationOptions *) animationOptions;
//
// called by UIView to create implicit animations from snapshotted values
// the snapshot will be gone afterwards. Also cancels all other
// animations. (?)
//
- (void) commitImplicitAnimationsWithID:(char *) animationsID
                               delegate:(MulleAnimationDelegate *) animationDelegate
                             parameters:(struct CAAnimationParameters *) info; // either UIView class or CATransaction

@end

