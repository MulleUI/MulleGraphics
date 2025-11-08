// Define a mock font with metrics for ASCII characters
#define MOCK_FONT_ASCII_START   32
#define MOCK_FONT_ASCII_END     127
#define MOCK_FONT_ASCII_COUNT   (MOCK_FONT_ASCII_END - MOCK_FONT_ASCII_START)

struct GlyphMetrics
{
   float   ascender;
   float   descender;
   float   width;
};


static struct GlyphMetrics   glyphMetrics[ MOCK_FONT_ASCII_COUNT] =
{
   // 32: ' '
   {  0.0f, 0.0f, 5.0f }, // space

   // 33–47: punctuation
   {  8.0f, 2.0f, 6.0f }, // !
   {  8.0f, 2.0f, 6.0f }, // "
   {  8.0f, 2.0f, 7.0f }, // #
   {  8.0f, 2.0f, 7.0f }, // $
   {  8.0f, 2.0f, 7.0f }, // %
   {  8.0f, 2.0f, 7.0f }, // &
   {  8.0f, 2.0f, 5.0f }, // '
   {  8.0f, 2.0f, 6.0f }, // (
   {  8.0f, 2.0f, 6.0f }, // )
   {  8.0f, 2.0f, 6.0f }, // *
   {  8.0f, 2.0f, 6.0f }, // +
   {  8.0f, 2.0f, 5.0f }, // ,
   {  8.0f, 2.0f, 6.0f }, // -
   {  8.0f, 2.0f, 5.0f }, // .
   {  8.0f, 2.0f, 6.0f }, // /

   // 48–57: digits
   {  9.0f, 0.0f, 7.0f }, // 0
   {  9.0f, 0.0f, 7.0f }, // 1
   {  9.0f, 0.0f, 7.0f }, // 2
   {  9.0f, 0.0f, 7.0f }, // 3
   {  9.0f, 0.0f, 7.0f }, // 4
   {  9.0f, 0.0f, 7.0f }, // 5
   {  9.0f, 0.0f, 7.0f }, // 6
   {  9.0f, 0.0f, 7.0f }, // 7
   {  9.0f, 0.0f, 7.0f }, // 8
   {  9.0f, 0.0f, 7.0f }, // 9

   // 58–64: punctuation
   {  5.0f, 0.0f, 6.0f }, // :
   {  5.0f, 2.0f, 6.0f }, // ;
   {  6.0f, 0.0f, 6.0f }, // <
   {  5.0f, 1.0f, 6.0f }, // =
   {  6.0f, 0.0f, 6.0f }, // >
   {  8.0f, 2.0f, 6.0f }, // ?
   {  9.0f, 0.0f, 6.0f }, // @

   // 65–90: uppercase A-Z
   {  9.0f, 1.0f, 7.5f }, // A
   {  9.0f, 1.0f, 7.5f }, // B
   {  9.0f, 1.0f, 7.5f }, // C
   {  9.0f, 1.0f, 7.5f }, // D
   {  9.0f, 1.0f, 7.5f }, // E
   {  9.0f, 1.0f, 7.5f }, // F
   {  9.0f, 1.0f, 7.5f }, // G
   {  9.0f, 1.0f, 7.5f }, // H
   {  9.0f, 1.0f, 7.5f }, // I
   {  9.0f, 1.0f, 7.5f }, // J
   {  9.0f, 1.0f, 7.5f }, // K
   {  9.0f, 1.0f, 7.5f }, // L
   {  9.0f, 1.0f, 7.5f }, // M
   {  9.0f, 1.0f, 7.5f }, // N
   {  9.0f, 1.0f, 7.5f }, // O
   {  9.0f, 1.0f, 7.5f }, // P
   {  9.0f, 1.0f, 7.5f }, // Q
   {  9.0f, 1.0f, 7.5f }, // R
   {  9.0f, 1.0f, 7.5f }, // S
   {  9.0f, 1.0f, 7.5f }, // T
   {  9.0f, 1.0f, 7.5f }, // U
   {  9.0f, 1.0f, 7.5f }, // V
   {  9.0f, 1.0f, 7.5f }, // W
   {  9.0f, 1.0f, 7.5f }, // X
   {  9.0f, 1.0f, 7.5f }, // Y
   {  9.0f, 1.0f, 7.5f }, // Z

