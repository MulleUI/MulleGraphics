#import "import-private.h"

#include <math.h>


@interface Orb : NSObject

@property( assign) CGPoint   origin;
@property( assign) CGPoint   lastOrigin;
@property( assign) CGFloat   colorAngle;
@property( assign) CGFloat   angle;
@property( assign) CGFloat   lastAngle;
@property( assign) CGFloat   size;
@property( assign) CGFloat   radius;
@property( assign) CGFloat   speed;
@property( assign) CGFloat   alpha;

@end


@implementation Orb

- (instancetype) initWithCanvas:(CGRect) canvas
                         origin:(CGPoint) m
{
   CGFloat  dx = (canvas.size.width/2) - m.x;
   CGFloat  dy = (canvas.size.height/2) - m.y;
   CGFloat  dist  = sqrtf(dx * dx + dy * dy);
   CGFloat  angle = atan2f(dy, dx);

   self->_origin     = m;
   self->_lastOrigin = m;
   self->_colorAngle = 0;
   self->_angle      = angle + M_PI_f/2;
   self->_lastAngle  = self->_angle;
   //size = .5+dist/250;
   self->_size       = CGFloatMakeRandomMinMax( 1, 5) / 2.0;
   self->_radius     = dist;
   self->_speed      = (CGFloatMakeRandomMinMax(5,10)/1000)*(dist/750)+.015;
   self->_alpha      = 1 - fabs(dist)/canvas.size.width ;

   return( self);
}


- (BOOL) drawInContext:(CGContext *) context
                canvas:(CGRect ) canvas
{
   CGFloat            hue;

    hue = fmod( _colorAngle, 360.0) / 360.0;

   CGPoint center   = CGPointMake( canvas.size.width  / 2,
                                    canvas.size.height / 2);
   CGContextBeginPath( context);
   CGContextArc( context, CACircleMake(center.x, center.y, _radius), self->_lastAngle, self->_angle);
   CGContextStrokeColor( context, CGColorMakeWithHSLA( hue, 1.0, 0.5, 1.0));
   CGContextStrokeWidth( context, _size);
   CGContextStroke( context);
   return( YES);
}


- (void) updateInCanvas:(CGRect ) canvas
{
   self->_lastOrigin = self->_origin;

   CGFloat x1     = canvas.size.width / 2;
   CGFloat y1     = canvas.size.height / 2;
   CGFloat x2     = _origin.x;
   CGFloat y2     = _origin.y;
   CGFloat rise   = y1-y2;
   CGFloat run    = x1-x2;
   CGFloat slope  = -(rise/run);
   CGFloat radian = atanf(slope);
   CGFloat angleH = floorf(radian*(180/M_PI_f));

   if( x2 < x1 && y2 < y1)                    { angleH += 180; }
   if( x2 < x1 && y2 > y1)                    { angleH += 180; }
   if( x2 > x1 && y2 > y1)                    { angleH += 360; }
   if( y2 < y1 && isinf( slope) && slope < 0) { angleH = 90;   }
   if( y2 > y1 && isinf( slope) && slope > 0) { angleH = 270;  }
   if( x2 < x1 && slope == 0)                 { angleH = 180;  }
   if( isnan(angleH))                         { angleH = 0;    }

   CGPoint center   = CGPointMake( canvas.size.width  / 2,
                                   canvas.size.height / 2);
   self->_colorAngle = angleH;
   self->_origin.x   = center.x + sinf(self->_angle*-1) * self->_radius;
   self->_origin.y   = center.y + cosf(self->_angle*-1) * self->_radius;
   self->_lastAngle  = self->_angle;
   self->_angle     += self->_speed;
}

@end


@interface OrbLayer : CGGraphicsLayer
{
   NSMutableArray  *_orbs;
}

@property( assign) BOOL   trail;

@end




@implementation OrbLayer

- (instancetype) initWithFrame:(CGRect) frame
{
   CGFloat   y;
   CGRect    canvas;
   Orb       *orb;

   [super initWithFrame:frame];

   self->_orbs  = [NSMutableArray new];
   [self->_orbs mulleSetThreadSafe:YES];
   self->_trail = YES;

   canvas = [self canvas];
   for( y = 0; y < frame.size.height / 2.0; y += 3.0)
   {
      orb = [[[Orb alloc] initWithCanvas:canvas
                                  origin:CGPointMake( canvas.size.width / 2,
                                                      canvas.size.height / 2 + y)] autorelease];
      [orb mulleSetThreadSafe:YES];
      [self->_orbs addObject:orb];
   }

   return( self);
}


- (void) dealloc
{
   [self->_orbs release];
   [super dealloc];
}


- (BOOL) drawInContext:(CGContext *) context
{
   Orb          *orb;
   CGRect       canvas;
   CGColor      fillColor;
   NSUInteger   i, n;

    canvas    = [self canvas];
   fillColor = CGColorMakeWithRGBA( 0, 0, 0, _trail ? 0.1 : 1.0);
   CGContextFillRectWithColor( context, canvas, fillColor);

   CGContextLineCap( context, NVG_ROUND);
   for( orb in _orbs)
      for( i = 0; i < 3; i++)
      {
         [orb updateInCanvas:canvas];  // location in Window!
         [orb drawInContext:context
                     canvas:canvas];
      }
   return( YES);
}

@end



