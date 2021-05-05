#import "MulleImageLayer.h"

#import "UIImage.h"
#import "CGContext.h"

// #define RENDER_DEBUG

@implementation UIImage( MulleImageLayer)

#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

- (Class) preferredLayerClass
{
	return( [MulleImageLayer class]);
}

@end


@implementation MulleImageLayer

- (instancetype) initWithImage:(UIImage *) image
{
	assert( ! image || [image isKindOfClass:[UIImage class]]);

   if( ! (self = [super init]))
      return( self);

   _image        = [image retain];  // ownership transfer

   _canvas.origin = CGPointZero;
   _canvas.size   = [image size];

   // set as well for convenience
   _frame          = _canvas;

   _selectionColor = MulleColorMake( 0x7FFF7F7F);

   return( self);
}


- (void) dealloc
{
   [_image release];

   [super dealloc];
}


- (void) drawInContext:(CGContext *) context
{
   int          textureId;
   NVGpaint     imgPaint;
   NVGcontext   *vg;
   CGSize       imageSize;
   CGRect       canvas;
   CGFloat      alpha;
   CGRect       rect;
   CGRect       layoutedRect;
   BOOL         flag;

   if( ! _image)
      return;

   textureId = [_image textureIDWithContext:context];
   if( textureId == -1)
      return;

   // TODO: check contentMode and translate/scale accordingly

   imageSize = [_image size];
   canvas    = [self canvas];
   alpha     = _selected ? 0.5 : 1.0;

   vg        = MulleContextGetNVGContext( context);
   nvgBeginPath( vg);

   layoutedRect = MulleSizeApplyContentModeInRect( imageSize, _contentMode, canvas);
//   flag = (_contentMode == UIViewContentModeScaleAspectFill);
//   if( flag)
   nvgIntersectScissor( vg, canvas.origin.x, canvas.origin.y, canvas.size.width, canvas.size.height);

   imgPaint  = nvgImagePattern( vg, layoutedRect.origin.x,
                                    layoutedRect.origin.y,
                                    layoutedRect.size.width,
                                    layoutedRect.size.height,
                                    0.0f/180.0f*NVG_PI,
                                    textureId,
                                    alpha);

   // shouldn't this be the frame ?
   nvgRoundedRect( vg, layoutedRect.origin.x,
                       layoutedRect.origin.y,
                       layoutedRect.size.width,
                       layoutedRect.size.height,
                       (int) _cornerRadius);
   nvgFillPaint( vg, imgPaint);
  // nvgFillColor( vg, getNVGColor( 0x402060FF));
   nvgFill( vg);

   //TODO: genau das gleiche wie MulleSVGLayer.Zusammenpacken!!
   if( _selected)
   {
      rect = [_image visibleBounds];

      layoutedRect = MulleSizeApplyContentModeInRect( rect.size, _contentMode, canvas);
      layoutedRect.origin.x += rect.origin.x;
      layoutedRect.origin.y += rect.origin.y;

      // MEMO: wenn man den nvgBeginPath weglaesst, dann klippt das rect gegen
      // den letzten shape, was ev. ganz nuetzlich mal sein kann.
		nvgBeginPath( vg);
      nvgRect( vg, layoutedRect.origin.x,
                   layoutedRect.origin.y,
                   layoutedRect.size.width,
                   layoutedRect.size.height);

  	   nvgFillColor( vg, _selectionColor);
	   nvgFill( vg);
   }
}


- (CGRect) visibleBounds
{
   CGRect   bounds;

   bounds = [_image visibleBounds];
   return( bounds);
}


- (void) getCursorPosition:(struct MulleIntegerPoint *) p_point
{
   p_point->x = _image ? 1 : 0;
   p_point->y = 0;
}


- (NSUInteger) characterIndexForPoint:(CGPoint) point
{
   // TODO: HACK!!!
   return( _image ? 1 : 0);
}


- (struct MulleIntegerPoint) cursorPositionForPoint:(CGPoint) mouseLocation
{
   // TODO: HACK!!!
   return( MulleIntegerPointMake( _image ? 1 : 0, 0));
}


- (CGFloat) offsetNeededToMakeCursorVisible
{
   return( 0.0);
}


- (struct MulleIntegerPoint) maxCursorPosition
{
   return( MulleIntegerPointMake( _image ? 1 : 0, 0));
}

@end
