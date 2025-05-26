/* Convert PNG to black and white.

   Usage:

      ./random_dither {input.png} {output.png}

   Use "-" for input or output to read/write from stdin/stdout.

   Given a grayscale (8bit) plus alpha (8bit) PNG, output a black and
   white (1bit) plus transparency (1bit) PNG, by using input pixel level
   to probabilistically set the output bit.
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

static unsigned char Dither(int v)
{
   return (255.0f / RAND_MAX) * (float)rand() < v ? 255 : 0;
}

int main(int argc, char **argv)
{
   png_image image;
   png_bytep pixels, p;
   int x, y;

   if( argc != 3 )
      return printf("%s {input.png} {output.png}\n", *argv);
   if( strcmp(argv[2], "-") == 0 && isatty(STDOUT_FILENO) )
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
         puts("Error reading from stdin");
         return 1;
      }
   }
   else
   {
      if( !png_image_begin_read_from_file(&image, argv[1]) )
         return printf("Error reading %s\n", argv[1]);
   }
   image.format = PNG_FORMAT_GA;
   pixels = (png_bytep)malloc(PNG_IMAGE_SIZE(image));
   if( pixels == NULL )
   {
      puts("Out of memory");
      return 1;
   }
   if( !png_image_finish_read(&image, NULL, pixels, 0, NULL) )
   {
      free(pixels);
      return printf("Error loading %s\n", argv[1]);
   }

   /* Use fixed seed for deterministic output. */
   srand(1);

   /* Dither pixels. */
   p = pixels;
   for(y = 0; y < (int)image.height; y++)
   {
      for(x = 0; x < (int)image.width; x++, p += 2)
      {
         /* Dither color and alpha independently. */
         *p = Dither((int)*p);
         *(p + 1) = Dither((int)*(p + 1));

         /* Set color part to zero if alpha is zero. */
         if( *(p + 1) == 0 )
            *p = 0;
      }
   }

   /* Write output.  Here we set the flags to optimize for encoding speed
      rather than output size so that we can iterate faster.  This is fine
      since the output of this tool are intermediate files that are used
      only in the build process, and are not the final PNGs that will be
      committed.                                                           */
   image.flags |= PNG_IMAGE_FLAG_FAST;
   x = 0;
   if( strcmp(argv[2], "-") == 0 )
   {
      if( !png_image_write_to_stdio(&image, stdout, 0, pixels, 0, NULL) )
      {
         fputs("Error writing to stdout\n", stderr);
         x = 1;
      }
   }
   else
   {
      if( !png_image_write_to_file(&image, argv[2], 0, pixels, 0, NULL) )
      {
         printf("Error writing %s\n", argv[2]);
         x = 1;
      }
   }
   free(pixels);
   return x;
}
