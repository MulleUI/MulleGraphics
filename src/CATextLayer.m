#import "CATextLayer.h"

#import "import-private.h"

#import "CALayer+MulleGraphics.h"
#import "CATextLayer+Cursor.h"
#import "CATextLayer+Selection.h"

#include <ctype.h>


@implementation CATextLayer : CALayer

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

   _rows  = NULL;
   _nRows = 0;
}


- (id) init
{
   [super init];

   _textColor           = CGColorMakeWithHexColor( 0x000000FF);
   _textBackgroundColor = CGColorMakeWithHexColor( 0xFFFFFFFF);
   _selectionColor      = CGColorMakeWithHexColor( 0x7FFF7F7F);
   _textRange           = NSMakeRange( NSNotFound, 0);

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

   MulleObjCInstanceDeallocateMemory( self, _fontName);
   MulleObjCInstanceDeallocateMemory( self, _data.characters);

   [super dealloc];
}



- (id) copy
{
   CATextLayer   *copy;

   copy = [super copy];

   //
   // somewhat tricky code, to make copy fully functional
   //
   [self _init];

   copy->_fontName        = NULL;
   copy->_data.characters = NULL;
   MulleObjCObjectSetDuplicatedUTF8String( copy,
                                          (char **) &copy->_fontName,
                                          (char *) _fontName);
   MulleObjCObjectSetDuplicatedUTF8String( copy,
                                           (char **) &copy->_data.characters,
                                           (char *) _data.characters);

   return( copy);
}


- (CGFloat) fontAscender
{
   return( _ascender);
}


- (CGFloat) fontDescender
{
   return( _descender);
}


- (CGFloat) fontLineHeight
{
   return( _lineh);
}


- (CGFloat) fontBaseline
{
   return( _lineh - _descender);
}


- (CGRect) textBounds
{
   CGRect   bounds;

   assert( _textBounds[ 0] != CGFLOAT_MIN);

   bounds.origin.x    = _textBounds[ 0];
   bounds.origin.y    = _textBounds[ 1];
   bounds.size.width  = _textBounds[ 2] - _textBounds[ 0];
   bounds.size.height = _textBounds[ 3] - _textBounds[ 1];

   return( bounds);
}


- (CGRect) textBoundsWithContext:(CGContext *) context
{
   CGRect   bounds;

   if( _textBounds[ 0] == CGFLOAT_MIN)
      [self updateGeometryWithContext:context];

   bounds.origin.x    = _textBounds[ 0];
   bounds.origin.y    = _textBounds[ 1];
   bounds.size.width  = _textBounds[ 2] - _textBounds[ 0];
   bounds.size.height = _textBounds[ 3] - _textBounds[ 1];

   return( bounds);
}


- (CGSize) sizeThatFits:(CGSize) max
                context:(id) context
{
   CGRect   bounds;

   assert( max.width == INFINITY && max.height == INFINITY);

   bounds = [self textBoundsWithContext:context];

#if 0
   fprintf( stderr, "textBounds: %.2f %.2f %.2f %.2f\n",
                     bounds[ 0],
                     bounds[ 1],
                     bounds[ 2],
                     bounds[ 3]);
#endif
   bounds = MulleEdgeInsetsExtrudeRect( _insets, bounds);
   return( bounds.size);
}


- (void) setUTF8Data:(struct mulle_utf8data) data
{
   struct mulle_allocator  *allocator;
   mulle_utf8_t            *p;
   NSUInteger               length;

   if( data.characters == _data.characters)
      return;

   allocator = MulleObjCInstanceGetAllocator( self);
   length    = data.length;

   // don't want two trailing zeroes in incoming data
   if( length)
      if( ! data.characters[ length - 1])
         --length;

   assert( ! length || data.characters[ length - 1]);

   p = mulle_allocator_malloc( allocator, length + 1);
   memcpy( p, data.characters, length);
   p[ length] = 0;

   mulle_allocator_free( allocator, _data.characters);

   _data.characters = p;
   _data.length     = length;

   // clear this to be recomputed later
   _textBounds[ 0] =
   _textBounds[ 1] =
   _textBounds[ 2] =
   _textBounds[ 3] = CGFLOAT_MIN;

   // reset
   _textRange      = NSMakeRange( NSNotFound, 0);
}


- (struct mulle_utf8data) UTF8Data
{
   return( _data);
}


- (char *) cString  // will be a copy if internal data has no trailing zero byte
{
   return( (char *) _data.characters);
}


- (void) setCString:(char *) s
{
   if( ! s)
      s = "";

   // include trailing \0 in data
   [self setUTF8Data:mulle_utf8data_make( (mulle_utf8_t *) s, strlen( s) + 1)];
}


