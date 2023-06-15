//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CAShapeLayer.h"

#import "import-private.h"

#import "CALayer+MulleGraphics.h"


@implementation CAShapeLayer( NanoVG)


// needs to restore context if changed
- (void) drawInContext:(CGContext *) context
{
   NVGcontext   *vg;
   BOOL          fill;
   BOOL          stroke;
   CGRect        frame;
   CGRect        canvas;

   [super drawInContext:context];

   fill   = ! CGColorIsTransparent( _fillColor);
   stroke = ! CGColorIsTransparent( _strokeColor);

   if( ! fill && ! stroke)
      return;

   vg     = CGContextGetNVGContext( context);
   frame  = [self frame];

   // scale untested
   canvas = [self canvas];

   nvgSave( vg);
   {
      nvgTranslate( vg, frame.origin.x, frame.origin.y);
      {
         if( ! CGSizeEqualToSize( frame.size, canvas.size))
         {
            nvgScale( vg, canvas.size.width / frame.size.width,
                           canvas.size.height / frame.size.height);
         }

         nvgBeginPath( vg);
         mvgAddCGPath( vg, _path);

         if( fill)
         {
            nvgFillColor( vg, _fillColor);
            nvgFill( vg);
         }

         if( stroke)
         {
            nvgStrokeColor( vg, _strokeColor);
            nvgStroke( vg);
         }
      }
   }
   nvgRestore( vg);
}
@end
