#define _GNU_SOURCE
#include "include.h"
#import <MulleGraphics/MulleGraphics.h>

static void  show( CATextLayer *layer, CGLayoutContext *context, char *text, UITextVerticalAlignment vAlign)
{
   CATextLayerLayouter   *layouter;
   CGPoint               origin;

   layouter = [CATextLayerLayouter instance];
   [layouter setTextLayer:layer];

   [layer setTextUTF8String:text];
   [layer setTextVerticalAlignment:vAlign];

   origin = [layouter textOriginInRect:[layer frame] context:context];

   printf( "lh:%g font:%g rows:%td v:%s origin:%s text:\n%s\n---\n",
           [layer textLineHeight],
           [layer fontPixelSize],
           [layer numberOfRows],
           UITextVerticalAlignmentUTF8String( vAlign),
           CGPointUTF8String( origin),
           text);
}

int main( void)
{
   CATextLayer       *layer;
   CGLayoutContext   *context;
   CGRect            rect;

   rect    = CGRectMake( 0, 0, 200, 100);
   layer   = [CATextLayer instance];
   context = [CGLayoutContext instance];

   [layer setFrame:rect];
   [layer setFontPixelSize:16.0f];
   [layer setLineBreakMode:NSLineBreakByWordWrapping];

   // baseline: default lineHeight == fontPixelSize
   show( layer, context, "A\nB\nC", UITextAlignmentBottom);

   // now enlarge line height to 1.5 * font
   [layer setTextLineHeight:16.0f * 1.5f];
   show( layer, context, "A\nB\nC", UITextAlignmentBottom);

   // extreme small line height
   [layer setTextLineHeight:8.0f];
   show( layer, context, "A\nB\nC", UITextAlignmentBottom);

   return( 0);
}
