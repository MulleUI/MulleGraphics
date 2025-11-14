#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


static void  test_paint_properties( void)
{
   CATextLayer   *layer;
   CGPaint       *textPaint;
   CGPaint       *selPaint;
   CGPaint       *cursorPaint;
   
   layer = [CATextLayer instance];
   
   printf( "=== Paint Properties ===\n");
   
   // Get initial paints
   textPaint   = [layer textPaint];
   selPaint    = [layer selectionPaint];
   cursorPaint = [layer cursorPaint];
   
   printf( "Initial textPaint: %s\n", textPaint ? "set" : "null");
   printf( "Initial selectionPaint: %s\n", selPaint ? "set" : "null");
   printf( "Initial cursorPaint: %s\n", cursorPaint ? "set" : "null");
}


static void  test_cleartype( void)
{
   CATextLayer   *layer;
   BOOL          enabled;
   
   layer = [CATextLayer instance];
   
   printf( "\n=== ClearType ===\n");
   
   enabled = [layer isClearTypeEnabled];
   printf( "Default clearTypeEnabled: %s\n", enabled ? "YES" : "NO");
   
   [layer setClearTypeEnabled:NO];
   enabled = [layer isClearTypeEnabled];
   printf( "After setClearTypeEnabled:NO: %s\n", enabled ? "YES" : "NO");
   
   [layer setClearTypeEnabled:YES];
   enabled = [layer isClearTypeEnabled];
   printf( "After setClearTypeEnabled:YES: %s\n", enabled ? "YES" : "NO");
}


static void  test_alias_pixel_visible( void)
{
   CATextLayer   *layer;
   BOOL          visible;
   
   layer = [CATextLayer instance];
   
   printf( "\n=== Alias Pixel Visible ===\n");
   
   visible = [layer isAliasPixelVisible];
   printf( "Default aliasPixelVisible: %s\n", visible ? "YES" : "NO");
   
   [layer setAliasPixelVisible:YES];
   visible = [layer isAliasPixelVisible];
   printf( "After setAliasPixelVisible:YES: %s\n", visible ? "YES" : "NO");
   
   [layer setAliasPixelVisible:NO];
   visible = [layer isAliasPixelVisible];
   printf( "After setAliasPixelVisible:NO: %s\n", visible ? "YES" : "NO");
}


int   main( void)
{
   test_paint_properties();
   test_cleartype();
   test_alias_pixel_visible();
   
   return( 0);
}

