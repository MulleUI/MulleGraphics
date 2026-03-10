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


static void  dump_layer_rows( CATextLayer *layer)
{
   NSUInteger                i;
   NSUInteger                nRows;
   struct CATextLayerRow     *row;
   struct mulle_utf8data     textData;

   textData = [layer textUTF8Data];
   nRows    = [layer numberOfRows];

   printf( "Layer has %td rows:\n", nRows);
   for( i = 0; i < nRows; i++)
   {
      row = [layer textLayerRowAtIndex:i];
      printf( "  row[%td]: range={%td,%td} text=\"%.*s\" sel=%s cur=%s\n",
              i,
              row->textRange.location,
              row->textRange.length,
              (int) row->textRange.length,
              &textData.characters[ row->textRange.location],
              row->selectionStyle == CATextLayerSelectionStyleNone ? "none" : "rect",
              row->cursorStyle == CATextLayerCursorStyleNone ? "none" : "line");
      printf( "         selX:%.1f selWidth:%.1f cursorX:%.1f\n",
              row->selectionX,
              row->selectionWidth,
              row->cursorX);
   }
   printf( "  origin:%s\n", CGPointUTF8String( [layer origin]));
}

int main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   CGRect               rect;
   struct UILayoutInfo  info;

   rect    = CGRectMake( 0, 0, 200, 100);
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];

   [layer setFrame:rect];
   [layer setFontPixelSize:16.0f];
   [layer setLineBreakMode:NSLineBreakByWordWrapping];
   [layer setTextAlignment:UITextAlignmentRight];
   [layer setTextVerticalAlignment:UITextAlignmentBottom];
   [layer setTextUTF8String:"VfL\nBochum\n1848"];

   layouter = [CATextLayerLayouter instance];
   [layer setLayouter:layouter];

   memset( &info, 0, sizeof( info));
   info.context = context;

   printf( "=== Multi-line Right/Bottom Layout ===\n");
   [layouter layoutLayer:layer info:&info];
   dump_layer_rows( layer);

   printf( "\n=== With larger lineHeight ===\n");
   [layer setTextLineHeight:24.0f];
   [layouter layoutLayer:layer info:&info];
   dump_layer_rows( layer);

   return( 0);
}
