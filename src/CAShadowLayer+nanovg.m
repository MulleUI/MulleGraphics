//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CAShadowLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"


@implementation CAShadowLayer( nanovg)

- (BOOL) drawInContext:(CGContext *) context
{
   NVGcontext     *vg;
   NVGpaint       nvgPaint;
   CGRect         canvas;
   CGRect         rect;
   CGRect         hole;
   unsigned int   i, n;
   unsigned int   j, m;
   CGRect         rects[ 4];
   CGRect         inferiors[ 4];

   if( ! [super drawInContext:context])
      return( NO);

   // our complete shadow area
   canvas   = [self canvas];
   // likely the original view contentRect
   rect     = [self shadowedRect];

   if( CGRectEqualToRect( canvas, rect))
      return( NO);

   hole     = MulleEdgeInsetsInsetRect( _shadowInsets, _shadowHole);
   vg       = CGContextGetNVGContext( context);
   nvgPaint = mvgBoxGradient( vg,
                              canvas,
                              _shadowColor,
                              _cornerInsets.topLeft,
                              _shadowBlur,
                              CGColorBySettingAlpha( _shadowColor, 0.0f));

   n = CGRectSubdivide( canvas, rect, rects);
   for( i = 0; i < n; i++)
   {
      m = CGRectSubdivide( rects[ i], hole, inferiors);
      for( j = 0; j < m; j++)
      {
         mvgFillRectWithNVGpaint( vg, inferiors[ j], nvgPaint);
      }
   }

   return( YES);
}

@end
