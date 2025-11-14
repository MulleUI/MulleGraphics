#define _GNU_SOURCE

#include "include.h"

#import <MulleGraphics/MulleGraphics.h>


// Dummy OSGraphicsContext for testing without real OpenGL
@interface DummyOSGraphicsContext : MulleObject <UIOSGraphicsContext>
@end


@implementation DummyOSGraphicsContext

- (UIGraphicsBackend) backend
{
   return( UIGraphicsBackendGL3);  // Pretend we have GL3
}

- (id) activeThread
{
   return( [NSThread currentThread]);  // Return current thread
}

@end


int   main( void)
{
   CATextLayer              *layer;
   CGContext                *context;
   DummyOSGraphicsContext   *osContext;
   CGRect                   frame;
   CGSize                   size;
   UIGraphicsOptions        options;
   struct UILayoutInfo      layoutInfo;

   mulle_printf( "=== CATextLayer Render Test ===\n");
   
   // Create dummy OS context
   osContext = [DummyOSGraphicsContext instance];
   
   // Create CGContext with no-drawing and trace flags
   options = UIGraphicsNoDrawing;
   
   context = [[[CGContext alloc] initWithOSGraphicsContext:osContext
                                                   shareID:0
                                                   options:options] autorelease];
   
   if( ! context)
   {
      mulle_printf( "ERROR: Failed to create CGContext\n");
      return( 1);
   }
   
   mulle_printf( "Created CGContext with NoDrawing and TraceDrawCalls\n");
   
   // Create and configure text layer
   layer = [CATextLayer instance];
   frame = CGRectMake( 50, 50, 300, 200);
   [layer setFrame:frame];
   [layer setTextUTF8String:"VfL Bochum 1848"];
   [layer setFontPixelSize:24.0f];
   
   mulle_printf( "Configured CATextLayer: \"%s\"\n", [layer textUTF8String]);
   mulle_printf( "Frame: %s\n", CGRectUTF8String( frame));
   
   // Prepare layout

   // Begin frame and render
   mulle_printf( "\n--- Begin Rendering ---\n");
   CGContextBeginFrame( context, CGSizeMake( 400, 300), 1.0);

   layoutInfo = UILayoutInfoMake( CGRectMake( 0, 0, 400, 300),
                                  UIEdgeInsetsZero,
                                  context);
   [layer layoutWithLayoutInfo:&layoutInfo];

   // Redirect nvg trace to stdout for our test
   nvgTrace( CGContextGetNVGContext( context), [context nameUTF8String], stdout);
   [layer renderInContext:context];
   nvgTrace( CGContextGetNVGContext( context), NULL, NULL);
   
   CGContextEndFrame( context);
   mulle_printf( "--- End Rendering ---\n");
   
   mulle_printf( "\nRender completed successfully\n");
   
   return( 0);
}
