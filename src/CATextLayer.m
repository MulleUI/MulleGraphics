#import "CATextLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"
#import "CATextLayer+Cursor.h"
#import "CATextLayer+Selection.h"
#import "CATextLayer+RowsAndGlyphs.h"

#include <ctype.h>



@interface CGGraphicsLayer( Private)

- (id) _initWithFrame:(CGRect) frame;

@end


//#define CATEXTLAYER_DATA_DEBUG

@interface CATextLayer ( LayoutPrivate)

// will also be used by copy
- (void) _initRowsAndGlyphs;
- (void) _doneRowsAndGlyphs;

@end



@implementation CATextLayer

// also used by copy!
- (instancetype) _initWithFrame:(CGRect) frame
{
   self = [super _initWithFrame:frame];

   _textPaint           = nil;  // default, depend on backgroundColor
   _textRange           = NSRangeMake( NSNotFound, 0);

   // because Fonts are crap and don't adhere to size requests properly, it's
   // usually better to overdraw than to clip.
   _clearTypeEnabled    = YES;
   _masksToBounds       = NO;
   _textLineHeight      = INFINITY;

   [self _initRowsAndGlyphs];

   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   self = [self _initWithFrame:frame];

   _suggestedTextPaint  = [[CGPaint paintWithHexColor:CGHexColorBlack] copy];
   _selectionPaint      = [[CGPaint paintWithHexColor:0x7FFF7F7F] copy];
   _cursorPaint         = [[CGPaint paintWithHexColor:0x7F2F2FCF] copy];

   return( self);
}


- (void) dealloc
{
   [self _doneRowsAndGlyphs];

   [_suggestedTextPaint release];

   MulleObjCInstanceDeallocateMemory( self, _fontNameUTF8String);

#ifdef CATEXTLAYER_DATA_DEBUG
   if( _data.characters)
      MulleUILog( "free %p for _data", _data.characters);
#endif
   mulle_utf8data_done( &_data, MulleObjCInstanceGetAllocator( self));

   [super dealloc];
}


