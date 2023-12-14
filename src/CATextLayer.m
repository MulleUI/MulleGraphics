#import "CATextLayer.h"

#import "import-private.h"

#import "CALayer+MulleGraphics.h"
#import "CATextLayer+Cursor.h"
#import "CATextLayer+Selection.h"

#include <ctype.h>


NS_ENUM_TABLE( CATextLayerAlignmentMode, 3) =
{
   NS_ENUM_ITEM( CAAlignmentLeft),
   NS_ENUM_ITEM( CAAlignmentRight),
   NS_ENUM_ITEM( CAAlignmentCenter)
};


NS_ENUM_TABLE( CATextLayerVerticalAlignmentMode, 6) =
{
   NS_ENUM_ITEM( MulleTextVerticalAlignmentMiddle),
   NS_ENUM_ITEM( MulleTextVerticalAlignmentBaseline),
   NS_ENUM_ITEM( MulleTextVerticalAlignmentBoundsMiddle),
   NS_ENUM_ITEM( MulleTextVerticalAlignmentVisualMiddle),
   NS_ENUM_ITEM( MulleTextVerticalAlignmentTop),
   NS_ENUM_ITEM( MulleTextVerticalAlignmentBottom)
};


NS_ENUM_TABLE( NSLineBreakMode, 2) = 
{
   NS_ENUM_ITEM( NSLineBreakByClipping),
   NS_ENUM_ITEM( NSLineBreakByWordWrapping)
};


@implementation CATextLayer : CALayer

// will also be used by copy
- (void) _init
{
   _mulle_structarray_init( &_rowArray, sizeof( NVGtextRow),
                                        alignof( NVGtextRow),
                                        0,
                                        MulleObjCInstanceGetAllocator( self));
   _mulle_structarray_init( &_rowGlyphArray, sizeof( struct CATextLayerRowGlyphs),
                                             alignof( struct CATextLayerRowGlyphs),
                                             0,
                                             MulleObjCInstanceGetAllocator( self));

   _rows      = NULL;
   _nRows     = 0;

   // just cleanliness
   memset( &_glyphData, 0, sizeof( _glyphData));
}


- (instancetype) init
{
   [super init];

   _textPaint           = nil;  // default, depend on backgroundColor
   _suggestedTextPaint  = [[CGPaint paintWithHexColor:CGHexColorBlack] copy];
   _selectionPaint      = [[CGPaint paintWithHexColor:0x7FFF7F7F] copy];
   _textRange           = NSMakeRange( NSNotFound, 0);

   // because Fonts are crap and don't adhere to size requests properly, it's
   // usually better to overdraw than to clip.
   _masksToBounds       = NO;
   _clearTypeEnabled    = YES;

   [self _init];

   return( self);
}


- (void) _doneRowGlyphs
{
   struct CATextLayerRowGlyphs   *p;
   struct CATextLayerRowGlyphs   *sentinel;
   unsigned int                     n;

   n = _mulle_structarray_get_count( &_rowGlyphArray);
   if( n)
   {
      p        = _mulle_structarray_get( &_rowGlyphArray, 0);
      sentinel = &p[ n];
      do
      {
         CATextLayerRowGlyphsDone( p);
         ++p;
      }
      while( p < sentinel);
   }

   _mulle_structarray_done( &_rowGlyphArray);
}


- (void) dealloc
{
   [self _doneRowGlyphs];
   _mulle_structarray_done( &_rowArray);

   [_suggestedTextPaint release];

   MulleObjCInstanceDeallocateMemory( self, _fontNameUTF8String);
   MulleObjCInstanceDeallocateMemory( self, _data.characters);

   [super dealloc];
}


