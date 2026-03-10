//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#ifdef __has_include
# if __has_include( "CGGraphicsLayer.h")
#  import "CGGraphicsLayer.h"
# endif
#endif

#import "import.h"


//
// this layer has a CGPath and draws it, nothing else.
//
@interface CAShapeLayer : CGGraphicsLayer

@property( observable, assign) CGFloat        strokeWidth;
@property( observable, copy) CGPaint          *strokePaint;
@property( observable, copy) CGPaint          *fillPaint;

// conveniences for above
@property( dynamic) CGColor                   strokeColor;
@property( dynamic) CGColor                   fillColor;

//
// Ownership of CGPath is transferred to the CAShapeLayer and CALayer will call
// CGPathDestroy on it (unless ownsPath is set to NO)
//
@property( assign) struct CGPath               *path;
@property( assign, getter=isOwningPath) BOOL   ownsPath;  // default YES

@end


// Actual drawing implemented by category
