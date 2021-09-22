#import <MulleUICore/MulleUICore.h>

#import <string.h>



@interface OpenGLTeapotLayer : CAOpenGLLayer
{
   int   _teaList;
}

@property( observable, assign) CGPoint      rotation;
@property( observable, assign) NSUInteger   grid;

@end 


@implementation OpenGLTeapotLayer

static long patchData[][16] = {
    {102,103,104,105,4,5,6,7,8,9,10,11,12,13,14,15},
    {12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27},
    {24,25,26,27,29,30,31,32,33,34,35,36,37,38,39,40},
    {96,96,96,96,97,98,99,100,101,101,101,101,0,1,2,3,},
    {0,1,2,3,106,107,108,109,110,111,112,113,114,115,116,117},
    {118,118,118,118,124,122,119,121,123,126,125,120,40,39,38,37},
    {41,42,43,44,45,46,47,48,49,50,51,52,53,54,55,56},
    {53,54,55,56,57,58,59,60,61,62,63,64,28,65,66,67},
    {68,69,70,71,72,73,74,75,76,77,78,79,80,81,82,83},
    {80,81,82,83,84,85,86,87,88,89,90,91,92,93,94,95}
};

static float cpData[][3] = {
    {0.2,0,2.7},{0.2,-0.112,2.7},{0.112,-0.2,2.7},{0,-0.2,2.7},
    {1.3375,0,2.53125},{1.3375,-0.749,2.53125},{0.749,-1.3375,2.53125},
    {0,-1.3375,2.53125},{1.4375,0,2.53125},{1.4375,-0.805,2.53125},
    {0.805,-1.4375,2.53125},{0,-1.4375,2.53125},{1.5,0,2.4},{1.5,-0.84,2.4},
    {0.84,-1.5,2.4},{0,-1.5,2.4},{1.75,0,1.875},{1.75,-0.98,1.875},
    {0.98,-1.75,1.875},{0,-1.75,1.875},{2,0,1.35},{2,-1.12,1.35},
    {1.12,-2,1.35},{0,-2,1.35},{2,0,0.9},{2,-1.12,0.9},{1.12,-2,0.9},
    {0,-2,0.9},{-2,0,0.9},{2,0,0.45},{2,-1.12,0.45},{1.12,-2,0.45},
    {0,-2,0.45},{1.5,0,0.225},{1.5,-0.84,0.225},{0.84,-1.5,0.225},
    {0,-1.5,0.225},{1.5,0,0.15},{1.5,-0.84,0.15},{0.84,-1.5,0.15},
    {0,-1.5,0.15},{-1.6,0,2.025},{-1.6,-0.3,2.025},{-1.5,-0.3,2.25},
    {-1.5,0,2.25},{-2.3,0,2.025},{-2.3,-0.3,2.025},{-2.5,-0.3,2.25},
    {-2.5,0,2.25},{-2.7,0,2.025},{-2.7,-0.3,2.025},{-3,-0.3,2.25},
    {-3,0,2.25},{-2.7,0,1.8},{-2.7,-0.3,1.8},{-3,-0.3,1.8},{-3,0,1.8},
    {-2.7,0,1.575},{-2.7,-0.3,1.575},{-3,-0.3,1.35},{-3,0,1.35},
    {-2.5,0,1.125},{-2.5,-0.3,1.125},{-2.65,-0.3,0.9375},{-2.65,0,0.9375},
    {-2,-0.3,0.9},{-1.9,-0.3,0.6},{-1.9,0,0.6},{1.7,0,1.425},
    {1.7,-0.66,1.425},{1.7,-0.66,0.6},{1.7,0,0.6},{2.6,0,1.425},
    {2.6,-0.66,1.425},{3.1,-0.66,0.825},{3.1,0,0.825},{2.3,0,2.1},
    {2.3,-0.25,2.1},{2.4,-0.25,2.025},{2.4,0,2.025},{2.7,0,2.4},
    {2.7,-0.25,2.4},{3.3,-0.25,2.4},{3.3,0,2.4},{2.8,0,2.475},
    {2.8,-0.25,2.475},{3.525,-0.25,2.49375},{3.525,0,2.49375},
    {2.9,0,2.475},{2.9,-0.15,2.475},{3.45,-0.15,2.5125},{3.45,0,2.5125},
    {2.8,0,2.4},{2.8,-0.15,2.4},{3.2,-0.15,2.4},{3.2,0,2.4},{0,0,3.15},
    {0.8,0,3.15},{0.8,-0.45,3.15},{0.45,-0.8,3.15},{0,-0.8,3.15},
    {0,0,2.85},{1.4,0,2.4},{1.4,-0.784,2.4},{0.784,-1.4,2.4},{0,-1.4,2.4},
    {0.4,0,2.55},{0.4,-0.224,2.55},{0.224,-0.4,2.55},{0,-0.4,2.55},
    {1.3,0,2.55},{1.3,-0.728,2.55},{0.728,-1.3,2.55},{0,-1.3,2.55},
    {1.3,0,2.4},{1.3,-0.728,2.4},{0.728,-1.3,2.4},{0,-1.3,2.4},{0,0,0},
    {1.425,-0.798,0},{1.5,0,0.075},{1.425,0,0},{0.798,-1.425,0},
    {0,-1.5,0.075},{0,-1.425,0},{1.5,-0.84,0.075},{0.84,-1.5,0.075}
};