   // 91–96: punctuation/brackets
   {  8.0f, 2.0f, 6.0f }, // [
   {  8.0f, 2.0f, 6.0f }, // \
   {  8.0f, 2.0f, 6.0f }, // ]
   {  8.0f, 2.0f, 6.0f }, // ^
   {  8.0f, 2.0f, 6.0f }, // _
   {  8.0f, 2.0f, 6.0f }, // `

   // 97–122: lowercase a-z
   {  8.0f, 0.0f, 7.0f }, // a
   {  8.0f, 2.0f, 7.0f }, // b
   {  8.0f, 0.0f, 7.0f }, // c
   {  8.0f, 2.0f, 7.0f }, // d
   {  8.0f, 0.0f, 7.0f }, // e
   {  8.0f, 2.0f, 7.0f }, // f
   {  8.0f, 2.0f, 7.0f }, // g
   {  8.0f, 0.0f, 7.0f }, // h
   {  8.0f, 0.0f, 5.0f }, // i
   {  8.0f, 2.0f, 7.0f }, // j
   {  8.0f, 0.0f, 7.0f }, // k
   {  8.0f, 0.0f, 7.0f }, // l
   {  8.0f, 0.0f, 7.0f }, // m
   {  8.0f, 0.0f, 7.0f }, // n
   {  8.0f, 0.0f, 7.0f }, // o
   {  8.0f, 2.0f, 7.0f }, // p
   {  8.0f, 2.0f, 7.0f }, // q
   {  8.0f, 0.0f, 7.0f }, // r
   {  8.0f, 0.0f, 7.0f }, // s
   {  8.0f, 0.0f, 7.0f }, // t
   {  8.0f, 0.0f, 7.0f }, // u
   {  8.0f, 0.0f, 7.0f }, // v
   {  8.0f, 0.0f, 7.0f }, // w
   {  8.0f, 0.0f, 7.0f }, // x
   {  8.0f, 2.0f, 7.0f }, // y
   {  8.0f, 0.0f, 7.0f }, // z

   // 123–126: punctuation
   {  8.0f, 2.0f, 6.0f }, // {
   {  8.0f, 2.0f, 6.0f }, // |
   {  8.0f, 2.0f, 6.0f }, // }
   {  8.0f, 2.0f, 6.0f }  // ~
};

// fing AI MAX usage
#ifndef MAX
#define MAX(a, b) ((a) > (b) ? (a) : (b))
#endif

@implementation MockUILayoutContext

#pragma mark - Properties

- (instancetype) init
{
   [self setFontSize:12.0];
   [self setTextLetterSpacing:1.0];
   [self setTextAlign:UITextAlignmentCenter];
   [self setTextLineHeight:13.0];
   [self setLineBreakMode:0];

   return(self);
}

- (void) useDefaultFont
{
   [self setFontSize:12.0f]; // Default font size
}

- (BOOL) useFontWithNameUTF8String:(char *)name
{
   [self setFontSize:12.0f]; // Default to 12pt for simplicity
   return(YES);
}

#pragma mark - Font Metrics Retrieval

- (struct CGTextMetrics) textMetrics
{
   struct CGTextMetrics metrics;
   CGFloat              scale;

   scale = [self fontSize] / 12.0f;
   metrics.ascender   = 9.0f * scale;   // Mock ascender
   metrics.descender  = 2.0f * scale;   // Mock descender
   metrics.lineHeight = 12.0f * scale;  // Mock line height

   return(metrics);
}

#pragma mark - Single-Line Text Bounding and Glyph Positioning

