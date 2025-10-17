//
// Copyright (c) 2022 Nat!, Mulle kybernetiK
//
#define _GNU_SOURCE

#import "import-private.h"

#include <string.h>


#define FONT_PIXEL_SIZE      96

//#define CATEXTLAYER_CLASS    CATextLayer
#define CATEXTLAYER_CLASS    DebugTextLayer


// DebugTextLayer just adds debugging to CATextLayer when VERBOSE_DEBUG is 1
// This is NOT the DemoView main layer!
@interface DebugTextLayer : CATextLayer
@end


// DebugTextLayer 
@implementation DebugTextLayer

- (BOOL) drawInContext:(CGContext *) context
{
   BOOL     flag;
   CGRect   canvas;
   CGFloat  ascender;
   CGFloat  descender;

   canvas = [self canvas];
   CGContextStrokeLineWithColor( context, 
                                 CGRectGetLeft( canvas),
                                 CGRectGetRight( canvas),
                                 1.0,
                                 CGColorMakeWhite());
   // compute metrics or get ascendet for baseline
   [self updateRowsAndGlyphsWithContextIfNeeded:context];
   ascender = [self fontAscender];
   CGContextStrokeLineWithColor( context, 
                                 CGPointMake( 0, 
                                              CGRectGetMidY( canvas) - ascender),
                                 CGPointMake( CGRectGetMaxX( canvas), 
                                              CGRectGetMidY( canvas) - ascender),
                                 1.0,
                                 CGColorMakeChartreuse());
   descender = [self fontDescender];
   CGContextStrokeLineWithColor( context,
                                 CGPointMake( 0,
                                              CGRectGetMidY( canvas) + descender),
                                 CGPointMake( CGRectGetMaxX( canvas),
                                              CGRectGetMidY( canvas) + descender),
                                 1.0,
                                 CGColorMakeChartreuse());

   [super drawInContext:context];
   
   CGContextFillCircleWithColor( context,
                                 CACircleMakeWithCenterAndRadius( _layoutOrigin, 8.0),
                                 CGColorMakePapaya());
   CGContextStrokeCircleWithColor( context,
                                   CACircleMakeWithCenterAndRadius( _layoutOrigin, 8.0),
                                   1.0,
                                   CGColorMakeWhite());
   return( YES);
}

- (id) copy
{
   id    copy;

   copy = [super copy];
   return( copy);
}

@end


//
// DemoView does the layer layout and shows the glyph rectangle
//
@interface DemoView : UIView

@property( assign) CGPoint   mouseLocation;

@end


@implementation DemoView

- (instancetype) initWithFrame:(CGRect) frame
{
   CATextLayer       *layer;
   CATextLayer       *info;
   CGGraphicsLayer   *outline;

   self = [super initWithFrame:frame];

   layer  = [CATEXTLAYER_CLASS instance];
   [layer setFontPixelSize:FONT_PIXEL_SIZE];
   [layer setTextAlignment:UITextAlignmentCenter];
   [layer setBackgroundColor:CGColorMakeLightGray()];
   [layer setTextBackgroundColor:CGColorMakeLightGray()];
   [layer setTextColor:CGColorMakeBlack()];

   [layer setTextUTF8String:"VfL\nBochum\n1848"];
   [layer setTag:1];
   [self addLayer:layer];

   // display vertical alignement
   info  = [CATextLayer instance];
   [info setFontPixelSize:12.0];
   [info setTextAlignment:UITextAlignmentCenter];
   [info setBackgroundColor:CGColorMakeTransparent()];
   [info setTextBackgroundColor:CGColorMakeWhite()];
   [info setTextColor:CGColorMakeBlack()];
   [info setTextUTF8String:UITextVerticalAlignmentUTF8String( [layer textVerticalAlignment])];
   [info setTag:-1];
   [self addLayer:info];

   // display red glyph rect
   outline = [CGGraphicsLayer instance];
   [outline setTag:-2];
   [outline setBackgroundColor:CGColorMakeTransparent()];
   [outline setBorderColor:CGColorMakePapaya()];
   [outline setBorderWidth:2.0];
   [self addLayer:outline];


   return( self);
}


