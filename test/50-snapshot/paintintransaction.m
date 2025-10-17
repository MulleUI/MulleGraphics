#import <MulleCA/MulleCA.h>
#import <MulleGraphics/MulleGraphics.h>


@interface Foo : NSObject  < CAImplicitlyAnimatableObject, CAAnimationStorageObject> // < CAImplicitlyAnimatableObject, CAAnimationStorage>
{
   CAImplicitlyAnimatableObjectIvars;
   CAAnimationStorageObjectIvars;
}
CAAnimationStorageObjectProperties;
@property( observable, copy) CGPaint   *paint;

CAImplicitlyAnimatableObjectInterface;
CAAnimationStorageObjectInterface;

@end 


@implementation Foo 

CAImplicitlyAnimatableObjectImplementation;
CAAnimationStorageObjectImplementation;

@end 



int   main( int argc, char *argv[])
{
   CATransaction      *transaction;
   CAAnimationGroup   *group;
   Foo                *foo;

   foo = [Foo instance];
   [foo setPaint:[CGPaint paintWithColor:CGColorMakeIndigo()]];

   transaction = [CATransaction instance];
   assert( transaction);

   [transaction begin];
   {
      // if duration is 0.0, then no animations are generated
      [transaction setAnimationDuration:1.0];
      [foo setPaint:[CGPaint paintWithColor:CGColorMakeMagenta()]];
   }
   group = [transaction commit];
   printf( "%td\n", [group numberOfAnimations]);
   return( 0);
}
