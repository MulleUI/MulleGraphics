#import "import-private.h"

#import <string.h>

#include <stdio.h>
#include <math.h>

#ifdef __APPLE__

int   main( void)
{
   fprintf( stderr, "%s does not run on your platform\n", __FILE__);
   return( 1);
}

#else

# include <GL/gl.h>
# include <GL/glu.h>

// This demo shows how you can fairly easily convert OpenGL code into
// a CAOpenGLLayer subclass.



/*
 * Copyright (C) 1999-2010  Terence M. Welsh
 *
 * This file is part of Plasma.
 *
 * Plasma is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published
 * by the Free Software Foundation; either version 2 of the License,
 * or (at your option) any later version.
 *
 * Plasma is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURP   OSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 */
#define PIx2 6.28318530718f
#define NUMCONSTS 18
#define TEXSIZE 1024


// Useful random number macros
// Don't forget to initialize with srand()
static inline int rsRandi(int x){
   return rand() % x;
}


static inline float rsRandf(float x){
   return x * ((float)(rand()) / (float)(RAND_MAX));
}


// Find absolute value and truncate to 1.0
static inline float fabstrunc(float f){
   if(f >= 0.0f)
      return(f <= 1.0f ? f : 1.0f);
   else
      return(f >= -1.0f ? -f : 1.0f);
}



@interface PlasmaLayer : CAOpenGLLayer
{
   int           readyToDraw;

   float         aspectRatio;
   float         c[NUMCONSTS];  // constant
   float         ct[NUMCONSTS];  // temporary value of constant
   float         cv[NUMCONSTS];  // velocity of constant
   float         position[TEXSIZE][TEXSIZE][2];
   float         plasma[TEXSIZE][TEXSIZE][3];
   float         plasmamap[TEXSIZE * TEXSIZE * 3];
   unsigned int  tex;
}

@property( assign) int   plasmasize;
@property( assign) int   zoom;
@property( assign) int   focus;
@property( assign) int   speed;
@property( assign) int   resolution;

@end


@implementation PlasmaLayer

- (id) initWithFrame:(CGRect) frame
{
   [super initWithFrame:frame];

   _plasmasize     = 64;

   _zoom           = 10;
   _focus          = 30;
   _speed          = 20;
   _resolution     = 25;

   return( self);
}


// done once (per OpenGL context, layer)
- (void) initPlasma
{
   int i, j;

   srand((unsigned)time(NULL));

   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();

   // Initialize constants
   for(i=0; i<NUMCONSTS; i++){
      ct[i] = rsRandf(PIx2);
      cv[i] = rsRandf(0.005f * (float)(_speed)) + 0.0001f;
   }

   // Make texture
   glGenTextures(1, &tex);
   CGContextCheckBackendError( NULL, "after glGenTextures");
   glBindTexture(GL_TEXTURE_2D, tex);
   CGContextCheckBackendError( NULL, "after glBindTexture");
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP);
   glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP);
   CGContextCheckBackendError( NULL, "after glTexParameteri");

   // doesn't work with OpenGLES it seems
   glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, TEXSIZE, TEXSIZE, 0,
      GL_RGB, GL_FLOAT, plasmamap);
   CGContextCheckBackendError( NULL, "after glTexImage2D");
   glEnable(GL_TEXTURE_2D);
   CGContextCheckBackendError( NULL, "after GL_TEXTURE_2D");
   glTexEnvf(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
   CGContextCheckBackendError( NULL, "after glTexEnvf");
}


