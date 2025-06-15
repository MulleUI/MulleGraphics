#import "import-private.h"

#import <string.h>


#define POSSIBLE_NANOVG_INTERSECT_BUG

// The problem is that the old scissor is converted to the current transform
// for intersection. Then the rotated version is now set as the
// new scissor, but that
//

// void nvgIntersectScissor(NVGcontext* ctx, float x, float y, float w, float h)
// {
//    NOT_AVAILABLE_IN_FONT_CONTEXT( ctx);
//    NOT_AVAILABLE_IN_PATH_CONTEXT( ctx);
//
//    NVGstate* state = nvg__getState(ctx);
//    float pxform[6], invxorm[6];
//    float rect[4];
//    float ex, ey, tex, tey;
//
//    // If no previous scissor has been set, set the scissor as current scissor.
//    if (state->scissor.extent[0] < 0) {
//       nvgScissor(ctx, x, y, w, h);
//       return;
//    }
//
//    // Transform the current scissor rect into current transform space.
//    // If there is difference in rotation, this will be approximation.
//    memcpy(pxform, state->scissor.xform, sizeof(float)*6);
//    ex = state->scissor.extent[0];
//    ey = state->scissor.extent[1];
//    nvgTransformInverse(invxorm, state->xform);
//    nvgTransformMultiply(pxform, invxorm);
//    tex = ex*nvg__absf(pxform[0]) + ey*nvg__absf(pxform[2]);
//    tey = ex*nvg__absf(pxform[1]) + ey*nvg__absf(pxform[3]);
//
//    // Intersect rects.
//    nvg__isectRects(rect, pxform[4]-tex,pxform[5]-tey,tex*2,tey*2, x,y,w,h);
//
//    nvgScissor(ctx, rect[0], rect[1], rect[2], rect[3]);
// }

//
// We draw little rectangles exactly 20x20
// as much as we can fit into the canvas
//
static BOOL   drawStuff( CGGraphicsLayer *layer, CGContext *_context)
{
   CGContext           *context = _context;
   NSUInteger          x;
   NSUInteger          y;
   NSUInteger          w;
   NSUInteger          h;
   struct NVGcontext   *vg;
   CGRect              bounds;
   CGFloat             col;
   CGFloat             col_inc;
   CGRect              canvas;

   vg = CGContextGetNVGContext( context);

#ifdef POSSIBLE_NANOVG_INTERSECT_BUG
   // visually this breaks the intersect we got from the view clipRect
   // or from our masksToBounds
   bounds = [layer bounds];
   nvgIntersectScissor( vg, bounds.origin.x,
                            bounds.origin.y,
                            bounds.size.width,
                            bounds.size.height);
#endif
   canvas = [layer canvas];
   w = (NSUInteger) ceil( canvas.size.width / 20.0);
   h = (NSUInteger) ceil( canvas.size.height / 20.0);

   for( y = 0; y < h; y++)
      for( x = 0; x < w; x++)
      {
         nvgBeginPath( vg);
         if( (x ^ y) & 1)
            nvgFillColor( vg, CGColorMakeWithHSL( 0.2 * y / h + 0.8 * x / w, 1.0, 0.8));
         else
            nvgFillColor( vg, CGColorMakeWithHSL( 0.8 * y / h + 0.2 * x / w, 0.8, 0.5));
         nvgRect( vg, x * 20.0, y * 20.0, 20.0, 20.0);
         nvgFill( vg);
      }

   return( YES);
}


void   setupSceneInView( UIView *contentView)
{
   CGRect            contentRect;
   CGRect            frame;
   UIView            *view;
   CGGraphicsLayer   *layer;

   contentRect = [contentView contentRect];

   frame = CGRectInset( contentRect, 100.0, 50.0);

   view  = [UIView viewWithFrame:frame];
   [view setDrawCallback:drawStuff];
   [view setBorderWidth:1.0];
   [view setBorderColor:CGColorMakeWithHexColor( 0x00FF00FF)];
   [view setClipsToBounds:NO];
   [contentView addSubview:view];

   layer = MULLE_OBJC_CLASS_CAST( CGGraphicsLayer, [view layer]);
   [layer setRotation:0.33];
   [layer setMasksToBounds:YES];
}


