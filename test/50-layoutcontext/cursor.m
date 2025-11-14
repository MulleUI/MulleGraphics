#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


static void  test_cursor_position_basics( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   MulleCursorPosition  cursorPos;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   printf( "=== Cursor Position Basics ===\n");
   
   // Cursor at start
   cursorPos = [layouter cursorPositionForCharacterOffset:0];
   printf( "Cursor at offset 0: {%tu, %tu}\n", 
           cursorPos.y, cursorPos.x);
   
   // Cursor at middle
   cursorPos = [layouter cursorPositionForCharacterOffset:7];
   printf( "Cursor at offset 7: {%tu, %tu}\n", 
           cursorPos.y, cursorPos.x);
   
   // Cursor at end
   cursorPos = [layouter cursorPositionForCharacterOffset:15];
   printf( "Cursor at offset 15 (end): {%tu, %tu}\n", 
           cursorPos.y, cursorPos.x);
}


static void  test_multiline_cursor( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   MulleCursorPosition  cursorPos;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL\nBochum\n1848"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   printf( "\n=== Multi-line Cursor ===\n");
   
   // First line
   cursorPos = [layouter cursorPositionForCharacterOffset:0];
   printf( "Line 1 start (offset 0): {%tu, %tu}\n", 
           cursorPos.y, cursorPos.x);
   
   // End of first line (before newline)
   cursorPos = [layouter cursorPositionForCharacterOffset:3];
   printf( "Line 1 end (offset 3): {%tu, %tu}\n", 
           cursorPos.y, cursorPos.x);
   
   // Second line start (after newline)
   cursorPos = [layouter cursorPositionForCharacterOffset:4];
   printf( "Line 2 start (offset 4): {%tu, %tu}\n", 
           cursorPos.y, cursorPos.x);
   
   // Third line
   cursorPos = [layouter cursorPositionForCharacterOffset:11];
   printf( "Line 3 start (offset 11): {%tu, %tu}\n", 
           cursorPos.y, cursorPos.x);
}


static void  test_cursor_offset_conversions( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   MulleCursorPosition  cursorPos;
   NSUInteger           offset;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"ABC"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   printf( "\n=== Cursor Offset Conversions ===\n");
   
   // Test round-trip: offset -> position
   for( offset = 0; offset <= 3; offset++)
   {
      cursorPos = [layouter cursorPositionForCharacterOffset:offset];
      printf( "Offset %tu -> Position {%tu, %tu}\n", 
              offset, cursorPos.y, cursorPos.x);
   }
}


static void  test_max_cursor_position( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   MulleCursorPosition  maxPos;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   printf( "\n=== Max Cursor Position ===\n");
   
   // Short text
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"VfL"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   maxPos = [layouter maxCursorPosition];
   printf( "\"VfL\" max cursor: {%tu, %tu}\n", 
           maxPos.y, maxPos.x);
   
   // Multi-line text
   [layer setTextUTF8String:"A\nB\nC"];
   [layer prepareLayoutContext:context];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   maxPos = [layouter maxCursorPosition];
   printf( "\"A\\nB\\nC\" max cursor: {%tu, %tu}\n", 
           maxPos.y, maxPos.x);
}


int   main( void)
{
   test_cursor_position_basics();
   test_multiline_cursor();
   test_cursor_offset_conversions();
   test_max_cursor_position();
   
   return( 0);
}