static void   assert_sane_font_name( char *s)
{
   int   c;

   if( s)
   {
      fprintf( stderr, "name: %s (%p)\n", s, s);
      while( (c = *s++))
         assert( isalnum( c));
   }
}

// fontNameUTF8String ?
- (void) setFontName:(char *) s
{
   assert_sane_font_name( s);

   MulleObjCObjectSetDuplicatedUTF8String( self, &_fontName, s);
}


- (enum CATextLayerVerticalAlignmentMode)  mulleVerticalAlignmentMode
{
   return( _verticalAlignmentMode);
}


- (void) mulleSetVerticalAlignmentMode:(enum CATextLayerVerticalAlignmentMode) mode
{
   _verticalAlignmentMode = mode;
}


- (NSRange) textRange
{
   NSRange                        range;
   struct mulle_utf_information   info;

   if( _textRange.location != NSNotFound)
      return( _textRange);

   if( mulle_utf8_information( _data.characters, _data.length, &info))
      return(  NSMakeRange( NSNotFound, 0));

   _textRange = NSMakeRange( 0, info.utf32len);
   return( _textRange);
}

//
// use above tzextRange to get the to be displayed data
//
- (struct mulle_utf8data) UTF8DataInTextRange
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
   NSUInteger   n;
   NSUInteger   diff;
   NSUInteger   size;

   assert( max >= 1);

   size  = _mulle_structarray_get_size( &_rowArray);
   if( max > size)
   {
      diff = max - size;
      _mulle_structarray_advance( &_rowArray, max);
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


NSUInteger
   MulleNVGglyphPositionSearch( NVGglyphPosition *glyphs,
                                NSUInteger nGlyphs,
                                CGFloat x)
{
   NSInteger          first;
   NSInteger          last;
   NSInteger          middle;
   NVGglyphPosition   *p;

   first  = 0;
   last   = (NSInteger) nGlyphs - 1;   // unsigned not good (need extra if)
   middle = (first + last) / 2;

   while( first <= last)
   {
      p = &glyphs[ middle];
      if( x >= p->minx && x <= p->maxx)
         return( middle);

      if( x > p->minx)
      {
         first = middle + 1;
      }
      else
         last = middle - 1;

      middle = (first + last) / 2;
   }

   return( NSNotFound);
}


- (void) updateRowGlyphsAtIndex:(NSUInteger) i
                        context:(NVGcontext *) vg
{
   NSUInteger                       nGlyphs;
   NSUInteger                       newSize;
   NSUInteger                       diff;
   NSUInteger                       sGlyphs;
   NSUInteger                       n;
   struct CATextLayerRowGlyphs   *p;

   p       = &_rowGlyphs[ i];
   nGlyphs = 100 / 2; // start with assumed 100 glyphs for each row

   // our assumed size, the buffer should be larger than this, so we can
   // figure out if we get truncated due to small a buffer also we need
   // one extra space for the sentinel node
   do
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

      p->nGlyphs = nvgTextGlyphPositions( vg, 0, 0,
                                              _rows[ i].start, _rows[ i].end,
                                              p->glyphs, sGlyphs);
   }
   while( p->nGlyphs >= sGlyphs - 1);  // subtract sentinel node

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


- (void) updateRowsAndGlyphsWithContext:(CGContext *) context
{
   NSUInteger               max;
   NSUInteger               i;
   CGFloat                  width;
   CGFloat                  extent;
   NVGcontext               *vg;
   struct mulle_utf8data    data;

   data = [self UTF8DataInTextRange];
   vg   = CGContextGetNVGContext( context);


   //
   // calculate max visible rows, which is frame.size.height / _lineh , but
   // because of partially visible rows we add + 2
   //
   if( _lineh == 0.0)
   {
      max = 2;
      memset( _textBounds, 0, sizeof( _textBounds));
   }
   else
   {
      max = (NSUInteger) ceil( _frame.size.height / _lineh) + 2;

      // calculate this always, as _textBounds can be useful later on as well
      extent  = nvgTextBounds( vg, 0,
                                   0,
                                   (void *) data.characters,
                                   (void *) &data.characters[ data.length],
                                   _textBounds);
      // produce row information
      switch( _lineBreakMode)
      {
      case NSLineBreakByWordWrapping :
         // the width can produce more lines, we assume worst case
         // we have a string of "max" number of linefeeds, followed by
         // a last line as one large string without linefeed
         // We will have to divide this by width to get the extra lengths
         // also when word wrapping how big can the biggest word be ?

         width   = _frame.size.width;
         // TODO check this is true, probably need to fuzz it
         max    += ceil( extent / width) + 1;
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
   if( _lineh == 0.0)
      _nRows = 0.0;
   else
      _nRows = nvgTextBreakLines( vg, (void *) data.characters,
                                      (void *) &data.characters[ data.length],
                                      width,
                                      _rows,
                                      max);

   // produce glyph information for each row
   for( i = 0; i < _nRows; i++)
      [self updateRowGlyphsAtIndex:i
                           context:vg];
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
         origin.y = _ascender;
         break;
      case MulleTextVerticalAlignmentBottom :
         origin.y = rect.size.height + _descender;  // _descender is neg.!
         break;
      case MulleTextVerticalAlignmentMiddle :
         origin.y = (rect.size.height + _ascender + _descender) / 2.0;
         break;
      case MulleTextVerticalAlignmentBaseline :
         origin.y = rect.size.height / 2.0;
         break;
      case MulleTextVerticalAlignmentBoundsMiddle :
         // the _textBounds values are inverted _ascender and descender
         origin.y = (rect.size.height + -_textBounds[ 1] + -_textBounds[ 3]) / 2.0;
      }
   }
   else
   {
      // now we know the number of rows,
      // calculate the height of all rows
      rowsHeight  = _lineh * _nRows;

      // this is top aligned as default, other alignments use this as well
      switch( _verticalAlignmentMode)
      {
         // set as bottom aligned
      case MulleTextVerticalAlignmentTop :
         origin.y = _ascender;
         break;

      case MulleTextVerticalAlignmentBottom :
         origin.y = rect.size.height - rowsHeight + _ascender;
         break;

      // the baseline alignment for multiple lines doesn't seem useful,
      // yet for visual stability we need to produce something

      case MulleTextVerticalAlignmentMiddle :
         origin.y = (rect.size.height - rowsHeight) / 2.0 + _ascender;
         break;

      case MulleTextVerticalAlignmentBoundsMiddle   :
      case MulleTextVerticalAlignmentBaseline :
         // if odd rows the baseline of the middle is in the center
         // otherwise same as "middle"
         if( _nRows & 1)
            origin.y = (rect.size.height - rowsHeight + _lineh) / 2.0;
         else
            origin.y = (rect.size.height - rowsHeight) / 2.0 + _ascender;
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
   }

   // If cursor is visible, keep it always visible
   if( [self isEditable])
      origin.x += [self offsetNeededToMakeCursorVisible];
   return( origin);
}


- (BOOL) updateGeometryWithContext:(CGContext *) context
{
   struct NVGcontext   *vg;
   float               lineh;
   CGFloat             fontPixelSize;
   CGFloat             rowsHeight;
   CGFloat             baseline;
   CGFont              *font;
   CGPoint             cursor;
   CGPoint             offset;
   CGRect              canvas;
   char                *name;
   int                 align;

   font   = [context fontWithNameUTF8String:_fontName ? _fontName : "sans"];
   name   = [font nameUTF8String];  // get actual name, which could have different address
   canvas = [self canvas];
   canvas = MulleEdgeInsetsInsetRect( _insets, canvas);

   vg = CGContextGetNVGContext( context);

   fontPixelSize = [self fontPixelSize];
   if( fontPixelSize == 0.0)
      fontPixelSize = (int) canvas.size.height;

   nvgFontFace( vg, name);
   nvgFontSize( vg, fontPixelSize);

   // I see no difference with different alignment options, for the metrics
   // likely because these are font (size) properties (duh!)
   nvgTextMetrics( vg, &_ascender, &_descender, &_lineh);

   switch( _alignmentMode)
   {
   case CAAlignmentLeft   : align = NVG_ALIGN_LEFT;
                            break;
   case CAAlignmentRight  : align = NVG_ALIGN_RIGHT;
                            break;
   case CAAlignmentCenter : align = NVG_ALIGN_CENTER;
                            break;
   }

   //
   // We always draw from the top, except if we are just a oneliner. Then
   // we use nvg vertical text alignment.
   //
   // The alignment is needed ASAP, because it changes the origin
   // and also affects the nvg text calculations for the horizontal plane.
   //
   nvgTextAlign( vg, align | NVG_ALIGN_BASELINE);

   [self updateRowsAndGlyphsWithContext:context];

   _origin    = [self textOriginInRect:canvas];

   _origin.x += _textOffset.x;
   _origin.y += _textOffset.y;

   return( _lineh != 0.0);
}


// textOffset in CGPoint
//  1.) figure out how
- (void) drawInContext:(CGContext *) context
{
   struct NVGcontext       *vg;
   CGColor                 textBackgroundColor;
   CGFloat                 fontPixelSize;
   CGPoint                 cursor;
   CGPoint                 offset;
   CGRect                  canvas;
   NSRange                 selectionRange;
   NSRange                 textRange;
   NSUInteger              i;
   struct mulle_utf8data   data;

   [super drawInContext:context];

   // nothing to draw ? then bail
   data = [self UTF8DataInTextRange];
   if( ! data.length)
      return;

   if( ! [self updateGeometryWithContext:context])
      return;

   canvas = [self canvas];
   canvas = MulleEdgeInsetsInsetRect( _insets, canvas);

   vg = CGContextGetNVGContext( context);

   for( i = 0; i < _nRows; i++)
   {
      textRange = NSMakeRange( _rows[ i].start - (char *) data.characters,
                               _rows[ i].end - _rows[ i].start);

      // Draw the first line only
      // don't render outside of myself
      nvgIntersectScissor( vg, canvas.origin.x,
                               canvas.origin.y,
                               canvas.size.width,
                               canvas.size.height);
   //   // nvgFillColor( vg, nvgRGBA(127,127,255,255));

      /*
       * Draw selection
       */
      [self drawSelectionWithNVGContext:vg
                              textRange:textRange
                                    row:i];
      /*
       * Draw Text
       * Bug: textBackgroundColor should be selection color if selected
       */
      textBackgroundColor = [self backgroundColor];
      if( CGColorGetAlpha( textBackgroundColor) < 1.0)
         textBackgroundColor = [self textBackgroundColor];
      nvgTextColor( vg, [self textColor], textBackgroundColor); // TODO: use textColor
      nvgText( vg, canvas.origin.x + _origin.x,
                   canvas.origin.y + _origin.y + (i * _lineh),
                   _rows[ i].start,
                   _rows[ i].end);

      /*
       * Draw Cursor
       */
      if( [self isEditable])
         [self drawCursorWithNVGContext:vg
                                    row:i];
   }
}


static size_t   mulle_utf8_utf32length( mulle_utf8_t *s, size_t len)
{
   mulle_utf8_t   *start;
   mulle_utf8_t   *sentinel;
   size_t          n;

   start    = s;
   sentinel = &s[ len];

   n = 0;
   while( s < sentinel)
   {
      mulle_utf8_next_utf32character( &s);
      ++n;
   }
   return( n);
}


// point is within bounds
// we find the range in the cstring 8bit characters we do not
// interpret UTF8
//
- (NSUInteger) characterIndexForPoint:(CGPoint) point
{
   CGRect                           rect;
   NSInteger                        y;
   NSUInteger                       x;
   CGFloat                          search;
   struct CATextLayerRowGlyphs   *p;
   struct mulle_utf8data            data;

   if( ! _nRows)
      return( NSNotFound);

   // figure out the row that was hit, a row is _lineh and
   // drawn at frame.origin.y + _origin.y  + i *_lineh
   y = (NSInteger) round( (point.y -_origin.y) / _lineh);
   if( y < 0)
      y = 0;
   else
      if( y >= _nRows)
         y = _nRows - 1;

   p = &_rowGlyphs[ y];
   // calculate characters up till till this


   search  = point.x;
   search -= _origin.x;

   x = MulleNVGglyphPositionSearch( p->glyphs, p->nGlyphs, search);
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

   data = [self UTF8DataInTextRange];
   return( p->glyphs[ x].str - (char *) data.characters);
}


char   *CATextLayerAlignmentModeUTF8String( enum CATextLayerAlignmentMode mode)
{
   switch( mode)
   {
   case CAAlignmentLeft   : return( "CAAlignmentLeft");
   case CAAlignmentRight  : return( "CAAlignmentRight");
   case CAAlignmentCenter : return( "CAAlignmentCenter");
   }
   return( "???");
}


char   *CATextLayerVerticalAlignmentModeUTF8String( enum CATextLayerVerticalAlignmentMode mode)
{
   switch( mode)
   {
   case MulleTextVerticalAlignmentMiddle   : return( "MulleTextVerticalAlignmentMiddle");
   case MulleTextVerticalAlignmentBaseline : return( "MulleTextVerticalAlignmentBaseline");
   case MulleTextVerticalAlignmentBoundsMiddle   : return( "MulleTextVerticalAlignmentBoundsMiddle");
   case MulleTextVerticalAlignmentTop      : return( "MulleTextVerticalAlignmentTop");
   case MulleTextVerticalAlignmentBottom   : return( "MulleTextVerticalAlignmentBottom");
   }
   return( "???");
}

@end
