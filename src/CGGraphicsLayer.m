#import "import-private.h"

#import "CGGraphicsLayer.h"


#pragma clang diagnostic ignored "-Wparentheses"
// #define RENDER_DEBUG
// #define CALAYER_DEBUG

@implementation CGGraphicsLayer

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

