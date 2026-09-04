//
//  CGGraphicsLayer.m
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
#import "import-private.h"

#import "CGGraphicsLayer.h"


#pragma clang diagnostic ignored "-Wparentheses"
// #define RENDER_DEBUG
// #define CALAYER_DEBUG

@interface CALayer( Private)

- (id) _initWithFrame:(CGRect) frame;

@end


@implementation CGGraphicsLayer

- (id) _initWithFrame:(CGRect) frame
{
   self = [super _initWithFrame:frame];
   if( ! self)
      return( self);

   _anchorPoint = CGPointMake( 0.5, 0.5);

   return( self);
}


- (id) copy 
{
   CGGraphicsLayer  *copy;

   // check that the subclass is actually implementing -copy, otherwise the
   // user is probably in a world of pain soon afterwards
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⠚⠋⢙⠉⠛⢶⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠀⢴⣿⣷⣶⣤⣰⠆⠀⠀⢀⡰⢟⣩⣵⣷⣶⣶⣿⣿⣾⡀⢄⠐⠀⠐⠀⠂⠀⠆⠀⠆⠐⢀⣰⣠⣴⣿⣿⣶
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠛⠿⠿⠻⠀⠂⠀⠂⢻⣯⣿⣿⣿⣿⣿⣿⣿⣿⣷⣌⢮⡀⢆⠀⡂⢐⠀⡆⠠⠣⠌⢻⠛⠟⠩⠉⠍
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠊⠹⣿⣿⠿⠋⠉⠉⢲⡆⠀⡂⠤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀
   // ⣆⠀⣀⢠⡄⠤⢴⣴⣶⣶⣶⣶⣾⣿⣷⡄⠀⠀⢀⠀⠀⢠⣤⣤⣰⣶⣾⣿⣷⠆⠀⢀⠾⠿⠆⣧⣼⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⢺⠆⠀⠀⠀⠀
   // ⡃⠀⠈⢸⢐⢚⣺⣿⠿⣿⣿⣿⣿⣿⣿⠁⠀⠐⠻⣿⣦⣾⣿⣿⣿⣧⣿⣿⣿⣿⣾⡔⣀⠀⣠⣿⣟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀
   // ⡁⠀⠐⠘⢈⣈⣆⣹⣃⣻⣿⣿⣿⣿⣷⣀⠀⠀⠀⣈⡉⠙⢿⣿⣿⠈⣿⣿⣿⣿⣿⢨⣾⣏⢙⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀
   // ⠀⠀⠀⠀⢀⢀⡀⢀⠶⢂⠟⣿⣿⣿⣿⣿⣷⣶⣿⣿⣿⣷⡄⠀⠟⠀⢸⣆⠀⠁⠀⠈⠉⠉⠀⠉⠀⠀⠀⠤⠤⠤⠶⠶⠴⠶⠶⠶⠷⠶⠿⠷⠶
   // ⠂⠀⠀⠠⠶⣸⣘⣩⣉⣈⣉⣿⣿⣿⣿⣟⠉⠉⠙⠿⠿⢟⣵⣆⣠⡔⠀⠙⠷⡆⠀⠀⠀⠀⢀⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⢿⣦⡀⠀⠀⠐⣤⣔⡀⢶⣾⣿⡄⠀⠢⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⣁⣠⣤⣭⣷⣿⣷⡄⠹⣷⣤⡀⠀⠈⠻⣿⣿⣿⣿⣿⡆⠀⠈⠛⢿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿
   // ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠛⠛⣛⣹⣿⣿⡧⠀⣿⣿⣿⣿⣦⠀⠙⢿⣿⣿⣿⡷⠀⠀⠀⣤⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
   // ⣿⣿⣿⣿⡿⠋⠠⠤⠀⠈⠋⠁⡀⠈⠹⢿⣦⣤⠀⠀⠻⢿⣿⣿⡇⠀⣻⣿⣿⣿⣿⣷⡄⠀⠈⠻⣿⡇⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
   // ⣿⣿⡟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠃⠻⣿⡄⠀⠀⠀⠻⣿⠇⠀⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠘⠁⠀⠀⠀⠀⠀⠙⣿⣷⣶⡞⢉⣴⡾⡟⠫
   // ⡞⣷⠇⡟⣷⣿⢸⢸⢸⣻⢾⣟⢤⢸⡃⣿⣼⠘⡟⢸⣟⢸⣻⢸⡇⣷⣿⣼⣻⢹⢿⢿⢹⢹⣼⣧⡇⣿⣷⢸⣻⢸⡇⢸⢻⣎⢱⣿⡆⣟⡛⠛⠃
   // ⣿⠿⢀⠧⠟⠻⠼⢸⡸⠸⠿⠧⢸⠸⠤⠿⠿⠀⠇⠸⠧⠸⠸⠸⠇⠏⠿⠻⠽⢸⠸⠻⢾⡼⣟⡿⠇⠿⠿⠸⠸⠺⠧⠸⠼⣿⣼⠿⡇⠇⠀⠀⠀
   // ⠀⠀⢈⠀⠀⠀⠀⠉⠉⠈⠉⠉⠘⢛⠿⠸⠿⠇⠀⠀⠀⢀⣀⡀⣀⡀⣀⢐⢛⢻⣿⣿⣵⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿
   // ⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠴⠦⠀⠀⣴⣶⣾⡀⠀⠀⢸⡷⢇⣏⡇⣿⢸⣿⢸⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⣽⣿⢹⣿⣿⣿
   // ⡀⠀⢸⢀⣀⣀⡀⠤⢤⡄⠀⠀⠀⠀⠐⡿⠿⣿⣷⣤⣤⠘⡃⠘⠃⠓⠛⠘⣸⣼⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⡇⣇⣈⣈⣉⣉⣹
   assert( MulleObjCClassImplementsSelector( [self class], @selector( copy)) &&
           "your subclass must implement -copy and then start by "
           "calling [super copy] then add additional copy code");

   copy = [super copy];

   copy->_borderPaint     = [self->_borderPaint copy];
   copy->_backgroundPaint = [self->_backgroundPaint copy];

   copy->_rotation        = self->_rotation;
   copy->_anchorPoint     = self->_anchorPoint;
   copy->_cornerInsets    = self->_cornerInsets;   
   copy->_borderWidth     = self->_borderWidth;   
   copy->_drawCallback    = self->_drawCallback;    

   return( copy);
}


