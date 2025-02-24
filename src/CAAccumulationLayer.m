//
//  CAAccumulationLayer.m
//  MulleGraphics
//
//  Copyright (c) 2024 Nat! - Mulle kybernetiK.
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
#import "CAAccumulationLayer.h"

#import "import-private.h"



@implementation CAAccumulationLayer


- (instancetype) init
{
   self = [super init];
   if( self)
   {
      _decay               = 0.0;
      _previousFramebufferInsets = MulleEdgeInsetsMake( -1, 0.0, INFINITY, 0.0);
   }
   return( self);
}


- (void) setCurrentFramebuffer:(CGFramebuffer *) layer
{
   NSUInteger   i;

   i = _currentFramebufferIndex;
   [_framebuffer[ i] autorelease];
   _framebuffer[ i] = [layer retain];
}


- (CGFramebuffer *) currentFramebuffer
{
   NSUInteger   i;

   i = _currentFramebufferIndex;
   return( _framebuffer[ i]);
}


- (void) setPreviousFramebuffer:(CGFramebuffer *) layer
{
   NSUInteger   i;

   i = ! _currentFramebufferIndex;
   [_framebuffer[ i] autorelease];
   _framebuffer[ i] = [layer retain];
}


- (CGFramebuffer *) previousFramebuffer
{
   NSUInteger   i;

   i = ! _currentFramebufferIndex;
   return( _framebuffer[ i]);
}


- (void) swapFramebuffers
{
   _currentFramebufferIndex = ! _currentFramebufferIndex;
}


- (CGRect) rectForPreviousFramebuffer:(CGFramebuffer *) layer
                               canvas:(CGRect) canvas
{
   CGRect   rect;

   rect = canvas;

   // INFINITY means "sticky"
   if( ! isinf( _previousFramebufferInsets.left))
   {
      rect.origin.x += _previousFramebufferInsets.left;
      if( ! isinf( _previousFramebufferInsets.right))
         rect.size.width -= _previousFramebufferInsets.left;
   }
   if( ! isinf( _previousFramebufferInsets.right))
      rect.size.width -= _previousFramebufferInsets.right;

   if( ! isinf( _previousFramebufferInsets.top))
   {
      rect.origin.y += _previousFramebufferInsets.top;
      if( ! isinf( _previousFramebufferInsets.bottom))
         rect.size.height -= _previousFramebufferInsets.top;
   }
   if( ! isinf( _previousFramebufferInsets.bottom))
      rect.size.height -= _previousFramebufferInsets.bottom;

   return( rect);
}


// thx: perplexity.ai
static inline double   computeDecayFactor( double y, int n)
{
    return pow( y, 1.0 / n);
}


- (float) alphaForPreviousFramebuffer:(CGFramebuffer *) layer
                               inRect:(CGRect) rect
                               canvas:(CGRect) canvas
{
   int       step;
   CGFloat   xOffset;
   CGFloat   yOffset;
   float     alpha;

   xOffset = fabsf( canvas.size.width - rect.size.width);
   yOffset = fabsf( canvas.size.height - rect.size.height);
   step    = 0;
   if( xOffset > yOffset)
      step = (int) canvas.size.width / xOffset;
   else
      if( yOffset != 0.0)
         step = (int) canvas.size.height / yOffset;

   if( ! step)
      step = (int) ceilf( canvas.size.height);

   alpha = computeDecayFactor( 1.0 - CGFloatClampToUnity( _decay), step);
   return( alpha);
}


- (void) drawPreviousFramebuffer:(CGFramebuffer *) layer
                       inContext:(CGContext *) context
                          canvas:(CGRect) canvas
{
   CGRect              rect;
   float               alpha;
   struct NVGcontext   *vg;
   NVGpaint            paint;

   rect   = [self rectForPreviousFramebuffer:layer
                                canvas:canvas];
   // figure out the alpha decay...
   // rect.size.height / 4 is the number of moves
   alpha = [self alphaForPreviousFramebuffer:layer
                                inRect:rect
                                canvas:canvas];

// Hack alpha like this
//   [previousFramebuffer setAlpha:alpha];
//   mvgFillRectWithPaint( vg, rect, previousFramebuffer);
   vg  = CGContextGetNVGContext( context);

   mvgBeginPath( vg);
   mvgRect( vg, rect);
   paint = mvgImagePattern( vg, rect, 0.0, [layer textureID], alpha);
   mvgFillPaint( vg, paint);
   mvgFill( vg);
}


- (void) willDrawInContext:(CGContext *) context
{
   CGFramebuffer              *drawFramebuffer;
   CGFramebuffer              *previousFramebuffer;
   CGRect                     canvas;
   CGPixelSize    bitmapSize;

   canvas     = [self canvas];
   bitmapSize = CGPixelSizeMakeWithSize( canvas.size);

   // get the layer we want to draw into, if the size of the window has
   // changed we junk it and build a-new
   drawFramebuffer  = [self currentFramebuffer];
   if( ! CGPixelSizeEqualToPixelSize( [drawFramebuffer bitmapSize],
                                             bitmapSize))
   {
      drawFramebuffer = [CGFramebuffer framebufferWithBitmapSize:bitmapSize
                                  textureFlags:0
                                       context:context];
      [self setCurrentFramebuffer:drawFramebuffer];
   }

   // the previousFramebuffer is kept as is, even if the size doesn't match
   // yet, as we scale the old contents. If we have none, then create a
   // rectangle of pure pitch black
   previousFramebuffer = [self previousFramebuffer];
   if( ! previousFramebuffer)
   {
      previousFramebuffer = [CGFramebuffer framebufferWithBitmapSize:bitmapSize
                                      textureFlags:0
                                           context:context];
      // init it with black
      [previousFramebuffer beginFBRenderWithBackgroundColor:CGColorMakeBlack()
                                           devicePixelRatio:1.0
                                            layerRenderInfo:&_memo];
      [previousFramebuffer endFBRender:&_memo];

      [self setPreviousFramebuffer:previousFramebuffer];
   }

   //
   // now copy over old contents into drawFramebuffer, then draw stuff fresh on
   // top
   [drawFramebuffer beginFBRenderWithBackgroundColor:CGColorMakeBlack()
                                    devicePixelRatio:1.0
                                     layerRenderInfo:&_memo];

   // a CGFramebuffer is a CGImage which is a CGPaint, so we don't have to do
   // much except reduce alpha
   [self drawPreviousFramebuffer:previousFramebuffer
                       inContext:context
                          canvas:canvas];
}


- (void) didDrawInContext:(CGContext *) context
{
   CGFramebuffer   *drawFramebuffer;
   CGRect          canvas;

   drawFramebuffer = [self currentFramebuffer];
   [drawFramebuffer endFBRender:&_memo];

   canvas = [self canvas];
   // now render into "our" context
   [drawFramebuffer drawRect:canvas
               options:NULL
               context:context];
   [self swapFramebuffers];
}

@end

