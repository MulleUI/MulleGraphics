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
#import "CAImageLayer.h"

//
// This class is useful for quick hacks and old-school demo effects.
// Drawing is done to CPU memory and then copies to the CPU (every frame!)
//
// This class creates a CPU texture during drawInContext: and calls
// -drawInBytes:bitmapInfo: to get it filled.
//
// If you want to simulate a display of 64x32 pixels. You setCanvas:
// setCanvas:CGRectMake( 0,0,63,32). This will not be scaled, if the layer
// frame is larger or small than.
// If you want your drawing scaled, then also do a
// setBounds:CGRectMake( 0,0,63,32)
// Sublass from CAImageLayer so we can get the storing and drawing of CGImage
// for free
//
@interface CACPUImageLayer : CAImageLayer
{
   void   *_texture;
}

// you may choose to keep the CPU texture around, this could be useful
// if you are just doing small incremental changes. Note! Just writing
// to the texture does nothing, changes only appear after drawInTexture:
// bitmapInfo: is called, as then the texture is uploaed to the GPU
@property( assign) BOOL   keepsCPUTexture;

//
// Subclasses will override this to do their drawing.
// Currently the texture is always RGBA, but assert the bitmapInfo encoding
// nevertheless. The default implementation fills the texture with white
//
- (void) drawInBytes:(void *) texture
          bitmapInfo:(struct CGBitmapInfo) bitmapInfo;

@end

