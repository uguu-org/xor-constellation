/* Take rasterized output from world.svg and generate a tileset.

   ./assemble_tiles {input.png} {output.png}

   This tool generates an image with 96x32 tiles by copying&pasting 32x32
   cells from the input image.  The original 32x32 set of images would
   have been sufficient, but since we got memory to spare, pre-generating
   all combinations will simplify processing a bit.

   We ended up not using it because the tiles are too large, in that the
   chip+connection images maxes out at ~8 targets on screen, and player
   would only be able to see one step ahead if we aggressively scroll.
   Instead, we have gone with a more abstract set of targets that allows
   us to pack the targets at higher density.
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

#define OUTPUT_WIDTH    1536
#define OUTPUT_HEIGHT   1216

/* Copy rectangular region from input to output. */
static void CopyRegion(png_image *input_image, png_bytep input_pixels,
                       png_image *output_image, png_bytep output_pixels,
                       int sx, int sy, int tx, int ty, int w, int h)
{
   int i;

   if( sx < 0 || sy < 0 || tx < 0 || ty < 0 ||
       sx + w > (int)(input_image->width) ||
       sy + h > (int)(input_image->height) ||
       tx + w > (int)(output_image->width) ||
       ty + h > (int)(output_image->height) )
   {
      fprintf(stderr, "Bad region (%d,%d) -> (%d,%d), width=%d, height=%d\n",
              sx, sy, tx, ty, w, h);
      exit(EXIT_FAILURE);
   }

   for(i = 0; i < h; i++)
   {
      memcpy(output_pixels + ((ty + i) * output_image->width + tx) * 2,
             input_pixels + ((sy + i) * input_image->width + sx) * 2,
             w * 2);
   }
}

/* Copy tile regions. */
static void AssembleTiles(png_image *input_image, png_bytep input_pixels,
                          png_image *output_image, png_bytep output_pixels)
{
   int x, y, i;

   #define COPY(sx, sy, tx, ty, w, h) \
      CopyRegion(input_image, input_pixels, output_image, output_pixels, \
                 sx, sy, tx, ty, w, h)

   /* Chip backgrounds. */
   for(y = 0; y < 17 * 2; y++)
   {
      for(x = 0; x < 16; x++)
         COPY(0, 224, x * 96, y * 32, 96, 32);
   }

   /* 4bit chips. */
   for(i = 0; i < 2; i++)
   {
      for(x = 0; x < 16; x++)
         COPY(x * 32, i * 96, x * 96 + 16, i * 32, 32, 32);
   }

   /* 8bit chips. */
   for(y = 0; y < 16; y++)
   {
      for(i = 0; i < 2; i++)
      {
         for(x = 0; x < 16; x++)
         {
            COPY(y * 32, 32 + i * 96,
                 x * 96, 64 + i * 32 + y * 64,
                 32, 32);
            COPY(x * 32,      64 + i * 96,
                 x * 96 + 32, 64 + i * 32 + y * 64,
                 32, 32);
         }
      }
   }

   /* Top connectors. */
   for(x = 0; x < 4; x++)
   {
      for(i = 0; i < 2; i++)
         COPY(x * 192, 320 + i * 128, (x + i * 4) * 96, 1152, 96, 32);
   }

   /* Bottom connectors. */
   for(x = 0; x < 4; x++)
   {
      for(i = 0; i < 2; i++)
         COPY(x * 192, 256 + i * 128, (x + i * 4) * 96, 1184, 96, 32);
   }

   /* Middle connector extension. */
   COPY(0,   288, 768, 1152, 96, 32);
   COPY(384, 288, 768, 1184, 96, 32);

   #undef COPY
}

int main(int argc, char **argv)
{
   png_image input_image, output_image;
   png_bytep input_pixels, output_pixels;

   if( argc != 3 )
   {
      fprintf(stderr, "%s {input.png} {output.png}\n", *argv);
      return 1;
   }
   if( strcmp(argv[2], "-") == 0 && isatty(STDOUT_FILENO) )
   {
      fputs("Not writing output to stdout because it's a tty\n", stderr);
      return 1;
   }

   /* Set binary output. */
   #ifdef _WIN32
      setmode(STDIN_FILENO, O_BINARY);
      setmode(STDOUT_FILENO, O_BINARY);
   #endif

   /* Load input. */
   memset(&input_image, 0, sizeof(input_image));
   input_image.version = PNG_IMAGE_VERSION;
   if( strcmp(argv[1], "-") == 0 )
   {
      if( !png_image_begin_read_from_stdio(&input_image, stdin) )
      {
         fputs("Error reading stdin\n", stderr);
         return 1;
      }
   }
   else
   {
      if( !png_image_begin_read_from_file(&input_image, argv[1]) )
      {
         fprintf(stderr, "Error reading from %s\n", argv[1]);
         return 1;
      }
   }
   input_image.format = PNG_FORMAT_GA;
   input_pixels = (png_bytep)malloc(PNG_IMAGE_SIZE(input_image));
   if( input_pixels == NULL )
   {
      fputs("Out of memory", stderr);
      return 1;
   }
   if( !png_image_finish_read(&input_image, NULL, input_pixels, 0, NULL) )
   {
      free(input_pixels);
      return fprintf(stderr, "Error loading %s\n", argv[1]);
   }

   /* Prepare output. */
   memset(&output_image, 0, sizeof(output_image));
   output_image.version = PNG_IMAGE_VERSION;
   output_image.format = PNG_FORMAT_GA;
   output_image.width = OUTPUT_WIDTH;
   output_image.height = OUTPUT_HEIGHT;
   output_pixels = (png_bytep)calloc(PNG_IMAGE_SIZE(output_image), 1);
   if( output_pixels == NULL )
   {
      fputs("Out of memory", stderr);
      return 1;
   }

   /* Copy pixels. */
   AssembleTiles(&input_image, input_pixels, &output_image, output_pixels);
   free(input_pixels);

   /* Write output. */
   if( strcmp(argv[2], "-") == 0 )
   {
      if( !png_image_write_to_stdio(
              &output_image, stdout, 0, output_pixels, 0, NULL) )
      {
         fputs("Error writing to stdout\n", stderr);
         free(output_pixels);
         return 1;
      }
   }
   else
   {
      if( !png_image_write_to_file(
             &output_image, argv[2], 0, output_pixels, 0, NULL) )
      {
         fprintf(stderr, "Error writing %s\n", argv[2]);
         free(output_pixels);
         return 1;
      }
   }

   /* Success. */
   free(output_pixels);
   return 0;
}