- (void) initTeapot:(long) grid
{
    float p[4][4][3], q[4][4][3], r[4][4][3], s[4][4][3];
    long i, j, k, l;

    if( _teaList)
      return;

    _teaList = glGenLists( 1);
    if( ! _teaList)
      return;

    glNewList( _teaList, GL_COMPILE);
    glPushMatrix();
    glRotatef(270.0, 1.0, 0.0, 0.0);
    for (i = 0; i < 10; i++) {
   for (j = 0; j < 4; j++) {
       for (k = 0; k < 4; k++) {
      for (l = 0; l < 3; l++) {
          p[j][k][l] = cpData[patchData[i][j*4+k]][l];
          q[j][k][l] = cpData[patchData[i][j*4+(3-k)]][l];
          if (l == 1) {
         q[j][k][l] *= -1.0;
          }
          if (i < 6) {
         r[j][k][l] = cpData[patchData[i][j*4+(3-k)]][l];
         if (l == 0) {
             r[j][k][l] *= -1.0;
         }
         s[j][k][l] = cpData[patchData[i][j*4+k]][l];
         if (l == 0) {
             s[j][k][l] *= -1.0;
         }
         if (l == 1) {
             s[j][k][l] *= -1.0;
         }
          }
      }
       }
   }
   glMap2f(GL_MAP2_VERTEX_3, 0, 1, 3, 4, 0, 1, 12, 4, &p[0][0][0]);
   glEnable(GL_MAP2_VERTEX_3);
   glMapGrid2f(grid, 0.0, 1.0, grid, 0.0, 1.0);
   glEvalMesh2(GL_FILL, 0, grid, 0, grid);
   glMap2f(GL_MAP2_VERTEX_3, 0, 1, 3, 4, 0, 1, 12, 4, &q[0][0][0]);
   glEvalMesh2(GL_FILL, 0, grid, 0, grid);
   if (i < 6) {
       glMap2f(GL_MAP2_VERTEX_3, 0, 1, 3, 4, 0, 1, 12, 4, &r[0][0][0]);
       glEvalMesh2(GL_FILL, 0, grid, 0, grid);
       glMap2f(GL_MAP2_VERTEX_3, 0, 1, 3, 4, 0, 1, 12, 4, &s[0][0][0]);
       glEvalMesh2(GL_FILL, 0, grid, 0, grid);
   }
    }
    glDisable(GL_MAP2_VERTEX_3);
    glPopMatrix();
    glEndList();
}

