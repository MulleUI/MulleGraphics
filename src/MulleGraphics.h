//
//  MulleGraphics.h
//  MulleGraphics
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "import.h"

#include <stdint.h>

/*
 *  (c) 2021 nat Mulle kybernetiK
 *
 *  version:  major, minor, patch
 */
#define MULLE_GRAPHICS_VERSION  ((0UL << 20) | (8 << 8) | 1)


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


MULLE_GRAPHICS_GLOBAL
uint32_t   MulleGraphics_get_version( void);

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

