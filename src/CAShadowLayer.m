//
//  CAShadowLayer.m
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


#define SHADOW_WIDTH    6.0
#define SHADOW_HEIGHT   8.0



@implementation CAShadowLayer

#ifdef DEBUG
+ (instancetype) alloc
{
   return( [super alloc]);
}
#endif


- (instancetype) initNoLock
{
   self = [super initNoLock];
   if( self)
   {
      _cornerInsets = MulleCornerInsetsMakeWithCornerRadius( fmaxf( SHADOW_HEIGHT, SHADOW_HEIGHT) / 2.0f);
      _shadowBlur   = fmaxf( SHADOW_WIDTH, SHADOW_HEIGHT) / 2.0f;

      _shadowColor  = CGColorMakeWithRGBA( 0.0f, 0.0f, 0.0f, 0.25f);
      _shadowInsets = MulleEdgeInsetsMake( - SHADOW_HEIGHT / 2.0f,
                                           - SHADOW_WIDTH / 2.0f,
                                           SHADOW_HEIGHT / 2.0f,
                                           SHADOW_WIDTH / 2.0f);
   }
   return( self);
}


- (id) copy
{
   CAShadowLayer  *copy;

   copy = [super copy];

   copy->_cornerInsets = self->_cornerInsets;
   copy->_shadowBlur   = self->_shadowBlur;
   copy->_shadowColor  = self->_shadowColor;
   copy->_shadowInsets = self->_shadowInsets;

   return( copy);
}


- (CGRect) shadowedRect
{
   CGRect   canvas;

   canvas = [self canvas];
   return( MulleEdgeInsetsInsetRect( _shadowInsets, canvas));
}

@end
