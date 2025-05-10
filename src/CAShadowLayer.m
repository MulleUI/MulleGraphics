#import "CAShadowLayer.h"

#import "import-private.h"


#define SHADOW_WIDTH    6.0
#define SHADOW_HEIGHT   8.0



@implementation CAShadowLayer

#ifdef DEBUG
+ (instancetype) alloc
{
   return( [super alloc]);
}
#endif


- (instancetype) initNoLock
{
   self = [super initNoLock];
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


- (id) copy
{
   CAShadowLayer  *copy;

   copy = [super copy];

   copy->_cornerInsets = self->_cornerInsets;
   copy->_shadowBlur   = self->_shadowBlur;
   copy->_shadowColor  = self->_shadowColor;
   copy->_shadowInsets = self->_shadowInsets;

   return( copy);
}


- (CGRect) shadowedRect
{
   CGRect   canvas;

   canvas = [self canvas];
   return( MulleEdgeInsetsInsetRect( _shadowInsets, canvas));
}

@end
