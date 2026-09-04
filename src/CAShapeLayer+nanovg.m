//
//  CAShapeLayer+nanovg.m
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