- (void) beginOpenGLWithContext:(CGContext *) context
{
    float position[] = {0.0, 3.0, 3.0, 0.0};
    float local_view[] = {0.0};
    float ambient[] = {0.1745, 0.01175, 0.01175};
    float diffuse[] = {0.61424, 0.04136, 0.04136};
    float specular[] = {0.727811, 0.626959, 0.626959};

    [super beginOpenGLWithContext:context];

    glEnable(GL_DEPTH_TEST);
    glDepthFunc(GL_LESS);

    glLightfv(GL_LIGHT0, GL_POSITION, position);
    glLightModelfv(GL_LIGHT_MODEL_LOCAL_VIEWER, local_view);

    glFrontFace(GL_CW);
    glEnable(GL_LIGHTING);
    glEnable(GL_LIGHT0);
    glEnable(GL_AUTO_NORMAL);
    glEnable(GL_NORMALIZE);

    glMaterialfv(GL_FRONT, GL_AMBIENT, ambient);
    glMaterialfv(GL_FRONT, GL_DIFFUSE, diffuse);
    glMaterialfv(GL_FRONT, GL_SPECULAR, specular);
    glMaterialf(GL_FRONT, GL_SHININESS, 0.6*128.0);

//    glClearColor(0.0, 0.0, 0.0, 0.0);
//    glColor3f(1.0, 1.0, 1.0);

   [self initTeapot:_grid ? _grid : 14];
}


- (void) drawOpenGLWithContext:(CGContext *) context 
{
   glMatrixMode(GL_PROJECTION);
   glLoadIdentity();
   glOrtho(-6.0, 6.0, -6.0, 6.0, -1.0, 10.0);

   glMatrixMode(GL_MODELVIEW);
   glLoadIdentity();

   glTranslatef(0.0, 0.0, -5.0);
   glRotatef( _rotation.y, 0.0,1.0,0.0);
   glRotatef( _rotation.x, 1.0,0.0,0.0);

   glCallList( _teaList);
}

@end


@interface UIView (AnimateFrame)

//
// If we use setFrame: to reset the animation, it is bad as it will get
// triggered during animations again (recursion!)
//
// It's tricky to reliably ask inside -setFrame: if this call comes during
// animation or layout.
//
- (void) setFrame:(CGRect) frame
          animate:(BOOL) animate;

- (void) animateWithFrame:(CGRect) frame 
                 animator:(CAAnimator *) animator;

@end 


@interface OpenGLTeapotView : UIView 
@end 

@implementation OpenGLTeapotView 

+ (Class) layerClass
{
   return( [OpenGLTeapotLayer class]);
} 

- (void) setFrame:(CGRect) frame
          animate:(BOOL) animate
{
   [super setFrame:frame];
   frame.origin.y += 100.0;
   [self animateWithFrame:frame
                 animator:nil];
}

@end 


@implementation UIView (AnimateFrame)

- (void) setFrame:(CGRect) frame
          animate:(BOOL) animate
{
   [self setFrame:frame];
}


- (CAAnimationGroup *) bounceAnimationWithFrame:(CGRect) frame
{
   CATransaction      *ta;
   CAAnimationGroup   *group;

   ta = [CATransaction object];
   [ta begin];
   {
      [ta setAnimationCurve:UIViewAnimationCurveEaseInOut];
      [ta setAnimationDelay:0];
      [ta setAnimationDuration:2];
      [ta setAnimationRepeatCount:INFINITY];
      [ta setAnimationAutoreverses:YES];

      [self setBackgroundColor:[UIColor blackColor]];
      [self setFrame:frame];
   }
   group = [ta commit];
   return( group);
}


- (void) animateWithFrame:(CGRect) frame 
                 animator:(CAAnimator *) animator
{
   CAAnimationGroup   *group;

   group = [self bounceAnimationWithFrame:frame];
   assert( [group animationObject] != nil);

   if( ! animator)
      animator = [[self window] postLayoutAnimator];
   [animator removeAnimationsForAnimationObject:self];
   [animator addAnimation:group];
}

@end 


