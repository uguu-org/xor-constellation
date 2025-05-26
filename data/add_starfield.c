/* Add random starfield to a PNG.

   ./add_starfield {input.png} {seed} > {output.png}

   Expect input image with transparencies for where stars will be added.
   Stars will be added as solid black pixels.
*/

#include<assert.h>
#include<inttypes.h>
#include<png.h>
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>

#ifdef _WIN32
   #include<fcntl.h>
   #include<io.h>
#endif

/* Minimum distance between stars any any non-transparent pixel. */
#ifndef RADIUS
   #define RADIUS  12
#endif

typedef struct { int x, y; } XY;

/* Syntactic sugar.  These may or may not be defined in standard library,
   so we just define our own functions for it.                            */
static int Max(int a, int b) { return a > b ? a : b; }
static int Min(int a, int b) { return a < b ? a : b; }

/* Return a random integer between [a,b]. */
static int RandomInt(int a, int b)
{
   return (int)(((double)rand() / (double)RAND_MAX) * (b - a) + a);
}

/* Jenkin's one-at-a-time hash.
   https://en.wikipedia.org/wiki/Jenkins_hash_function
*/
static uint32_t Hash(uint8_t *bytes, size_t size)
{
   uint32_t hash = 0;
   size_t i;

   for(i = 0; i < size; i++)
   {
      hash += bytes[i];
      hash += hash << 10;
      hash ^= hash >> 6;
   }
   hash += hash << 3;
   hash ^= hash >> 11;
   hash += hash << 15;
   return hash;
}

/* Hash two numbers. */
static uint32_t HashPair(int x, int y)
{
   uint8_t buffer[sizeof(int) * 2];

   memcpy(buffer, &x, sizeof(int));
   memcpy(buffer + sizeof(int), &y, sizeof(int));
   return Hash(buffer, sizeof(buffer));
}

/* Check if a coordinate is eligible for stars, returns 1 if so.  This is
   done by hashing only the coordinate value, so the stars always appear
   in the same positions regardless of input pixels.                      */
static int IsStarLocation(int x, int y)
{
   return (HashPair(x, y) & 0x11111) == 0;
}

/* Check if a region centered around some point is completely transparent,
   returns 1 if so.                                                        */
static int IsEmptyRegion(png_image *image, png_bytep pixels, int x, int y)
{
   int ix, iy, dx2, dy2;

   for(iy = Max(y - RADIUS, 0); iy <= Min(y + RADIUS, image->height); iy++)
   {
      dy2 = (y - iy) * (y - iy);
      for(ix = Max(x - RADIUS, 0); ix <= Min(x + RADIUS, image->width); ix++)
      {
         dx2 = (x - ix) * (x - ix);
         if( dx2 + dy2 > RADIUS * RADIUS )
            continue;

         /* Check for alpha component not equal to zero. */
         if( pixels[(iy * image->width + ix) * 2 + 1] != 0 )
            return 0;
      }
   }
   return 1;
}

/* Draw a single opaque black pixel. */
static void DrawPixel(png_image *image, png_bytep pixels, int x, int y)
{
   png_bytep p;

   if( x >= 0 && x < (int)(image->width) && y >= 0 && y < (int)(image->height) )
   {
      p = pixels + (y * image->width + x) * 2;
      *p++ = 0;
      *p = 0xff;
   }
}

