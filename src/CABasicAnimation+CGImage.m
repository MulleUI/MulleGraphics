//
//  CABasicAnimation+CGImage.m
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
#import "CABasicAnimation+CGImage.h"

#import "import-private.h"




@implementation CGImagePaint( CAInterpolatableValue)

- (id) interpolateTo:(id) end
              factor:(double) x
            additive:(BOOL) additive
{
   CGFloat        startRotation;
   CGFloat        endRotation;
   CGFloat        dstRotation;
   CGFloat        startBlend;
   CGFloat        endBlend;
   CGFloat        dstBlend;
   CGImagePaint   *imagePaint;

   startBlend    = _blend;
   endBlend      = ((CGImagePaint *) end)->_blend;
   startRotation = _rotation;
   endRotation   = ((CGImagePaint *) end)->_rotation;

   if( additive)
   {
      dstBlend    = CAInterpolateAdditive( startBlend, endBlend, x);
      dstRotation = CAInterpolateAdditive( startRotation, endRotation, x);
   }
   else
   {
      dstBlend    = CAInterpolate( startBlend, endBlend, x);
      dstRotation = CAInterpolate( startRotation, endRotation, x);
   }

   imagePaint = [CGImagePaint imagePaintWithImage:_image
                                       otherImage:_otherImage
                                            blend:dstBlend
                                         rotation:dstRotation];
   return( imagePaint);
}



// self - previous + diff
- (id) interpolatedValueWithDiff:(id) diff
                    previousDiff:(id) previous
{
   CGFloat          previousRotation;
   CGFloat          diffRotation;
   CGFloat          rotation;
   CGFloat          previousBlend;
   CGFloat          diffBlend;
   CGFloat          blend;
   CGImagePaint     *imagePaint;

   previousBlend    = ((CGImagePaint *) previous)->_blend;
   diffBlend        = ((CGImagePaint *) diff)->_blend;
   blend            = _blend - previousBlend + diffBlend;

   previousRotation = ((CGImagePaint *) previous)->_rotation;
   diffRotation     = ((CGImagePaint *) diff)->_rotation;
   rotation         = _rotation - previousRotation + diffRotation;
         // create new gradient
   imagePaint       = [CGImagePaint imagePaintWithImage:_image
                                             otherImage:_otherImage
                                                  blend:blend
                                               rotation:rotation];
   return( imagePaint);
}

@end



@implementation CABasicAnimation( CGImage)

+ (CABasicAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                               startCGImage:(CGImage *) startImage
                                 endCGImage:(CGImage *) endImage
                                    options:(struct CABasicAnimationOptions *) options
{
   CGImagePaint   *startPaint;
   CGImagePaint   *endPaint;
   CABasicAnimation *obj;

   startPaint = [CGImagePaint imagePaintWithImage:startImage
                                      otherImage:endImage
                                           blend:0.0f
                                        rotation:[startImage rotation]];
   endPaint   = [CGImagePaint imagePaintWithImage:startImage
                                      otherImage:endImage
                                           blend:1.0f
                                        rotation:[endImage rotation]];
   obj = [self alloc];
   obj = [obj initWithProperty:property
                startObjectValue:startPaint
                  endObjectValue:endPaint
                        options:options];
   obj = [obj autorelease];
   return(obj);
}

@end

