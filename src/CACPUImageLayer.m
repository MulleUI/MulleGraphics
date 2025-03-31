//
//  CACPUImageLayer.m
//  MulleGraphics
//
//  Copyright (c) 2021 Nat! - Mulle kybernetiK.
//  Copyright (c) 2021 Codeon GmbH.
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
#import "CACPUImageLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"



@implementation CACPUImageLayer

- (void) dealloc
{
   mulle_allocator_free( MulleObjCInstanceGetAllocator( self), _texture);
   [super dealloc];
}


- (void) drawInBytes:(void *) texture
          bitmapInfo:(struct CGBitmapInfo) bitmapInfo
{
   memset( texture, 0xFF, CGBitmapInfoGetAllocationLength( bitmapInfo));
}

//
// this is called every frame. If an image doesn't exist yet, now is the
// time to create it, as a context is present. A CGImage is basically a
// container for a GPU texture. It needs an active context to be created.
// We couldn't do this in "setupScene" (without some major effort)
//
- (BOOL) drawInContext:(CGContext *) context
{
   CGImage               *image;
   CGRect                canvas;
   CGPixelSize   bitmapSize;
   CGPixelSize   imageSize;

   // check to see of we need a new image
   canvas     = [self canvas];
   bitmapSize = CGPixelSizeMakeWithSize( canvas.size);

   image      = (CGImage *) [self image];
   imageSize  = [image bitmapSize];
   if( bitmapSize.width != imageSize.width || bitmapSize.height != imageSize.height)
   {
      mulle_allocator_free( MulleObjCInstanceGetAllocator( self), _texture);
      _texture = NULL;
      image    = nil;
   }

   _bitmapInfo = CGBitmapInfoMake( bitmapSize, 0, CGBitmapEncodingRGBABytes);
   if( ! _texture)
      _texture = mulle_allocator_malloc( MulleObjCInstanceGetAllocator( self),
                                         CGBitmapInfoGetAllocationLength( _bitmapInfo));

   [self drawInBytes:_texture
          bitmapInfo:_bitmapInfo];

   // Send it off to the GPU
   if( ! image)
   {
      image = [[[CGImage alloc] initWithRGBABytes:_texture
                                       bitmapSize:_bitmapInfo.size
                                     textureFlags:0
                                   nameUTF8String:"CACPUImageLayer"
                                          context:context] autorelease];
      [self setImage:image];
   }
   else
      [context setRGBABytes:_texture
               forTextureID:[image textureID]];

   // We don't have to keep it around, though we haven't drawn yet
   // Usually we don't unless requested.
   if( ! _keepsCPUTexture)
   {
      mulle_allocator_free( MulleObjCInstanceGetAllocator( self), _texture);
      _texture = NULL;
      memset( &_bitmapInfo, 0, sizeof( _bitmapInfo));
   }

   // TODO: need comment here, why this is last
   return( [super drawInContext:context]);
}

@end