int   main( void)
{
   CGContext       *context;
   UIWindow        *window;
   UIApplication   *app;

   /*
    * window and app
    */
   app = [UIApplication sharedInstance];

   window = [UIWindow windowWithFrame:CGRectMake( 0.0, 0.0, 800, 600)];
   [window setBackgroundColor:CGColorMakeWithRGBA( 1.0, 1.0, 1.0, 1.0)];

   setupSceneInView( [window contentView]);
   [app addWindow:window];

   return( [app runApp]);
}



// PROPOSED AI FIX:
#if 0
// Line intersection helper
static bool lineIntersection(float x1, float y1, float x2, float y2,
                            float x3, float y3, float x4, float y4,
                            float* ix, float* iy)
{
    float denom = (x1-x2)*(y3-y4) - (y1-y2)*(x3-x4);
    if (fabsf(denom) < 1e-10f) return false; // parallel lines

    float t = ((x1-x3)*(y3-y4) - (y1-y3)*(x3-x4)) / denom;
    *ix = x1 + t*(x2-x1);
    *iy = y1 + t*(y2-y1);
    return true;
}

// Check if point is inside edge (left side of directed edge)
static bool isInside(float px, float py, float x1, float y1, float x2, float y2)
{
    return ((x2-x1)*(py-y1) - (y2-y1)*(px-x1)) >= 0;
}

// Clip polygon against one edge
static int clipAgainstEdge(float* input, int inputCount, float* output,
                          float x1, float y1, float x2, float y2)
{
    if (inputCount == 0) return 0;

    int outputCount = 0;
    float prevX = input[(inputCount-1)*2];
    float prevY = input[(inputCount-1)*2+1];
    bool prevInside = isInside(prevX, prevY, x1, y1, x2, y2);

    for (int i = 0; i < inputCount; i++) {
        float currX = input[i*2];
        float currY = input[i*2+1];
        bool currInside = isInside(currX, currY, x1, y1, x2, y2);

        if (currInside) {
            if (!prevInside) {
                // Entering - add intersection point
                float ix, iy;
                if (lineIntersection(prevX, prevY, currX, currY, x1, y1, x2, y2, &ix, &iy)) {
                    output[outputCount*2] = ix;
                    output[outputCount*2+1] = iy;
                    outputCount++;
                }
            }
            // Add current point
            output[outputCount*2] = currX;
            output[outputCount*2+1] = currY;
            outputCount++;
        } else if (prevInside) {
            // Exiting - add intersection point
            float ix, iy;
            if (lineIntersection(prevX, prevY, currX, currY, x1, y1, x2, y2, &ix, &iy)) {
                output[outputCount*2] = ix;
                output[outputCount*2+1] = iy;
                outputCount++;
            }
        }

        prevX = currX;
        prevY = currY;
        prevInside = currInside;
    }
    return outputCount;
}

// Main clipping function
static int clipRectangles(float* subject, int subjectCount,
                         float* clipRect, float* result)
{
    float temp1[16], temp2[16]; // Max 8 vertices * 2 coords
    float* input = subject;
    float* output = temp1;
    int count = subjectCount;

    // Clip against all 4 edges of the clip rectangle
    // clipRect is [x1,y1, x2,y1, x2,y2, x1,y2] (4 corners)
    for (int edge = 0; edge < 4; edge++) {
        if (count == 0) break;

        int nextEdge = (edge + 1) % 4;
        float x1 = clipRect[edge*2];
        float y1 = clipRect[edge*2+1];
        float x2 = clipRect[nextEdge*2];
        float y2 = clipRect[nextEdge*2+1];

        count = clipAgainstEdge(input, count, output, x1, y1, x2, y2);

        // Swap input/output buffers
        float* temp = input;
        input = output;
        output = (temp == temp1) ? temp2 : temp1;
    }

    // Copy result
    for (int i = 0; i < count * 2; i++) {
        result[i] = input[i];
    }

    return count;
}

