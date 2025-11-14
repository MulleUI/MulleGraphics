#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


int   main( void)
{
   CATextLayer          *layer;
   CATextLayerLayouter  *layouter;
   CGLayoutContext      *context;
   MulleCursorPosition  cursorPos;
   char                 *text;
   
   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   context  = [CGLayoutContext instance];
   
   [layouter setTextLayer:layer];
   
   [layer setFrame:CGRectMake( 0, 0, 200, 100)];
   [layer setTextUTF8String:"ABC"];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];
   [layouter updateRowsAndGlyphsWithContextIfNeeded:context];
   
   printf( "=== Cursor Editing ===\n");
   
   text = [layer textUTF8String];
   printf( "Initial text: \"%s\"\n", text);
   
   // Cursor at start
   cursorPos = [layouter cursorPositionForCharacterOffset:0];
   printf( "Cursor at start: {%td, %td}\n", cursorPos.y, cursorPos.x);
   
   // Cursor at end
   cursorPos = [layouter cursorPositionForCharacterOffset:3];
   printf( "Cursor at end: {%td, %td}\n", cursorPos.y, cursorPos.x);
   
   return( 0);
}
