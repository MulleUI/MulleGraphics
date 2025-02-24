#import "CAImageLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"


// #define RENDER_DEBUG


@implementation CAImageLayer


+ (instancetype) layerWithImage:(NSObject <CGDrawable> *)  image
{
   return( [[[self alloc] initWithImage:image] autorelease]);
}


- (id) init
{
   self = [super init];
   if( self)
      _selectionPaint = [[CGPaint paintWithHexColor:0x7FFF7F7F] copy];
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


- (void) mulleGainAccess
{
   [super mulleGainAccess];
   [self->_image mulleGainAccess];  
   [self->_selectionPaint mulleGainAccess];  
}


- (void) mulleRelinquishAccess
{
   [self->_selectionPaint mulleRelinquishAccess];  
   [self->_image mulleRelinquishAccess];  
   [super mulleRelinquishAccess];
}



- (void) setSelectionColor:(CGColor) color
{
   [self setSelectionPaint:[CGPaint paintWithColor:color]];
}


- (void) drawSelectionRect:(CGRect) canvas
                 inContext:(CGContext *) context
{
   NVGcontext   *vg;

   vg = CGContextGetNVGContext( context);

   // MEMO: wenn man den nvgBeginPath weglaesst, dann klippt das rect gegen
   // den letzten shape, was ev. ganz nuetzlich mal sein kann.

   mvgFillRectWithPaint( vg, canvas, _selectionPaint);
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
