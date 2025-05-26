/* Erase every other scanline from image.

   Usage:

      ./horizontal_stripes < {input1.png} > {output.png}
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

int main(int argc, char **argv)
{
   png_image image;
   png_bytep pixels;
   int y;

   if( argc != 1 )
      return printf("%s < {input.png} > {output.png}\n", *argv);

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
      fputs("Read error\n", stderr);
      return 1;
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
      fputs("Load error\n", stderr);
      return 1;
   }

   /* Remove every other line. */
   for(y = 1; y < (int)(image.height); y += 2)
      memset(pixels + y * image.width * 2, 0, image.width * 2);

   /* Write output.  Here we set the flags to optimize for encoding speed
      rather than output size so that we can iterate faster.  This is fine
      since the output of this tool are intermediate files that are used
      only in the build process, and are not the final PNGs that will be
      committed.                                                           */
   image.flags |= PNG_IMAGE_FLAG_FAST;
   if( !png_image_write_to_stdio(&image, stdout, 0, pixels, 0, NULL) )
   {
      fputs("Write error\n", stderr);
      return 1;
   }

   free(pixels);
   return 0;
}
