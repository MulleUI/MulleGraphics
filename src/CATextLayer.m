#import "CATextLayer.h"

#import "import-private.h"

#import "CGGraphicsLayer+MulleGraphics.h"
#import "CATextLayerLayouter+CGGraphicsLayerLayouter.h" // for protocol


#include <ctype.h>



@interface CGGraphicsLayer( Private)

- (id) _initWithFrame:(CGRect) frame;

@end



@implementation CATextLayer

// also used by copy!
- (instancetype) _initWithFrame:(CGRect) frame
{
   CATextLayerLayouter   *layouter;

   self = [super _initWithFrame:frame];

   _clearTypeEnabled = YES;

   // because Fonts are crap and don't adhere to size requests properly, it's
   // usually better to overdraw than to clip.
   _textLineHeight                = INFINITY;   // means copy _fontPixelSize
   _masksToBounds                 = NO;
   _fontPixelSize                 = INFINITY;   // means height of inset canvas
   _textAlignment                 = UITextAlignmentCenter;
   _textVerticalAlignment         = UITextAlignmentVisualMiddle;
   _textPropertiesGenerationCount = 1; // start initially out of sync with editor
   _mulle_structarray_init( &_rowArray, sizeof( struct CATextLayerRow),
                                        alignof( struct CATextLayerRow),
                                        1,
                                        NULL);

   // do we always want a layouter ? hmmm
   layouter = [CATextLayerLayouter new];
   [layouter setTextLayer:self];

   _layouter = layouter;

   return( self);
}


- (instancetype) initWithFrame:(CGRect) frame
{
   self = [self _initWithFrame:frame];

   _selectionPaint = [[CGPaint paintWithHexColor:0x7FFF7F7F] copy];
   _cursorPaint    = [[CGPaint paintWithHexColor:0x7F2F2FCF] copy];

   return( self);
}


- (void) dealloc
{
   _mulle_structarray_done( &_rowArray);

   MulleObjCInstanceDeallocateMemory( self, _fontNameUTF8String);

#ifdef CATEXTLAYER_DATA_DEBUG
   if( _textData.characters)
      MulleUILog( "free %p for _textData", _textData.characters);
#endif
   mulle_utf8data_done( &_textData, MulleObjCInstanceGetAllocator( self));

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
   copy->_selectionPaint      = [self->_selectionPaint copy];

   // because Fonts are crap and don't adhere to size requests properly, it's
   // usually better to overdraw than to clip.
   copy->_clearTypeEnabled    = self->_clearTypeEnabled;
   copy->_masksToBounds       = self->_masksToBounds;

   //
   copy->_fontPixelSize       = self->_fontPixelSize;
   copy->_textAlignment       = self->_textAlignment;
   copy->_textLetterSpacing   = self->_textLetterSpacing;
   copy->_textLineHeight      = self->_textLineHeight;

   MulleObjCObjectSetDuplicatedUTF8String( copy,
                                           (char **) &copy->_fontNameUTF8String,
                                           (char *) self->_fontNameUTF8String);
   return( copy);
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


- (void) setFontPixelSize:(CGFloat) value
{
   [self willChange];
   if( value != _fontPixelSize)
   {
      _fontPixelSize = value;
      _textPropertiesGenerationCount++;
   }
}

- (void) setFrame:(CGRect) frame
{
   [super setFrame:frame];
   _textPropertiesGenerationCount++;
}


- (void) setInsets:(UIEdgeInsets) insets
{
   [self willChange];
   _insets = insets;
   _textPropertiesGenerationCount++;
}



- (void) setTextLetterSpacing:(CGFloat) textLetterSpacing
{
   [self willChange];
   if( textLetterSpacing != _textLetterSpacing)
   {
      _textLetterSpacing = textLetterSpacing;
      _textPropertiesGenerationCount++;
   }
}


- (void) setTextLineHeight:(CGFloat) textLineHeight
{
   [self willChange];
   if( textLineHeight != _textLineHeight)
   {
      _textLineHeight = textLineHeight;
      _textPropertiesGenerationCount++;
   }
}



- (void) setTextAlignment:(UITextAlignment) textAlignment
{
   // not observable
   if( textAlignment != _textAlignment)
   {
      _textAlignment = textAlignment;
      _textPropertiesGenerationCount++;
   }
}


- (CGRect) insetCanvas
{
   return( CGRectInsetWithInsets( [self canvas], _insets));
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

   if( strcmp( _fontNameUTF8String, s))
   {
      MulleObjCObjectSetDuplicatedUTF8String( self, &_fontNameUTF8String, s);
      _textPropertiesGenerationCount++;
   }
}


- (CGPaint *) suggestedTextPaint
{
   CGColor   color;
   CGPaint   *paint;

   paint = _textBackgroundPaint ? _textBackgroundPaint : _backgroundPaint;

   // if we have nothing now, reset to black
   color = paint ? [paint suggestedTextColor] : CGColorMakeBlack();
   return( [CGPaint paintWithColor:color]);
}


- (void) _setTextUTF8Data:(struct mulle_utf8data) data
{
   struct mulle_allocator   *allocator;

   allocator = MulleObjCInstanceGetAllocator( self);

#ifdef CATEXTLAYER_DATA_DEBUG
   if( data.length)
      MulleUILog( "free %p for _textData", _textData.characters);
#endif
   mulle_utf8data_done( &_textData, allocator);

   // don't want two trailing zeroes in incoming data
   // need one trailing zero though
   assert( ! data.length || data.characters[ data.length - 1]);
   assert( ! data.characters[ data.length]);

#ifdef CATEXTLAYER_DATA_DEBUG
   MulleUILog( "set %p for _textData", data.characters);
#endif
   _textData = data;
   _textPropertiesGenerationCount++;

   _mulle_structarray_reset( &_rowArray);
}


- (void) setTextUTF8Data:(struct mulle_utf8data) data
{
   struct mulle_allocator   *allocator;
   NSUInteger               length;
   struct mulle_utf8data    copied;

   if( data.characters == _textData.characters && data.length == _textData.length)
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
   return( _textData);
}


- (char *) textUTF8String  // will be a copy, if internal data has no trailing zero byte
{
   return( _textData.characters ? (char *) _textData.characters : "");
}


- (void) setTextUTF8String:(char *) s
{
   if( ! s)
      s = "";

   // include trailing \0 in data
   [self setTextUTF8Data:mulle_utf8data_make( s, strlen( s) + 1)];
}

- (void) removeAllTextLayerRows
{
   mulle_structarray_reset( &_rowArray);
}


- (void) addTextLayerRows:(struct CATextLayerRow *) row
                    count:(NSUInteger) count
{
   struct CATextLayerRow   *p;

   p = _mulle_structarray_advance( &_rowArray, count);
   memcpy( p, row, count * sizeof( struct CATextLayerRow));
}


- (void) addTextLayerRow:(struct CATextLayerRow *) row
{
   mulle_structarray_add( &_rowArray, row);
}


- (NSUInteger) numberOfRows
{
   return( _mulle_structarray_get_count( &_rowArray));
}



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
   uintptr_t               n;
   char                    *s;
   struct mulle_utf8data   data;

   data = [self textUTF8Data];
   s    = &data.characters[ offset];
   n    = mulle_utf8_utf32_offset_at_characters( data.characters, data.length, s);
   return( n);
}