- (void) layoutAuxillaryLayer:(id <UILayer>) layer
                   layoutInfo:(struct UILayoutInfo *) info
{
   CATextLayer           *textLayer;
   CATextLayer           *infoLayer;
   CGRect                frame;
   NSInteger             tag;
   CGFloat               borderWidth_2;
   CGGraphicsLayer       *outlineLayer;
   CGPoint               point;
   CGRect                outlineFrame;
   CGRect                extrudedRect;
   CGRect                rect;

   tag = [layer tag];
   switch( tag)
   {
   case 1 : 
      textLayer  = MULLE_OBJC_CLASS_CAST( CATextLayer, layer);
      frame.size = [textLayer sizeThatFits:info->rect.size
                                   context:info->context];

      // add some space so we notice an alignment
      frame.size.width  += 64;
      frame.size.height += 64;
      frame.origin       = CGPointMake( CGRectGetMidX( info->rect) - frame.size.width / 2.0,
                                        CGRectGetMidY( info->rect) - frame.size.height / 2.0);
      [layer setFrame:frame];
      break;

   case -1 :
      // ok so we know the info layer is layouted after textLayer, so we can 
      // use that frame to calculate a position

      infoLayer  = MULLE_OBJC_CLASS_CAST( CATextLayer, layer);
      textLayer  = MULLE_OBJC_CLASS_CAST( CATextLayer, [self layerWithTag:1]);

      frame          = [textLayer frame];
      frame.origin.x = CGRectGetMidX( frame);
      frame.origin.y = CGRectGetMaxY( frame) + 10.0;

      frame.size     = [infoLayer sizeThatFits:info->rect.size
                                       context:info->context];
      frame.origin.x -= frame.size.width / 2.0;
      [layer setFrame:frame];
      break;

   case -2 :
      outlineFrame  = CGRectZero;
      outlineLayer  = MULLE_OBJC_CLASS_CAST( CGGraphicsLayer, layer);

      textLayer     = MULLE_OBJC_CLASS_CAST( CATextLayer, [self layerWithTag:1]);
      [textLayer updateRowsAndGlyphsWithContextIfNeeded:info->context];

      point         = [self convertPoint:[self mouseLocation]
                                 toLayer:textLayer];
      rect          = [textLayer glyphRectAtPoint:point];
      if( ! CGRectIsNull( rect))
      {
         borderWidth_2 = [outlineLayer borderWidth] / 2.0;
         extrudedRect  = CGRectExtrude( rect, borderWidth_2, borderWidth_2);
         outlineFrame  = [self convertRect:extrudedRect
                                 fromLayer:textLayer];
         mulle_fprintf( stderr, "%s: %s -> %s -> %s -> %s\n", 
                                 __FUNCTION__,
                                 CGPointUTF8String( point),
                                 CGRectUTF8String( rect),
                                 CGRectUTF8String( extrudedRect),
                                 CGRectUTF8String( outlineFrame));
      }
      [outlineLayer setFrame:outlineFrame];
      break;
   }

   [super layoutAuxillaryLayer:layer
                   layoutInfo:info];
}


- (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event
{
   CGPoint   location;

   location = [event locationInView:self];
   [self setMouseLocation:location];
   [self setNeedsLayout];
   return( event);  // don't consume event (we could if wanted though)
}


- (BOOL) resignFirstResponder
{
   if( ! [self isFirstResponder])
      return( YES);

   return( NO);  /// NOOOOO i stay first responder to get motion events
}


static UITextVerticalAlignment   values[] = 
{
   UITextAlignmentMiddle,
   UITextAlignmentTop,
   UITextAlignmentBottom,
   UITextAlignmentBaseline,          // only for single line
   UITextAlignmentBoundsMiddle,      // only for single line
   UITextAlignmentVisualMiddle 
};
#define n_values (sizeof( values) / sizeof( values[ 0]))


static inline NSUInteger   getIndex( UITextVerticalAlignment valignment)
{
   NSUInteger   i;

   for( i = 0; i < n_values; i++)
   {
      if( valignment == values[ i])
         return( i);
   }
   return( NSNotFound);
}


//
// could also implement scrollWheel:
//
- (UIInputEvent *) scrollWheel:(UIMouseScrollEvent *) event
{
   CGPoint                   diff;
   UITextVerticalAlignment   valignment;
   CATextLayer               *textLayer;
   CATextLayer               *infoLayer;
   NSUInteger                index;

   textLayer  = MULLE_OBJC_CLASS_CAST( CATextLayer, [self layerWithTag:1]);
   valignment = [textLayer textVerticalAlignment];
   index      = getIndex( valignment);
   assert( index != NSNotFound);

   diff = [event scrollOffsetWithAcceleration:NO
                                useModifiers:NO];

   if( diff.y < 0.0)
   {
      if( index-- == 0)
         index = n_values - 1;
   }
   else
      if( diff.y > 0.0)
      {
         if( ++index == n_values)
            index = 0;
      }

   valignment = values[ index];
   [textLayer setTextVerticalAlignment:valignment];
   [self setNeedsLayout];

//   // ok so the textLayer glyphs are now invalid. need to update
//   [textLayer updateRowsAndGlyphsWithContextIfNeeded:[self layoutContext]];
//   [self updateOutlineLayerForMouseLocation:[event locationInView:self]];
//
   infoLayer = MULLE_OBJC_CLASS_CAST( CATextLayer, [self layerWithTag:-1]);
   [infoLayer setTextUTF8String:UITextVerticalAlignmentUTF8String( valignment)];

   [self setNeedsDisplay];
   return( nil);
}

@end


void   setupScene( UIWindow *window)
{
   DemoView   *view;
   CGRect     frame;

   frame   = [[window contentView] contentRect];
   view    = [DemoView viewWithFrame:frame];
   [view setAutoresizingMask:UIViewAutoresizingScaleToFill];
   // [view setMouseMotionEventCallback:handleMouseMotionEvent];

   [[window contentView] addSubview:view];
   // do this after adding view to window, need to be first responder to get
   // mouse tracking events
   [view becomeFirstResponder];
}


int   main( int argc, char *argv[])
{
   UIApplication   *app;
   UIWindow        *window;
   NSUInteger      styleMask;

   app = [UIApplication sharedInstance];

   @autoreleasepool
   {
      styleMask = UIWindowStyleMaskDefault;
      styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleResizable, YES);
      styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStyleRetained, NO);
      styleMask = UIWindowStyleMaskBySetting( styleMask, UIWindowStylePlanes, NO);

      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 1000, 600)
                         titleUTF8String:"Demo"
                               styleMask:styleMask];

      assert( window);
      [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];
      setupScene( window);

      [app addWindow:window];
   }

   return( [app runApp]);
}