int main(int argc, char **argv)
{
   png_image image;
   png_bytep pixels;
   int star_count, max_star_count, x, y, i, j, frame;
   XY *stars;

   if( argc != 3 )
      return printf("%s {input.png} {frame} > {output.png}\n", *argv);
   if( isatty(STDOUT_FILENO) )
   {
      fputs("Not writing output to stdout because it's a tty\n", stderr);
      return 1;
   }
   #ifdef _WIN32
      setmode(STDIN_FILENO, O_BINARY);
      setmode(STDOUT_FILENO, O_BINARY);
   #endif

   /* Load input. */
   memset(&image, 0, sizeof(image));
   image.version = PNG_IMAGE_VERSION;
   if( strcmp(argv[1], "-") == 0 )
   {
      if( !png_image_begin_read_from_stdio(&image, stdin) )
      {
         fputs("Error reading from stdin", stderr);
         return 1;
      }
   }
   else
   {
      if( !png_image_begin_read_from_file(&image, argv[1]) )
         return printf("Error reading %s\n", argv[1]);
   }
   if( image.width < 10 || image.height < 10 )
   {
      return fprintf(stderr, "Input too small (%d,%d)\n",
                     (int)(image.width), (int)(image.height));
   }

   image.format = PNG_FORMAT_GA;
   pixels = (png_bytep)malloc(PNG_IMAGE_SIZE(image));
   if( pixels == NULL )
   {
      fputs("Out of memory\n", stderr);
      return 1;
   }
   if( !png_image_finish_read(&image, NULL, pixels, 0, NULL) )
   {
      free(pixels);
      fputs("Error loading input\n", stderr);
      return 1;
   }

   /* Initialize star positions.  This is done by visiting all eligible
      coordinates in random order, and then drop the ones that failed
      proximity check.

      We used to do a simpler check where we visit each coordinate in
      YX order, but hash the coordinates to determine if a coordinate is
      eligible.  But due to the proximity check being more strict than the
      hash function, the end result tend to exhibit a rectangular grid-like
      pattern.  That pattern doesn't happen when we visit in random order.  */
   max_star_count = image.width * image.height;
   stars = (XY*)malloc(max_star_count * sizeof(XY));
   if( stars == NULL )
   {
      fputs("Out of memory\n", stderr);
      free(pixels);
      return 1;
   }
   for(i = y = 0; y < (int)(image.height); y++)
   {
      for(x = 0; x < (int)(image.width); x++, i++)
      {
         stars[i].x = x;
         stars[i].y = y;
      }
   }

   /* Fisher-Yates shuffle, with deterministic seed. */
   srand(1);
   for(i = max_star_count - 1; i > 0; i--)
   {
      j = RandomInt(0, i);
      x = stars[i].x;
      y = stars[i].y;
      stars[i].x = stars[j].x;
      stars[i].y = stars[j].y;
      stars[j].x = x;
      stars[j].y = y;
   }

   /* Visit each coordinate. */
   for(i = star_count = 0; i < max_star_count; i++)
   {
      x = stars[i].x;
      y = stars[i].y;

      /* Apply a hash check to see if a location is eligible, followed
         by a proximity check.

         Even though we have eliminated the grid-like pattern due to
         randomized visit order, we would still get a ring-like pattern
         around opaque pixels that were present in the original image.
         This is because proximity check alone would cause the pixels
         to be placed at the nearest available spot near the previously
         placed pixels.

         By combining both random visit order and hash eligibility check,
         we would eliminate the ring-like patterns as well.               */
      if( IsStarLocation(x, y) && IsEmptyRegion(&image, pixels, x, y) )
      {
         /* Star location is accepted.  We will write it back to the
            array in-place.

            If location is rejected, star_count will not be incremented
            while we read ahead in "i", so stars array will end up with
            those rejected entries skipped.                             */
         stars[star_count].x = x;
         stars[star_count].y = y;
         star_count++;

         /* Draw a black pixel to mark the selected star location, so
            that we don't draw another star near it.                  */
         DrawPixel(&image, pixels, x, y);
      }
   }

   /* Draw stars with varying glitter status. */
   frame = atoi(argv[2]);
   for(i = 0; i < star_count; i++)
   {
      /* Glitter status is generated from user supplied frame number,
         with a divisor to extend the period so that the individual
         stars don't flicker too fast.

         To maximize variety, each star gets assigned a random phase
         based on a hash of its coordinates.  Alternatively, we could
         just use its index as the phase (since the stars are already
         shuffled), but because the visibility of each star could vary
         from frame to frame, there is no guarantee that the frame
         indices would be sufficiently stable for this purpose.        */
      j = (((HashPair(stars[i].x, stars[i].y) >> 4) + frame) / 5) % 4;
      if( j == 0 )
      {
         /* Remove black pixel. */
         memset(pixels + (stars[i].y * image.width + stars[i].x) * 2, 0, 2);
         continue;
      }

      if( j == 1 || j == 3 )
         continue;
      DrawPixel(&image, pixels, stars[i].x - 1, stars[i].y);
      DrawPixel(&image, pixels, stars[i].x + 1, stars[i].y);
      DrawPixel(&image, pixels, stars[i].x, stars[i].y - 1);
      DrawPixel(&image, pixels, stars[i].x, stars[i].y + 1);
   }

   /* Write output. */
   if( !png_image_write_to_stdio(&image, stdout, 0, pixels, 0, NULL) )
   {
      fputs("Error writing output\n", stderr);
      free(pixels);
      return 1;
   }
   free(pixels);
   return 0;
}
