#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


int   main( int argc, char *argv[])
{
   CATextLayer              *layer;
   CATextLayerLayouter      *layouter;
   CGLayoutContext          *context;
   CGRect                   vbounds;
   struct mulle_utf8data    textData;
   char                     *text;
   CGFloat                  ascender;
   CGFloat                  descender;
   CGFloat                  lineHeight;

   layer    = [CATextLayer instance];
   layouter = [CATextLayerLayouter instance];
   [layouter setTextLayer:layer];
   
   context = [CGLayoutContext instance];

   text = "Vfl Bochum 1848";
   [layer setTextUTF8String:text];
   [layer setFontPixelSize:16.0f];
   [layer prepareLayoutContext:context];

   // Test visual bounds
   vbounds = [layer visualBoundsWithContext:context];
   printf( "vbounds: %s\n", CGRectUTF8String( vbounds));

   // Test font metrics
   ascender   = [layouter fontAscender];
   descender  = [layouter fontDescender];
   lineHeight = [layouter fontLineHeight];
   
   printf( "ascender: %g\n", ascender);
   printf( "descender: %g\n", descender);
   printf( "lineHeight: %g\n", lineHeight);

   // Test text data in range
   textData = [layouter textUTF8DataInTextRange];
   printf( "textData: %.*s (length: %tu)\n", 
            (int) textData.length, 
            textData.characters, 
            textData.length);

   return( 0);
}
