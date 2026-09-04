//
//  CGGraphicsLayer+MulleGraphics.h
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
// prefer a local CALayer over one in import.h
#ifdef __has_include
# if __has_include( "CGGraphicsLayer.h")
#  import "CGGraphicsLayer.h"
# endif
#endif

// we want "import.h" always anyway
#import "import.h"

#ifdef __has_include
# if __has_include( <MulleCG/CGContext+Render.h>)
#  import <MulleCG/CGContext+Render.h>
# endif
#endif


@interface CGGraphicsLayer( MulleGraphics) < CGRenderObject>

//
// renderInContext resets the drawing context with transform and global alpha
// then calls (in this order):
//
//    -drawBackgroundInContext:  // will not be called if backgroundColor * opacity * alpha is transparent
//    [CGContext saveState];     // or similiar :)
//    -drawInContext:            // if bounds.size != zero
//    [CGContext restoreState];  // or similiar :)
//    -drawBorderInContext:      // will not be called if borderColor * opacity * alpha is transparent
//
// If you do drawing afterwards, its best to nvgReset( vg); If you are
// calling this from your own drawCallBack() then wrap it in nvgSave()
// nvgRestore()
//
- (void) renderInContext:(CGContext *) ctx;

//
// Subclasses do their drawing in -drawInContext. The default implementation
// calls the drawCallback if one is set, otherwise it does nothing.
//
// This method should draw "canvas". The transformation has been setup for
// frame/bounds projection already by renderInContext:
//
// The drawing context will have been saved before
// the call and restored afterwards. You may assume the state is setup
// as if nvgReset() has been called with the following exceptions:
//
// fillColor is random
// strokeColor is random
// transform is setup already
// alpha is setup already
//
// if [super drawInContext:] returns NO, do not continue drawing
//
// if you don't want do call [super drawInContext:], you should call
// CGGraphicsLayerExecuteDrawCallback, so that your code can be patched out
// from C:
//
// if( ! CGGraphicsLayerExecuteDrawCallback( self, context))
//    return( NO);
//
- (BOOL) drawInContext:(CGContext *) context;


// immediately called before and after drawInContext
// return YES, to draw. call super in willDrawInContext to setup the
// proper transforms
- (BOOL) willDrawInContext:(CGContext *) context;
- (void) didDrawInContext:(CGContext *) context;

//
// these two methods draw "frame". Bounds and canvas are to be ignored.
// therefore a border doesn't scale with bounds!
//
// Ensure that the drawing context remains unchanged except for
// fillColor and strokeColor.
//

// default impl. says NO, if alpha time background color alpha is transparent
- (BOOL) drawsBackgroundWithAlpha:(CGFloat) alpha;

- (void) drawBackgroundInContext:(CGContext *) context;
- (void) drawBorderInContext:(CGContext *) context;

// only use this method in drawBackgroundInContext
- (void) fillBackgroundInContext:(CGContext *) context
                           paint:(CGPaint *) paint;

// Returns canvas.size. Subclasses may want to compute actual used space
// and return it. Used for layouting by UIView
- (CGSize) sizeThatFits:(CGSize) size
                context:(id <UILayoutContext>) context;

@end


MULLE_GRAPHICS_GLOBAL
void  CGGraphicsLayerSetupDrawTransform( CGGraphicsLayer *self,
                                         CGContext *context,
                                         CGRect bounds);



static inline
CGAffineTransform  CGGraphicsLayerMakeBoundsTransform( CGRect frame,
                                                       CGRect bounds)
{
   CGAffineTransform   originTransform;
   CGAffineTransform   boundsTransform;
   CGAffineTransform   scaleTransform;
   CGVector            scale;

   originTransform = CGAffineTransformMakeTranslationInline( frame.origin);
   boundsTransform = CGAffineTransformMakeTranslationInline( CGPointNegate( bounds.origin));
   scale           = CGVectorMake(frame.size.width / bounds.size.width,
                                  frame.size.height / bounds.size.height);
   scaleTransform  = CGAffineTransformMakeScaleInline( scale);

   boundsTransform = CGAffineTransformConcatInline( originTransform, boundsTransform);
   boundsTransform = CGAffineTransformConcatInline( boundsTransform, scaleTransform);
   return( boundsTransform);
}


static inline
CGAffineTransform  CGGraphicsLayerMakeRotationTransform( CGRect canvas,
                                                         CGPoint anchorPoint,
                                                         CARotation rotation)
{
   CGAffineTransform   rotationTransform;
   CGPoint             center;

   center            = CGRectGetCenterWithAnchorPoint( canvas, anchorPoint);
   rotationTransform = CGAffineTransformMakeRotationAroundPoint( center, rotation);
   return( rotationTransform);
}