- (void) setPlasmaSize
{
   CGRect   frame;
   CGFloat  wide;
   CGFloat  high;

   // use aspect ration of frame!
   frame       = [self frame];
   aspectRatio = frame.size.width / frame.size.height;

   if(aspectRatio >= 1.0f){
      wide = 30.0f / (float)(_zoom);
      high = wide / aspectRatio;
   }
   else{
      high = 30.0f / (float)(_zoom);
      wide = high * aspectRatio;
   }

   // Set resolution of plasma
   if(aspectRatio >= 1.0f)
      _plasmasize = (int)((float)(_resolution * TEXSIZE) * 0.01f);
   else
      _plasmasize = (int)((float)(_resolution * TEXSIZE) * aspectRatio * 0.01f);

   for(int i=0; i<_plasmasize; i++){
      for(int j=0; j<(int)((float)(_plasmasize) / aspectRatio); j++){
         plasma[i][j][0] = 0.0f;
         plasma[i][j][1] = 0.0f;
         plasma[i][j][2] = 0.0f;
         position[i][j][0] = (float)(i * wide) / (float)(_plasmasize - 1) - (wide * 0.5f);
         position[i][j][1] = (float)(j * high) / ((float)(_plasmasize) / aspectRatio - 1.0f) - (high * 0.5f);
      }
   }
}

- (void) beginOpenGLWithContext:(CGContext *) context
{
   [super beginOpenGLWithContext:context];

   // #warning TODO: create UIGLView to handle resizes and first time inits
   if( ! readyToDraw)
   {
      [self initPlasma];
      [self setPlasmaSize];
      readyToDraw = 1;
   }

   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();
   glOrtho(0.0f, 1.0f, 0.0f, 1.0f, -1, 1);
}


- (void) drawOpenGLInContext:(CGContext *) context
{
   int     i, j;
   float   rgb[3];
   float   temp;
   int     index;
   float   maxdiff;
   float   focus;

   // init formerly static values...
   focus   = (float)(_focus) / 50.0f + 0.3f;
   maxdiff = 0.004f * (float)(_speed);

   //Update constants
   for(i=0; i<NUMCONSTS; i++){
      ct[i] += cv[i];
      if(ct[i] > PIx2)
         ct[i] -= PIx2;
      c[i] = sinf(ct[i]) * focus;
   }

   // Update colors
   for(i=0; i<_plasmasize; i++){
      for(j=0; j<(int)((float)(_plasmasize) / aspectRatio); j++){
         // Calculate vertex colors
         rgb[0] = plasma[i][j][0];
         rgb[1] = plasma[i][j][1];
         rgb[2] = plasma[i][j][2];
         plasma[i][j][0] = 0.7f
                     * (c[0] * position[i][j][0] + c[1] * position[i][j][1]
                     + c[2] * (position[i][j][0] * position[i][j][0] + 1.0f)
                     + c[3] * position[i][j][0] * position[i][j][1]
                     + c[4] * rgb[1] + c[5] * rgb[2]);
         plasma[i][j][1] = 0.7f
                     * (c[6] * position[i][j][0] + c[7] * position[i][j][1]
                     + c[8] * position[i][j][0] * position[i][j][0]
                     + c[9] * (position[i][j][1] * position[i][j][1] - 1.0f)
                     + c[10] * rgb[0] + c[11] * rgb[2]);
         plasma[i][j][2] = 0.7f
                     * (c[12] * position[i][j][0] + c[13] * position[i][j][1]
                     + c[14] * (1.0f - position[i][j][0] * position[i][j][1])
                     + c[15] * position[i][j][1] * position[i][j][1]
                     + c[16] * rgb[0] + c[17] * rgb[1]);

         // Don't let the colors change too much
         temp = plasma[i][j][0] - rgb[0];
         if(temp > maxdiff)
            plasma[i][j][0] = rgb[0] + maxdiff;
         if(temp < -maxdiff)
            plasma[i][j][0] = rgb[0] - maxdiff;
         temp = plasma[i][j][1] - rgb[1];
         if(temp > maxdiff)
            plasma[i][j][1] = rgb[1] + maxdiff;
         if(temp < -maxdiff)
            plasma[i][j][1] = rgb[1] - maxdiff;
         temp = plasma[i][j][2] - rgb[2];
         if(temp > maxdiff)
            plasma[i][j][2] = rgb[2] + maxdiff;
         if(temp < -maxdiff)
            plasma[i][j][2] = rgb[2] - maxdiff;

         // Put colors into texture
         index = (i * TEXSIZE + j) * 3;
         plasmamap[index] = fabstrunc(plasma[i][j][0]);
         plasmamap[index+1] = fabstrunc(plasma[i][j][1]);
         plasmamap[index+2] = fabstrunc(plasma[i][j][2]);
      }
   }

   // Update texture
   glPixelStorei(GL_UNPACK_ROW_LENGTH, TEXSIZE);
   glBindTexture(GL_TEXTURE_2D, tex);
   glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, (int)((float)(_plasmasize) / aspectRatio), _plasmasize,
      GL_RGB, GL_FLOAT, plasmamap);

   // Draw it
   // The "- 1" cuts off right and top edges to get rid of blending to black
   float texright = (float)(_plasmasize - 1) / (float)(TEXSIZE);
   float textop = (float)((int)((float)(_plasmasize) / aspectRatio) - 1) / (float)(TEXSIZE);
   glBegin(GL_TRIANGLE_STRIP);
      glTexCoord2f(0.0f, 0.0f);
      glVertex2f(0.0f, 0.0f);
      glTexCoord2f(0.0f, texright);
      glVertex2f(1.0f, 0.0f);
      glTexCoord2f(textop, 0.0f);
      glVertex2f(0.0f, 1.0f);
      glTexCoord2f(textop, texright);
      glVertex2f(1.0f, 1.0f);
   glEnd();
}

