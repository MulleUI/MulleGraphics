//
// Copyright (c) 2022 Nat!, Mulle kybernetiK
//
#define _GNU_SOURCE

#import "import-private.h"

#include <string.h>

#define FONT_PIXEL_SIZE      24
#define LINE_HEIGHT         32

// Pure CATextLayer demo without layouter
// Demonstrates manual creation of CATextLayerRow structs
// Shows how to add rows with selection and cursor directly to CATextLayer

@interface DemoView : UIView
{
   CATextLayer   *_textLayer;
}

@end


@implementation DemoView

- (instancetype) initWithFrame:(CGRect) frame
{
   char                         *text;
   struct CATextLayerRow        rows[ 4];
   struct mulle_utf8data        data;
   
   self = [super initWithFrame:frame];
   
   // Create text layer
   _textLayer = [CATextLayer instance];
   [_textLayer setFontPixelSize:FONT_PIXEL_SIZE];
   [_textLayer setTextAlignment:UITextAlignmentLeft];
   [_textLayer setBackgroundColor:CGColorMakeLightGray()];
   [_textLayer setTextBackgroundColor:CGColorMakeLightGray()];
   [_textLayer setTextColor:CGColorMakeBlack()];
   [_textLayer setSelectionColor:CGColorMakeWithRGBA( 0.0, 0.0, 1.0, 0.3)];
   [_textLayer setCursorColor:CGColorMakeRed()];
   [_textLayer setSelectable:YES];
   [_textLayer setEditing:YES];
   
   // Set text content
   text = "The quick brown fox\njumps over the lazy dog.\nThis is line three.\nAnd here's line four.";
   data = mulle_utf8data_make( text, strlen( text) + 1);
   [_textLayer setTextUTF8Data:data];
   
   // Manually create rows - this is what the layouter would normally do
   // Row 0: "The quick brown fox" (0-19)
   rows[ 0].textRange       = NSMakeRange( 0, 19);
   rows[ 0].selectionRect   = CGRectMake( 0, 0, 100, LINE_HEIGHT);
   rows[ 0].selectionStyle  = CATextLayerSelectionStyleRect;
   rows[ 0].cursorRect      = CGRectZero;
   rows[ 0].cursorStyle     = CATextLayerCursorStyleNone;
   
   // Row 1: "jumps over the lazy dog." (20-44)
   rows[ 1].textRange       = NSMakeRange( 20, 24);
   rows[ 1].selectionRect   = CGRectZero;
   rows[ 1].selectionStyle  = CATextLayerSelectionStyleNone;
   rows[ 1].cursorRect      = CGRectMake( 150, LINE_HEIGHT, 2, LINE_HEIGHT);
   rows[ 1].cursorStyle     = CATextLayerCursorStyleLine;
   
   // Row 2: "This is line three." (45-64)
   rows[ 2].textRange       = NSMakeRange( 45, 19);
   rows[ 2].selectionRect   = CGRectZero;
   rows[ 2].selectionStyle  = CATextLayerSelectionStyleNone;
   rows[ 2].cursorRect      = CGRectZero;
   rows[ 2].cursorStyle     = CATextLayerCursorStyleNone;
   
   // Row 3: "And here's line four." (65-86)
   rows[ 3].textRange       = NSMakeRange( 65, 21);
   rows[ 3].selectionRect   = CGRectMake( 50, LINE_HEIGHT * 3, 120, LINE_HEIGHT);
   rows[ 3].selectionStyle  = CATextLayerSelectionStyleRect;
   rows[ 3].cursorRect      = CGRectZero;
   rows[ 3].cursorStyle     = CATextLayerCursorStyleNone;
   
   // Add rows to text layer
   [_textLayer addTextLayerRows:rows
                          count:4];
   
   [self addLayer:_textLayer];
   
   return self;
}


- (void) layoutAuxillaryLayer:(id <UILayer>) layer
                    layoutInfo:(struct UILayoutInfo *) info
{
   CGRect   frame;
   
   if( layer == _textLayer)
   {
      frame = info->rect;
      frame = UIEdgeInsetsInsetRect( frame, UIEdgeInsetsMake( 20, 20, 20, 20));
      [_textLayer setFrame:frame];
   }
   
   [super layoutAuxillaryLayer:layer
                    layoutInfo:info];
}

@end


void   setupScene( UIWindow *window)
{
   DemoView   *view;
   CGRect     frame;
   
   frame   = [[window contentView] contentRect];
   view    = [DemoView viewWithFrame:frame];
   [view setAutoresizingMask:UIViewAutoresizingScaleToFill];
   
   [[window contentView] addSubview:view];
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
                         titleUTF8String:"CATextLayer Pure Demo"
                               styleMask:styleMask];
      
      assert( window);
      [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];
      setupScene( window );
      
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
//    █      ,-ª▓╛  `██▀½      "▄  ,╓╓╓╓;╓▄▄▄╗▄█,             ╙▄         ▀
//   █  `██▄   ▓. - Φ█═.~     ,≤█▄▀-      `   █└"▀▀▀▀▄╓╓╓       ▌    ██▄, █
//  ║⌐  " ▀   ▓╨⌐   }▀`      ,█  `           █      .█▀▄▄███▄     ▌  ` ▀    ▌
//  ▌        ▐M A   '┴      ▌                ▀        ╙█▌████▌    ╙▄        ║⌐
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀ΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
// █"      ╙▐H-═M ▄███████¥█H "^╙    '█, ,«^``     `     ║▌        ▐M▄▀    "Φ█
// ║        !█▄▄████≤═^`╓█ █▌╓▀╦▄▀█   ╙█⌐               ╓█▌        ▓ `       █
//  ▌      ,▄██╫██ ▄█═╜" █▌▐█╣Hj⌐ █    █▌╙¥w,           ██▄       ╓▌        ▐M
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