- (id) copy
{
   CATextLayer   *copy;

   copy = [super copy];

   // copy will have called _initWithFrame: !
   // So this is somewhat tricky code, to make copy fully functional
   // and not leak
   //
   copy->_textPaint           = [self->_textPaint copy];
   copy->_suggestedTextPaint  = [self->_suggestedTextPaint copy];
   copy->_selectionPaint      = [self->_selectionPaint copy];

   // because Fonts are crap and don't adhere to size requests properly, it's
   // usually better to overdraw than to clip.
   copy->_clearTypeEnabled    = self->_clearTypeEnabled;
   copy->_masksToBounds       = self->_masksToBounds;
   copy->_textLineHeight      = self->_textLineHeight;

   //
   copy->_fontPixelSize       = self->_fontPixelSize;
   copy->_lineBreakMode       = self->_lineBreakMode;
   copy->_textOffset          = self->_textOffset;
   copy->_textAlignment       = self->_textAlignment;
   copy->_textLetterSpacing   = self->_textLetterSpacing;

   //
   copy->_textVerticalAlignment = self->_textVerticalAlignment;
   copy->_insets              = self->_insets;
//   copy->_multiLineEnabled    = self->_multiLineEnabled;

   MulleObjCObjectSetDuplicatedUTF8String( copy,
                                           (char **) &copy->_fontNameUTF8String,
                                           (char *)   self->_fontNameUTF8String);
   return( copy);
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


- (void) setTextColor:(CGColor) color
{
   [self setTextPaint:[CGPaint paintWithColor:color]];
}


- (void) setTextBackgroundColor:(CGColor) color
{
   [self setTextBackgroundPaint:[CGPaint paintWithColor:color]];
}

- (void) setCursorColor:(CGColor) color
{
   [self setCursorPaint:[CGPaint paintWithColor:color]];
}



- (void) setSelectionColor:(CGColor) color
{
   [self setSelectionPaint:[CGPaint paintWithColor:color]];
}



- (void) _setTextUTF8Data:(struct mulle_utf8data) data
{
   struct mulle_allocator   *allocator;

   allocator = MulleObjCInstanceGetAllocator( self);

#ifdef CATEXTLAYER_DATA_DEBUG
   if( data.length)
      MulleUILog( "free %p for _data", _data.characters);
#endif
   mulle_utf8data_done( &_data, allocator);

   // don't want two trailing zeroes in incoming data
   // need one trailing zero though
   assert( ! data.length || data.characters[ data.length - 1]);
   assert( ! data.characters[ data.length]);

#ifdef CATEXTLAYER_DATA_DEBUG
   MulleUILog( "set %p for _data", data.characters);
#endif
   _data       = data;

   [self invalidateRowsAndGlyphs];
}


- (void) setTextUTF8Data:(struct mulle_utf8data) data
{
   struct mulle_allocator   *allocator;
   NSUInteger               length;
   struct mulle_utf8data    copied;

   if( data.characters == _data.characters && data.length == _data.length)
      return;

   allocator = MulleObjCInstanceGetAllocator( self);
   length    = data.length;

   // don't want two trailing zeroes in incoming data
   if( length)
      if( ! data.characters[ length - 1])
         --length;

   mulle_utf8data_init( &copied, data.characters, length, allocator);
   [self _setTextUTF8Data:copied];
}


- (struct mulle_utf8data) textUTF8Data
{
   return( _data);
}


- (char *) textUTF8String  // will be a copy, if internal data has no trailing zero byte
{
   return( _data.characters ? (char *) _data.characters : "");
}


- (void) setTextUTF8String:(char *) s
{
   if( ! s)
      s = "";

   // include trailing \0 in data
   [self setTextUTF8Data:mulle_utf8data_make( s, strlen( s) + 1)];
}


static void   assert_sane_font_name( char *s)
{
   int   c;

   if( s)
   {
      //fprintf( stderr, "name: %s (%p)\n", s, s);
      while( (c = *s++))
         assert( isalnum( c));
   }
}


// fontNameUTF8String ?
- (void) setFontNameUTF8String:(char *) s
{
   assert_sane_font_name( s);

   MulleObjCObjectSetDuplicatedUTF8String( self, &_fontNameUTF8String, s);
   [self invalidateRowsAndGlyphs];
}


- (NSRange) textRange
{
   struct mulle_utf_information   info;

   if( _textRange.location != NSNotFound)
      return( _textRange);

   if( mulle_utf8_information( _data.characters, _data.length, &info))
      return( NSRangeMake( NSNotFound, 0));

   _textRange = NSRangeMake( 0, info.utf32len);
   return( _textRange);
}


//
// use above textRange to get the to be displayed data
//
- (struct mulle_utf8data) textUTF8DataInTextRange
{
   if( _textRange.location == NSNotFound)
      return( _data);
   return( mulle_utf8data_range_of_utf32_range( _data, _textRange));
}



- (void) setFontPixelSize:(CGFloat) fontPixelSize
{
   [self willChange];
   if( fontPixelSize != _fontPixelSize)
   {
      [self invalidateRowsAndGlyphs];
      _fontPixelSize = fontPixelSize;
   }
}


- (void) setTextAlignment:(UITextAlignment) textAlignment
{
   if( textAlignment != _textAlignment)
   {
      [self invalidateRowsAndGlyphs];
      _textAlignment = textAlignment;
   }
}


// Does not affect vertical rows and glyphs
//- (void) setTextVerticalAlignment:(UITextVerticalAlignment) textVerticalAlignment
//{
//   if( textVerticalAlignment != _textVerticalAlignment)
//   {
//      [self invalidateRowsAndGlyphs];
//      _textVerticalAlignment = textVerticalAlignment;
//   }
//}


- (void) setTextLetterSpacing:(float) textLetterSpacing
{
   [self willChange];
   if( textLetterSpacing != _textLetterSpacing)
   {
      [self invalidateRowsAndGlyphs];
      _textLetterSpacing = textLetterSpacing;
   }
}

- (void) setLineBreakMode:(NSLineBreakMode) lineBreakMode
{
   if( lineBreakMode != _lineBreakMode)
   {
      [self invalidateRowsAndGlyphs];
      _lineBreakMode = lineBreakMode;
   }
}


- (CGFloat) textLineHeight
{
   return( isinf( _textLineHeight) ? _fontPixelSize : _textLineHeight);
}


- (void) setTextLineHeight:(CGFloat) textLineHeight
{
   [self willChange];
   if( textLineHeight != _textLineHeight)
   {
      [self invalidateRowsAndGlyphs];
      _textLineHeight = textLineHeight;
   }
}


- (void) updateSuggestedTextPaintWithBackgroundPaint:(CGPaint *) paint
{
   CGColor   color;

   if( ! paint)
   {
      // if we cleared one use the other now
      paint = _textBackgroundPaint
              ? _textBackgroundPaint
              : _backgroundPaint;
   }

   // if we have nothing now, reset to black
   color = paint ? [paint suggestedTextColor] : CGColorMakeBlack();

   [_suggestedTextPaint autorelease];
   _suggestedTextPaint = [[CGPaint paintWithColor:color] copy];
}


- (void) setBackgroundPaint:(CGPaint *) paint
{
   [super setBackgroundPaint:paint];

   [self updateSuggestedTextPaintWithBackgroundPaint:paint];
}


- (void) setTextBackgroundPaint:(CGPaint *) paint
{
   [_textBackgroundPaint autorelease];
   _textBackgroundPaint = [paint copy];

   [self updateSuggestedTextPaintWithBackgroundPaint:paint];
}



//static size_t   mulle_utf8_utf32length( mulle_utf8_t *s, size_t len)
//{
//   mulle_utf8_t   *sentinel;
//   size_t          n;
//
//   sentinel = &s[ len];
//
//   n = 0;
//   while( s < sentinel)
//   {
//      mulle_utf8_next_utf32character( &s);
//      ++n;
//   }
//   return( n);
//}


char  *mulle_utf8_characters_at_utf32_offset( char *data,
                                              size_t length,
                                              size_t offset)
{
   char   *s;
   char   *sentinel;

   s        = data;
   sentinel = &s[ length];

   for(;;)
   {
      if( ! offset)
         return( s);     
      if( s >= sentinel)
         return( NULL); 

      mulle_utf8_next_utf32character( &s);
   }
}


uintptr_t   mulle_utf8_utf32_offset_at_characters( char *data,
                                                   size_t length, 
                                                   char *characters)
{
   char        *s;
   char        *sentinel;
   uintptr_t   n;

   s        = data;
   sentinel = &s[ length];
   if( characters > sentinel || characters < s)
      return( NSNotFound); 

   for( n = 0;; n++)
   {
      if( s >= characters)
      {
         if( s == characters)
            return( n);
         return( NSNotFound); 
      } 

      mulle_utf8_next_utf32character( &s);
   }
}


// utf32 offset (a la textRange) for offset in bytes into UTF8 string (a la selection)
- (NSUInteger) textOffsetForCharacterOffset:(NSUInteger) offset
{
   uintptr_t   n;
   char        *s;

   s = &_data.characters[ offset];   
   n = mulle_utf8_utf32_offset_at_characters( _data.characters, _data.length, s);
   return( n);
}


// offset in bytes into UTF8 string (a la selection) for utf32 offset (a la textRange)
- (NSUInteger) characterOffsetForTextOffset:(NSUInteger) offset;
{
   char  *s;
   
   s = mulle_utf8_characters_at_utf32_offset( _data.characters, _data.length, offset);
   if( ! s)
      return( NSNotFound);
   return( s - _data.characters);
}


@end