- (float) getTextBounds:(CGRect *)bounds
                   text:(char *)text
                 length:(NSUInteger)length
{
   CGFloat               height;
   CGFloat               maxWidth;
   CGFloat               scale;
   CGFloat               x;
   NSUInteger            i;
   struct GlyphMetrics   glyph;
   unsigned char         index;
   CGFloat               scaledAscender;
   CGFloat               scaledDescender;
   CGFloat               scaledWidth;

   height    = 0.0f;
   maxWidth  = 0.0f;
   scale     = [self fontSize] / 12.0f;
   x         = 0.0f;

   for(i = 0; i < length; i++)
   {
      int ch;

      ch = text[i];

      if(ch >= MOCK_FONT_ASCII_START && ch < MOCK_FONT_ASCII_END)
      {

         index = (unsigned char)(ch - MOCK_FONT_ASCII_START);
         glyph = glyphMetrics[index];

         // Apply font scaling
         scaledWidth     = glyph.width * scale;
         scaledAscender  = glyph.ascender * scale;
         scaledDescender = glyph.descender * scale;

         maxWidth = MAX(maxWidth, x + scaledWidth);
         height   = MAX(height, scaledAscender - scaledDescender);

         x += scaledWidth;
      }
   }

   bounds->origin.x    = 0.0f;
   bounds->origin.y    = 0.0f;
   bounds->size.width  = maxWidth;
   bounds->size.height = height;

   return(maxWidth); // Return horizontal advance
}

- (CGRect) visualBoundsOfText:(char *)text
                       length:(NSUInteger)length
{
   CGFloat    height;
   CGFloat    maxWidth;
   CGFloat    scale;
   CGFloat    x;
   NSUInteger i;

   height   = 0.0f;
   maxWidth = 0.0f;
   scale    = [self fontSize] / 12.0f;
   x        = 0.0f;

   for(i = 0; i < length; i++)
   {
      int ch;

      ch = text[i];

      if(ch >= MOCK_FONT_ASCII_START && ch < MOCK_FONT_ASCII_END)
      {
         struct GlyphMetrics glyph;
         unsigned char      index;
         CGFloat            scaledAscender;
         CGFloat            scaledDescender;
         CGFloat            scaledWidth;

         index = (unsigned char)(ch - MOCK_FONT_ASCII_START);
         glyph = glyphMetrics[index];

         // Apply font scaling
         scaledWidth    = glyph.width * scale;
         scaledAscender = glyph.ascender * scale;
         scaledDescender = glyph.descender * scale;

         maxWidth = MAX(maxWidth, x + scaledWidth);
         height   = MAX(height, scaledAscender - scaledDescender);

         x += scaledWidth;
      }
   }

   return(CGRectMake(0.0f, 0.0f, maxWidth, height));
}


- (NSUInteger) getGlyphPositions:(struct UIGlyphPosition *)positions
                           count:(NSUInteger)count
                            text:(char *)text
                          length:(NSUInteger)length
{
   NSUInteger actualCount;
   CGFloat    baseline;
   CGFloat    letterSpacing;
   CGFloat    scale;
   CGFloat    x;
   NSUInteger i;

   actualCount   = 0;
   baseline      = 0.0f; // Start at baseline y=0 for the first row
   letterSpacing = [self textLetterSpacing]; // Pixel-based spacing, not scaled
   scale         = [self fontSize] / 12.0f;
   x             = 0.0f;

   for(i = 0; i < length && actualCount < count; i++)
   {
      int ch;

      ch = text[i];

      if(ch == '\n')
      {
         x = 0.0f; // Reset x to start of new line
      }
      else if(ch >= MOCK_FONT_ASCII_START && ch < MOCK_FONT_ASCII_END)
      {
         struct GlyphMetrics glyph;
         unsigned char      index;
         CGFloat            scaledWidth;
         CGFloat            advance;

         index = (unsigned char)(ch - MOCK_FONT_ASCII_START);
         glyph = glyphMetrics[index];

         // Apply font scaling to glyph metrics
         scaledWidth = glyph.width * scale;

         positions[actualCount].str  = text + i;
         positions[actualCount].x    = x;
         positions[actualCount].minx = x;
         positions[actualCount].maxx = x + scaledWidth;
         positions[actualCount].miny = baseline - (glyph.descender * scale);
         positions[actualCount].maxy = baseline + (glyph.ascender * scale);

         // Compute advance: glyph width + letter spacing (if not last character before newline or end)
         advance = scaledWidth;
         if(i < length - 1 && text[i + 1] != '\n') // Add letter spacing except for last glyph in row
         {
            advance += letterSpacing;
         }
         x += (int)(advance + 0.5f); // Round to nearest integer, mimicking NanoVG
         actualCount++;
      }
   }

   return(actualCount);
}


