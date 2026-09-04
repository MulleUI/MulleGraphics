//
// Copyright (c) 2022 Nat!, Mulle kybernetiK
//
#define _GNU_SOURCE

#import "import-private.h"

#include <string.h>

#define VERBOSE_DEBUG 0

#if VERBOSE_DEBUG
# define CATEXTLAYER_CLASS    DebugTextLayer
#else 
# define CATEXTLAYER_CLASS    CATextLayer
#endif

// DebugTextLayer just adds debugging to CATextLayer when VERBOSE_DEBUG is 1
// This is NOT the DemoView main layer!
@interface DebugTextLayer : CATextLayer
@end
//
// DemoView does the layer layout and shows the glyph rectangle
//
@interface DemoView : UIView
@end
@implementation DemoView

- (instancetype) initWithFrame:(CGRect) frame
{
   CATextLayer       *layer;
   CATextLayer       *left;
   CATextLayer       *center;
   CATextLayer       *right;
   CGGraphicsLayer   *outline;

   self = [super initWithFrame:frame];

   // prototype
   layer  = [CATEXTLAYER_CLASS instance];
   [layer setFontPixelSize:32.0];
   [layer setTextAlignment:UITextAlignmentLeft];
   [layer setBackgroundColor:CGColorMakeLightGray()];
   [layer setTextBackgroundColor:CGColorMakeLightGray()];
   [layer setTextColor:CGColorMakeBlack()];

   left  = [layer copiedInstance];;
   [left setTextUTF8String:"Left Aligned"];
   [left setTag:1];
   [self addLayer:left];

   center = [layer copiedInstance];;
   [center setTextUTF8String:"Center Aligned"];
   [center setTag:2];
   [center setTextAlignment:UITextAlignmentCenter];
   [self addLayer:center];

   right = layer;
   [right setTextUTF8String:"Right Aligned"];
   [right setTextAlignment:UITextAlignmentRight];
   [right setTag:3];
   [self addLayer:right];

   outline = [CGGraphicsLayer instance];
   [outline setTag:-2];
   [outline setBackgroundColor:CGColorMakeTransparent()];
   [outline setBorderColor:CGColorMakePapaya()];
   [outline setBorderWidth:2.0];
   [self addLayer:outline];

   return( self);
}
- (void) layoutAuxillaryLayer:(id <UILayer>) layer
                   layoutInfo:(struct UILayoutInfo *) info;
{
   CATextLayer           *textLayer;
   CGRect                frame;
   CGRect                rect;
   id <UILayoutContext>  context;
   NSInteger             tag;

   tag = [layer tag];
   if( tag >= 1 && tag <= 3)
   {
      context    = [self layoutContext];
      rect       = [self contentRect];
      textLayer  = MULLE_OBJC_CLASS_CAST( CATextLayer, layer);
      frame.size = [textLayer sizeThatFits:rect.size
                                   context:context];

      // add some space so we notice an alignment
      frame.size.width += 64;

      switch( tag)
      {
      case 1 : // Left Aligned
         frame.origin = CGPointMake( CGRectGetMidX( info->rect),
                                     CGRectGetMidY( info->rect) - 32);
         break;

      case 2 : // Center Aligned
         frame.origin = CGPointMake( CGRectGetMidX( info->rect) - frame.size.width / 2.0,
                                     CGRectGetMidY( info->rect));
         break;

      case 3 : // Right Aligned
         frame.origin = CGPointMake( CGRectGetMidX( info->rect) - frame.size.width,
                                     CGRectGetMidY( info->rect) + 32);
         break;
      }

      [layer setFrame:frame];
   }

   [super layoutAuxillaryLayer:layer
                    layoutInfo:info];
}
 - (UIMouseMotionEvent *) handleMouseMotionEvent:(UIMouseMotionEvent *) event
 {
   CGFloat           borderWidth_2;
   CGGraphicsLayer   *outlineLayer;
   CGPoint           location;
   CGPoint           point;
   CGRect            oldFrame;
   CGRect            outlineFrame;
   CGRect            rect;
   CATextLayer       *layer;
   NSUInteger        i;

   location      = [event locationInView:self];

   outlineFrame  = CGRectZero;
   outlineLayer  = MULLE_OBJC_CLASS_CAST_OR_NIL( CGGraphicsLayer, [self layerWithTag:-2]);

   for( i = 1; i <= 3; i++)
   {
      layer = MULLE_OBJC_CLASS_CAST_OR_NIL( CATextLayer, [self layerWithTag:i]);
      if( CGRectContainsPoint( [layer frame], location))
      {
         point = [self convertPoint:location
                            toLayer:layer];
         rect  = [layer glyphRectAtPoint:point];
         if( CGRectIsNull( rect))
            continue;

         borderWidth_2 = [outlineLayer borderWidth] / 2.0;
         rect          = CGRectExtrude( rect, borderWidth_2, borderWidth_2);
         outlineFrame  = [self convertRect:rect
                                 fromLayer:layer];
         //mulle_fprintf( stderr, "%s: %s -> %s\n", __FUNCTION__,
         //                        CGPointUTF8String( point),
         //                        CGRectUTF8String( outlineFrame));
         break;
      }
   }

   oldFrame = [outlineLayer frame];
   if( ! CGRectEqualToRect( oldFrame, outlineFrame))
   {
      [outlineLayer setFrame:outlineFrame];
      [self setNeedsDisplay];
   }

   return( event);  // don't consume event (we could if wanted though)
}

- (BOOL) resignFirstResponder
{
   if( ! [self isFirstResponder])
      return( YES);

   return( NO);  /// NOOOOO i stay first responder to get motion events
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
// DebugTextLayer 
@implementation DebugTextLayer

#if VERBOSE_DEBUG
- (void) renderInContext:(CGContext *) context
{
   FILE   *old;

   mulle_fprintf( stderr, "%s\n", __FUNCTION__);

   old = CGContextTrace( context, stderr);
   [super renderInContext:context];
   CGContextTrace( context, old);
   mulle_fprintf( stderr, "\n");
}
//
// will not be called if backgroundColor is transparent
//
- (void) drawBackgroundInContext:(CGContext *) context
{
   mulle_fprintf( stderr, "%s\n", __FUNCTION__);

   [super drawBackgroundInContext:context];
}
//
// will not be called if border is 0.0 or transparent
//
- (void) drawBorderInContext:(CGContext *) context
{
   mulle_fprintf( stderr, "%s\n", __FUNCTION__);

   [super drawBorderInContext:context];
}


- (BOOL) willDrawInContext:(CGContext *) context
{
   BOOL   flag;

   mulle_fprintf( stderr, "%s\n", __FUNCTION__);
   flag = [super willDrawInContext:context];
   return( flag);
}


- (void) didDrawInContext:(CGContext *) context
{
   mulle_fprintf( stderr, "%s\n", __FUNCTION__);
   [super didDrawInContext:context];
}


/// b -[DemoTextLayer drawInContext:]
- (BOOL) drawInContext:(CGContext *) context
{
   BOOL   flag;

   mulle_fprintf( stderr, "%s\n", __FUNCTION__);
   flag = [super drawInContext:context];
   return( flag);
}
#endif
- (id) copy
{
   id    copy;

   copy = [super copy];
   return( copy);
}

@end
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
