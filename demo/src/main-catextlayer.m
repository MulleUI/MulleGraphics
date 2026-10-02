/*
 Descender rendering and text metrics: a practical guide (2025-11-05T10:31:46.617Z)

 Context
 - We render short UTF-8 text (e.g. "|y|") with CATextLayer -> CGContext -> NanoVG -> FreeType
 - We overlay helper lines: ascender (top), baseline, descender (bottom) using CGTextMetrics
 - Observation: the glyph 'y' extends visually below the descender line by ~10 pixels, while 'v' sits perfectly on the baseline

 Why this happens (metrics vs. pixels)
 - Font metrics (ascender, descender, lineHeight) come from FreeType via CGContextTextMetrics.
   All values are positive distances from the baseline:
     ascender   = distance from the baseline up to the ascender line
     descender  = distance from the baseline down to the descender line
     lineHeight = ascender + descender (+ optional lineGap)
 - Rendering uses an atlas of glyph bitmaps at integer pixel boundaries. Glyphs may include implicit padding/overshoot to avoid clipping and to improve rasterization (hinting, stem fitting, coverage).
 - Therefore, the actual inked pixels (visual bounds) can exceed theoretical metric lines (especially descenders with curved shapes like 'y', 'g', 'p'). This is expected and font-dependent, not a bug.

 Baseline, metrics and visual bounds
 - Baseline: y where text is positioned; 'v' touches baseline; 'y' descends below.
 - CGTextMetrics from CGContextTextMetrics are the canonical font metrics. Both
   ascender and descender are positive distances from the baseline (ascender
   points up, descender points down).
 - Visual bounds are computed from actual glyph geometry (struct UIGlyphPosition minx/miny/maxx/maxy) transformed into layer coordinates, with small insets (CATextLayerVisualBoundsInsets) to account for overdraw.
 - Hence, metric descender is a theoretical limit; visual descender reflects real pixel coverage and may extend a few pixels further.

 How text is actually rendered (pipeline)
 1) CATextLayer prepares layout (font size, letter spacing, line height, alignments)
 2) CGContext selects font, calls CGContextText at the baseline (origin.y)
 3) NanoVG/Fontstash pulls glyph bitmaps from an atlas and positions them per glyph metrics
 4) The atlas uses integer pixel positions; subpixel coverage and hinting can push pixels slightly beyond metric lines

 Practical implications
 - Expect small overdraw beyond descender when drawing curved descenders ('y', 'g', 'p').
 - Helper lines using CGTextMetrics show canonical font lines; visual pixels may exceed them by a few px.
 - For vertical centering that matches what the eye sees, center by visual bounds, not by metrics.

 Vertical alignment
 - The layer's UITextVerticalAlignment selects the vertical placement of the
   text block. See UITextTypes.h in MulleUIBase for the exact per-mode formulas
   (Top / Bottom / Middle / Baseline / Fill, single- and multi-row).
 - For a single row, Baseline leaves the baseline at "ascender", so it coincides
   with Top; only with more than one row does it vertically center the block.
   Middle places the single-row baseline at height / 2.
 - Metrics-based (asc/desc/lineHeight): stable across text changes; can visually
   drift if glyphs lack extents.
 - Visual-based (setUseVisualBounds:YES): matches perceived centering; depends
   on the actual glyphs; preferred for short labels.

 Tracing tips
 - Enable draw call tracing: mulle-sde run --mulleui-trace-draw
 - Inspect CGContextText and CGContextTextMetrics calls to correlate baseline, ascender/descender, and final lines.

 Summary
 - The descender line is a font-metric reference; minor visual overdraw below it is expected due to glyph rasterization and padding.
 - Use visual-bounds-based alignment when perceptual centering matters; use metric lines when typographic stability matters.
*/
#import "import-private.h"

#include <unistd.h>

@interface DebugTextLayer : CATextLayer
@end

