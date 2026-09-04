//
//  CAImageLayer.m
//  MulleGraphics
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
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
#import "CAImageLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"


// #define RENDER_DEBUG


@implementation CAImageLayer

MulleCursorImplementation;


+ (instancetype) layerWithImage:(NSObject <CGDrawable> *)  image
{
   CAImageLayer *obj;

   obj = [self alloc];
   obj = [obj initWithImage:image];
   obj = [obj autorelease];
   return(obj);
}


- (id) initWithImage:(NSObject <CGDrawable> *)  image
{
   CGRect   frame;

   frame.origin = CGPointZero;
   frame.size   = [image size];

   self = [self initWithFrame:frame];
   [self setImage:image];
   return( self);
}


- (id) initNoLock
{
   self = [super initNoLock];
   if( self)
      _selectionPaint = [[CGPaint paintWithHexColor:0x7FFF7F7F] copy];
   return( self);
}



- (id) copy
{
   CAImageLayer  *copy;

   copy = [super copy];

   MulleCursorCopy( copy, self);

   copy->_selected       = self->_selected;
   copy->_selectionPaint = [self->_selectionPaint copy];

   // the -copy is preferred, the -retain can be questionable if the image
   // is actually mutable
   if( [self->_image respondsToSelector:@selector( copy)])
      copy->_image       = [(id <NSCopying>) self->_image copy];
   else
      copy->_image       = [self->_image retain];

   copy->_displayedRect  = self->_displayedRect;
   copy->_contentMode    = self->_contentMode;

   return( copy);
}


- (void) setSelectionColor:(CGColor) color
{
   [self setSelectionPaint:[CGPaint paintWithColor:color]];
}


- (void) drawSelectionRect:(CGRect) canvas
                 inContext:(CGContext *) context
{
   // MEMO: wenn man den nvgBeginPath weglaesst, dann klippt das rect gegen
   // den letzten shape, was ev. ganz nuetzlich mal sein kann.

   CGContextFillRectWithPaintable( context, canvas, _selectionPaint);
}


- (BOOL) drawInContext:(CGContext *) context
{
   CGSize              imageSize;
   CGRect              canvas;
   CGRect              rect;
   CGDrawableOptions   options;

   if( ! [super drawInContext:context])
      return( NO);

   canvas    = [self canvas];
   imageSize = [_image size];
   rect      = CGSizePlaceInRect( imageSize, canvas, _contentMode);

   // for radial rainbows...
   if( isinf( imageSize.width))
   {
      rect.origin.x   = canvas.origin.x;
      rect.size.width = canvas.size.width;
   }
   if( isinf( imageSize.width))
   {
      rect.origin.y    = canvas.origin.y;
      rect.size.height = canvas.size.height;
   }

   options = CGDrawableOptionsMake( _cornerInsets,
                                    _selected ? 0.5 : 1.0,
                                    CGRotationNone,
                                    [_image isRepeating] ? CGScaleNone : CGScaleToFit,
                                    CGFlipNone,
                                    CGRepeatAsIs,
                                    CGContentModeCenterPoint);
   if( _displayedRect.size.width != 0.0 && _displayedRect.size.height != 0.0 &&
       [_image respondsToSelector:@selector( drawRect:fromRect:options:context:)])
   {
      [(CGBitmapDrawable *) _image drawRect:rect
                                   fromRect:_displayedRect
                                    options:&options
                                    context:context];
   }
   else
      [_image drawRect:rect
               options:&options
               context:context];

   if( _selected)
      [self drawSelectionRect:canvas
                    inContext:context];

   return( YES);
}

@end
