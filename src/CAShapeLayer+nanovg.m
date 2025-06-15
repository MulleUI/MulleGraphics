//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CAShapeLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"


@implementation CAShapeLayer( nanovg)


// needs to restore context if changed
- (BOOL) drawInContext:(CGContext *) context
{
   CGRect   frame;
   CGRect   canvas;
   CGRect   bounds;

   if( ! [super drawInContext:context])
      return( NO);

   // easy way out if nothing is defined
   if( ! _fillPaint && ! _strokePaint)
      return( YES);

   frame  = [self frame];

   // scale untested
   canvas = [self canvas];
   bounds = [_fillPaint needsBounds] || [_strokePaint needsBounds]
            ? CGPathGetBounds( _path)
            : CGRectZero;

   CGContextSave( context);
   {
      if( ! CGSizeEqualToSize( frame.size, canvas.size))
      {
         CGContextScale( context, CGVectorMake( canvas.size.width / frame.size.width,
                                                canvas.size.height / frame.size.height));
      }

      CGContextBeginPath( context);
      CGContextAddCGPath( context, _path);

      [_fillPaint fillWithBounds:bounds
                         context:context];

      [_strokePaint strokeWithBounds:bounds
                         strokeWidth:_strokeWidth
                             context:context];
   }
   CGContextRestore( context);
   return( YES);
}
@end
