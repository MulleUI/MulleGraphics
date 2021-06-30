#import "CALayer+CAAnimation.h"

#import "import-private.h"

#import "NSObject+CAAnimation.h"


@implementation CALayer( CAAnimation)

/*
 * Snapshot management
 */
//
// This is called very often during animation, it would be good if the
// animation code could use a different setter that does not call
// will change..
//
- (void) willChange
{
   id   manager;
   // this is called frequently so use C
   manager = CATransactionGetCurrentTransaction();
   if( ! manager)
      return;
   if( _snapshot)
      return;

   _snapshot = [self copy];
   [manager addAnimatableObject:self];
}


- (void) commitImplicitAnimations:(CAAnimationGroup *) group
{

   if( ! _snapshot)
      return;

   /** Our animatable properties
       subclasses might want to add more
    **/
   [self animatePropertiesWithSnapshot:_snapshot
                        animationGroup:group]; // add to layer

   [_snapshot autorelease];
   _snapshot = nil;
}

@end

