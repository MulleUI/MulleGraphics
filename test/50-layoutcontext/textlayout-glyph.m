#define _GNU_SOURCE
#include "include.h"
#import <MulleGraphics/MulleGraphics.h>

@interface CATextLayer( Test)
- (struct CATextLayerRow *) textLayerRowAtIndex:(NSUInteger) index;
@end

@implementation CATextLayer( Test)

- (struct CATextLayerRow *) textLayerRowAtIndex:(NSUInteger) index
{
   if( index >= _mulle_structarray_get_count( &_rowArray))
      return( NULL);
   
   return( _mulle_structarray_get( &_rowArray, index));
}

@end


int main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   CGRect               rect;
   CGRect               glyphRect;
   CGPoint              testPoint;
   NSUInteger           charOffset;
   struct UILayoutInfo  info;
   struct mulle_utf8data textData;

   rect    = CGRectMake( 0, 0, 200, 100);
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];

   [layer setFrame:rect];
   [layer setFontPixelSize:16.0f];
   [layer setLineBreakMode:NSLineBreakByWordWrapping];
   [layer setTextAlignment:UITextAlignmentRight];
   [layer setTextVerticalAlignment:UITextAlignmentBottom];
   [layer setTextUTF8String:"X"];

   layouter = [CATextLayerLayouter instance];
   [layer setLayouter:layouter];

   memset( &info, 0, sizeof( info));
   info.context = context;

   printf( "=== Single 'X' Right/Bottom Layout ===\n");
   [layouter layoutLayer:layer info:&info];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   printf( "Layer origin: %s\n", CGPointUTF8String( [layer origin]));
   printf( "Layer frame: %s\n", CGRectUTF8String( [layer frame]));

   // Test point near bottom-right corner
   testPoint = CGPointMake( 190.0, 95.0);
   printf( "\nTesting point: %s\n", CGPointUTF8String( testPoint));
   
   glyphRect = [layer glyphRectAtPoint:testPoint];
   printf( "Glyph rect: %s\n", CGRectUTF8String( glyphRect));
   
   charOffset = [layer characterOffsetAtPoint:testPoint];
   printf( "Character offset: %td\n", charOffset);
   
   textData = [layer textUTF8Data];
   if( charOffset < textData.length)
      printf( "Character at offset: '%c'\n", textData.characters[ charOffset]);
   else
      printf( "Character at offset: (out of bounds)\n");

   // Test several points around the expected X position
   printf( "\n=== Testing multiple points ===\n");
   CGPoint points[] = {
      CGPointMake( 180.0, 90.0),
      CGPointMake( 190.0, 90.0),
      CGPointMake( 195.0, 95.0),
      CGPointMake( 200.0, 100.0),
      CGPointMake( 185.0, 85.0)
   };
   
   for( int i = 0; i < 5; i++)
   {
      glyphRect  = [layer glyphRectAtPoint:points[i]];
      charOffset = [layer characterOffsetAtPoint:points[i]];
      
      printf( "Point %s -> offset:%td rect:%s",
              CGPointUTF8String( points[i]),
              charOffset,
              CGRectUTF8String( glyphRect));
      
      if( charOffset < textData.length)
         printf( " char:'%c'\n", textData.characters[ charOffset]);
      else
         printf( " char:(none)\n");
   }

   return( 0);
}
