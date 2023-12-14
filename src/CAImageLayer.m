#import "CAImageLayer.h"

#import "import-private.h"

#import "CALayer+MulleGraphics.h"


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
   CGRect              displayedRect;
   CGDrawableOptions   options;
   CGPoint             factor;
   CGPoint             scale;

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
      //
      // Unfortunately OpenGL "overreaches" into neighboring texturing, when
      // scaling up the pixels
      // The math gets a little bit too pragmatic here...
      //

      displayedRect = _displayedRect;
      scale.x       = rect.size.width  / displayedRect.size.width;
      scale.y       = rect.size.height / displayedRect.size.height;
      if( scale.x > 1.0)
         factor.x = scale.x < 2.0
                    ? (rect.size.width - displayedRect.size.width) / displayedRect.size.width / 2.0
                    : 0.5;
      if( scale.y > 1.0)
         factor.y = scale.y < 2.0
                    ? (rect.size.height - displayedRect.size.height) / displayedRect.size.height / 2.0
                    : 0.5;

      displayedRect.origin.x    += factor.x;
      displayedRect.origin.y    += factor.y;
      displayedRect.size.width  -= factor.x * 2.0;
      displayedRect.size.height -= factor.y * 2.0;

//      MulleUILog( "rect                                   : %s", CGRectUTF8String( rect));
//      MulleUILog( "_displayedRect (dRect)                 : %s", CGRectUTF8String( _displayedRect));
//      MulleUILog( "_fummel                                : %s", CGPointUTF8String( _fummel));
//      MulleUILog( "scale = rect.size / dRect.size         : %s", CGPointUTF8String( scale));
//      MulleUILog( "factor = _fummel * scale               : %s", CGPointUTF8String( factor));
//      MulleUILog( "displayedRect = inset( dRect, _fummel) : %s", CGRectUTF8String( displayedRect));

      [(CGBitmapDrawable *) _image drawRect:rect
                                   fromRect:displayedRect
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
