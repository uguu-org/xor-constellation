/* Crop tile table entries to reduce the amount of pixels around the border.

   Usage:

      ./crop_table {w0} {h0} {w1} {h1} {x} {y} < {old.png} > {new.png}

      {w0} {h0} = old tile size.
      {w1} {h1} = new tile size.
      {x} {y} = offset within the old tile cells
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

/* Shift the pixels in-place. */
static void CropTilesInPlace(png_image *image, png_bytep pixels,
                             int w0, int h0, int w1, int h1, int x, int y)
{
   int tile_x, tile_y, cell_y;
   png_bytep r, w = pixels;

   for(tile_y = 0; tile_y < (int)(image->height) / h0; tile_y++)
   {
      for(cell_y = 0; cell_y < h1; cell_y++)
      {
         for(tile_x = 0; tile_x < (int)(image->width) / w0; tile_x++)
         {
            r = pixels +
                2 * ((tile_y * h0 + cell_y + y) * image->width +
                     (tile_x * w0 + x));
            memmove(w, r, w1 * 2);
            w += w1 * 2;
         }
      }
   }
}

int main(int argc, char **argv)
{
   int w0, h0, w1, h1, x, y;
   png_image image;
   png_bytep pixels;

   /* Check input arguments. */
   if( argc != 7 )
   {
      fprintf(stderr,
              "%s {w0} {h0} {w1} {h1} {x} {y} < {old.png} > {new.png}\n",
              *argv);
      return 1;
   }

   w0 = atoi(argv[1]);
   h0 = atoi(argv[2]);
   w1 = atoi(argv[3]);
   h1 = atoi(argv[4]);
   x = atoi(argv[5]);
   y = atoi(argv[6]);
   if( w0 < 1 || h0 < 1 ||
       w1 < 1 || h1 < 1 ||
       x < 0 || y < 0 ||
       x + w1 > w0 || y + h1 > h0 )
   {
      fprintf(stderr, "Invalid crop parameters: %dx%d -> %dx%d+%d+%d\n",
              w0, h0, w1, h1, x, y);
      return 1;
   }

   /* Set binary output. */
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
   if( !png_image_begin_read_from_stdio(&image, stdin) )
   {
      fputs("Error reading input\n", stderr);
      return 1;
   }
   if( image.width % w0 != 0 || image.height % h0 != 0 )
   {
      fprintf(stderr,
              "Image dimension is not a multiple of (%d,%d): (%d,%d)\n",
              w0, h0, (int)image.width, (int)image.height);
      return 1;
   }

   image.format = PNG_FORMAT_GA;
   pixels = (png_bytep)malloc(PNG_IMAGE_SIZE(image));
   if( pixels == NULL )
   {
      fputs("Out of memory", stderr);
      return 1;
   }
   if( !png_image_finish_read(&image, NULL, pixels, 0, NULL) )
   {
      free(pixels);
      fputs("Error loading input\n", stderr);
      return 1;
   }

   /* Apply crop. */
   CropTilesInPlace(&image, pixels, w0, h0, w1, h1, x, y);
   image.width = (image.width / w0) * w1;
   image.height = (image.height / h0) * h1;

   /* Write output.  Here we set the flags to optimize for encoding speed
      rather than output size so that we can iterate faster.  This is fine
      since the output of this tool are intermediate files that are used
      only in the build process, and are not the final PNGs that will be
      committed.                                                           */
   image.flags |= PNG_IMAGE_FLAG_FAST;
   if( !png_image_write_to_stdio(&image, stdout, 0, pixels, 0, NULL) )
   {
      fputs("Error writing output\n", stderr);
      free(pixels);
      return 1;
   }

   free(pixels);
   return 0;
}
