//
//  CAAnimation+CGPaint.m
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
#import "CAAnimation+CGPaint.h"

#import "import-private.h"

#import "CABasicAnimation+CGGradient.h"
#import "CABasicAnimation+CGPaint.h"



// this gets called from CAAnimation in "animate_object_property", it will
// eventually call the constructor above 

@implementation CGPaint( CAAnimation)

+ (CAAnimation *) animationFrom:(id) startObject
                                   to:(id) endObject
                             property:(struct _mulle_objc_property *) property
                              options:(struct CABasicAnimationOptions *) options
{
   if( ! startObject && ! endObject)
      return( nil);

   startObject = MULLE_OBJC_CLASS_CAST( CGPaint, startObject);
   endObject   = MULLE_OBJC_CLASS_CAST( CGPaint, endObject);

   // this will also catch monoColor as it is a CGGradient subclass
   if( (! startObject || [startObject __isCGGradient]) &&
       (! endObject   || [endObject __isCGGradient]))
   {
      return( [CABasicAnimation animationWithProperty:property
                                      startCGGradient:startObject
                                        endCGGradient:endObject
                                              options:options]);
   }

   return( [CABasicAnimation animationWithProperty:property
                                      startCGPaint:startObject
                                        endCGPaint:endObject
                                           options:options]);

}

@end