@end


//
// here we use a custom View to react to changes in the view size
// to pass it onto the layer
//
@interface PlasmaView : UIView
@end

@implementation PlasmaView

+ (Class) layerClass
{
   return( [PlasmaLayer class]);
}

- (void) layoutLayers
{
   [(PlasmaLayer *) [self layer] setPlasmaSize];

   [super layoutLayers];
}

@end


@interface PlasmaView( Forwarding) <MulleObjectForwarding>

@property( assign) int   plasmasize;
@property( assign) int   zoom;
@property( assign) int   focus;
@property( assign) int   speed;
@property( assign) int   resolution;

@end


@implementation PlasmaView( Forwarding)
@end


@implementation UIView ( AnimateFrame)
@end


static PlasmaView   *setupPlasmaView( UIWindow *window, CGColor color)
{
   PlasmaView   *view;

   view  = [PlasmaView viewWithFrame:CGRectZero];
   [view setBackgroundColor:[UIColor darkGrayColor]];
   [view setBorderColor:color];
   [view setBorderWidth:6.0];

   return( view);
}


void   setupScene( UIWindow *window)
{
   PlasmaView   *plasmaView;
   UIView       *contentView;

   contentView = [window contentView];

   plasmaView = setupPlasmaView( window, [UIColor whiteColor]);
   [plasmaView setMargins:UIEdgeInsetsMake( 40, 40, 40, 40)];
   [plasmaView setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [contentView addSubview:plasmaView];

   plasmaView = setupPlasmaView( window, [UIColor blackColor]);
   [plasmaView setMargins:UIEdgeInsetsMake( 120, 120, 120, 220)];
   [plasmaView setAutoresizingMask:UIViewAutoresizingScaleToFill];
   [plasmaView setZoom:5];  // gets forwarded to mainLayer
   [contentView addSubview:plasmaView];
}


int   main( int argc, char *argv[])
{
   UIWindow       *window;
   UIApplication  *app;
   /*
    * window and app
    */
   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0.0f, 0.0f, 640.0f, 400.0f)
                      titleUTF8String:"Demo"
                            styleMask:UIWindowStyleMaskDefault|UIWindowOpenGLDeprecated];
   [window setBackgroundColor:CGColorMakeWithRGBA( 0.0, 0.0, 0.0, 1.0)];
   [window setFrameRateHz:120.0];

   setupScene( window);

   [app addWindow:window];

   return( [app runApp]);
}

#endif


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

