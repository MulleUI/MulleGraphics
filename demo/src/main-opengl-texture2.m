#import "import-private.h"


// texture from Unreal Tournament 2003 used w/o permission
static char  tunnelstonetex_png_data[] =
#include "tunnelstonetex.inc"
;

#define s_tunnelstonetex_png_data  (sizeof( tunnelstonetex_png_data) - 1)


static void   checkGLError( const char* str)
{
	GLenum   err;

	err = glGetError();
	if( err != GL_NO_ERROR)
   {
		mulle_fprintf( stderr, "Error %08x after %s\n", err, str);
		return;
	}
}



@interface OpenGLTexturedQuadLayer : CAOpenGLLayer
{
   UIBitmapImage   *_textureImage;
   GLuint           _glTextureID;
}
@end


@implementation OpenGLTexturedQuadLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   struct mulle_data   data;

   [super initWithFrame:frame];

   data = mulle_data_make( tunnelstonetex_png_data, s_tunnelstonetex_png_data);

   _textureImage = [[UIBitmapImage alloc] initWithFileCData:data
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
   MulleUILog( "dealloc");
   [_textureImage release];
   [super dealloc];
}


- (void) drawOpenGLInContext:(CGContext *) context
{
   struct CGBitmapInfo   bitmapInfo;

//   glDisable( GL_STENCIL_TEST);
//   glDisable( GL_SCISSOR_TEST);
//   glDisable( GL_DEPTH_TEST);
//   glShadeModel( GL_FLAT);
//   glEnable( GL_DEPTH_TEST);
//   glDepthFunc( GL_LESS);

   glEnable( GL_TEXTURE_2D);
   glTexEnvf( GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
   checkGLError( "incoming");

   if( ! _glTextureID)
   {
      MulleUILog( "load image");

      bitmapInfo = [_textureImage bitmapInfo];

      glGenTextures( 1, &_glTextureID);
      glBindTexture( GL_TEXTURE_2D, _glTextureID);
      glPixelStorei( GL_UNPACK_ALIGNMENT, 1);
      checkGLError( "generate");
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
      glTexParameteri( GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
      glTexImage2D( GL_TEXTURE_2D, 0,        // mimmap level
                                   GL_RGBA,  // openGL format
                                   (GLsizei) bitmapInfo.size.width,
                                   (GLsizei) bitmapInfo.size.height,
                                   0,       // border (0 or 1)
                                   GL_RGBA,  // incoming bitmap format
                                   GL_UNSIGNED_BYTE,
                                   [_textureImage bytes]);
      checkGLError( "upload");
   //      glBindTexture(GL_TEXTURE_2D, 0);

   //   [_textureImage autorelease];
   //   _textureImage = nil;
   }

   MulleUILog( "draw texture: %d", _glTextureID);

   glBindTexture( GL_TEXTURE_2D, _glTextureID);

//   glDisable( GL_TEXTURE_2D);
//   glColor3f(1.0, 0.0, 0.0); // Set color to red

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
   NSUInteger      styleMask;

   app = [UIApplication sharedInstance];
   {
      layer     = [OpenGLTexturedQuadLayer layerWithFrame:CGRectMake( 0, 0, 640, 400)];

      styleMask = UIWindowStyleMaskNonRetained;
      styleMask = UIWindowsStyleMaskBySetting( styleMask, UIWindowOpenGLDeprecated, YES);

      window = [UIWindow windowWithLayer:layer
                         titleUTF8String:"Demo"
                               styleMask:styleMask];
      [window setFrameRateHz:1 / 3.0f];
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