@implementation DebugTextLayer

 - (BOOL) drawInContext:(CGContext *) context
 {
   CGTextMetrics        metrics;
   CGRect               canvas;
   CGRect               textRect;

   if( ! [super drawInContext:context])
      return( NO);

   CGContextFillCircleWithColor( context, CACircleMakeWithCenterAndRadius( _origin, 8.0), CGColorMakeDarkGray()); // Converted from mvgFillCircleWithColor

   canvas   = [self insetCanvas];

   // This debug overlay is only a rough aid:
   //  * [super drawInContext:] has already restored the layer's default font,
   //    so the metrics read below are the *default* font metrics and not the
   //    metrics of the rendered text.
   //  * the guide lines are drawn around the canvas midpoint, which is the
   //    actual baseline only for UITextAlignmentMiddle.
   metrics  = [context textMetrics];

   CGContextStrokeLineHWithColor( context,
                                  CGPointMake( canvas.origin.x, _origin.y - metrics.ascender),
                                  canvas.size.width,
                                  1,
                                  CGColorMakeDodgerBlue());

   CGContextStrokeLineHWithColor( context,
                                  CGPointMake( canvas.origin.x, _origin.y),
                                  canvas.size.width ,
                                  1,
                                  CGColorMakePapaya());

   CGContextStrokeLineHWithColor( context,
                                  CGPointMake( canvas.origin.x, _origin.y + metrics.descender),
                                  canvas.size.width,
                                  1,
                                  CGColorMakeDodgerBlue());

   textRect = CGRectInset( canvas, 30, 20);

   CGContextFontSize( context, 14.0);
   CGContextTextColor( context, CGColorMakeOrange());
   CGContextTextBackgroundColor( context, CGColorMakeGray());

   mulle_sprintf_do( buf, "UITextVerticalAlignment : %s", UITextVerticalAlignmentUTF8String( _textVerticalAlignment))
   {
      CGContextTextInRect( context, buf,
                           (size_t) -1,
                           CGRectMake( textRect.origin.x, textRect.origin.y, textRect.size.width, 20),
                           CGContentModeLeft,
                           CGTextOptionAlignVisually);
      textRect.origin.y += 20;
   }

   mulle_sprintf_do( buf, "InsetCanvas : %s", CGRectUTF8String( canvas))
   {
      CGContextTextInRect( context, buf,
                           (size_t) -1,
                           CGRectMake( textRect.origin.x, textRect.origin.y, textRect.size.width, 20),
                           CGContentModeLeft,
                           CGTextOptionAlignVisually);
      textRect.origin.y += 20;
   }
   mulle_sprintf_do( buf, "visualBounds : %s", CGRectUTF8String( [self visualBoundsWithContext:context]))
   {
      CGContextTextInRect( context, buf,
                           (size_t) -1,
                           CGRectMake( textRect.origin.x, textRect.origin.y, textRect.size.width, 20),
                           CGContentModeLeft,
                           CGTextOptionAlignVisually);
      textRect.origin.y += 20;
   }

   mulle_sprintf_do( buf, "origin : %s", CGPointUTF8String( _origin))
   {
      CGContextTextInRect( context, buf,
                           (size_t) -1,
                           CGRectMake( textRect.origin.x, textRect.origin.y, textRect.size.width, 20),
                           CGContentModeLeft,
                           CGTextOptionAlignVisually);
      textRect.origin.y += 20;
   }
   mulle_sprintf_do( buf, "FontPixelSize : %g", _renderedFontMetrics.fontPixelSize)
   {
      CGContextTextInRect( context, buf,
                           (size_t) -1,
                           CGRectMake( textRect.origin.x, textRect.origin.y, textRect.size.width, 20),
                           CGContentModeLeft,
                           CGTextOptionAlignVisually);
      textRect.origin.y += 20;
   }

   mulle_sprintf_do( buf, "TextLineHeight : %g", _renderedFontMetrics.textLineHeight)
   {
      CGContextTextInRect( context, buf,
                                    (size_t) -1,
                                    CGRectMake( textRect.origin.x, textRect.origin.y, textRect.size.width, 20),
                                    CGContentModeLeft,
                                    CGTextOptionAlignVisually);
      textRect.origin.y += 20;
   }

   mulle_sprintf_do( buf, "metrics : %s", CGTextMetricsUTF8String( metrics))
   {
      CGContextTextInRect( context, buf,
                                    (size_t) -1,
                                    CGRectMake( textRect.origin.x, textRect.origin.y, textRect.size.width, 20),
                                    CGContentModeLeft,
                                    CGTextOptionAlignVisually);
      textRect.origin.y += 20;
   }
   return( YES);
}