static UIView   *setupTeapotView( UIWindow *window, CGColorRef color, int grid)
{
   CAAnimationGroup                 *group;
   CAAnimator                       *animator;
   CABasicAnimation                 *animation;
   CATransaction                    *ta;
   CGRect                           frame;
   OpenGLTeapotLayer                *layer;
   OpenGLTeapotView                 *view;
   struct CABasicAnimationOptions   options;

   //frame.origin.x = CGRectGetMaxX( rect) - frame.size.width;  
//   view  = [UIView viewWithFrame:CGRectZero];
   view  = [OpenGLTeapotView viewWithFrame:CGRectZero];
   [view setBackgroundColor:[UIColor darkGrayColor]];
   [view setBorderColor:color];
   [view setBorderWidth:6.0];

   options = CABasicAnimationOptionsMakeCurve( CARelativeTimeRangeMake( 0, 3.0),
                                               INFINITY,
                                               0,
                                               CAAnimationCurveLinear);
                                              
   layer     = (OpenGLTeapotLayer *) [view layer];
   animation = [[[CABasicAnimation alloc] initWithProperty:MulleObjCInstanceSearchProperty( layer, @selector( rotation))
                                           startPointValue:CGPointMake( 0, 0)
                                             endPointValue:CGPointMake( 360, 720)
                                                   options:&options] autorelease];
   [layer addAnimation:animation];
   [layer setGrid:grid];

   return( view);
}


static BOOL   layoutRedView( UIView *view)
{
   CGRect   contentRect;
   CGRect   frame;
   UIView   *greenView;
   UIView   *blueView;
   UIView   *yellowView;
   CGRect   rects[ 2];

   contentRect = [view contentRect];
   CGRectPartitionHorizontally( contentRect, 50.0, 2, rects);

   greenView  = [view subviewWithTag:1];
   blueView   = [view subviewWithTag:2];
   yellowView = [view subviewWithTag:3];
  
   frame = UIEdgeInsetsInsetRect( rects[ 0], UIEdgeInsetsMake( 0, 50, 50, 0));
   [greenView setFrame:frame
               animate:YES];

   frame = UIEdgeInsetsInsetRect( rects[ 1], UIEdgeInsetsMake( 0, 0, 50, 50));
   [blueView setFrame:frame
              animate:YES];

   frame              = contentRect;

   frame.origin.x    += 20.0;
   frame.size.width  -= 40.0;
   frame.origin.y     = CGRectGetMidY( contentRect) - 5.0;
   frame.size.height  = 10.0;
  
   [yellowView setFrame:frame];

   return( NO); // default code should not run
}


void   setupScene( UIWindow *window)
{
   UIView   *redView;
   UIView   *greenView;
   UIView   *blueView;
   UIView   *yellowView;
   UIView   *contentPlane;
   CGRect   rect;
   CGRect   frame;

   contentPlane = [window contentPlane];
   rect         = [contentPlane contentRect];
   frame        = CGRectInset( rect, 40, 40);

   redView = [UIView viewWithFrame:frame];
   [redView setWillLayoutSubviews:layoutRedView];
   [redView setMargins:UIEdgeInsetsMake( 40, 40, 40, 40)];
   [redView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];

   [redView setBackgroundColor:[UIColor redColor]];
   [contentPlane addSubview:redView];

   greenView = setupTeapotView( window, [UIColor greenColor], 14); // smooth  
   [greenView setTag:1];
   [redView addSubview:greenView];

   blueView = setupTeapotView( window, [UIColor blueColor], 2);  // coarse
   [blueView setTag:2];
   [redView addSubview:blueView];

   yellowView = [UIView viewWithFrame:CGRectZero];
   [yellowView setTag:3];
   [yellowView setBackgroundColor:[UIColor yellowColor]];
  
   [redView addSubview:yellowView];
}


int   main( int argc, char *argv[])
{
   UIWindow       *window;
   UIApplication  *app;
   /*
    * window and app
    */
   app    = [UIApplication sharedInstance];
   window = [UIWindow windowWithFrame:CGRectMake( 0.0f, 0.0f, 640.0f, 400.0f)];
   [window setBackgroundColor:CGColorMakeRGBA( 0.0, 0.0, 0.0, 1.0)];
//   [window setFrameRateHz:5.0];
   [app addWindow:window];

   setupScene( window);

   [window renderLoop];

   [app terminate];
   return( 0);
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

