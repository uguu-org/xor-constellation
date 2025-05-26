/* Generate a set of star tiles. */

#include<png.h>
#include<stdio.h>
#include<stdlib.h>
#include<string.h>

/* Size of each star tile. */
#define TILE_SIZE       32

/* Number of star variations.  Each tile will contain exactly one star. */
#define TILE_COUNT      ((TILE_SIZE - 2) / 3)

/* Output image dimensions. */
#define IMAGE_WIDTH     (TILE_COUNT * TILE_SIZE * 2)
#define IMAGE_HEIGHT    TILE_SIZE

/* Coordinate of a single star within a tile. */
typedef struct
{
   int x, y;
} XY;

/* Draw a white opaque rectangle. */
static void Rect(png_image *image, png_bytep pixels, int x, int y, int w, int h)
{
   int i;

   for(i = 0; i < h; i++)
      memset(pixels + ((y + i) * image->width + x) * 2, 0xff, w * 2);
}

int main(int argc, char **argv)
{
   XY stars[TILE_COUNT];
   int i, j, t;
   png_image image;
   png_bytep pixels;

   if( argc != 2 )
      return printf("%s {output.png}\n", *argv);

   /* Allocate output image and fill it with blank pixels. */
   memset(&image, 0, sizeof(image));
   image.version = PNG_IMAGE_VERSION;
   image.flags |= PNG_IMAGE_FLAG_FAST;
   image.format = PNG_FORMAT_GA;
   image.width = IMAGE_WIDTH;
   image.height = IMAGE_HEIGHT;
   pixels = (png_bytep)calloc(PNG_IMAGE_SIZE(image), 1);
   if( pixels == NULL )
   {
      puts("Out of memory");
      return 1;
   }

   /* Use deterministic seed. */
   srand(1);

   /* Assign coordinates to each star so that there is no overlap in
      rows or columns.  The coordinates are separated by 3 pixels to
      account for the cross shapes.                                  */
   for(i = 0; i < TILE_COUNT; i++)
      stars[i].x = stars[i].y = 1 + i * 3;

   /* Shuffle tile coordinates by component, so that the stars are
      not aligned along the x=y diagonals.                         */
   #define SHUFFLE(component) \
      for(i = TILE_COUNT - 1; i > 0; i--)                            \
      {                                                              \
         j = (int)((double)i * (double)rand() / (double)RAND_MAX);   \
         t = stars[i].component;                                     \
         stars[i].component = stars[j].component;                    \
         stars[j].component = t;                                     \
      }
   SHUFFLE(x)
   SHUFFLE(y)
   #undef SHUFFLE

   /* Generate two variations for each star. */
   for(i = 0; i < TILE_COUNT; i++)
   {
      /* Small dot. */
      Rect(&image, pixels, i * 2 * TILE_SIZE + stars[i].x, stars[i].y, 1, 1);

      /* Cross. */
      Rect(&image, pixels,
           (i * 2 + 1) * TILE_SIZE + stars[i].x - 1, stars[i].y, 3, 1);
      Rect(&image, pixels,
           (i * 2 + 1) * TILE_SIZE + stars[i].x, stars[i].y - 1, 1, 3);
   }

   /* Write output. */
   if( !png_image_write_to_file(&image, argv[1], 0, pixels, 0, NULL) )
   {
      printf("Error writing %s\n", argv[1]);
      free(pixels);
      return 1;
   }
   free(pixels);
   return 0;
}