void nvgIntersectScissor(NVGcontext* ctx, float x, float y, float w, float h)
{
    NOT_AVAILABLE_IN_FONT_CONTEXT( ctx);
    NOT_AVAILABLE_IN_PATH_CONTEXT( ctx);

    NVGstate* state = nvg__getState(ctx);

    // If no previous scissor has been set, set the scissor as current scissor.
    if (state->scissor.extent[0] < 0) {
        nvgScissor(ctx, x, y, w, h);
        return;
    }

    // Get the 4 corners of the existing scissor in local space
    float ex = state->scissor.extent[0];  // half-width
    float ey = state->scissor.extent[1];  // half-height
    float clipRect[8] = {
        -ex, -ey,  // bottom-left
         ex, -ey,  // bottom-right
         ex,  ey,  // top-right
        -ex,  ey   // top-left
    };

    // Transform clip rectangle corners to current coordinate space
    float pxform[6], invxorm[6];
    memcpy(pxform, state->scissor.xform, sizeof(float)*6);
    nvgTransformInverse(invxorm, state->xform);
    nvgTransformMultiply(pxform, invxorm);

    for (int i = 0; i < 4; i++) {
        nvgTransformPoint(&clipRect[i*2], &clipRect[i*2+1],
                         pxform, clipRect[i*2], clipRect[i*2+1]);
    }

    // Subject rectangle (new scissor request)
    float subject[8] = {
        x, y,
        x+w, y,
        x+w, y+h,
        x, y+h
    };

    // Clip them
    float result[16];
    int resultCount = clipRectangles(subject, 4, clipRect, result);

    if (resultCount == 0) {
        // Empty intersection - set empty scissor
        state->scissor.extent[0] = 0;
        state->scissor.extent[1] = 0;
        return;
    }

    // Find bounding box of clipped polygon
    float minX = result[0], maxX = result[0];
    float minY = result[1], maxY = result[1];
    for (int i = 1; i < resultCount; i++) {
        minX = nvg__minf(minX, result[i*2]);
        maxX = nvg__maxf(maxX, result[i*2]);
        minY = nvg__minf(minY, result[i*2+1]);
        maxY = nvg__maxf(maxY, result[i*2+1]);
    }

    // Set new scissor with bounding box
    nvgScissor(ctx, minX, minY, maxX-minX, maxY-minY);
}


/// and

