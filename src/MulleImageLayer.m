#import "MulleImageLayer.h"

#import "import-private.h"


// #define RENDER_DEBUG


@implementation MulleImageLayer

- (instancetype) initWithImage:(NSObject <CGImage> *) image
{
	assert( ! image || [image conformsToProtocol:@protocol( CGImage)]);

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


- (void) drawSelectionRect:(CGRect) canvas
                 inContext:(CGContext *) context
{
   NVGcontext   *vg;

   vg = MulleContextGetNVGContext( context);

   // MEMO: wenn man den nvgBeginPath weglaesst, dann klippt das rect gegen
   // den letzten shape, was ev. ganz nuetzlich mal sein kann.
   nvgBeginPath( vg);
   nvgRect( vg, canvas.origin.x,
                canvas.origin.y,
                canvas.size.width,
                canvas.size.height);
   nvgFillColor( vg, _selectionColor);
   nvgFill( vg);
}


- (void) drawInContext:(CGContext *) context
{
   int          textureId;
   NVGpaint     imgPaint;
   CGSize       imageSize;
   CGRect       canvas;
   CGRect       rect;

   imageSize = [_image size];
   canvas    = [self canvas];
   rect      = MulleSizeApplyContentModeInRect( imageSize, _contentMode, canvas);

   [_image drawRect:rect
       cornerRadius:_cornerRadius
              alpha:_selected ? 0.5 : 1.0
            context:context];

   if( _selected)
      [self drawSelectionRect:canvas
                    inContext:context];
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
