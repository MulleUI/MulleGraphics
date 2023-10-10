#import "CAShadowLayer.h"

#import "import-private.h"


#define SHADOW_WIDTH    6.0
#define SHADOW_HEIGHT   8.0



@implementation CAShadowLayer

- (instancetype) init
{
   self = [super init];
   if( self)
   {
      _cornerInsets = MulleCornerInsetsMakeWithCornerRadius( fmaxf( SHADOW_HEIGHT, SHADOW_HEIGHT) / 2.0f);
      _shadowBlur   = fmaxf( SHADOW_WIDTH, SHADOW_HEIGHT) / 2.0f;

      _shadowColor  = CGColorMakeWithRGBA( 0.0f, 0.0f, 0.0f, 0.25f);
      _shadowInsets = MulleEdgeInsetsMake( - SHADOW_HEIGHT / 2.0f,
                                           - SHADOW_WIDTH / 2.0f,
                                           SHADOW_HEIGHT / 2.0f,
                                           SHADOW_WIDTH / 2.0f);
   }
   return( self);
}


- (CGRect) shadowedRect
{
   CGRect   canvas;

   canvas = [self canvas];
   return( MulleEdgeInsetsInsetRect( _shadowInsets, canvas));
}

@end