@end


static void   setupSceneInWindow( UIWindow *window,
                                  UITextVerticalAlignment valignment,
                                  char *text)
{
   CATextLayer     *layer;
   CGRect          frame;
   UIView          *view;
   UIWindowPlane   *contentPlane;

   contentPlane = [window contentView];
   frame        = [contentPlane contentRect];
   frame        = UIEdgeInsetsInsetRect( frame, UIEdgeInsetsMake( 30, 30, 30, 30));

   layer = [DebugTextLayer layerWithFrame:frame];
   [layer setTextColor:CGColorMakeWhite()];
   [layer setTextBackgroundColor:CGColorMakeWithRGBA( 0.5, 0.5, 0.5, 1.0)];
   [layer setBackgroundColor:CGColorMakeWithRGBA( 0.5, 0.5, 0.5, 1.0)];
   [layer setTextUTF8String:text];
   mulleui_log( "Alignment : %s", NS_ENUM_PRINT( UITextVerticalAlignment, valignment));
   mulleui_log( "Text      : \"%#s\"", text);
   [layer setTextVerticalAlignment:valignment];

   view  = [UIView viewWithLayer:layer];
   [view setClipsToBounds:NO];
   [contentPlane addSubview:view];
}


int   main( int argc, char *argv[])
{
   UIWindow                  *window;
   UIApplication             *app;
   NSUInteger                styleMask;
   int                       i;
   unsigned long long        value;
   UITextVerticalAlignment   valignment = UITextAlignmentBaseline;
   char                      *text      = "|y|";

   i = 1;
   if( argc > i)
   {
      if( NS_ENUM_PARSE_STRICT( UITextVerticalAlignment, argv[ i], &value))
      {
         valignment = value;
      }
      else
      {
         mulle_fprintf( stderr, "Unknown vertical alignment \"%s\", known are %s\n", argv[ i],
"UITextAlignmentBaseline"
", UITextAlignmentTop"
", UITextAlignmentBottom"
", UITextAlignmentMiddle"
", UITextAlignmentFill");
         return( 1);
      }
   }

   i = 2;
   if( argc > i)
   {
      text = argv[ i];
   }

   app = [UIApplication sharedInstance];
   {
      styleMask = UIWindowStyleMaskDefault & ~UIWindowStyleRetained;
      window    = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 800.0)
                            titleUTF8String:"Demo"
                                  styleMask:styleMask];
      [window setBackgroundColor:CGColorMakeWithRGBA( 0.25, 0.25, 0.25, 1.0)];
      setupSceneInWindow( window, valignment, text);

      [app addWindow:window];
   }
   return( [app runApp]);
}

//
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
// ║⌐        █⌐'║▄ Γr2«    ║▀                 ▄▄▄      ╙▌▄███      █         ▌
// █]     ,▄▐H  ██████═ª  ╓` ▄█▀▀▀▀█▄        ████     ╓███` `╙╙║█  ▐H        █
// █ "% ,▄▀ ║░╠K█═╣███^   ╛╓█▀      ▐█         ,╓╓═ª╙└   █      ╙█▄▐▌▓######▌╫
// █║▄▄▄█▄▄▄║H:  "╙▀███▄╓▄,█▌╓▄,,▄∩  ██p$ΦΦ▀▀▀▀▀ΦΦΦR≡≥▄╓ ║▄       ╙j▌` ▄▀╙╗ `╫
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
//                          ╙╙▀%▄▄▄▌,≤▄_▄≡,▐▓▓▄▄#ª▀"`

