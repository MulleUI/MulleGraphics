#import "import-private.h"

#include <unistd.h>


@interface DemoTextLayer : CATextLayer
@end


@implementation DemoTextLayer

- (BOOL) drawInContext:(CGContext *) context
{
   CGRect                      vbounds;
   struct MulleEdgeInsets      insets;

    //
   // draw visual bounds on top of what CATextLayer drew
   //
   [super drawInContext:context];
   [self getTextVisualBounds:&vbounds
                     context:context];

    MulleUICLog( "%s", CGRectUTF8String( vbounds));

    insets = [self insets];

    CGContextSave( context);
   {
      CGContextResetScissor( context);
      CGContextTranslate( context, CGPointMake(insets.left, insets.right));
      CGContextStrokeRectWithColor( context, vbounds, 1.0, CGColorMakeLime());
   }
   CGContextRestore( context);

   return( YES);
}

@end


// red border around text should be "snug"
static char   *strings[] =
{
   "\n  Ahoi! \n \n",
   "Ohne Descender",
   "______",
   "Interview mit van Duijnhoven:\n„Habe den VfL immer im Blick“",
   "Xoy|_Ban",
};

#define N_STRINGS   (sizeof( strings) / sizeof( strings[ 0]))


static void   changeLayerString( UIView *view)
{
   CATextLayer              *layer;
   CGFloat                  insetValue;
   CGLayoutContext          *context;
   CGRect                   frame;
   CGSize                   size;
   char                     *s;
   static NSUInteger        i;
   struct MulleEdgeInsets   insets;
   UIView                   *contentView;
   UIWindow                 *window;

   assert( view);

   window = (UIWindow *) [view window];
   assert( window);

   layer = (CATextLayer *) [view layer];
   assert( [layer isKindOfClass:[CATextLayer class]]);

   s = strings[ i % N_STRINGS];
   [layer setTextUTF8String:s];

   insetValue = ((i / N_STRINGS) & 0x1) ? 10.0f : 0.0f;
   insets     = MulleEdgeInsetsMake( insetValue, insetValue, insetValue, insetValue);
   [layer setInsets:insets];
   i++;

   MulleUICLog( "%td: %g \"%s\"", i, insetValue, s);

   context = [view layoutContext];
   size    = [layer sizeThatFits:CGSizeMake( INFINITY, INFINITY)
                         context:context];
   size.width  += insetValue * 2.0f;
   size.height += insetValue * 2.0f;
   contentView  = [window contentView];

   frame = CGSizeCenterInRect( size, [contentView contentRect]);
   [view setFrame:frame];
}


static UIView *   setupSceneInWindow( UIWindow *window)
{
   CATextLayer     *layer;
   CGRect          frame;
   UIView          *view;
   UIView          *contentView;
   CGSize          size;

   contentView = [window contentView];
   [contentView setBackgroundColor:CGColorMakeGray()];

   layer = [DemoTextLayer object];
   [layer setFontPixelSize:20.0f];
   [layer setBorderWidth:1.0];
   [layer setBorderColor:CGColorMakeRed()];
   [layer setTextBackgroundColor:CGColorMakeGray()];
   [layer setTextColor:CGColorMakeBlack()];
   [layer setTextBackgroundColor:CGColorMakeGray()];

   view = [UIView viewWithLayer:layer];
   [contentView addSubview:view];

   changeLayerString( view);

   return( view);
}


static void   timerCallback( NSTimer *timer, id userInfo)
{
   UIView   *view;

   MulleUICLog( "--------------TIMER-------------------");

   view = userInfo;
   changeLayerString( view);
   [view setNeedsDisplay];
}


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   UIView          *view;
   NSTimer         *timer;
   NSUInteger      styleMask;
   double          delay;

   app = [UIApplication sharedInstance];
   {
      styleMask = UIWindowStyleMaskDefault; // & ~UIWindowStyleRetained;
      window    = [UIWindow windowWithFrame:CGRectMake( 0.0f, 0.0f, 640.0f, 400.0f)
                            titleUTF8String:"Demo"
                                  styleMask:styleMask];
      view = setupSceneInWindow( window);
      [app addWindow:window];

      timer = [[[NSTimer alloc] mulleInitWithRelativeTimeInterval:3.0
                                                   repeatInterval:3.0
                                                         callback:timerCallback
                                                         userInfo:view] autorelease];
      // after addWindow:
      [window addTimer:timer];
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

