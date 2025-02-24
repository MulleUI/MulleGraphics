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
   NVGcontext   *vg;
   CGRect        frame;
   CGRect        canvas;
   CGRect        bounds;

   if( ! [super drawInContext:context])
      return( NO);

   // easy way out if nothing is defined
   if( ! _fillPaint && ! _strokePaint)
      return( YES);

   vg     = CGContextGetNVGContext( context);
   frame  = [self frame];

   // scale untested
   canvas = [self canvas];
   bounds = [_fillPaint needsBounds] || [_strokePaint needsBounds]
            ? CGPathGetBounds( _path)
            : CGRectZero;

   nvgSave( vg);
   {
      if( ! CGSizeEqualToSize( frame.size, canvas.size))
      {
         nvgScale( vg, canvas.size.width / frame.size.width,
                       canvas.size.height / frame.size.height);
      }

      mvgBeginPath( vg);
      mvgAddCGPath( vg, _path);

      [_fillPaint fillWithBounds:bounds
                      NVGcontext:vg];

      [_strokePaint strokeWithBounds:bounds
                         strokeWidth:_strokeWidth
                          NVGcontext:vg];
   }
   nvgRestore( vg);
   return( YES);
}
@end
