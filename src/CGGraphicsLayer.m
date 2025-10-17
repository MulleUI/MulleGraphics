#import "import-private.h"

#import "CGGraphicsLayer.h"


#pragma clang diagnostic ignored "-Wparentheses"
// #define RENDER_DEBUG
// #define CALAYER_DEBUG

@interface CALayer( Private)

- (id) _initWithFrame:(CGRect) frame;

@end


@implementation CGGraphicsLayer

- (id) _initWithFrame:(CGRect) frame
{
   self = [super _initWithFrame:frame];
   if( ! self)
      return( self);

   _anchorPoint = CGPointMake( 0.5, 0.5);

   return( self);
}


- (id) copy 
{
   CGGraphicsLayer  *copy;

   // check that the subclass is actually implementing -copy, otherwise the
   // user is probably in a world of pain soon afterwards
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣀⣀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠐⠷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠳⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣠⣴⠚⠋⢙⠉⠛⢶⠄⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠀⢴⣿⣷⣶⣤⣰⠆⠀⠀⢀⡰⢟⣩⣵⣷⣶⣶⣿⣿⣾⡀⢄⠐⠀⠐⠀⠂⠀⠆⠀⠆⠐⢀⣰⣠⣴⣿⣿⣶
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠛⠛⠿⠿⠻⠀⠂⠀⠂⢻⣯⣿⣿⣿⣿⣿⣿⣿⣿⣷⣌⢮⡀⢆⠀⡂⢐⠀⡆⠠⠣⠌⢻⠛⠟⠩⠉⠍
   // ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠊⠹⣿⣿⠿⠋⠉⠉⢲⡆⠀⡂⠤⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠀⠀⠀⠀⠀
   // ⣆⠀⣀⢠⡄⠤⢴⣴⣶⣶⣶⣶⣾⣿⣷⡄⠀⠀⢀⠀⠀⢠⣤⣤⣰⣶⣾⣿⣷⠆⠀⢀⠾⠿⠆⣧⣼⣦⠀⠀⠀⠀⠀⠀⠀⠀⠀⢺⠆⠀⠀⠀⠀
   // ⡃⠀⠈⢸⢐⢚⣺⣿⠿⣿⣿⣿⣿⣿⣿⠁⠀⠐⠻⣿⣦⣾⣿⣿⣿⣧⣿⣿⣿⣿⣾⡔⣀⠀⣠⣿⣟⠃⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⠀⠀⠀⠀⠀
   // ⡁⠀⠐⠘⢈⣈⣆⣹⣃⣻⣿⣿⣿⣿⣷⣀⠀⠀⠀⣈⡉⠙⢿⣿⣿⠈⣿⣿⣿⣿⣿⢨⣾⣏⢙⣿⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⡄⠀⠀⠀⠀
   // ⠀⠀⠀⠀⢀⢀⡀⢀⠶⢂⠟⣿⣿⣿⣿⣿⣷⣶⣿⣿⣿⣷⡄⠀⠟⠀⢸⣆⠀⠁⠀⠈⠉⠉⠀⠉⠀⠀⠀⠤⠤⠤⠶⠶⠴⠶⠶⠶⠷⠶⠿⠷⠶
   // ⠂⠀⠀⠠⠶⣸⣘⣩⣉⣈⣉⣿⣿⣿⣿⣟⠉⠉⠙⠿⠿⢟⣵⣆⣠⡔⠀⠙⠷⡆⠀⠀⠀⠀⢀⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣀⣻⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⠟⢿⣦⡀⠀⠀⠐⣤⣔⡀⢶⣾⣿⡄⠀⠢⣤⣄⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀
   // ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣏⣁⣠⣤⣭⣷⣿⣷⡄⠹⣷⣤⡀⠀⠈⠻⣿⣿⣿⣿⣿⡆⠀⠈⠛⢿⣿⣿⣿⣿⣿⣿⣿⣶⣶⣿⣿
   // ⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⡿⠛⠛⠛⣛⣹⣿⣿⡧⠀⣿⣿⣿⣿⣦⠀⠙⢿⣿⣿⣿⡷⠀⠀⠀⣤⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
   // ⣿⣿⣿⣿⡿⠋⠠⠤⠀⠈⠋⠁⡀⠈⠹⢿⣦⣤⠀⠀⠻⢿⣿⣿⡇⠀⣻⣿⣿⣿⣿⣷⡄⠀⠈⠻⣿⡇⠀⠀⠀⠙⢿⣿⣿⣿⣿⣿⣿⣿⣿⣿⣿
   // ⣿⣿⡟⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠃⠻⣿⡄⠀⠀⠀⠻⣿⠇⠀⣿⣿⣿⣿⣿⣿⣷⡀⠀⠀⠘⠁⠀⠀⠀⠀⠀⠙⣿⣷⣶⡞⢉⣴⡾⡟⠫
   // ⡞⣷⠇⡟⣷⣿⢸⢸⢸⣻⢾⣟⢤⢸⡃⣿⣼⠘⡟⢸⣟⢸⣻⢸⡇⣷⣿⣼⣻⢹⢿⢿⢹⢹⣼⣧⡇⣿⣷⢸⣻⢸⡇⢸⢻⣎⢱⣿⡆⣟⡛⠛⠃
   // ⣿⠿⢀⠧⠟⠻⠼⢸⡸⠸⠿⠧⢸⠸⠤⠿⠿⠀⠇⠸⠧⠸⠸⠸⠇⠏⠿⠻⠽⢸⠸⠻⢾⡼⣟⡿⠇⠿⠿⠸⠸⠺⠧⠸⠼⣿⣼⠿⡇⠇⠀⠀⠀
   // ⠀⠀⢈⠀⠀⠀⠀⠉⠉⠈⠉⠉⠘⢛⠿⠸⠿⠇⠀⠀⠀⢀⣀⡀⣀⡀⣀⢐⢛⢻⣿⣿⣵⣿⣿⣷⡀⠀⠀⠀⠀⠀⠀⠀⠀⠘⣿⣿⣿⣿⣿⣿⣿
   // ⠀⠀⢀⠀⠀⠀⠀⠀⠀⠀⠀⠴⠦⠀⠀⣴⣶⣾⡀⠀⠀⢸⡷⢇⣏⡇⣿⢸⣿⢸⣿⣿⣿⣿⣿⣿⣧⠀⠀⠀⠀⠀⠀⠀⠀⠀⡿⣽⣿⢹⣿⣿⣿
   // ⡀⠀⢸⢀⣀⣀⡀⠤⢤⡄⠀⠀⠀⠀⠐⡿⠿⣿⣷⣤⣤⠘⡃⠘⠃⠓⠛⠘⣸⣼⣿⣿⣿⣿⣿⣿⣿⡆⠀⠀⠀⠀⠀⠀⠀⠀⡇⣇⣈⣈⣉⣉⣹
   assert( MulleObjCClassImplementsSelector( [self class], @selector( copy)) &&
           "your subclass must implement -copy and then start by "
           "calling [super copy] then add additional copy code");

   copy = [super copy];

   copy->_borderPaint     = [self->_borderPaint copy];
   copy->_backgroundPaint = [self->_backgroundPaint copy];

   copy->_rotation        = self->_rotation;
   copy->_anchorPoint     = self->_anchorPoint;
   copy->_cornerInsets    = self->_cornerInsets;   
   copy->_borderWidth     = self->_borderWidth;   
   copy->_drawCallback    = self->_drawCallback;    

   return( copy);
}


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



- (CGPoint) position
{
   CGPoint   pos;

   pos.x = _frame.origin.x + (_frame.size.width * _anchorPoint.x);
   pos.y = _frame.origin.y + (_frame.size.height * _anchorPoint.y);

   return( pos);
}


- (void) setPosition:(CGPoint) position
{
   CGRect newFrame = _frame;

   newFrame.origin.x = position.x - (_frame.size.width * _anchorPoint.x);
   newFrame.origin.y = position.y - (_frame.size.height * _anchorPoint.y);

   [self setFrame:newFrame];
}


- (CAPose) pose
{
   CGPoint   pos;

   pos.x = _frame.origin.x + (_frame.size.width * _anchorPoint.x);
   pos.y = _frame.origin.y + (_frame.size.height * _anchorPoint.y);

   return( CAPoseMakeWithPositionAndRotation( pos, _rotation));
}


- (void) setPose:(CAPose) pose
{
   _frame.origin.x = pose.position.x - (_frame.size.width * _anchorPoint.x);
   _frame.origin.y = pose.position.y - (_frame.size.height * _anchorPoint.y);
   _rotation       = CAPoseGetRotation( pose);
}

@end

