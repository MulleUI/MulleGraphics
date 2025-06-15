#import "import-private.h"


@interface View : UIView
@end


@implementation View

#define ZOOM_FACTOR  0.25


- (UIInputEvent *) scrollWheel:(UIMouseScrollEvent *) event
{
   CGFloat   radius;
   CGPoint   center;
   CGPoint   diff;
   CGRect    bounds;
   CGRect    frame;
   CGRect    rect;

   bounds = [[self superview] bounds];
   frame  = [self frame];
   radius = CGRectGetInnerRadius( frame);

   //
   // use zoom factor relative to current zoom, that makes the zoom
   // smoother
   //

   diff = [event scrollOffsetWithAcceleration:YES
                                 useModifiers:YES];

   radius += diff.y * ZOOM_FACTOR * -1.0;
   if( radius <= 4.0)
      radius = 4.0;
   if( radius > bounds.size.width / 2.0)
      radius = bounds.size.width / 2.0;
   if( radius > bounds.size.height / 2.0)
      radius = bounds.size.height / 2.0;

   center = CGRectGetCenter( bounds);
   rect   = CGRectMakeWithCenterAndInnerRadius( center, radius);

   [self setFrame:rect];
   [self setNeedsLayout];

   return( nil);
}

@end


static void   setupSceneInWindow( UIWindow *window)
{
   CGRect        frame;
   View          *view;
   UIView        *contentView;
   CAImageLayer  *layer;
   UIImage       *image;

   contentView = [window contentView];
   frame       = [contentView contentRect];

   frame = UIEdgeInsetsInsetRect( frame, UIEdgeInsetsMake( 4, 4, 4, 4));
   image = [UIImage imageWithContentsOfFileUTF8String:"Outdoors.png"];
   if( ! image)
   {
      mulle_fprintf( stderr, "\"Outdoors.png\" not found\n");
      exit( 1);
   }
   layer = [CAImageLayer layerWithImage:image];
   [layer setFrame:frame];
   [layer setDisplayedRect:CGRectMake( 1.0, 1.0, 32, 32)];
   view  = [View viewWithLayer:layer];
  //[view setBorderColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 0.33)];
  //[view setBorderWidth:1.0];
   [contentView addSubview:view];

   //
   // this ensures that scroll events come to "us" even if the mouse pointer
   // is not over the view
   //
   [view becomeFirstResponder];
}



int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   int             w;

   w = 1024;
   if( argc >= 2)
   {
      w = atoi( argv[ 1]);
      if( w <= 0)
         w = 64;
   }

   app = [UIApplication sharedInstance];
   {
      window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, w+8.0, w+8.0)];
      [window setBackgroundColor:CGColorMakeWithRGBA( 0.5, 0.5, 0.5, 1.0)];
      setupSceneInWindow( window);
      [window setBackgroundColor:CGColorMakeBlack()];
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