int   main( int argc, char *argv[])
{
   UIWindow        *window;
   UIApplication   *app;
   UIView          *view;
   UIWindowPlane   *contentPlane;
   MulleUIPerf     *perf;
   OrbLayer        *layer;
   CGRect          contentRect;
   CGRect          frame;
   NSUInteger      styleMask;

   app = [UIApplication sharedInstance];
   {
      styleMask = UIWindowStyleMaskDefault; //  & ~UIWindowStyleRetained;
      window    = [UIWindow windowWithFrame:CGRectMake( 0, 0, 800, 600)
                            titleUTF8String:"Demo"
                                  styleMask:styleMask];

      //window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800.0, 600.0)];
      assert( window);

      [window setFrameRateHz:60.0];
      [window setBackgroundColor:CGColorMakeBlack()]; // this avoids the window contents being cleared
      [window setOpaque:YES]; // this avoids the window contents being cleared

      contentPlane = [window contentView];
      contentRect  = [contentPlane contentRect];
      frame        = contentRect;
      layer        = [OrbLayer layerWithFrame:frame];
      view         = [UIView viewWithLayer:layer];
      [view setAutoresizingMask:UIViewAutoresizingScaleToFill];
      [contentPlane addSubview:view];

      perf = [MulleUIPerf instance];
      [window setFrameDelegate:perf];

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




/*
window.requestAnimFrame=function(){return window.requestAnimationFrame||window.webkitRequestAnimationFrame||window.mozRequestAnimationFrame||window.oRequestAnimationFrame||window.msRequestAnimationFrame||function(a){window.setTimeout(a,1E3/60)}}();

document.onselectstart = function() {
  return false;
};
CGFloat c = document.getElementById('c');
CGFloat ctx = c.getContext('2d');
CGFloat dpr = window.devicePixelRatio;
CGFloat cw = window.innerWidth;
CGFloat ch = window.innerHeight;
c.width = cw * dpr;
c.height = ch * dpr;
ctx.scale(dpr, dpr);
CGFloat rand = function(rMi, rMa){return ~~((Math.random()*(rMa-rMi+1))+rMi);}
ctx.lineCap = 'round';
CGFloat orbs = [];
CGFloat orbCount = 30;
CGFloat radius;

CGFloat trailCB = document.getElementById('trail');
CGFloat trail = trailCB.checked;
CGFloat clearer = document.getElementById('clear');

function createOrb(mx,my){
  CGFloat dx = (cw/2) - mx;
   CGFloat dy = (ch/2) - my;
   CGFloat dist = Math.sqrt(dx * dx + dy * dy);
   CGFloat angle = Math.atan2(dy, dx);
   orbs.push({
      x: mx,
      y: my,
      lastX: mx,
      lastY: my,
      hue: 0,
      colorAngle: 0,
      angle: angle + M_PI_f/2,
      //size: .5+dist/250,
      size: rand(1,3)/2,
      centerX: cw/2,
      centerY: ch/2,
      radius: dist,
      speed: (rand(5,10)/1000)*(dist/750)+.015,
      alpha: 1 - Math.abs(dist)/cw,
      draw: function() {
         ctx.strokeStyle = 'hsla('+self->_colorAngle+',100%,50%,1)';
         ctx.lineWidth = self->_size;
         ctx.beginPath();
         ctx.moveTo(self->_lastX, self->_lastY);
         ctx.lineTo(self->_x, self->_y);
         ctx.stroke();
      },
      update: function(){
         CGFloat mx = self->_x;
         CGFloat my = self->_y;
         self->_lastX = self->_x;
         self->_lastY = self->_y;
         CGFloat x1 = cw/2;
         CGFloat y1 = ch/2;
         CGFloat x2 = mx;
         CGFloat y2 = my;
         CGFloat rise = y1-y2;
         CGFloat run = x1-x2;
         CGFloat slope = -(rise/run);
         CGFloat radian = Math.atan(slope);
         CGFloat angleH = Math.floor(radian*(180/M_PI_f));
         if(x2 < x1 && y2 < y1){angleH += 180;}
         if(x2 < x1 && y2 > y1){angleH += 180;}
         if(x2 > x1 && y2 > y1){angleH += 360;}
         if(y2 < y1 && slope =='-Infinity'){angleH = 90;}
         if(y2 > y1 && slope =='Infinity'){angleH = 270;}
         if(x2 < x1 && slope =='0'){angleH = 180;}
         if(isNaN(angleH)){angleH = 0;}

         self->_colorAngle = angleH;
         self->_x = self->_centerX + Math.sin(self->_angle*-1) * self->_radius;
         self->_y = self->_centerY + Math.cos(self->_angle*-1) * self->_radius;
         self->_angle += self->_speed;

      }
   });
}

function orbGo(e){
   CGFloat mx = e.pageX - c.offsetLeft;
   CGFloat my = e.pageY - c.offsetTop;
   createOrb(mx,my);
}

function turnOnMove(){
   c.addEventListener('mousemove', orbGo, false);
}

function turnOffMove(){
   c.removeEventListener('mousemove', orbGo, false);
}

function toggleTrails(){
   trail = trailCB.checked;
}

function clear(){
 orbs = [];
}

c.addEventListener('mousedown', orbGo, false);
c.addEventListener('mousedown', turnOnMove, false);
c.addEventListener('mouseup', turnOffMove, false);
trailCB.addEventListener('change', toggleTrails, false);
clearer.addEventListener('click', clear, false);

CGFloat count = 100;
while(count--){
      createOrb(cw/2, ch/2+(count*2));
}

CGFloat loop = function(){
  window.requestAnimFrame(loop);
   if(trail){
      ctx.fillStyle = 'rgba(0,0,0,.1)';
      ctx.fillRect(0,0,cw,ch);
   } else {
      ctx.clearRect(0,0,cw,ch);
   }
   CGFloat i = orbs.length;
   while(i--){
      CGFloat orb = orbs[i];
      CGFloat updateCount = 3;
      while(updateCount--){
      orb.update();
      orb.draw(ctx);
      }

   }
}

loop();

*/