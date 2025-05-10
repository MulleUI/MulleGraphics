#import "import-private.h"

#import "CGGraphicsLayer.h"


#pragma clang diagnostic ignored "-Wparentheses"
// #define RENDER_DEBUG
// #define CALAYER_DEBUG

@implementation CGGraphicsLayer


- (id) copy 
{
   CGGraphicsLayer  *copy;

   copy = [super copy];

   copy->_cornerInsets    = self->_cornerInsets;   
   copy->_borderWidth     = self->_borderWidth;   
   copy->_borderPaint     = [self->_backgroundPaint copy];
   copy->_backgroundPaint = [self->_backgroundPaint copy];
   copy->_pixelCenter     = self->_pixelCenter;     
   copy->_drawCallback    = self->_drawCallback;    

   return( copy);
}

// MEMO: never do this for paints
// 
// - (void) mulleGainAccess
// {
//    [super mulleGainAccess];
//    [self->_borderPaint mulleGainAccess];  
//    [self->_backgroundPaint mulleGainAccess];  
// }
// 
// 
// - (void) mulleRelinquishAccess
// {
//    [self->_backgroundPaint mulleRelinquishAccess];  
//    [self->_borderPaint mulleRelinquishAccess];  
//    [super mulleRelinquishAccess];
// }


- (void) setCornerRadius:(CGFloat) r
{
   _cornerInsets = MulleCornerInsetsMakeWithCornerRadius( r);
}


- (CGFloat) cornerRadius
{
   return( fmaxf( fmaxf( _cornerInsets.topLeft, _cornerInsets.topRight),
                  fmaxf( _cornerInsets.bottomLeft, _cornerInsets.bottomRight)));
}


- (void) setBorderColor:(CGColor) color
{
   [self setBorderPaint:[CGPaint paintWithColor:color]];
}


- (void) setBackgroundColor:(CGColor) color
{
   [self setBackgroundPaint:[CGPaint paintWithColor:color]];
}


- (CGColor) borderColor
{
   return( [_borderPaint mainColor]);
}


- (CGColor) backgroundColor
{
   return( [_backgroundPaint mainColor]);
}

@end

