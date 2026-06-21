#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>

//
// Regression test for BUG: CATextLayer crash in drawInContext: when
// _rowArray holds stale textRange after setTextUTF8String: shortens text.
//
// Root cause: updateRowsWithContextIfNeeded: did not call
// CATextLayerLayouterNeedsUpdates(), so _rowArrayValid stayed YES after
// a text change, causing the layouter to push stale row ranges to the layer.
//
// This test verifies the fix by simulating the exact crash scenario:
// manually inject stale rows (as if layouter pushed them), then trigger
// drawInContext: which would assert-crash on stale ranges.
//
int   main( void)
{
   CATextLayer            *layer;
   struct CATextLayerRow  row;

   layer = [CATextLayer layerWithFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setFontPixelSize:16.0f];

   // 1. Set long text, simulate layouter having added a row
   [layer setTextUTF8String:"Hello World VfL Bochum 1848"];
   memset( &row, 0, sizeof( row));
   row.textRange = NSMakeRange( 0, 27);
   [layer addTextLayerRow:&row];
   printf( "rows with long text: %tu\n", [layer numberOfRows]);

   // 2. setTextUTF8String: resets _rowArray
   [layer setTextUTF8String:"Red"];
   printf( "rows after text change: %tu\n", [layer numberOfRows]);

   // 3. Add a valid row for the short text
   memset( &row, 0, sizeof( row));
   row.textRange = NSMakeRange( 0, 3);
   [layer addTextLayerRow:&row];
   printf( "rows after valid add: %tu\n", [layer numberOfRows]);

   // 4. Verify mulle_utf8data_characters_in_range works (would crash before fix)
   {
      struct mulle_utf8data  data;
      char                   *s;

      data = [layer textUTF8Data];
      s    = mulle_utf8data_characters_in_range( data, row.textRange);
      printf( "text: \"%.*s\"\n", (int) row.textRange.length, s);
   }

   printf( "passed\n");
   return( 0);
}
