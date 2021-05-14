#import "import.h"

#include <stdint.h>

/*
 *  (c) 2021 nat <|ORGANIZATION|>
 *
 *  version:  major, minor, patch
 */
#define MULLE_GRAPHICS_VERSION  ((0 << 20) | (7 << 8) | 56)


static inline unsigned int   MulleGraphics_get_version_major( void)
{
   return( MULLE_GRAPHICS_VERSION >> 20);
}


static inline unsigned int   MulleGraphics_get_version_minor( void)
{
   return( (MULLE_GRAPHICS_VERSION >> 8) & 0xFFF);
}


static inline unsigned int   MulleGraphics_get_version_patch( void)
{
   return( MULLE_GRAPHICS_VERSION & 0xFF);
}


extern uint32_t   MulleGraphics_get_version( void);

/*
   Add your library headers here for exposure to library
   consumers.
*/
// #import "MyClass.h"



#import "_MulleGraphics-export.h"
#include "_MulleGraphics-provide.h"

#ifdef __has_include
# if __has_include( "_MulleGraphics-versioncheck.h")
#  include "_MulleGraphics-versioncheck.h"
# endif
#endif

