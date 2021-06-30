#import "CAImageLayer.h"

#import "import-private.h"


// #define RENDER_DEBUG


@implementation CAImageLayer

- (id) init
{
   self = [super init];
   if( self)
      _selectionColor = MulleColorMake( 0x7FFF7F7F);
   return( self);
}


- (void) drawSelectionRect:(CGRect) canvas
                 inContext:(CGContext *) context
{
   NVGcontext   *vg;

   vg = CGContextGetNVGContext( context);

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
   int                 textureId;
   NVGpaint            imgPaint;
   CGSize              imageSize;
   CGRect              canvas;
   CGRect              rect;
   CGDrawableOptions   options;

   [super drawInContext:context];

   imageSize = [_image size];
   canvas    = [self canvas];
   rect      = CGSizePlaceInRect( imageSize, canvas, _contentMode);

   options = CGDrawableOptionsMake( _cornerRadius,
                                    _selected ? 0.5 : 1.0,
                                    0.0,
                                    YES);
   [_image drawRect:rect
            options:&options
            context:context];

   if( _selected)
      [self drawSelectionRect:canvas
                    inContext:context];
}

@end
