/* Find the smallest tile cells that can hold all non-transparent pixels.

   Usage:

      ./shrink_tiles {tile_width} {tile_height} {input.png}

   Reads from stdin if {input.png} is "-".

   Outputs 4 numbers to stdout: {width} {height} {x} {y}

   These define a tighter bounding box around each cell, and are meant to
   be used with crop_table.c
*/

#include<png.h>
#include<stdio.h>
#include<stdlib.h>
#include<string.h>
#include<unistd.h>

#ifdef _WIN32
   #include<fcntl.h>
   #include<io.h>
#endif

/* Find minimum Y value where at least one cell contains a nonempty pixel. */
static int FindTopEdge(png_image *image, png_bytep pixels, int h)
{
   int tile_y, x, y;
   png_bytep p;

   for(y = 0; y < h - 1; y++)
   {
      for(tile_y = 0; tile_y < (int)(image->height) / h; tile_y++)
      {
         /* Pixels are two bytes each, first byte is gray level and second
            byte is alpha level.  We only want to check the alpha part.    */
         p = pixels + (tile_y * h + y) * image->width * 2 + 1;
         for(x = 0; x < (int)(image->width); x++)
         {
            if( *p != 0 )
               return y;
            p += 2;
         }
      }
   }
   return y;
}

/* Find maximum Y where at least one cell contains a nonempty pixel. */
static int FindBottomEdge(png_image *image, png_bytep pixels, int h)
{
   int tile_y, x, y;
   png_bytep p;

   for(y = h - 1; y > 0; y--)
   {
      for(tile_y = 0; tile_y < (int)(image->height) / h; tile_y++)
      {
         p = pixels + (tile_y * h + y) * image->width * 2 + 1;
         for(x = 0; x < (int)(image->width); x++)
         {
            if( *p != 0 )
               return y;
            p += 2;
         }
      }
   }
   return y;
}

/* Find minimum X value where at least one cell contains a nonempty pixel. */
static int FindLeftEdge(png_image *image, png_bytep pixels, int w)
{
   int tile_x, x, y;
   png_bytep p;

   for(x = 0; x < w - 1; x++)
   {
      for(tile_x = 0; tile_x < (int)(image->width) / w; tile_x++)
      {
         p = pixels + (tile_x * w + x) * 2 + 1;
         for(y = 0; y < (int)(image->height); y++)
         {
            if( *p != 0 )
               return x;
            p += image->width * 2;
         }
      }
   }
   return x;
}

/* Find maximum X value where at least one cell contains a nonempty pixel. */
static int FindRightEdge(png_image *image, png_bytep pixels, int w)
{
   int tile_x, x, y;
   png_bytep p;

   for(x = w - 1; x > 0; x--)
   {
      for(tile_x = 0; tile_x < (int)(image->width) / w; tile_x++)
      {
         p = pixels + (tile_x * w + x) * 2 + 1;
         for(y = 0; y < (int)(image->height); y++)
         {
            if( *p != 0 )
               return x;
            p += image->width * 2;
         }
      }
   }
   return x;
}

int main(int argc, char **argv)
{
   int tile_width, tile_height, x0, y0, x1, y1;
   png_image image;
   png_bytep pixels;

   if( argc != 4 )
      return printf("%s {tile_width} {tile_height} {input.png}\n", *argv);

   tile_width = atoi(argv[1]);
   tile_height = atoi(argv[2]);
   if( tile_width < 1 || tile_height < 1 )
      return printf("Invalid tile size: %d, %d\n", tile_width, tile_height);

   /* Load input. */
   #ifdef _WIN32
      setmode(STDIN_FILENO, O_BINARY);
   #endif
   memset(&image, 0, sizeof(image));
   image.version = PNG_IMAGE_VERSION;
   if( strcmp(argv[3], "-") == 0 )
   {
      if( !png_image_begin_read_from_stdio(&image, stdin) )
      {
         puts("Error reading -");
         return 1;
      }
   }
   else
   {
      if( !png_image_begin_read_from_file(&image, argv[3]) )
         return printf("Error reading %s\n", argv[3]);
   }
   image.format = PNG_FORMAT_GA;
   if( (int)image.width % tile_width != 0 ||
       (int)image.height % tile_height != 0 )
   {
      return printf("Image dimension is not a multiple of (%d,%d): (%d,%d)\n",
                    tile_width, tile_height,
                    (int)image.width, (int)image.height);
   }

   pixels = (png_bytep)malloc(PNG_IMAGE_SIZE(image));
   if( pixels == NULL )
   {
      puts("Out of memory");
      return 1;
   }
   if( !png_image_finish_read(&image, NULL, pixels, 0, NULL) )
   {
      free(pixels);
      return printf("Error loading %s\n", argv[3]);
   }

   /* Determine cell dimensions. */
   y0 = FindTopEdge(&image, pixels, tile_height);
   y1 = FindBottomEdge(&image, pixels, tile_height);
   x0 = FindLeftEdge(&image, pixels, tile_width);
   x1 = FindRightEdge(&image, pixels, tile_width);

   /* Output results. */
   if( x1 <= x0 || y1 <= y0 )
   {
      puts("Input is completely blank.");
   }
   else
   {
      printf("%d %d %d %d\n", x1 - x0 + 1, y1 - y0 + 1, x0, y0);
   }
   free(pixels);
   return 0;
}