- (void) setCornerRadius:(CGFloat) r
{
   _cornerInsets = MulleCornerInsetsMakeWithCornerRadius( r);
}


- (CGFloat) cornerRadius
{
   return( fmaxf( fmaxf( _cornerInsets.topLeft, _cornerInsets.topRight),
                  fmaxf( _cornerInsets.bottomLeft, _cornerInsets.bottomRight)));
}


- (void) setBorderColor:(CGColor) color
{
   [self setBorderPaint:[CGPaint paintWithColor:color]];
}


- (void) setBackgroundColor:(CGColor) color
{
   [self setBackgroundPaint:[CGPaint paintWithColor:color]];
}


- (CGColor) borderColor
{
   return( [_borderPaint mainColor]);
}


- (CGColor) backgroundColor
{
   return( [_backgroundPaint mainColor]);
}


- (CGPoint) position
{
   CGPoint   pos;

   pos.x = _frame.origin.x + (_frame.size.width * _anchorPoint.x);
   pos.y = _frame.origin.y + (_frame.size.height * _anchorPoint.y);

   return( pos);
}


- (void) setPosition:(CGPoint) position
{
   CGRect newFrame = _frame;

   newFrame.origin.x = position.x - (_frame.size.width * _anchorPoint.x);
   newFrame.origin.y = position.y - (_frame.size.height * _anchorPoint.y);

   [self setFrame:newFrame];
}


- (CAPose) pose
{
   CGPoint   pos;

   pos.x = _frame.origin.x + (_frame.size.width * _anchorPoint.x);
   pos.y = _frame.origin.y + (_frame.size.height * _anchorPoint.y);

   return( CAPoseMakeWithPositionAndRotation( pos, _rotation));
}


- (void) setPose:(CAPose) pose
{
   _frame.origin.x = pose.position.x - (_frame.size.width * _anchorPoint.x);
   _frame.origin.y = pose.position.y - (_frame.size.height * _anchorPoint.y);
   _rotation       = CAPoseGetRotation( pose);
}


- (void) layoutWithLayoutInfo:(struct UILayoutInfo *) info
{
   [_layouter layoutLayer:self
                     info:info];
}



- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp
{
   [super dumpWithIndent:indent
                    FILE:fp];
   [_layouter dumpWithIndent:indent + 3
                        FILE:fp];
}


//
// forward methods to layouter
//
- (void *) forward:(void *) param
{
   void   *rval;
   int    fail = 0;

   rval = _MulleDynamicObjectForward( self, _cmd, param, &fail);
   if( ! fail)
      return( rval);

   return( mulle_objc_object_call_variable_inline( _layouter,
                                                   (mulle_objc_methodid_t) _cmd,
                                                   param));
}

@end

