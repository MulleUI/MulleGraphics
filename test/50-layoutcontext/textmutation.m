#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


static void  test_basic_text_set_get( void)
{
   CATextLayer              *layer;
   struct mulle_utf8data    data;
   char                     *retrieved;
   
   layer = [CATextLayer instance];
   
   printf( "=== Basic Text Set/Get ===\n");
   
   // Test UTF-8 string
   [layer setTextUTF8String:"VfL Bochum"];
   retrieved = [layer textUTF8String];
   printf( "Set string: \"VfL Bochum\", got: \"%s\"\n", retrieved);
   
   // Test UTF-8 data roundtrip
   data = mulle_utf8data_make( "1848", 5);  // include null terminator
   [layer setTextUTF8Data:data];
   data = [layer textUTF8Data];
   printf( "Set data: \"1848\", got: \"%.*s\" (length: %tu)\n",
           (int) data.length, data.characters, data.length);
   
   // Test empty string
   [layer setTextUTF8String:""];
   retrieved = [layer textUTF8String];
   printf( "Set empty string, got: \"%s\" (length: %zu)\n", 
           retrieved, strlen( retrieved));
}


static void  test_generation_count( void)
{
   CATextLayer   *layer;
   NSUInteger    gen1;
   NSUInteger    gen2;
   NSUInteger    gen3;
   NSUInteger    gen4;
   
   layer = [CATextLayer instance];
   
   printf( "\n=== Generation Count ===\n");
   
   // Initial count
   gen1 = [layer textPropertiesGenerationCount];
   printf( "Initial count: %tu\n", gen1);
   
   // Setting text should increment
   [layer setTextUTF8String:"VfL"];
   gen2 = [layer textPropertiesGenerationCount];
   printf( "After setText: %tu (increment: %td)\n", gen2, gen2 - gen1);
   
   // Setting same text should still increment
   [layer setTextUTF8String:"VfL"];
   gen3 = [layer textPropertiesGenerationCount];
   printf( "After setText again: %tu (increment: %td)\n", gen3, gen3 - gen2);
   
   // Changing font properties should increment
   [layer setFontPixelSize:24.0f];
   gen4 = [layer textPropertiesGenerationCount];
   printf( "After setFontPixelSize: %tu (increment: %td)\n", gen4, gen4 - gen3);
}


static void  test_row_management( void)
{
   CATextLayer              *layer;
   struct CATextLayerRow    row;
   struct CATextLayerRow    rows[3];
   NSUInteger               count;
   
   layer = [CATextLayer instance];
   
   printf( "\n=== Row Management ===\n");
   
   // Initial state
   count = [layer numberOfRows];
   printf( "Initial row count: %tu\n", count);
   
   // Set text (wipes rows!)
   [layer setTextUTF8String:"VfL\nBochum\n1848"];
   count = [layer numberOfRows];
   printf( "After setText (wipes rows): %tu\n", count);
   
   // Add single row
   memset( &row, 0, sizeof( row));
   row.textRange = NSMakeRange( 0, 3);
   [layer addTextLayerRow:&row];
   count = [layer numberOfRows];
   printf( "After addTextLayerRow: %tu\n", count);
   
   // Add multiple rows
   memset( rows, 0, sizeof( rows));
   rows[0].textRange = NSMakeRange( 4, 6);
   rows[1].textRange = NSMakeRange( 11, 4);
   rows[2].textRange = NSMakeRange( 0, 0);
   [layer addTextLayerRows:rows count:3];
   count = [layer numberOfRows];
   printf( "After addTextLayerRows (3): %tu\n", count);
   
   // Remove all
   [layer removeAllTextLayerRows];
   count = [layer numberOfRows];
   printf( "After removeAllTextLayerRows: %tu\n", count);
}


static void  test_text_data_without_null( void)
{
   CATextLayer              *layer;
   struct mulle_utf8data    data;
   struct mulle_utf8data    retrieved;
   char                     *str;
   
   layer = [CATextLayer instance];
   
   printf( "\n=== Text Data Without Null Terminator ===\n");
   
   // Set data without null terminator
   data = mulle_utf8data_make( "VfL", 3);  // NO null terminator
   printf( "Setting data without null: length=%tu\n", data.length);
   [layer setTextUTF8Data:data];
   
   // Get it back
   retrieved = [layer textUTF8Data];
   printf( "Retrieved data: \"%.*s\" (length: %tu)\n",
           (int) retrieved.length, retrieved.characters, retrieved.length);
   
   // Get as string (should add null)
   str = [layer textUTF8String];
   printf( "Retrieved string: \"%s\" (strlen: %zu)\n", str, strlen( str));
}


static void  test_multiple_mutations( void)
{
   CATextLayer   *layer;
   NSUInteger    gen1;
   NSUInteger    gen2;
   NSUInteger    gen3;
   
   layer = [CATextLayer instance];
   
   printf( "\n=== Multiple Mutations ===\n");
   
   [layer setTextUTF8String:"A"];
   gen1 = [layer textPropertiesGenerationCount];
   printf( "Text: \"%s\", gen: %tu\n", [layer textUTF8String], gen1);
   
   [layer setTextUTF8String:"AB"];
   gen2 = [layer textPropertiesGenerationCount];
   printf( "Text: \"%s\", gen: %tu\n", [layer textUTF8String], gen2);
   
   [layer setTextUTF8String:"ABC"];
   gen3 = [layer textPropertiesGenerationCount];
   printf( "Text: \"%s\", gen: %tu\n", [layer textUTF8String], gen3);
}


static void  test_property_changes( void)
{
   CATextLayer   *layer;
   NSUInteger    gen1;
   NSUInteger    gen2;
   NSUInteger    gen3;
   NSUInteger    gen4;
   NSUInteger    gen5;
   
   layer = [CATextLayer instance];
   [layer setTextUTF8String:"VfL"];
   
   printf( "\n=== Property Changes ===\n");
   
   gen1 = [layer textPropertiesGenerationCount];
   printf( "Initial: %tu\n", gen1);
   
   [layer setFontPixelSize:16.0f];
   gen2 = [layer textPropertiesGenerationCount];
   printf( "After setFontPixelSize: %tu (delta: %td)\n", gen2, gen2 - gen1);
   
   [layer setTextLetterSpacing:2.0f];
   gen3 = [layer textPropertiesGenerationCount];
   printf( "After setTextLetterSpacing: %tu (delta: %td)\n", gen3, gen3 - gen2);
   
   [layer setTextLineHeight:20.0f];
   gen4 = [layer textPropertiesGenerationCount];
   printf( "After setTextLineHeight: %tu (delta: %td)\n", gen4, gen4 - gen3);
   
   [layer setTextAlignment:UITextAlignmentLeft];
   gen5 = [layer textPropertiesGenerationCount];
   printf( "After setTextAlignment: %tu (delta: %td)\n", gen5, gen5 - gen4);
}


int   main( void)
{
   test_basic_text_set_get();
   test_generation_count();
   test_row_management();
   test_text_data_without_null();
   test_multiple_mutations();
   test_property_changes();
   
   return( 0);
}
