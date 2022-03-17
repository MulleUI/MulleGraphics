#import "CAImageLayer.h"

#import "import-private.h"


// #define RENDER_DEBUG


@implementation CAImageLayer( NanoVG)

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

@end
