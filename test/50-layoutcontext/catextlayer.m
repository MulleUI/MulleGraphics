#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CATextLayer              *layer;
   CGLayoutContext          *context;
   CGRect                   vbounds;
   struct mulle_utf8data    textData;
   char                     *text;
   NSUInteger               offset;
   NSUInteger               charOffset;

   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];

   text = "Vfl Bochum 1848";
   [layer setTextUTF8String:text];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];

   // Test visual bounds
   vbounds = [layer visualBoundsWithContext:context];
   printf( "vbounds: %s\n", CGRectUTF8String( vbounds));

   // Test text data
   textData = [layer textUTF8Data];
   printf( "textData: %.*s (length: %tu)\n", 
            (int) textData.length, 
            textData.characters, 
            textData.length);

   // Test offset conversions
   offset = [layer textOffsetForCharacterOffset:5];
   printf( "textOffset for charOffset 5: %tu\n", offset);

   charOffset = [layer characterOffsetForTextOffset:5];
   printf( "charOffset for textOffset 5: %tu\n", charOffset);

   return( 0);
}
