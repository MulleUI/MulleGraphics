//
//  CABasicAnimation+CGPaint.m
//  MulleGraphics
//
//  Copyright (c) 2025 Nat! - Mulle kybernetiK.
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
#import "CABasicAnimation+CGPaint.h"

#import "import-private.h"

#import "CAAnimation+CGPaint.h"


@interface CGBlendedPaint( CAInterpolatableValue) < CAInterpolatableValue>
@end


@implementation CGBlendedPaint( CAInterpolatableValue)

- (id) interpolateTo:(id) end
              factor:(double) x
            additive:(BOOL) additive
{
   CGFloat          startRotation;
   CGFloat          endRotation;
   CGFloat          dstRotation;
   CGFloat          startBlend;
   CGFloat          endBlend;
   CGFloat          dstBlend;
   CGPaint          *paint;
   CGBlendedPaint   *endPaint;

   endPaint      = MULLE_OBJC_CLASS_CAST( CGBlendedPaint, end);
   endBlend      = endPaint->_blend;
   endRotation   = endPaint->_rotation;

   startBlend    = _blend;
   startRotation = _rotation;

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


   paint = [CGBlendedPaint paintWithPaint:_paint
                               otherPaint:_otherPaint
                                    blend:dstBlend
                                 rotation:dstRotation];
   return( paint);
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
   CGBlendedPaint   *prevPaint;
   CGBlendedPaint   *diffPaint;
   CGPaint          *paint;

   prevPaint        = MULLE_OBJC_CLASS_CAST( CGBlendedPaint, previous);
   diffPaint        = MULLE_OBJC_CLASS_CAST( CGBlendedPaint, diff);

   previousBlend    = prevPaint->_blend;
   diffBlend        = diffPaint->_blend;
   blend            = _blend - previousBlend + diffBlend;

   previousRotation = prevPaint->_rotation;
   diffRotation     = diffPaint->_rotation;
   rotation         = _rotation - previousRotation + diffRotation;
         // create new gradient
   paint            = [CGBlendedPaint paintWithPaint:_paint
                                          otherPaint:_otherPaint
                                               blend:blend
                                            rotation:rotation];
   return( paint);
}

@end


@implementation CABasicAnimation( CGPaint)

+ (CABasicAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                                startCGPaint:(CGPaint *) startPaint
                                  endCGPaint:(CGPaint *) endPaint
                                     options:(struct CABasicAnimationOptions *) options
{
   CGBlendedPaint     *startBlendedPaint;
   CGBlendedPaint     *endBlendedPaint;
   CABasicAnimation   *obj;

   startBlendedPaint = [CGBlendedPaint paintWithPaint:startPaint
                                           otherPaint:endPaint
                                                blend:0.0f
                                             rotation:[startPaint rotation]];
   endBlendedPaint   = [CGBlendedPaint paintWithPaint:startPaint
                                           otherPaint:endPaint
                                                blend:1.0f
                                             rotation:[endPaint rotation]];
   obj = [self alloc];
   obj = [obj initWithProperty:property
              startObjectValue:startBlendedPaint
                endObjectValue:endBlendedPaint
                       options:options];
   obj = [obj autorelease];
   return(obj);
}


+ (CABasicAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                                startCGImage:(CGImage *) startPaint
                                  endCGImage:(CGImage *) endPaint
                                     options:(struct CABasicAnimationOptions *) options
{
   return( [self animationWithProperty:property
                          startCGPaint:startPaint
                            endCGPaint:endPaint
                               options:options]);
}

@end