#pragma mark - Multi-Line Text Handling
- (NSInteger)getTextRows:(struct UITextRow *)outputRows
                   count:(NSUInteger)maxCount
             textRowSize:(size_t) textRowSize
                    text:(char *)string
                  length:(NSUInteger)length
           breakRowWidth:(CGFloat)breakRowWidth
{
    CGFloat charWidth;
    CGFloat currentWidth;
    CGFloat letterSpacing;
    CGFloat scale;
    NSInteger rowCount;
    NSUInteger i;
    NSUInteger start;

    assert( textRowSize == sizeof( struct struct UITextRow));

    charWidth = 0.0f;
    currentWidth = 0.0f;
    scale = [self fontSize] / 12.0f;
    letterSpacing = [self textLetterSpacing] * scale;
    rowCount = 0;
    start = 0;

    // Start first row
    if (outputRows) {
        outputRows[rowCount].range.location = 0;
    }

    for (i = 0; i < length; i++) {
        int ch = string[i];

        // Lookup glyph width
        if (ch >= MOCK_FONT_ASCII_START && ch < MOCK_FONT_ASCII_END) {
            struct GlyphMetrics glyph;
            unsigned char index = (unsigned char)(ch - MOCK_FONT_ASCII_START);
            glyph = glyphMetrics[index];
            charWidth = glyph.width * scale;
        } else {
            // Default to 'X' width if character not found
            charWidth = glyphMetrics['X' - MOCK_FONT_ASCII_START].width * scale;
        }

        // Add character width
        currentWidth += charWidth;

        // Add letter spacing between characters (except after last character in the row)
        if (i < length - 1 && string[i + 1] != '\n') {
            currentWidth += letterSpacing;
        }

        // Word boundary or end of string
        if (ch == ' ' || ch == '\n' || i == length - 1) {
            // If the current word exceeds the row width, we backtrack
            if (currentWidth > breakRowWidth) {
                // If current word overflows, we backtrack to the start of the word
                if (currentWidth - charWidth > breakRowWidth) {
                    // Backtrack to start of the current word and start a new row
                    i = start - 1;
                    currentWidth = 0.0f;
                    continue;
                }

                // Finalize current row
                if (outputRows) 
                {
                    outputRows[rowCount].range.length = i- outputRows[rowCount].location];
                    outputRows[rowCount].width = currentWidth;
                    outputRows[rowCount].next  = &string[start];
                }

                rowCount++;
                if (rowCount >= maxCount) {
                    break;
                }

                // Start new row
                if (outputRows) {
                    outputRows[rowCount].range.location = start;
                }
                currentWidth = 0.0f;
            }

            // Update start pointer for the next word/row
            start = i + 1;

            // Handle newline (this always forces a new row)
            if (ch == '\n') {
                // Finalize the current row on encountering a newline
                if (outputRows) {
                    outputRows[rowCount].range.length = i - outputRows[rowCount].location];
                    outputRows[rowCount].width = currentWidth;
                }
                rowCount++;
                currentWidth = 0.0f;  // Reset for the next row
                if (rowCount >= maxCount) {
                    break;
                }

                // Start the new row right after the newline
                if (outputRows) {
                    outputRows[rowCount].range.location = i + 1;
                }
                start = i + 1;
            }
        }
    }

    // Handle the final row after the loop
    if (rowCount < maxCount) {
        if (outputRows) {
            outputRows[rowCount].range.length = length - outputRows[rowCount].location];
            outputRows[rowCount].width = currentWidth;
        }
        rowCount++;
    }

    return rowCount;
}
   

- (CGRect) boundsOfTextRows:(struct UITextRow *)rows
                      count:(NSUInteger)count
{
   CGFloat    maxWidth;
   CGFloat    scale;
   CGFloat    totalHeight;
   NSUInteger i;

   maxWidth    = 0.0f;
   scale       = [self fontSize] / 12.0f;
   totalHeight = 0.0f;

   for(i = 0; i < count; i++)
   {
      maxWidth = MAX(maxWidth, rows[i].width);
      totalHeight += 12.0f * scale; // Assume line height scaling as well
   }

   return(CGRectMake(0.0f, 0.0f, maxWidth, totalHeight));
}

@end
