#ifndef R
# define R   0xFF, 0x00, 0x00, 0xFF
#endif
#ifndef G
# define G   0x00, 0xFF, 0x00, 0xFF
#endif
#ifndef B
# define B   0x00, 0x00, 0xFF, 0xFF
#endif
#ifndef Y
# define Y   0xFF, 0xFF, 0x00, 0xFF
#endif
#ifndef W
# define W   0xFF, 0xFF, 0xFF, 0xFF
#endif
#ifndef _
# define _   0x00, 0x00, 0x00, 0xFF
#endif

#ifndef BITMAP_NAME
# define BITMAP_NAME  bitmap2
#endif


static unsigned char    BITMAP_NAME[ 4 * 32 * 32] =
{
   W, _, W, _,  W, _, W, _,  W, _, W, _,  W, _, W, _,  W, _, W, _,  W, _, W, _,  W, _, W, _,  W, _, W, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,

   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, _, _,  _, _, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, _, _,  _, _, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, _, _,  _, _, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, _, _,  _, _, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,

   W, B, B, B,  B, B, B, B,  R, R, R, R,  _, _, _, _,  _, _, _, _,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, _, _, _,  _, _, _, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, _, _,  _, _, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, _,  _, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,

   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, W,
   W, B, B, B,  B, B, B, B,  R, R, R, R,  R, R, R, R,  Y, Y, Y, Y,  Y, Y, Y, Y,  G, G, G, G,  G, G, G, _,
   _, W, _, W,  _, W, _, W,  _, W, _, W,  _, W, _, W,  _, W, _, W,  _, W, _, W,  _, W, _, W,  _, W, _, W
};