//                           ,╓≤æKª╨╙╙▓█D"╙╙╙*╨¥W▄╓,
//                      ╓▄ª╙└╧▓        █           ⁿ▓▓ª╦w
//                  ╓#╜^*█⌐   `╕       █           ╓▌    `╙%w
//               ╓ΦΓ      █    ╙⌐     ,█,,,Φ      ╓▌         ╙¥▄
//            ,▄▀ █▄       █µ,╓╝,╓≤╗≡≡ª╨╨╨¥≡∞╗w╓,ª█,  ,       ]▄▀V,
//          ,Φ└   ║"▀▄     ,▄▀╨"                 "╙¥▓▓       ▄▀  º▄¥,
//        ,#▌Φ▓▄╓  Φ `█Q▄M╙                           ╙¥▄ ,▄▀ ╙▄⌐`  `Φ
//       ▄▀   `V,"▀▀¼╓╩└                                 ╙¥▓╗ ,       ╙▄
//      Φ       `¥═▄▀                            ╒          ▀▄          ▓
//    .▓         ╓▓]V▄H       ▓                 ,Å            ▀,         ▀
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙███` `╙╙║█  ▐H        █
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//  ╢"▄▄#▀▀╙╟█Ü███▀`▀█  ║██J█▄▌jH █    ██    ╙▀W▄;    ,██  `╙w,   █▄     ,╓ █
//   █╙     ▐███▌▀█w ▀█ ╠██████j▌║█▌   ▀██▄       `╙▓██▀w,     ╙╗█'`"▀█▀╙"`║`
//   ╙▌     Φ████████▄██ ███████████    ═██▀W▄,   ╓█▀└         ╓▀ "    ╙▄ ╓▀
//    ╙▄     ╙▀███╙█▄▐██▄,╙▀█████▄▀▄▀▄   ,█M╗ ▀▄██▀╙""*ⁿ═─≈-,,▄▌,        ▄▀
//     `▌╙µ,▄Φ▀x███▄██████████▀V███▀╙└ ,▄#▌████▀`"*«,      .█▀▄▀▄,      ▄╛
//       ▀Ö█  ;▓████████▄▄█▀▄╙W "V▄██▀▀│▄███▀└ ▀╦     "*═╥▄▀ ║,  ║▀▄  ,▓
//        ╙W▀ '█████╨▀▀█████████   "▀▀████└      ╙▄   ,▄▀'   `▀▀╣H ▐▀▄▀
//          ╙▄  ▀▀Γ╓▌  ▄▀ⁿ`╙▀███      ██▌         ╓█R▀▄A█        ▀▀▄▀
//            ╙W,Φ╙  ║█        ▄╙╙ª%≡╦██≤≤╗╗≡≡╜▀▀   ╣▌   █╕     ,▄▀
//              `▀▄M█┘        ║▀▌   ╫"    *Φ▄  █       Φ` ▀▌, ▄M╙
//                 "▀╦,       M ╙▌  ▀       `█W▐▌       wæQ▄▀╙
//                     ╙▀W╥,╓╣   ╙█║        ╫M  █    ,╓▄╝╙`
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`
