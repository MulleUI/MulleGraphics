//
//  CABasicAnimation+CGGradient.m
//  MulleGraphics
//
//  Copyright (c) 2023 Nat! - Mulle kybernetiK.
//  All rights reserved.
//
//
//  Redistribution and use in source and binary forms, with or without
//  modification, are permitted provided that the following conditions are met:
//
//  Redistributions of source code must retain the above copyright notice, this
//  list of conditions and the following disclaimer.
//
//  Redistributions in binary form must reproduce the above copyright notice,
//  this list of conditions and the following disclaimer in the documentation
//  and/or other materials provided with the distribution.
//
//  Neither the name of Mulle kybernetiK nor the names of its contributors
//  may be used to endorse or promote products derived from this software
//  without specific prior written permission.
//
//  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
//  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
//  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
//  ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
//  LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
//  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
//  SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
//  INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
//  CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
//  ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
//  POSSIBILITY OF SUCH DAMAGE.
//
#import "CABasicAnimation+CGGradient.h"

#import "import-private.h"


@implementation CGGradient( CAInterpolatableValue)


// standard interpolation self is start: start + (end - start) * x;
// gets triggered through standard object behavior of CAInterpolatableValue
// no need to add it to anything
- (id) interpolateTo:(id) end
              factor:(double) x
            additive:(BOOL) additive
{
   CARotation                 rotation;
   CARotation                 endRotation;
   CARotation                 startRotation;
   CGColor                    *interpolated_colors;
   CGColor                    end_color;
   CGColor                    start_color;
   CGGradient                 *gradient;
   float                      *dst_locations;
   float                      *end_locations;
   float                      *interpolated_locations;
   float                      *start_locations;
   float                      end_location;
   float                      start_location;
   float                      i_f;
   float                      j_f;
   float                      i_step_f;
   float                      j_step_f;   
   NSUInteger                 count;
   NSUInteger                 endCount;
   NSUInteger                 i;
   NSUInteger                 j;
   NSUInteger                 k;
   NSUInteger                 n;
   NSUInteger                 startCount;
   union CGColorOrColorDiff   *dst_colors;
   union CGColorOrColorDiff   *end_colors;
   union CGColorOrColorDiff   *start_colors;

   MULLE_C_ASSERT( sizeof( union CGColorOrColorDiff) == sizeof( CGColor));

   startCount = [self numberOfColors];
   endCount   = [end numberOfColors];
   count      = startCount > endCount ? startCount : endCount;

   // interpolate from nil to nil, must not happen (just don't run an
   // animation for that)
   assert( count);

   n = startCount + endCount + count;
   mulle_flexarray_do( colors_buf, union CGColorOrColorDiff, 12, n)
   {
      start_colors        = colors_buf;
      end_colors          = &start_colors[ startCount];
      dst_colors          = &end_colors[ endCount];
      interpolated_colors = (CGColor *) dst_colors;

      [self getColors:(void *) start_colors];
      [end getColors:(void *) end_colors];

      mulle_flexarray_do( locations_buf, float, 12, n)
      {
         start_locations        = locations_buf;
         end_locations          = &start_locations[ startCount];
         interpolated_locations = &end_locations[ endCount];
         dst_locations          = interpolated_locations;

         [self getLocations:start_locations];
         [end getLocations:end_locations];

         i_f      = 0.0f; 
         j_f      = 0.0f;
         i_step_f = (double) startCount / count;
         j_step_f = (double) endCount / count;

         for( k = 0; k < count; k++)
         {
            i = (NSUInteger) floorf( i_f + 0.001f); // 0.999 should be 1.0
            j = (NSUInteger) floorf( j_f + 0.001f);

            if( startCount)
            {
               start_color    = start_colors[ i].color;
               start_location = start_locations[ i];
            }
            else
            {
               start_color = CGColorMakeTransparent();
            }

            if( endCount)   
            {
               end_color    = end_colors[ j].color;
               end_location = end_locations[ j];
            }
            else
            {
               end_color = CGColorMakeTransparent();
            }

            if( additive)
            {
               dst_colors->diff = CGColorInterpolateAdditive( start_color, end_color, x);
               dst_colors++;
               *dst_locations++ = CAInterpolateAdditive( start_location, end_location, x);
            }
            else
            {
               dst_colors->color = CGColorInterpolate( start_color, end_color, x);
               dst_colors++;
               *dst_locations++  = CAInterpolate( start_location, end_location, x);
            }

            i_f += i_step_f;
            j_f += j_step_f;
         }

         startRotation = [self rotation];
         endRotation   = [end rotation];
         rotation      = additive
                         ? CAInterpolateAdditive( startRotation, endRotation, x)
                         : CAInterpolate( startRotation, endRotation, x);
         gradient      = [CGGradient gradientWithColors:interpolated_colors
                                              locations:interpolated_locations
                                                  count:count
                                               rotation:rotation];
      }
   }
   return( gradient);
}