// Optimized clipping for axis-aligned rectangle against rotated rectangle
static int clipAxisAlignedAgainstRotated(float x, float y, float w, float h,
                                        float* clipRect, float* result)
{
    // Only need 2 slopes for the rotated rectangle since opposite edges are parallel
    float m1, b1_1, b1_2;  // for first pair of parallel edges
    float m2, b2_1, b2_2;  // for second pair of parallel edges
    bool isVertical1 = false, isVertical2 = false;

    // Get first pair of parallel edges (edge 0 and edge 2)
    if (fabsf(clipRect[2] - clipRect[0]) < 1e-10f) {
        isVertical1 = true;
        m1 = clipRect[0]; // store x-coordinate for vertical line
        b1_1 = clipRect[4]; // x-coordinate of parallel edge
    } else {
        m1 = (clipRect[3] - clipRect[1]) / (clipRect[2] - clipRect[0]);
        b1_1 = clipRect[1] - m1 * clipRect[0];        // edge 0
        b1_2 = clipRect[5] - m1 * clipRect[4];        // edge 2 (parallel to edge 0)
    }

    // Get second pair of parallel edges (edge 1 and edge 3)
    if (fabsf(clipRect[4] - clipRect[2]) < 1e-10f) {
        isVertical2 = true;
        m2 = clipRect[2]; // store x-coordinate for vertical line
        b2_1 = clipRect[6]; // x-coordinate of parallel edge
    } else {
        m2 = (clipRect[5] - clipRect[3]) / (clipRect[4] - clipRect[2]);
        b2_1 = clipRect[3] - m2 * clipRect[2];        // edge 1
        b2_2 = clipRect[7] - m2 * clipRect[6];        // edge 3 (parallel to edge 1)
    }

    float points[16]; // max 8 intersection points
    int pointCount = 0;

    // Add corners of axis-aligned rectangle that are inside rotated rectangle
    float rectCorners[8] = {x, y, x+w, y, x+w, y+h, x, y+h};
    for (int i = 0; i < 4; i++) {
        float px = rectCorners[i*2];
        float py = rectCorners[i*2+1];

        // Check if point is inside rotated rectangle using all 4 edges
        bool inside = true;
        for (int j = 0; j < 4; j++) {
            int next = (j + 1) % 4;
            if (!isInside(px, py, clipRect[j*2], clipRect[j*2+1],
                         clipRect[next*2], clipRect[next*2+1])) {
                inside = false;
                break;
            }
        }

        if (inside) {
            points[pointCount*2] = px;
            points[pointCount*2+1] = py;
            pointCount++;
        }
    }

    // Add corners of rotated rectangle that are inside axis-aligned rectangle
    for (int i = 0; i < 4; i++) {
        float px = clipRect[i*2];
        float py = clipRect[i*2+1];

        if (px >= x && px <= x+w && py >= y && py <= y+h) {
            points[pointCount*2] = px;
            points[pointCount*2+1] = py;
            pointCount++;
        }
    }

    // Find intersections between vertical edges of axis-aligned rect and rotated rect
    for (int xEdge = 0; xEdge < 2; xEdge++) {
        float xVal = (xEdge == 0) ? x : x + w;

        if (!isVertical1) {
            // Intersect with first edge of first parallel pair
            float yVal = m1 * xVal + b1_1;
            if (yVal >= y && yVal <= y+h) {
                // Check if intersection is within the rotated edge segment
                float minX = nvg__minf(clipRect[0], clipRect[2]);
                float maxX = nvg__maxf(clipRect[0], clipRect[2]);
                if (xVal >= minX && xVal <= maxX) {
                    points[pointCount*2] = xVal;
                    points[pointCount*2+1] = yVal;
                    pointCount++;
                }
            }

            // Intersect with second edge of first parallel pair
            yVal = m1 * xVal + b1_2;
            if (yVal >= y && yVal <= y+h) {
                float minX = nvg__minf(clipRect[4], clipRect[6]);
                float maxX = nvg__maxf(clipRect[4], clipRect[6]);
                if (xVal >= minX && xVal <= maxX) {
                    points[pointCount*2] = xVal;
                    points[pointCount*2+1] = yVal;
                    pointCount++;
                }
            }
        }
    }

    // Find intersections between horizontal edges of axis-aligned rect and rotated rect
    for (int yEdge = 0; yEdge < 2; yEdge++) {
        float yVal = (yEdge == 0) ? y : y + h;

        if (!isVertical2 && fabsf(m2) > 1e-10f) {
            // Intersect with first edge of second parallel pair
            float xVal = (yVal - b2_1) / m2;
            if (xVal >= x && xVal <= x+w) {
                float minY = nvg__minf(clipRect[3], clipRect[5]);
                float maxY = nvg__maxf(clipRect[3], clipRect[5]);
                if (yVal >= minY && yVal <= maxY) {
                    points[pointCount*2] = xVal;
                    points[pointCount*2+1] = yVal;
                    pointCount++;
                }
            }

            // Intersect with second edge of second parallel pair
            xVal = (yVal - b2_2) / m2;
            if (xVal >= x && xVal <= x+w) {
                float minY = nvg__minf(clipRect[7], clipRect[1]);
                float maxY = nvg__maxf(clipRect[7], clipRect[1]);
                if (yVal >= minY && yVal <= maxY) {
                    points[pointCount*2] = xVal;
                    points[pointCount*2+1] = yVal;
                    pointCount++;
                }
            }
        }
    }

    // Copy results
    for (int i = 0; i < pointCount * 2; i++) {
        result[i] = points[i];
    }

    return pointCount;
}


#endif

