#import "import-private.h"


#define STEP  30.0

@interface LSystemLayer : CGGraphicsLayer
{
   CGPoint   center;
   CGFloat   angle;

   char      *string;
   size_t    string_len;
   size_t    index;
}

@end


@implementation LSystemLayer


#define N_RULES 2

static struct
{
   char   key;
   char   *command;
} rules[ 2]  =
{
   { 'A', "-BF+AFA+FB-" },
   { 'B', "+AF-BFB-FA+" }
};

// interpret an L-system
static char   *lindenmayer( char *s)
{
   size_t   i, s_len;
   size_t   j, rules_len;
   int      ismatch;
   char     *outputstring;

   s_len = strlen( s);
   mulle_buffer_do_string( buffer, NULL, outputstring)
   {
      for( i = 0; i < s_len; i++)
      {
         ismatch = 0; // by default, no match
         for( j = 0; j < N_RULES; j++)
         {
            if( s[i] == rules[ j].key)
            {
               mulle_buffer_add_string( buffer, rules[ j].command);
               ismatch = 1;
               break;
            }
         }

         if( ismatch == 0)
            mulle_buffer_add_byte( buffer, s[ i]);
      }
   }

   return( outputstring);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   char   *oldstring;
   int    i;

   self   = [super initWithFrame:frame];

   center = CGPointMake( 0, frame.size.height - 1);
   angle  = 0.0;

   for( i = 0; i < 5; i++)
   {
      oldstring = string;
      string    = lindenmayer( oldstring ? oldstring : "A");
      mulle_free( oldstring);
   }
   string_len = strlen( string);

   return( self);
}


- (void) dealloc
{
   mulle_free( string);
   [super dealloc];
}


// this is a custom function that draws turtle commands
- (void) drawNextCommand:(int) k
               inContext:(CGContext *) context
{
   CGFloat   radius;
   CGPoint   oldCenter;
   CGFloat   r, g, b, a;
   CGColor   color;

   if( k == 'F')
   {
      oldCenter = center;
       // draw forward
       // polar to cartesian based on step and angle:
      center.x = oldCenter.x + STEP * cos( angle * M_PI_f / 180.0);
      center.y = oldCenter.y + STEP * sin( angle * M_PI_f / 180.0);
      [context strokeLineFromPoint:oldCenter
                           toPoint:center
                       strokeWidth:1.0
                          hexColor:0x000000FF];
   }
   else
      if( k == '+')
      {
          angle += 90.0; // turn left
      }
      else
         if( k == '-')
         {
            angle -= 90.0; // turn right
         }

  // pick a gaussian (D&D) distribution for the radius:

  radius  = CGFloatMakeRandomMinMax( 0, STEP - STEP / 4);
  radius += CGFloatMakeRandomMinMax( 0, STEP - STEP / 4);
  radius += CGFloatMakeRandomMinMax( 0, STEP - STEP / 4);
  radius  = radius / 3 / 2.0;

  // draw the stuff:

  // give me some random color values:
  r = CGFloatMakeRandomMinMax( 128 / 255.0, 255 / 255.0);
  g = CGFloatMakeRandomMinMax( 0 / 255.0, 192 / 255.0);
  b = CGFloatMakeRandomMinMax( 0 / 255.0, 50 / 255.0);
  a = CGFloatMakeRandomMinMax( 50 / 255.0, 100 / 255.0);

  [context fillCircle:CACircleMakeWithCenterAndRadius( center, radius)
             hexColor:CGHexColorMakeWithRGBA( r, g, b, a)];
  [context strokeCircle:CACircleMakeWithCenterAndRadius( center, radius)
            strokeWidth:1.0
               hexColor:0x000000FF];
}


- (BOOL) drawInContext:(CGContext *) context
{
  [self drawNextCommand:string[ index]
              inContext:context];
  if( ++index >= string_len)
      index = 0;
   return( YES);
}

@end


int   main( int argc, char *argv[])
{
   UIWindow        *window;
   LSystemLayer    *layer;
   UIWindowPlane   *contentPlane;
   UIApplication   *app;

   app = [UIApplication sharedInstance];
   /*
    * window and app
    */
   window = [UIWindow windowWithFrame:CGRectMake( 0, 0, 710, 400)
                      titleUTF8String:"Demo"
                            styleMask:UIWindowStyleMaskDefault & ~UIWindowStyleRetained];
   {
      contentPlane = [window contentView];
      layer        = [LSystemLayer layerWithFrame:[contentPlane contentRect]];
      [contentPlane addLayer:layer];
      [window setOpaque:YES];
      [window os_setSwapInterval:0];
      [window setBackgroundColor:CGColorMakeWhite()];
      [window setFrameRateHz:60.0];
   }
   [app addWindow:window];

   return( [app runApp]);
}