// self - previous + diff
- (id) interpolatedValueWithDiff:(id) diff
                    previousDiff:(id) previous
{
   BOOL                       i_inside;
   BOOL                       j_inside;
   CARotation                 rotation;
   CARotation                 diffRotation;
   CARotation                 previousRotation;
   CGColor                    *interpolated_colors;
   CGColorDiff                colordiff;
   CGColorDiff                previous_colordiff;
   CGGradient                 *gradient;
   float                      *interpolated_locations;
   float                      *locationdiffs;
   float                      *locations;
   float                      *previous_locationdiffs;
   float                      locationdiff;
   float                      previous_locationdiff;
   NSInteger                  i;
   NSInteger                  j;
   NSUInteger                 count;
   NSUInteger                 diffCount;
   NSUInteger                 k;
   NSUInteger                 n;
   NSUInteger                 previousCount;
   union CGColorOrColorDiff   *colordiffs;
   union CGColorOrColorDiff   *colors;
   union CGColorOrColorDiff   *previous_colordiffs;

   diffCount     = [diff numberOfColors];
   previousCount = [previous numberOfColors];
   count         = [self numberOfColors];
   i             = CAArrayIndexForInterpolation( previousCount,
                                                 count,
                                                 CAAnimationStickyArrayCenter);
   j             = CAArrayIndexForInterpolation( diffCount,
                                                 count,
                                                 CAAnimationStickyArrayCenter);
   n = previousCount + diffCount + count;
   mulle_flexarray_do( colors_buf, union CGColorOrColorDiff, 12, n)
   {
      previous_colordiffs = colors_buf;
      colordiffs          = &previous_colordiffs[ previousCount];
      colors              = &colordiffs[ diffCount];
      interpolated_colors = (CGColor *) colors;

      [self getColors:(CGColor *) colors];
      [diff getColors:(CGColor *) colordiffs];
      [previous getColors:(CGColor *) previous_colordiffs];

      mulle_flexarray_do( locations_buf, float, 12, n)
      {
         previous_locationdiffs = locations_buf;
         locationdiffs          = &previous_locationdiffs[ previousCount];
         locations              = &locationdiffs[ diffCount];
         interpolated_locations = locations;

         [self getLocations:interpolated_locations];
         [diff getLocations:locationdiffs];
         [previous getLocations:previous_locationdiffs];

         for( k = 0; k < count; k++)
         {
            i_inside              = (i >= 0 && i < previousCount);
            previous_colordiff    = i_inside ? (previous_colordiffs++)->diff : CGColorDiffZero;
            previous_locationdiff = i_inside ? *previous_locationdiffs++     : 0.0;

            j_inside              = (j >= 0 && j < diffCount);
            colordiff             = j_inside ? (colordiffs++)->diff : CGColorDiffZero;
            locationdiff          = j_inside ? *locationdiffs++     : 0.0;

            colordiff             = CGColorDiffSubtract( colordiff, previous_colordiff);
            colors->color         = CGColorAddDiff( colors->color, colordiff);
            ++colors;

            *locations++         += locationdiff - previous_locationdiff;

            i++;
            j++;
         }

         previousRotation = [previous rotation];
         diffRotation     = [diff rotation];
         rotation         = [self rotation] - previousRotation + diffRotation;
         // create new gradient
         gradient  = [CGGradient gradientWithColors:interpolated_colors
                                          locations:interpolated_locations
                                              count:count
                                           rotation:rotation];
      }
   }
   return( gradient);
}

@end


@implementation CABasicAnimation( CGGradient)

+ (CABasicAnimation *) animationWithProperty:(struct _mulle_objc_property *) property
                             startCGGradient:(CGGradient *) startGradient
                               endCGGradient:(CGGradient *) endGradient
                                     options:(struct CABasicAnimationOptions *) options
{
   assert( [startGradient isKindOfClass:[CGGradient class]]);
   assert( ! endGradient || [endGradient isKindOfClass:[CGGradient class]]);

   return( [[[self alloc] initWithProperty:property
                          startObjectValue:startGradient
                            endObjectValue:endGradient
                                  options:options] autorelease]);
}

@end

