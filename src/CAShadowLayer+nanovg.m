//
//  CAShadowLayer+nanovg.m
//  MulleGraphics
//
//  Copyright (c) 2023 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "CAShadowLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"


@implementation CAShadowLayer( nanovg)

- (BOOL) drawInContext:(CGContext *) context
{
   CGRect         canvas;
   CGRect         rect;
   CGRect         hole;
   unsigned int   i, n;
   unsigned int   j, m;
   CGRect         rects[ 4];
   CGRect         inferiors[ 4];
   CGPaint        *paint;

   if( ! [super drawInContext:context])
      return( NO);

   // our complete shadow area
   canvas   = [self canvas];
   // likely the original view contentRect
   rect     = [self shadowedRect];

   if( CGRectEqualToRect( canvas, rect))
      return( NO);

   hole  = MulleEdgeInsetsInsetRect( _shadowInsets, _shadowHole);
   paint = [CGGradient boxGradientWithRoundedRect:canvas
                                     cornerRadius:_cornerInsets.topLeft
                                            color:_shadowColor
                                          feather:_shadowBlur
                                     featherColor:CGColorBySettingAlpha( _shadowColor, 0.0f)];

   n = CGRectSubdivide( canvas, rect, rects);
   for( i = 0; i < n; i++)
   {
      m = CGRectSubdivide( rects[ i], hole, inferiors);
      for( j = 0; j < m; j++)
      {
         CGContextFillRectWithPaintable( context, inferiors[ j], paint);
      }
   }

   return( YES);
}

@end
