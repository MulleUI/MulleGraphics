//
//  CATextLayerLayouter.m
//  MulleGraphics
//
//  Copyright (c) 2025 Nat! - Mulle kybernetiK.
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
#import "CATextLayerLayouter.h"

#import "import-private.h"

#import "CATextLayer.h"
#include <ctype.h>



@interface CGGraphicsLayer( Private)

- (id) _initWithFrame:(CGRect) frame;

@end


//#define CATEXTLAYER_DATA_DEBUG


@implementation CATextLayerLayouter

static NSUInteger   CATextLayerLayouterClassDebuggingFlags;

+ (void) initialize
{
   char   *s;

   if( MulleObjCClassGetID( self) != @selector( CATextLayerLayouter))
      return;
   s = getenv( "CATextLayerLayouterDebuggingFlags");
   if( s)
      CATextLayerLayouterClassDebuggingFlags = strtol( s, NULL, 0);
}


- (instancetype) init
{
   [super init];

   _debuggingFlags = CATextLayerLayouterClassDebuggingFlags;

   _textRange = NSRangeMake( NSNotFound, 0);

   _mulle_structarray_init( &_rowArray, sizeof( struct CATextLayerLayouterRow),
                                        alignof( struct CATextLayerLayouterRow),
                                        0,
                                        MulleObjCInstanceGetAllocator( self));
   _mulle_structarray_init( &_glyphArray, sizeof( struct UIGlyphPosition),
                                             alignof( struct UIGlyphPosition),
                                             0,
                                             MulleObjCInstanceGetAllocator( self));
   return( self);
}


- (void) dealloc
{
   _mulle_structarray_done( &_glyphArray);
   _mulle_structarray_done( &_rowArray);

   [super dealloc];
}


- (CGFloat) fontAscender
{
   return( _metrics.ascender);
}


- (CGFloat) fontDescender
{
   return( _metrics.descender);
}


- (CGFloat) fontLineHeight
{
   return( _metrics.lineHeight);
}


- (CGFloat) fontBaseline
{
   return( _metrics.lineHeight - _metrics.descender);
}


- (NSRange) textRange
{
   struct mulle_utf_information   info;
   struct mulle_utf8data          data;

   if( _textRange.location != NSNotFound)
      return( _textRange);

   data = [_textLayer textUTF8Data];
   if( mulle_utf8_information( data.characters, data.length, &info))
      return( NSRangeMake( NSNotFound, 0));

   _textRange = NSRangeMake( 0, info.utf32len);
   return( _textRange);
}


//
// use above textRange to get the to be displayed data
//
- (struct mulle_utf8data) textUTF8DataInTextRange
{
   struct mulle_utf8data   data;

   data = [_textLayer textUTF8Data];
   if( _textRange.location == NSNotFound)
      return( data);
   return( mulle_utf8data_range_of_utf32_range( data, _textRange));
}



- (void) invalidate
{
   _generationCount = 0; // sufficient
}



- (void) setTextLayer:(CATextLayer *) textLayer
{
   if( _textLayer != textLayer)
   {
      _textLayer = textLayer;
      [self invalidate];
   }
}


- (void) setSelection:(NSRange) range
{
   CATextLayerLayouterLog( CATextLayerLayouterDebugSelection,
      "selection {%tu,%tu} -> {%tu,%tu}",
      _selection.location, _selection.length,
      range.location, range.length);
   _selection = range;
}


@end
