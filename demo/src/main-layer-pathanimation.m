#import "import-private.h"

#include <math.h>

#define DO_ANIMATION          1  // Set to 1 to enable animations
#define ROTATION_ANIMATION    1


static CGPath   *createCirclePath(CGPoint center, CGFloat radius)
{
   CGPath *path = CGPathCreate( NULL);

   CGPathAddArcWithCenter( path, center, radius, 0.0, 1.0);

   return path;
}


// Helper function to create a triangle path
static CGPath   *createTrianglePath( CGRect bounds)
{
   CGPath   *path;
   CGPoint  p1;
   CGPoint  p2;
   CGPoint  p3;

   path = CGPathCreate( NULL);
   p1   = CGPointMake( CGRectGetMidX(bounds), CGRectGetMinY(bounds));
   p2   = CGPointMake( CGRectGetMaxX(bounds), CGRectGetMaxY(bounds));
   p3   = CGPointMake( CGRectGetMinX(bounds), CGRectGetMaxY(bounds));

   CGPathMoveToPoint(path, p1);
   CGPathAddLineToPoint(path, p2);
   CGPathAddLineToPoint(path, p3);
   CGPathCloseSubpath(path);

   return( path);
}


// Drawing callback to show the animation path
static BOOL   drawPaths( CGGraphicsLayer *layer, CGContext *context)
{
   CGFloat  radius;
   CGPath  *path;
   CGPoint  center;
   CGRect   frame;

   frame = [layer canvas];
   frame = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(50, 50, 50, 50));

   center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
   radius = CGFloatMinimum(CGRectGetWidth(frame), CGRectGetHeight(frame)) * 0.3;
   path   = createCirclePath(center, radius);

   // Draw the path with fine gray line
   if( path)
   {
      CGContextBeginPath(context);
      CGContextAddCGPath(context, path);
      CGContextStrokeColor(context, CGColorMakeWithRGBA(0.8, 0.8, 0.8, 1.0)); // Light gray
      CGContextStrokeWidth(context, 1.0);
      CGContextStroke(context);
      CGPathDestroy(path);
   }

   return( YES);
}


static void   setupScene( UIWindow *window)
{
   CABasicAnimation                *colorAnimation;
   CAPathAnimation                 *pathAnimation;
   CAPathAnimationValueType         pathValueType;
   CAShapeLayer                    *layer;
   CGFloat                          radius;
   CGPathRef                        path;
   CGPoint                          center;
   CGRect                           frame;
   CGRect                           layerFrame;
   struct CABasicAnimationOptions   colorOptions;
   struct CABasicAnimationOptions   pathOptions;
   struct _mulle_objc_property     *colorProperty;
   struct _mulle_objc_property     *property;

   frame = [[window contentView] contentRect];
   frame = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(50, 50, 50, 50));
   
   center = CGPointMake(CGRectGetMidX(frame), CGRectGetMidY(frame));
   radius = CGFloatMinimum(CGRectGetWidth(frame), CGRectGetHeight(frame)) * 0.3;
   path   = createCirclePath(center, radius);

   // Create small layer to animate along the path
   layerFrame = CGRectMake(center.x - 10, center.y - 10, 20, 20);
   layer      = [CAShapeLayer layerWithFrame:layerFrame];
   
   [layer setAnchorPoint:CGPointMake( 0.5, 1.0)];
   [layer setPath:createTrianglePath([layer bounds])];
   [layer setFillColor:CGColorMakeWithRGBA(1.0, 0.0, 0.0, 1.0)];
   [layer setNameUTF8String:"triangle"];
   [[window contentView] addLayer:layer];

#if DO_ANIMATION
   // Color animation
   colorProperty = MulleObjCInstanceSearchProperty(layer, @selector(fillColor));
   if( colorProperty)
   {
      colorOptions = CABasicAnimationOptionsMakeEaseInOut(
         mulle_relativetimerange_make(0.0, 2.0),
         INFINITY,
         YES
      );
      
      colorAnimation = [[[CABasicAnimation alloc]
         initWithProperty:colorProperty
          startColorValue:CGColorMakeWithRGBA(1.0, 0.0, 0.0, 1.0)  // red
            endColorValue:CGColorMakeWithRGBA(0.0, 0.0, 1.0, 1.0)  // blue
                  options:&colorOptions] autorelease];
      
      [colorAnimation setAnimationObject:layer];
      [[window postLayoutAnimator] addAnimation:colorAnimation];
   }

#if ROTATION_ANIMATION
   // Rotation Animation
   property      = MulleObjCInstanceSearchProperty(layer, @selector(pose));
   pathValueType = CAPathAnimationValuePose;
#else
   // Path animation
   property      = MulleObjCInstanceSearchProperty(layer, @selector(position));
   pathValueType = CAPathAnimationValuePositionAsOrigin;
#endif

   if( property && path)
   {
      pathOptions = CABasicAnimationOptionsMakeLinear(
         mulle_relativetimerange_make(0.0, 4.0),
         INFINITY,
         NO
      );
      
      pathAnimation = [[[CAPathAnimation alloc]
                          initWithProperty:property
                                      path:path
                             pathValueType:pathValueType
                                   options:&pathOptions] autorelease];
      
      [pathAnimation setAnimationObject:layer];
      [[window postLayoutAnimator] addAnimation:pathAnimation];
   }
#endif
}


int main(int argc, char *argv[])
{
   UIWindow *window;
   UIApplication *app;

   app = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake(0.0, 0.0, 800.0, 600.0)];
   assert(window);

   [window setBackgroundColor:CGColorMakeWithRGBA(1.0, 1.0, 1.0, 1.0)];
   [window setDrawCallback:(CGGraphicsLayerDrawCallback_t *) drawPaths];

   setupScene(window);

   [app addWindow:window];

   return [app runApp];
}
