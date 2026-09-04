//
//  CGGraphicsLayer.h
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
#import "import.h"


@class CGContext;
@class CGGraphicsLayer;



@protocol CGGraphicsLayerLayouter

- (void) layoutLayer:(CGGraphicsLayer *) layer
                info:(struct UILayoutInfo *) info;

- (CGSize) layer:(CGGraphicsLayer *) layer
    sizeThatFits:(CGSize) size
         context:(id <UILayoutContext>) context;

- (void) dumpWithIndent:(NSUInteger) indent
                   FILE:(FILE *) fp;
@end

//
// if the callback returns NO, then the drawInContext: method preempts.
// If you return YES, then the drawing will be underneath whatever the
// CGGraphicsLayer will draw. YES should be the default.
//
typedef BOOL   CGGraphicsLayerDrawCallback_t( CGGraphicsLayer *layer,
                                              CGContext *context);

// A CGGraphicsLayer ideally only contains the necessary information to
// draw what its supposed to draw and no more. Ideally the CGGraphicsLayer
// can be serialized, send over a wire, then get deserialized on the other
// side of the planet and then it draws the same it would draw in this
// process.
//
// Try to offload as much as possible especially in regards to layouting
// and user interaction to UIView. A CGGraphicsLayer should just draw.
//
// inherits all the geometry smarts from CALayer.
//
@interface CGGraphicsLayer : CALayer


// animatable properties
@property( observable) MulleCornerInsets   cornerInsets;

@property( observable) CGFloat             borderWidth;
@property( observable, copy) CGPaint       *borderPaint;
@property( observable, copy) CGPaint       *backgroundPaint;
// colors are "conveniences" for borderPaint and backgroundPaint
// they are properties, so we can animate them
@property( observable, dynamic) CGColor    borderColor;
@property( observable, dynamic) CGColor    backgroundColor;

@property( observable, assign) CARotation  rotation;

// anchorPoint is used to determine the position from frame
@property( observable, assign) CGPoint     anchorPoint;

// pose is position and rotation (its dynamically calculated)
@property( dynamic, assign) CAPose         pose;
// position is based on frame and anchorPoint (its dynamically calculated)
@property( dynamic) CGPoint                position;

// draw [layer canvas]
// clip [layer bounds]
@property CGGraphicsLayerDrawCallback_t    *drawCallback;

// set to stderr or stdout turn off with NULL (default)
// NULL will not disrupt a CGContext trace though
@property( assign) FILE                    *drawCallTracer;
@property( dynamic, assign) CGFloat        cornerRadius;

@property( retain, nonserializable) id <CGGraphicsLayerLayouter>  layouter;

// MEMO: initNoLock is actually the designated initializer funneled into by
// _initWithFrame which is hidden. Subclasses generally want to override
// initWithFrame: though
// - (instancetype) initNoLock;                    // designated
// - (instancetype) initWithFrame:(CGRect) frame;

@end


static inline BOOL   CGGraphicsLayerExecuteDrawCallback( CGGraphicsLayer *self,
                                                         CGContext *context)
{
   if( ! self)
      return( NO);
   return( ((struct { @defs( CGGraphicsLayer); } *) self)->_drawCallback
           ? (*((struct { @defs( CGGraphicsLayer); } *) self)->_drawCallback)( self, context)
           : YES);
}


