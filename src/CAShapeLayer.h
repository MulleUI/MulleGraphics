//
//  CAShapeLayer.h
//  MulleGraphics
//
//  Copyright (c) 2020 Nat! - Mulle kybernetiK.
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