// offset in bytes into UTF8 string (a la selection) for utf32 offset (a la textRange)
- (NSUInteger) characterOffsetForTextOffset:(NSUInteger) offset
{
   char                    *s;
   struct mulle_utf8data   data;

   data = [self textUTF8Data];
   s    = &data.characters[ offset];
   s    = mulle_utf8_characters_at_utf32_offset( data.characters, data.length, offset);
   if( ! s)
      return( NSNotFound);
   return( s - data.characters);
}


- (CGFloat) suggestedFontPixelSizeWithContext:(id <UILayoutContext>) context
{
   CGFloat      actualFontHeight;
   CGFloat      probe;
   CGFloat      factor;
   CGRect       canvas;
   CGRect       fontBounds;
   NSUInteger   nRows;

   canvas = [self insetCanvas];
   if( canvas.size.height <= 0.0f)
      return( 0.0);

   factor = 1.0;
   if( _textVerticalAlignment == UITextAlignmentVisualMiddle)
   {
      actualFontHeight = canvas.size.height;
   }
   else
   {
      [context useFontWithNameUTF8String:_fontNameUTF8String];
      [context setTextAlign:NVG_ALIGN_LEFT | NVG_ALIGN_TOP];
      [context setTextLetterSpacing:_textLetterSpacing];

      probe = 32.0f;
      [context setFontSize:probe];

      fontBounds.size.height = 0.0;
      if( _textVerticalAlignment == UITextAlignmentVisualFill)
         fontBounds = [context visualBoundsOfText:_textData.characters
                                           length:_textData.length];
      // can happen if text is empty or just spaces
      if(fontBounds.size.height == 0.0)
         fontBounds = [context visualBoundsOfText:"|_;y\xB4" length:4];

      actualFontHeight = fontBounds.size.height;
      if( actualFontHeight != 0.0)
         factor = probe / actualFontHeight;
   }

   nRows = [self numberOfRows];
   if( ! nRows)
      nRows = 1;

   return( (CGFloat) (int) ((canvas.size.height / (CGFloat) nRows) * factor));
}


