//
//  CAShapeLayer.m
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
#import "CAShapeLayer.h"

#import "import-private.h"


@implementation CAShapeLayer

- (instancetype) initNoLock
{
   self = [super initNoLock];
   if( self)
   {
      _ownsPath = YES;
   }
   return( self);
}


- (void) setPath:(CGPath *) path
{
   assert( !path || path != _path);

   if( _ownsPath)
      CGPathDestroy( _path);
   _path = path;
}


- (void) dealloc
{
   if( _ownsPath)
      CGPathDestroy( _path);
   [super dealloc];
}


- (id) copy 
{
   CAShapeLayer  *copy;

   copy = [super copy];

   copy->_strokePaint  = [self->_strokePaint copy];   
   copy->_fillPaint    = [self->_fillPaint copy];   
   copy->_strokeWidth  = self->_strokeWidth;   
   copy->_path         = CGPathCopy( self->_path, MulleObjCInstanceGetAllocator( copy));
   copy->_ownsPath     = YES;   

   return( copy);
}


// MEMO: a paint is usually a value and not mutable i.e. thread-safe no problem
//       we don't need to gain or relinquish. But! if we have a CGImage it
//       could be a CGFramebuffer, which is mutable and we would need to
//       transfer it. But! The CGImage is also part of the resource management
//       of the CGContext and will be gained/relinquished there. So doing it
//       twice would be disastrous. So luck has it, we don't need to
//       transfer paints. Now with the uniquing done by NSObject this should
//       all be moot, but the comment is left in, in case not...

- (void) setStrokeColor:(CGColor) color
{
   [self setStrokePaint:[CGPaint paintWithColor:color]];
}


- (void) setFillColor:(CGColor) color
{
   [self setFillPaint:[CGPaint paintWithColor:color]];
}


- (CGColor) strokeColor
{
   return( [_strokePaint mainColor]);
}


- (CGColor) fillColor
{
   return( [_fillPaint mainColor]);
}

@end
