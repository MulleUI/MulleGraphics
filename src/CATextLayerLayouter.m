#import "CATextLayerLayouter.h"

#import "import-private.h"

#import "CATextLayer.h"
#include <ctype.h>



@interface CGGraphicsLayer( Private)

- (id) _initWithFrame:(CGRect) frame;

@end


//#define CATEXTLAYER_DATA_DEBUG


@implementation CATextLayerLayouter


- (instancetype) init
{
   [super init];

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

@end
