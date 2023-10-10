#import "import.h"

#include <math.h>


/*
 * This demo is the MulleUICore mulle-glfw-texture demo, which was derived
 * from GLUT, and puts it into a CGOpenGLLayer. This requires lots of changes
 * to the code. There are advantages to using CGOpenGLLayer, as this new layer
 * subclass can be used multiple times.
 *
 */

/**
 * An application that displays a rotating cube with a
 * texture mapped image.
 *
 * @author  Prof. David Bernstein, James Madison University
 */
@interface RotatingQuadLayer : CAOpenGLLayer < UIWindowFrameDelegate>
{
   GLuint    textureName;
   CGFloat   angle[3];
   GLint     axis;
}
@end


@implementation RotatingQuadLayer

#define R  { 0xFF, 0x00, 0x00, 0xFF }
#define G  { 0x00, 0xFF, 0x00, 0xFF }
#define B  { 0x00, 0x00, 0xFF, 0xFF }
#define Y  { 0xFF, 0xFF, 0x00, 0xFF }

//#define R  { 0x7F, 0x3F, 0x00, 0xFF }
//#define G  { 0x00, 0x7F, 0x3F, 0xFF }
//#define B  { 0x3F, 0x00, 0x7F, 0xFF }
//#define Y  { 0x5F, 0x5F, 0x00, 0xFF }

static char   texture[ 8 * 8][ 4] =
{
   R, R, R, R,   Y, Y, Y, Y,
   R, R, R, R,   Y, Y, Y, Y,
   R, R, Y, G,   B, R, Y, Y,
   R, R, B, R,   Y, G, Y, Y,

   B, B, R, B,   G, B, G, G,
   B, B, Y, G,   R, Y, G, G,
   B, B, B, B,   G, G, G, G,
   B, B, B, B,   G, G, G, G
};


- (instancetype) initWithFrame:(CGRect) frame
{
   [super initWithFrame:frame];
   [self setBackgroundColor:CGColorMakeBlack()];
   axis = 2;
   return( self);
}

//
// elevate init_texture to a method
//
- (void) initTexture
{
#if 1
   glEnable( GL_TEXTURE_2D);
   glGenTextures( 1, &textureName);
   glBindTexture( GL_TEXTURE_2D, textureName);

   glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
   glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
   glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST);
   glTexParameterf( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);

   //  glTexEnvi has no effect when a fragment shader is bound.
   glTexEnvi( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_REPLACE);

   glTexImage2D( GL_TEXTURE_2D, 0,                 // One resolution (i.e. level 0)
                                GL_RGBA,
                                8,                 // Width
                                8,                 // Height
                                0,                 // Border width
                                GL_RGBA,           // Format
                                GL_UNSIGNED_BYTE,  // Data type of the texels
                                texture);
#endif   
}


- (void) display
{
   static GLfloat vertices[][3] = {
                                   {-1.0,-1.0, 1.0},
                                   { 1.0,-1.0, 1.0},
                                   { 1.0, 1.0, 1.0},
                                   {-1.0, 1.0, 1.0}
                                   };

   glBindTexture( GL_TEXTURE_2D, textureName);

   // Draw the quad

   glBegin(GL_POLYGON);

   glTexCoord2f(0.0, 0.0);  // Map to the bottom left texel
   glVertex3fv(vertices[0]);

   glTexCoord2f(0.0, 1.0);  // Map to the bottom right texel
   glVertex3fv(vertices[1]);

   glTexCoord2f(1.0, 1.0);  // Map to the top right texel
   glVertex3fv(vertices[2]);

   glTexCoord2f(1.0, 0.0);  // Map to the top left texel
   glVertex3fv(vertices[3]);

   glEnd();
}


- (void) viewPortDidChange:(CGContext *) context
{
#if 1
   GLfloat  aspect;
   CGSize   size;

   size = [self viewPort].size;
   if( size.width <= size.height)
   {
      aspect = (GLfloat) size.height / (GLfloat) size.width;
      glOrtho(-2.0, 2.0, -2.0 * aspect, 2.0 * aspect, -10.0, 10.0);
   }
   else
   {
      aspect = (GLfloat) size.width / (GLfloat) size.height;
      glOrtho(-2.0 * aspect, 2.0 * aspect, -2.0, 2.0, -10.0, 10.0);
   }
#endif   
}


// as we are now coexisting with others, the update can not setup global state
// so the function has been split into update and rotate
- (void) update
{
   angle[ axis] += 2.0;
   if( angle[ axis] > 360.0)
      angle[ axis] -= 360.0;
}


// as the rotation is local state, this has to be redone for each frame
- (void) rotate
{
   glRotatef( angle[ 0], 1.0, 0.0, 0.0);
   glRotatef( angle[ 1], 0.0, 1.0, 0.0);
   glRotatef( angle[ axis], 0.0, 0.0, 1.0);
}


- (void) beginOpenGLWithContext:(CGContext *) context
{
   [super beginOpenGLWithContext:context];

   if( ! textureName)
      [self initTexture];
}


- (void) drawOpenGLInContext:(CGContext *) context
{
   [self rotate];
   [self display];
}


- (void) window:(UIWindow *) window
    didEndFrame:(struct CGFrameInfo *) info
graphicsContext:(id <UIGraphicsContext>) context;
{
   [self update];
}

@end


// int   main( int argc, char *argv[])
// {
//    UIWindow                          *window;
//    UIApplication                     *app;
//    CALayer<UIWindowFrameDelegate>   *layer;
// 
//    app = [UIApplication sharedInstance];
//    {
//       layer  = [CAOpenGLLayer layerWithFrame:CGRectMake( 0, 0, 500, 500)];
//       window = [UIWindow windowWithLayer:layer
//                          titleUTF8String:NULL];
// 
//       assert( window);
//       [window setFrameRate:UIWindowFrameRateAsync];
// 
//       //[window setFrameRateHz:1000/20.0];
//       //[window setFrameDelegate:layer];
//    }
//    return( [app run]);
// }

int   main()
{
   UIWindow            *window;
   UIApplication       *app;
   RotatingQuadLayer   *layer;
   UIView              *view;
   NSUInteger          styleMask;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];
   {
      layer  = [RotatingQuadLayer layerWithFrame:CGRectMake( 0, 0, 300, 300)];

      // teapot is old code
      styleMask = UIWindowStyleMaskDefault;
      styleMask = UIWindowsStyleMaskBySetting( styleMask, UIWindowOpenGLDeprecated, YES);

      window = [UIWindow windowWithLayer:layer
                         titleUTF8String:"Demo"
                              styleMask:styleMask];
      [window setFrameDelegate:layer];
      // static view, no need to refresh
      [window setFrameRateHz:60.0];

      [app addWindow:window];
   }
   return( [app run]);
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

