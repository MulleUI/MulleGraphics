#import "CAImageLayer.h"

#import "import-private.h"

#import "CALayer+MulleGraphics.h"


// #define RENDER_DEBUG


@implementation CAImageLayer

- (id) init
{
   self = [super init];
   if( self)
      _selectionColor = CGColorMakeWithHexColor( 0x7FFF7F7F);
   return( self);
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
   int                 imageID;
   NVGpaint            imgPaint;
   CGSize              imageSize;
   CGRect              canvas;
   CGRect              rect;
   CGDrawableOptions   options;

   [super drawInContext:context];

   imageSize = [_image size];
   canvas    = [self canvas];
   rect      = CGSizePlaceInRect( imageSize, canvas, _contentMode);
   options = CGDrawableOptionsMake(  _selected ? 0.5 : 1.0,
                                     _cornerRadius,
                                     CGRotationNone,
                                     [_image isRepeating] ?  CGScaleNone : CGScaleToFit,
                                     CGFlipNone,
                                     CGRepeatAsIs,
                                     CGContentModeCenterPoint);
   [_image drawRect:rect
            options:&options
            context:context];

   if( _selected)
      [self drawSelectionRect:canvas
                    inContext:context];
}

@end
