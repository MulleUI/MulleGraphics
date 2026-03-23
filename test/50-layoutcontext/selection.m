#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


static void  test_basic_selection( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   NSRange              sel;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   
   printf( "=== Basic Selection ===\n");
   
   // Initial state - no selection
   sel = [layouter selection];
   printf( "Initial selection: {%tu, %tu}\n", sel.location, sel.length);
   
   // Select all
   [layouter selectAll];
   sel = [layouter selection];
   printf( "After selectAll: {%tu, %tu}\n", sel.location, sel.length);
   
   // Deselect
   [layouter deselectAll];
   sel = [layouter selection];
   printf( "After deselectAll: {%tu, %tu}\n", sel.location, sel.length);
}


static void  test_selection_at_point( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   CGPoint              point;
   NSRange              sel;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL\nBochum\n1848"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   printf( "\n=== Selection at Point ===\n");
   
   // Start selection at beginning
   point = CGPointMake( 0, 0);
   [layouter startSelectionAtPoint:point];
   sel = [layouter selection];
   printf( "Start at (0,0): {%tu, %tu}\n", sel.location, sel.length);
   
   // Adjust forward
   point = CGPointMake( 50, 0);
   [layouter adjustSelectionToPoint:point];
   sel = [layouter selection];
   printf( "Adjust to (50,0): {%tu, %tu}\n", sel.location, sel.length);
   
   // Start new selection at middle
   point = CGPointMake( 100, 50);
   [layouter startSelectionAtPoint:point];
   sel = [layouter selection];
   printf( "Start at (100,50): {%tu, %tu}\n", sel.location, sel.length);
}


static void  test_selection_rect( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   NSRange              sel;
   NSUInteger           i;
   NSUInteger           nRows;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL\nBochum\n1848"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   printf( "\n=== Selection Rectangles ===\n");
   
   // Select all
   [layouter selectAll];
   sel = [layouter selection];
   
   nRows = [layer numberOfRows];
   printf( "Number of rows: %tu, selection: {%tu, %tu}\n", 
           nRows, sel.location, sel.length);
   
   for( i = 0; i < nRows; i++)
   {
      CGFloat  x, width;
      [layouter selectionInRow:i textRange:sel selectionX:&x selectionWidth:&width];
      printf( "Row %tu selection rect: x=%.2f width=%.2f\n", i, x, width);
   }
}


static void  test_delete_selection( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   char                 *text;
   NSRange              sel;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   
   printf( "\n=== Delete Selection ===\n");
   
   text = [layer textUTF8String];
   printf( "Initial text: \"%s\"\n", text);
   
   // Select middle portion
   [layouter setSelection:NSMakeRange( 4, 6)];
   sel = [layouter selection];
   printf( "Selection: {%tu, %tu}\n", sel.location, sel.length);
   
   // Delete it
   [layouter deleteSelection];
   text = [layer textUTF8String];
   sel = [layouter selection];
   printf( "After delete: \"%s\", selection: {%tu, %tu}\n", 
           text, sel.location, sel.length);
}


static void  test_multiline_selection( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   NSRange              sel;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"Line 1\nLine 2\nLine 3"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   
   printf( "\n=== Multi-line Selection ===\n");
   
   // Select across lines
   [layouter setSelection:NSMakeRange( 3, 10)];
   sel = [layouter selection];
   printf( "Selection spanning lines: {%tu, %tu}\n", sel.location, sel.length);
   
   // Select including newlines
   [layouter setSelection:NSMakeRange( 0, 14)];
   sel = [layouter selection];
   printf( "Selection with newlines: {%tu, %tu}\n", sel.location, sel.length);
}


int   main( void)
{
   test_basic_selection();
   test_multiline_selection();
   
   return( 0);
}

