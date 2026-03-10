//
// Copyright (c) 2020 Nat!, Mulle kybernetiK
//
#import "CAShapeLayer.h"

#import "import-private.h"


@implementation CAShapeLayer

- (instancetype) initNoLock
{
   self = [super initNoLock];
   if( self)
   {
      _ownsPath = YES;
   }
   return( self);
}


- (void) setPath:(CGPath *) path
{
   assert( path != _path);

   if( _ownsPath)
      CGPathDestroy( _path);
   _path = path;
}


- (void) dealloc
{
   if( _ownsPath)
      CGPathDestroy( _path);
   [super dealloc];
}


- (id) copy 
{
   CAShapeLayer  *copy;

   copy = [super copy];

   copy->_strokePaint  = [self->_strokePaint copy];   
   copy->_fillPaint    = [self->_fillPaint copy];   
   copy->_strokeWidth  = self->_strokeWidth;   
   copy->_path         = CGPathCopy( self->_path, MulleObjCInstanceGetAllocator( copy));
   copy->_ownsPath     = YES;   

   return( copy);
}


// MEMO: a paint is usually a value and not mutable i.e. thread-safe no problem
//       we don't need to gain or relinquish. But! if we have a CGImage it
//       could be a CGFramebuffer, which is mutable and we would need to
//       transfer it. But! The CGImage is also part of the resource management
//       of the CGContext and will be gained/relinquished there. So doing it
//       twice would be disastrous. So luck has it, we don't need to
//       transfer paints. Now with the uniquing done by NSObject this should
//       all be moot, but the comment is left in, in case not...

- (void) setStrokeColor:(CGColor) color
{
   [self setStrokePaint:[CGPaint paintWithColor:color]];
}


- (void) setFillColor:(CGColor) color
{
   [self setFillPaint:[CGPaint paintWithColor:color]];
}


- (CGColor) strokeColor
{
   return( [_strokePaint mainColor]);
}


- (CGColor) fillColor
{
   return( [_fillPaint mainColor]);
}

@end