- (id) copy
{
   CATextLayer              *copy;
   struct mulle_allocator   *allocator;

   copy = [super copy];

   //
   // somewhat tricky code, to make copy fully functional. Properties are
   // copied by -co

   // this inits _rowArray and
   [self _init];

   allocator                 = MulleObjCInstanceGetAllocator( copy);
   copy->_data               = mulle_utf8data_copy( copy->_data, allocator);
   copy->_suggestedTextPaint = [copy->_suggestedTextPaint copy];
   copy->_fontNameUTF8String = NULL;

   MulleObjCObjectSetDuplicatedUTF8String( copy,
                                          (char **) &copy->_fontNameUTF8String,
                                          (char *) _fontNameUTF8String);
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


- (void) setSelectionColor:(CGColor) color
{
   [self setSelectionPaint:[CGPaint paintWithColor:color]];
}


- (CGSize) textSizeWithContext:(id <UILayoutContext>) context
{
   NSUInteger                    i;
   struct CATextLayerRowGlyphs   *p;
   struct UIGlyphPosition        *glyph;
   float                         minx;
   float                         maxx;

   if( _textSize.height == 0.0f)
   {
      [self updateGeometryWithContext:context];

//      MulleUILog( "%td rows a: %g d: %g h: %g", _nRows, _metrics.ascender, _metrics.descender, _metrics.lineHeight);

      assert( _metrics.lineHeight);

      // the height don't change, and our virtual start is always zero
      _textSize.width  = 0.0f;
      _textSize.height = _metrics.lineHeight * _nRows;

      minx = INFINITY;
      maxx = -INFINITY;

      for( i = 0; i < _nRows; i++)
      {
         p = &_rowGlyphs[ i];
         if( ! p->nGlyphs)
            continue;

         // get last
         glyph = &p->glyphs[ 0];
         minx  = fminf( minx, glyph->minx);
         glyph = &p->glyphs[ p->nGlyphs - 1];
         maxx  = fmaxf( maxx, glyph->maxx - 2.0f);  // fummel
      }

      if( ! isinf( maxx))
         _textSize.width = maxx - minx;
   }

//   MulleUILog( "s: %s", CGSizeUTF8String( _textSize));

   return( _textSize);
}




- (void) getTextVisualBounds:(CGRect *) vbounds
                      insets:(struct MulleEdgeInsets) insets
                     context:(id <UILayoutContext>) context
{
   NSUInteger                    i, j;
   struct CATextLayerRowGlyphs   *p;
   struct UIGlyphPosition        *glyph;
   float                         minx;
   float                         miny;
   float                         maxx;
   float                         maxy;
   CGFloat                       x;
   CGFloat                       y;

   assert( vbounds);

   if( _textSize.height == 0.0f)
   {
      [self updateGeometryWithContext:context];
   }

   MulleUILog( "a: %g d: %g h: %g", _metrics.ascender, _metrics.descender, _metrics.lineHeight);

   assert( _metrics.lineHeight);

   // get x and width, then redo Y
   minx = INFINITY;
   miny = INFINITY;
   maxx = -INFINITY;
   maxy = -INFINITY;

   for( j = 0; j < _nRows; j++)
   {
      p = &_rowGlyphs[ j];

      // get last
      i = 0;
      for(;;)
      {
         if( i >= p->nGlyphs)
            goto next;

         glyph = &p->glyphs[ i];
         // if this is true, assume glyph produces no ink
         if( UIGlyphPositionHasStrokes( glyph))
         {
            x    = glyph->minx + insets.left;
            minx = fminf( minx, x);
            break;
         }
      }

      // p->nGlyphs know to be > 0 by above loop
      for( i = p->nGlyphs - 1;; --i)
      {
         glyph = &p->glyphs[ i];
         if( UIGlyphPositionHasStrokes( glyph))
         {
            x    = glyph->maxx - insets.right;
            maxx = fmaxf( maxx, x);
            break;
         }
         if ( ! i)
            break;
      }
next:
      ;
   }


   // get top y of first row with visible characters
   // we have to
   j = 0;
   for(;;)
   {
      if( j >= _nRows)
         break;

      p = &_rowGlyphs[ j];
      for( i = 0; i < p->nGlyphs; i++)
      {
         glyph = &p->glyphs[ i];
         if( UIGlyphPositionHasStrokes( glyph))
         {
            // converted from baseline
            y    = glyph->miny + insets.top;
            y   += _metrics.ascender + j * _metrics.lineHeight;
            miny = fminf( miny, y);
         }
      }

      if( ! isinf( miny))
         break;
      ++j;
   }

   j = _nRows;
   for(;;)
   {
      if( ! j)
         break;
      --j;

      p = &_rowGlyphs[ j];
      for( i = 0; i < p->nGlyphs; i++)
      {
         glyph = &p->glyphs[ i];
         if( UIGlyphPositionHasStrokes( glyph))
         {
            y    = glyph->maxy - insets.bottom;
            y   += _metrics.ascender + j * _metrics.lineHeight;
            maxy = fmaxf( maxy, y);
         }
      }

      if( ! isinf( maxy))
         break;
   }

   MulleUILog( "%g %g %g %g", minx, miny, maxx, maxy);

   *vbounds = CGRectMake( minx, miny, maxx - minx, maxy - miny);
}


- (void) getTextVisualBounds:(CGRect *) vbounds
                     context:(id <UILayoutContext>) context
{
   [self getTextVisualBounds:vbounds
                      insets:CATextLayerVisualBoundsInsets
                     context:context];
}


- (CGSize) sizeThatFits:(CGSize) max
                context:(id <UILayoutContext>) context
{
   CGRect   bounds;
   CGSize   size;

   bounds.origin = CGPointZero;
   bounds.size   = [self textSizeWithContext:context];

   // should be calculated in already
   // bounds        = MulleEdgeInsetsExtrudeRect( _insets, bounds);

   size.width  = CGFloatClamp( bounds.size.width, 0, max.width);
   size.height = CGFloatClamp( bounds.size.height, 0, max.height);
   return( size);
}


- (void) _setTextUTF8Data:(struct mulle_utf8data) data
{
   struct mulle_allocator   *allocator;

   allocator = MulleObjCInstanceGetAllocator( self);

   mulle_allocator_free( allocator, _data.characters);

   // don't want two trailing zeroes in incoming data
   // need one trailing zero though
   assert( ! data.length || data.characters[ data.length - 1]);
   assert( ! data.characters[ data.length]);

   _data = data;

   // clear this to be recomputed later
   _textSize   = CGSizeZero;

   // reset
   _textRange  = NSMakeRange( NSNotFound, 0);
}


- (void) setTextUTF8Data:(struct mulle_utf8data) data
{
   struct mulle_allocator   *allocator;
   char                     *p;
   NSUInteger               length;

   if( data.characters == _data.characters)
      return;

   allocator = MulleObjCInstanceGetAllocator( self);
   length    = data.length;

   // don't want two trailing zeroes in incoming data
   if( length)
      if( ! data.characters[ length - 1])
         --length;

   p = mulle_allocator_malloc( allocator, length + 1);
   memcpy( p, data.characters, length);
   p[ length] = 0;

   [self _setTextUTF8Data:mulle_utf8data_make( p, length)];
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
}


- (CATextLayerVerticalAlignmentMode)  mulleVerticalAlignmentMode
{
   return( _verticalAlignmentMode);
}


- (void) mulleSetVerticalAlignmentMode:(CATextLayerVerticalAlignmentMode) mode
{
   _verticalAlignmentMode = mode;
}


- (NSRange) textRange
{
   struct mulle_utf_information   info;

   if( _textRange.location != NSNotFound)
      return( _textRange);

   if( mulle_utf8_information( _data.characters, _data.length, &info))
      return( NSMakeRange( NSNotFound, 0));

   _textRange = NSMakeRange( 0, info.utf32len);
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


#if 0
static NSUInteger  count_newlines( mulle_utf8_t *s)
{
   mulle_utf32_t    c;
   mulle_utf32_t    d;
   NSUInteger       lf;

   // use code from nvg
   c  = 0;
   lf = 0;
   for(;*s;)
   {
      d = c;
      c = mulle_utf8_next_utf32character( &s);
      switch( c)
      {
      case '\n':
          if( d != '\r')
            ++lf;
         break;

      case 0x85:
      case '\r':
         ++lf;
         break;
      }
   }
   return( lf);
}
#endif


/* MEMO: Font/Glyph scaling
 *
 * Truetype is a font format (we just care about truetype fonts)
 * Freetype is a font library that reads truetype fonts.
 *
 * Freetype has no dependency on opengl. Freetype returns a glyph either as a
 * vector or a bitmap (possibly rasterized from a vector font). We just care
 * about vector fonts though.
 *
 * This bitmap is transferred to a font atlas, basically a mega-texture.
 * This is done in the fons__ stuff. Confusingly, there is also an atlas in
 * nvg. But it does not seem to be used, at least as long as the fons__
 * stuff supplies glyphs ?
 *
 * Size conversion: A freetype/truetye  vector font has a height, that's fixed at 2048.
 * this is distributed to an ascender and a descender. So ascender - descender = 2048.
 * (Actually <= 2048, but we ignore that for now) https://www.freetype.org/freetype2/docs/tutorial/step2.html
 * `fons__tt_getPixelHeightScale` for example is defined as ` size / (font->font->ascender - font->font->descender)`
 * so basically `size / 2048`.
 *
 * The texture you get from freetype is upside down. So a d actually looks
 * like a q (sort of).
 *
 * The pipe glyph has a vertical overshoot of one pixel for Anonymous Pro.
 *
 * Even if you request LCD from a freetype front, you may get monochrome
 * instead. The fontstash library will correct this.
 *
 * By experiment, if running cleartype it makes no use to turn of cleartype
 * for monochrome or grayscale only fonts.
 *
 * Since emojis could be used from a fallback font, it maybe necessary to
 * split the string for multiple nvgText calls, setting the correct font
 * everytime.
 */
- (void) resizeRowsTo:(NSUInteger) max
{
   NSUInteger   size;
   NSUInteger   diff;

   assert( max >= 1);

   size = _mulle_structarray_get_size( &_rowArray);
   if( max > size)
   {
      diff = max - size;
      _mulle_structarray_advance( &_rowArray, diff);
   }

   _rows  = _mulle_structarray_get( &_rowArray, 0);
   _nRows = 0;
}


- (void) resizeRowGlyphsArrayTo:(NSUInteger) max
{
   NSUInteger                       size;
   NSUInteger                       diff;
   struct CATextLayerRowGlyphs   *p;
   struct CATextLayerRowGlyphs   *sentinel;

   assert( max);

   //
   // The contents of _rowGlyphArray will be reused, as they contain
   // other mulle_structarrays.
   //
   size = _mulle_structarray_get_size( &_rowGlyphArray);
   if( max > size)
   {
      diff     = max - size;
      p        = _mulle_structarray_advance( &_rowGlyphArray, diff);
      sentinel = &p[ diff];
      while( p < sentinel)
      {
         _CATextLayerRowGlyphsInit( p, MulleObjCInstanceGetAllocator( self));
         ++p;
      }
   }
   _rowGlyphs = _mulle_structarray_get( &_rowGlyphArray, 0);
}


- (void) updateRowGlyphsAtIndex:(NSUInteger) i
                        context:(id <UILayoutContext>) context
{
   NSUInteger                    nGlyphs;
   NSUInteger                    newSize;
   NSUInteger                    diff;
   NSUInteger                    sGlyphs;
   struct CATextLayerRowGlyphs   *p;

   p       = &_rowGlyphs[ i];
   nGlyphs = 100 / 2; // start with assumed 100 glyphs for each row

   // our assumed size, the buffer should be larger than this, so we can
   // figure out if we get truncated due to small a buffer also we need
   // one extra space for the sentinel node
   for(;;)
   {
      sGlyphs = _mulle_structarray_get_size( &p->glyphArray);
      if( sGlyphs <= nGlyphs + 1) // add sentinel node
      {
         newSize = nGlyphs + nGlyphs;
         if( newSize < 100)
            newSize = 100;
         diff     = newSize - sGlyphs;
         _mulle_structarray_advance( &p->glyphArray, diff);
         p->glyphs = _mulle_structarray_get( &p->glyphArray, 0);
         sGlyphs   = newSize;
      }

      p->nGlyphs = [context getGlyphPositions:p->glyphs
                                        count:sGlyphs
                                         text:_rows[ i].start
                                       length:_rows[ i].end - _rows[ i].start];
      if( p->nGlyphs < sGlyphs - 1) // subtract sentinel node
         break;

      nGlyphs = p->nGlyphs;
   }

   // put in a node at the sentinel position
   if( p->nGlyphs)
      p->glyphs[ p->nGlyphs].x = p->glyphs[ p->nGlyphs - 1].maxx;
   else
      p->glyphs[ p->nGlyphs].x = 0;

   p->glyphs[ p->nGlyphs].minx = 0;
   p->glyphs[ p->nGlyphs].maxx = 0;
   p->glyphs[ p->nGlyphs].str  = _rows[ i].end;
   // ''   nglyphs == 0, _cursorPositon=={ 0 - 0 }
   // 'A'  nglyphs == 1, _cursorPositon=={ 0 - 1 }  |A or A|
   // 'AB' nglyphs == 2, _cursorPositon=={ 0 - 2 }  |AB or A|B or AB|
}


- (void) updateRowsAndGlyphsWithContext:(id <UILayoutContext>) context
{
   NSUInteger                  max;
   NSUInteger                  i;
   CGFloat                     width;
   CGFloat                     extent;
   struct mulle_utf8data       data;
   CGRect                      visualBounds;
   CGRect                      textBounds;

   data = [self textUTF8DataInTextRange];

   // so when editing the text, we will likely realloc the data. But
   // glyphs contain a pointer to the data. When you change the text
   // the glyph->str is stale. We can still use glyph->str for address
   // calculation though
   _glyphData = data;

   if( _metrics.lineHeight == 0.0f)
      [context getTextMetrics:&_metrics];

   //
   // calculate max visible rows, which is frame.size.height / _metrics.lineHeight , but
   // because of partially visible rows we add + 2
   //
   if( _metrics.lineHeight == 0.0)
   {
      max                   = 2;
      _visualFontLineHeight = 0.0;
   }
   else
   {
      [context getTextVisualBounds:&visualBounds
                              text:data.characters
                            length:data.length];
      _visualFontLineHeight = visualBounds.size.height;
      // calculate this always, as _textBounds can be useful later on as well
      extent = [context getTextBounds:&textBounds
                                 text:data.characters
                               length:data.length];

      max = (NSUInteger) ceilf( textBounds.size.height / _metrics.lineHeight) + 2;
      // produce row information
      switch( _lineBreakMode)
      {
      case NSLineBreakByWordWrapping :
         // the width can produce more lines, we assume worst case
         // we have a string of "max" number of linefeeds, followed by
         // a last line as one large string without linefeed
         // We will have to divide this by width to get the extra lengths
         // also when word wrapping how big can the biggest word be ?

         width  = textBounds.size.width;
         // TODO check this is true, probably need to fuzz it
         max   += ceil( extent / width) + 1;
         break;

      default :
         width = INFINITY;
         break;
      }
   }

   [self resizeRowsTo:max];
   [self resizeRowGlyphsArrayTo:max];

   //
   // Calculate actual amount of rows available
   // Here the problem is, that we always calculate from the start though
   // which doesn't work well for middle/bottom...
   //
   if( _metrics.lineHeight == 0.0)
      _nRows = 0;
   else
   {

      _nRows = [context getTextRows:_rows
                              count:max
                               text:data.characters
                             length:data.length
                      breakRowWidth:width];
   }

   // produce glyph information for each row
   for( i = 0; i < _nRows; i++)
      [self updateRowGlyphsAtIndex:i
                           context:context];
}


- (CGPoint) textOriginInRect:(CGRect) rect
{
   CGPoint   origin;
   CGFloat   rowsHeight;

   if( _nRows <= 1)
   {
      switch( _verticalAlignmentMode)
      {
      case MulleTextVerticalAlignmentTop :
         origin.y = _metrics.ascender;
         break;
      case MulleTextVerticalAlignmentBottom :
         origin.y = rect.size.height + _metrics.descender;  // _metrics.descender is neg.!
         break;
      case MulleTextVerticalAlignmentMiddle :
         origin.y = (rect.size.height + _metrics.ascender + _metrics.descender) / 2.0;
         break;
      case MulleTextVerticalAlignmentBaseline :
         origin.y = rect.size.height / 2.0;
         break;
      // 
      // w=10
      // 0123456789
      // xxxx
      // 10 / 2.0 + (4 - 0) / 2 = 7 
      // 20 -> 10   rect.size.height - (rect.size.height - _visualBounds[ 3])
      case MulleTextVerticalAlignmentVisualMiddle :
         origin.y = (rect.size.height + - _visualFontLineHeight) / 2.0;
         break;
      case MulleTextVerticalAlignmentBoundsMiddle :
         // the _textBounds values are inverted _metrics.ascender and descender
         origin.y = (rect.size.height - _metrics.lineHeight) / 2.0;
         break;

      default :
         abort();
      }
   }
   else
   {
      // now we know the number of rows,
      // calculate the height of all rows
      rowsHeight  = _metrics.lineHeight * _nRows;

      // this is top aligned as default, other alignments use this as well
      switch( _verticalAlignmentMode)
      {
         // set as bottom aligned
      case MulleTextVerticalAlignmentTop :
         origin.y = _metrics.ascender;
         break;

      case MulleTextVerticalAlignmentBottom :
         origin.y = rect.size.height - rowsHeight + _metrics.ascender;
         break;

      // the baseline alignment for multiple lines doesn't seem useful,
      // yet for visual stability we need to produce something

      case MulleTextVerticalAlignmentMiddle :
         origin.y = (rect.size.height - rowsHeight) / 2.0 + _metrics.ascender;
         break;

      case MulleTextVerticalAlignmentVisualMiddle   :
      case MulleTextVerticalAlignmentBoundsMiddle   :
      case MulleTextVerticalAlignmentBaseline :
         // if odd rows the baseline of the middle is in the center
         // otherwise same as "middle"
         if( _nRows & 1)
            origin.y = (rect.size.height - rowsHeight + _metrics.lineHeight) / 2.0;
         else
            origin.y = (rect.size.height - rowsHeight) / 2.0 + _metrics.ascender;
      default :
         abort();
      }
   }

   switch( _alignmentMode)
   {
   case CAAlignmentLeft   : origin.x = CGRectGetMinX( rect) - rect.origin.x;
                            break;
   case CAAlignmentRight  : origin.x = CGRectGetMaxX( rect) - rect.origin.x;
                            break;
   case CAAlignmentCenter : origin.x = CGRectGetMidX( rect) - rect.origin.x;
                            break;
   default :
      abort();
   }

   // If cursor is visible, keep it always visible
   if( [self isEditing])
      origin.x += [self offsetNeededToMakeCursorVisible];
   return( origin);
}


//
// MEMO: rewriting this to UILayoutContext may have been a mistake
//       could have kept nvg calls
//
- (BOOL) updateGeometryWithContext:(id <UILayoutContext>) context
{
   CGFloat                      fontPixelSize;
   CGRect                       canvas;
   int                          align;
   CGRect                       fontBounds;
   CGFloat                      actualFontHeight;
   struct MulleEdgeInsets       insets;

   [context useFontWithNameUTF8String:_fontNameUTF8String
                                      ? _fontNameUTF8String
                                      : "sans"];

   canvas = [self canvas];

   // allow construction of unknown size canvas
   insets = MulleEdgeInsetsZero;
   if( canvas.size.width > 0.0)
   {
      insets.left  = _insets.left;
      insets.right = _insets.right;
   }

   if( canvas.size.height > 0.0)
   {
      insets.top    = _insets.top;
      insets.bottom = _insets.bottom;
   }

   canvas = MulleEdgeInsetsInsetRect( insets, canvas);

   fontPixelSize = [self fontPixelSize];
   if( fontPixelSize == 0.0)
   {
      assert( canvas.size.height > 0.0f);  // need a height for fontPixelSize

      // figure out actual space used by font for a string, that should
      // cover the highest and the lowest glyph in a "reasonable" font
      
      [context setTextAlign:NVG_ALIGN_LEFT | NVG_ALIGN_TOP];
      [context setFontSize:32.0f]; // calculate size for 32
      [context getTextVisualBounds:&fontBounds
                              text:"|_;y´"
                            length:4];
      actualFontHeight = fontBounds.size.height;
      fontPixelSize    = (int) (canvas.size.height * 32.0 / actualFontHeight);
   }

   if( canvas.size.height == 0.0f)
   {
      // now at least we can assume a canvas height
      canvas.size.height = fontPixelSize + _insets.top + _insets.bottom;
   }

   _lastFontPixelSize = fontPixelSize;

   [context setFontSize:fontPixelSize]; // calculate size for 32

   // I see no difference with different alignment options, for the metrics
   // likely because these are font (size) properties (duh!)
   // These values are wishful thinking though, the actual glyph can extend this
   [context getTextMetrics:&_metrics]; // calculate size for 32

   switch( _alignmentMode)
   {
   case CAAlignmentLeft   : align = NVG_ALIGN_LEFT; break;
   case CAAlignmentRight  : align = NVG_ALIGN_RIGHT; break;
   case CAAlignmentCenter : align = NVG_ALIGN_CENTER; break;
   }

   //
   // We always draw from the top, except if we are just a oneliner. Then
   // we use nvg vertical text alignment.
   //
   // The alignment is needed ASAP, because it changes the origin
   // and also affects the nvg text calculations for the horizontal plane.
   //
   [context setTextAlign:align | NVG_ALIGN_BASELINE];

   [self updateRowsAndGlyphsWithContext:context];

   if( canvas.size.width == 0.0f)
   {
      _origin    = CGPointMake( _insets.left, _insets.top);
   }
   else
   {
      _origin    = [self textOriginInRect:canvas];

      _origin.x += _textOffset.x;
      _origin.y += _textOffset.y;
   }
   return( _metrics.lineHeight != 0.0);
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


// textOffset in CGPoint
//  1.) figure out how
- (BOOL) drawInContext:(CGContext *) context
{
   struct NVGcontext       *vg;
   CGRect                  canvas;
   NSRange                 textRange;
   NSUInteger              i;
   NVGpaint                nvgPaint;
   struct mulle_utf8data   data;
   BOOL                    useClearType;
   BOOL                    isSelectionDrawn;
   BOOL                    isCursorDrawn;
   CGPaint                 *textPaint;
   CGPaint                 *textBackgroundPaint;
   CGRect                  rect;

   if( ! [super drawInContext:context])
      return( NO);

   // nothing to draw ? then bail
   data = [self textUTF8DataInTextRange];
   if( ! data.length)
      return( YES);

   if( ! [self updateGeometryWithContext:context])
      return( YES);

   canvas = [self canvas];
   canvas = MulleEdgeInsetsInsetRect( _insets, canvas);

   vg = CGContextGetNVGContext( context);

   // if textPaint is not set, use color derived from :_backgroundPaint
   textPaint = _textPaint ? _textPaint : _suggestedTextPaint;
   assert( textPaint);

   // figure out if we can use clearType
   // as we are a CALayer, we can't walk the ancestors up, so backgroundPaint
   // has to be the exact color we are painting on

   useClearType        = _clearTypeEnabled;
   textBackgroundPaint = useClearType && _textBackgroundPaint
                         ? _textBackgroundPaint
                         : _backgroundPaint;

   useClearType &= [textBackgroundPaint isMonochrome] &&
                   [textPaint isMonochrome] &&
                   [_selectionPaint isMonochrome];
   useClearType &= [textBackgroundPaint isOpaque];

   nvgClearType( vg, useClearType);

   isCursorDrawn = NO;
   for( i = 0; i < _nRows; i++)
   {
      textRange = NSMakeRange( _rows[ i].start - (char *) data.characters,
                               _rows[ i].end - _rows[ i].start);

      rect = CGRectMake( canvas.origin.x + _origin.x,
                         canvas.origin.y + _origin.y + (i * _metrics.lineHeight),
                         _metrics.lineHeight * 3.0f / 4.0f,  // guess for single char
                         _metrics.lineHeight);

//      // Draw the first line only
//      // don't render outside of myself
//      nvgIntersectScissor( vg, canvas.origin.x,
//                               canvas.origin.y,
//                               canvas.size.width,
//                               canvas.size.height);
   //   // nvgFillColor( vg, nvgRGBA(127,127,255,255));

      /*
       * Draw selection
       */
      isSelectionDrawn = [self drawSelectionWithNVGContext:vg
                                                textRange:textRange
                                                      row:i];

      // maybe a bit over kill, but I don't want to reset same colors on each
      // line
      if( i == 0 || isSelectionDrawn || isCursorDrawn)
      {
         /*
          * Draw Text
          * Bug: textBackgroundColor should be selection color, where selection
          *      is drawn. Or rather a mix of both colors
          */
         if( useClearType)
         {
            mvgTextColor( vg, [textPaint mainColor]);
            mvgTextBackgroundColor( vg, [textBackgroundPaint mainColor]);
         }
         else
         {
            // coloring with gradients not possible, not super sure why not
            // but it is what it is
            nvgPaint = [textPaint NVGpaintWithBounds:rect
                                          NVGcontext:vg];

            mvgFillPaint( vg, nvgPaint);
         }
      }

      // redo this since we fill color may have changed
      nvgText( vg, rect.origin.x, rect.origin.y, _rows[ i].start, _rows[ i].end);

      /*
       * Draw Cursor
       */
      isCursorDrawn = [self isEditing];
      if( isCursorDrawn)
      {
         [self drawCursorWithNVGContext:vg
                                    row:i];
      }
   }
   nvgClearType( vg, 0);

   return( YES);
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




// point is within bounds
// we find the range in the textUTF8String 8bit characters we do not
// interpret UTF8
//
- (NSUInteger) characterOffsetForPoint:(CGPoint) point
{
   NSInteger                     y;
   NSUInteger                    x;
   CGFloat                       search;
   struct CATextLayerRowGlyphs   *p;
   struct mulle_utf8data         data;

   if( ! _nRows)
      return( NSNotFound);

   // figure out the row that was hit, a row is _metrics.lineHeight and
   // drawn at frame.origin.y + _origin.y  + i *_metrics.lineHeight
   y = (NSInteger) round( (point.y -_origin.y) / _metrics.lineHeight);
   if( y < 0)
      y = 0;
   else
      if( y >= _nRows)
         y = _nRows - 1;

   p = &_rowGlyphs[ y];

   // calculate characters up till till this

   search  = point.x;
   search -= _origin.x;

   x = UIGlyphPositionSearch( p->glyphs, p->nGlyphs, search);
   if( x == NSNotFound)
   {
      if( search >= p->glyphs[ p->nGlyphs].x - 0.5)
         x = p->nGlyphs;
      else
         x = 0;
   }
   else
   {
      // left side/right side (use third, matter of taste)
      if( search >= p->glyphs[ x].minx + (p->glyphs[ x].maxx - p->glyphs[ x].minx) / 3.0)
         x++;
   }

   data = [self textUTF8DataInTextRange];
   return( p->glyphs[ x].str - (char *) data.characters);
}

@end