- (struct CATextLayerFontMetrics) fontMetricsWithLayoutContext:(id <UILayoutContext>) context
{
   struct CATextLayerFontMetrics   metrics;

   // these properties can be INFINITY for special values
   metrics.fontPixelSize = _fontPixelSize;
   if( isinf( _fontPixelSize))
      metrics.fontPixelSize = [self suggestedFontPixelSizeWithContext:context];

   assert( ! isinf( metrics.fontPixelSize) && ! isnan( metrics.fontPixelSize));

   metrics.textLineHeight = _textLineHeight;
   if( isinf( metrics.textLineHeight))
      metrics.textLineHeight = metrics.fontPixelSize;

   assert( ! isinf( metrics.textLineHeight) && ! isnan( metrics.textLineHeight));

   return( metrics);
}


- (struct CATextLayerFontMetrics) prepareLayoutContext:(id <UILayoutContext>) context
{
   struct CATextLayerFontMetrics   metrics;

   [context useFontWithNameUTF8String:_fontNameUTF8String];

   // set this last, depends on text letter spacing and font name
   metrics = [self fontMetricsWithLayoutContext:context];
   MulleUILog( "metrics: { %g, %g}", metrics.fontPixelSize, metrics.textLineHeight);
   [context setFontSize:metrics.fontPixelSize];
   [context setTextLineHeight:metrics.textLineHeight];

   [context setTextAlign:UITextAlignmentToTextAlign( _textAlignment)];
   [context setTextLetterSpacing:_textLetterSpacing];
   [context setLineBreakMode:_lineBreakMode];

   // memo we dont use vertical height, thats used by the layouter only
   return( metrics);
}


- (BOOL) drawInContext:(CGContext *) context
{
   BOOL                    useClearType;
   CGPaint                 *textBackgroundPaint;
   CGPaint                 *textPaint;
   CGPoint                 origin;
   NSUInteger              i;
   NSUInteger              nRows;
   CGColor                 textColor;
   CGColor                 textBackgroundColor;
   struct CATextLayerRow   *row;
   char                    *s;

   if( ! [super drawInContext:context])
      return( NO);

   nRows = _mulle_structarray_get_count( &_rowArray);
   // nothing to draw ? then bail
   if( ! nRows)
      return( YES);


   // set font, size, alignment...
   _renderedFontMetrics = [self prepareLayoutContext:context];

   origin = _origin;

   // if textPaint is not set, use color derived from :_backgroundPaint
   textPaint = _textPaint ? _textPaint : [self suggestedTextPaint];
   assert( textPaint);

   // figure out if we can use clearType
   // as we are a CALayer, we can't walk the ancestors up, so backgroundPaint
   // has to be the exact color we are painting on

   useClearType        = _clearTypeEnabled;
   textBackgroundPaint = useClearType && _textBackgroundPaint
                         ? _textBackgroundPaint
                         : _backgroundPaint;

   textColor           = [textPaint mainColor];
   textBackgroundColor = [textBackgroundPaint mainColor];


   useClearType &= [textBackgroundPaint isMonochrome] &&
                   [textPaint isMonochrome] &&
                   [_selectionPaint isMonochrome];
   useClearType &= [textBackgroundPaint isOpaque];

   CGContextClearType( context, useClearType);

   for( i = 0; i < nRows; i++)
   {
      row = _mulle_structarray_get( &_rowArray, i);

      /*
       * Draw selection
       */
      if( _selectable)
         switch( row->selectionStyle)
         {
         default :
            CGContextFillRectWithPaintable( context, row->selectionRect, _selectionPaint);
         case CATextLayerSelectionStyleNone :
            break;
         }

      CGContextTextColor( context, textColor);
      CGContextTextBackgroundColor( context, textBackgroundColor);

      s = mulle_utf8data_characters_in_range( self->_textData, row->textRange);
      CGContextText( context, origin, s, row->textRange.length);

      /*
       * Draw Cursor
       */
      if( _editing)
      {
         switch( row->cursorStyle)
         {
         default :
            CGContextFillRectWithPaintable( context, row->cursorRect, _cursorPaint);
         case CATextLayerCursorStyleNone :
            break;
         }
      }

      origin.y += _renderedFontMetrics.textLineHeight;

   }
   CGContextClearType( context, 0);

   return( YES);
}


- (void) dumpPropertiesToFILE:(FILE *) fp
{
   mulle_fprintf( fp, "@fontNameUTF8String : %s\n", _fontNameUTF8String ? _fontNameUTF8String: "NULL");
   mulle_fprintf( fp, "@fontPixelSize      : %g\n", [self fontPixelSize]);
   mulle_fprintf( fp, "@textAlignment      : %s\n", UITextAlignmentUTF8String( _textAlignment));
   mulle_fprintf( fp, "@textLetterSpacing  : %f\n", _textLetterSpacing);
   mulle_fprintf( fp, "@textLineHeight     : %f\n", [self textLineHeight]);
}

@end
