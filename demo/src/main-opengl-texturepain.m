#import "import-private.h"


// texture from Unreal Tournament 2003 used w/o permission
static char  tunnelstonetex_png_data[] =
#include "tunnelstonetex.inc"
;

#define s_tunnelstonetex_png_data  (sizeof( tunnelstonetex_png_data) - 1)

#define R  { 0xFF, 0x00, 0x00, 0xFF }
#define G  { 0x00, 0xFF, 0x00, 0xFF }
#define B  { 0x00, 0xFF, 0xFF, 0xFF }
#define Y  { 0xFF, 0xFF, 0x00, 0xFF }

static char   texture[ 8 * 8][ 4] =
{
   R, R, R, R,   Y, Y, Y, Y,
   R, R, R, R,   Y, Y, Y, Y,
   R, R, R, R,   Y, Y, Y, Y,
   R, R, R, R,   Y, Y, Y, Y,

   B, B, B, B,   G, G, G, G,
   B, B, B, B,   G, G, G, G,
   B, B, B, B,   G, G, G, G,
   B, B, B, B,   G, G, G, G
};


static void   checkGLError( const char* str)
{
	GLenum   err;

	err = glGetError();
	if (err != GL_NO_ERROR)
   {
		mulle_fprintf( stderr, "Error %08x after %s\n", err, str);
		return;
	}
}



@interface TriangleLayer : CAOpenGLLayer
{
   UIBitmapImage   *_textureImage;
   GLuint           _glTextureID;
}
@end


@implementation TriangleLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   [super initWithFrame:frame];

   _textureImage = [[UIBitmapImage alloc] initWithFileCData:mulle_data_make( tunnelstonetex_png_data,
                                                                            s_tunnelstonetex_png_data)
                                                  allocator:NULL];
   if( ! _textureImage)
   {
      [self release];
      return( nil);
   }

   return( self);
}


- (void) dealloc
{
   [_textureImage release];
   [super dealloc];
}


- (void) drawOpenGLWithContext:(CGContext *) context
{
   struct CGBitmapInfo   bitmapInfo;

   glDisable( GL_SCISSOR_TEST);
   glEnable(GL_DEPTH_TEST);
   glShadeModel(GL_FLAT);
   checkGLError( "incoming");
   if( ! _glTextureID)
   {
      bitmapInfo = [_textureImage bitmapInfo];

      glGenTextures( 1, &_glTextureID);
      glBindTexture( GL_TEXTURE_2D, _glTextureID);
      glPixelStorei( GL_UNPACK_ALIGNMENT, 1);
      checkGLError( "generate");

      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
#if 0
      glTexImage2D( GL_TEXTURE_2D, 0,        // mimmap level
                                   GL_RGBA,  // openGL format
                                   (GLsizei) bitmapInfo.size.width,
                                   (GLsizei) bitmapInfo.size.height,
                                   0,       // border (0 or 1)
                                   GL_RGBA,  // incoming bitmap format
                                   GL_UNSIGNED_BYTE,
                                   [_textureImage bytes]);
#else
      glTexImage2D( GL_TEXTURE_2D, 0,        // mimmap level
                                   GL_RGBA,  // openGL format
                                   (GLsizei) 8,
                                   (GLsizei) 8,
                                   0,       // border (0 or 1)
                                   GL_RGBA,  // incoming bitmap format
                                   GL_UNSIGNED_BYTE,
                                   texture);
#endif
      checkGLError( "upload");
   //      glBindTexture(GL_TEXTURE_2D, 0);

   //   [_textureImage autorelease];
   //   _textureImage = nil;
   }

   glEnable( GL_TEXTURE_2D);
   glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
   assert( _glTextureID);
   checkGLError( "enable");

   glBindTexture(GL_TEXTURE_2D, _glTextureID);
   glBegin( GL_QUADS);
   {
      glTexCoord2f( 0.0, 0.0);
      glVertex2f( -0.5, -0.5);
      glTexCoord2f( 1.0, 0.0);
      glVertex2f( 0.5, -0.5);
      glTexCoord2f( 1.0, 1.0);
      glVertex2f( 0.5, 0.5);
      glTexCoord2f( 0.0, 1.0);
      glVertex2f( -0.5, 0.5);
   }
   glEnd();
   checkGLError( "draw");
}

@end


int   main( int argc, char *argv[])
{
   UIApplication   *app;
   UIWindow        *window;
   CALayer         *layer;

   app = [UIApplication sharedInstance];
   {
      layer  = [TriangleLayer layerWithFrame:CGRectMake( 0, 0, 640, 400)];
      window = [UIWindow windowWithLayer:layer
                         titleUTF8String:NULL];
      [window setFrameRateHz:1.0];
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

