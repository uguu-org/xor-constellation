/* Composite a series of same-size black-and-white PNGs into a single image.

   Usage:

      ./stack_bw {input1.png} {input2.png} ... > {output.png}

   This can be done with ImageMagick, but the command line options for
   compositing more than two images is cumbersome, which is why we
   have this tool.
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
   png_image image, add_image;
   png_bytep pixels, add_pixels, r, w;
   int i, j;

   if( argc == 1 )
      return fprintf(stderr, "%s {input.png} ... > {output.png}\n", *argv);
   if( isatty(STDOUT_FILENO) )
   {
      fputs("Not writing output to stdout because it's a tty\n", stderr);
      return 1;
   }

   #ifdef _WIN32
      setmode(STDOUT_FILENO, O_BINARY);
   #endif

   /* Load first input. */
   memset(&image, 0, sizeof(image));
   image.version = PNG_IMAGE_VERSION;
   if( !png_image_begin_read_from_file(&image, argv[1]) )
      return fprintf(stderr, "%s: read error\n", argv[1]);

   image.format = PNG_FORMAT_GA;
   pixels = (png_bytep)malloc(PNG_IMAGE_SIZE(image));
   add_pixels = (png_bytep)malloc(PNG_IMAGE_SIZE(image));
   if( pixels == NULL || add_pixels == NULL )
   {
      fputs("Out of memory\n", stderr);
      return 1;
   }
   if( !png_image_finish_read(&image, NULL, pixels, 0, NULL) )
      return fprintf(stderr, "%s: load error\n", argv[1]);

   /* Load and composite subsequent images. */
   for(i = 2; i < argc; i++)
   {
      memset(&add_image, 0, sizeof(add_image));
      add_image.version = PNG_IMAGE_VERSION;
      if( !png_image_begin_read_from_file(&add_image, argv[i]) )
         return fprintf(stderr, "%s: read error\n", argv[i]);
      if( add_image.width != image.width || add_image.height != image.height )
      {
         return fprintf(stderr, "%s: size mismatch (%d,%d), expected (%d,%d)\n",
                       argv[i],
                       (int)(add_image.width), (int)(add_image.height),
                       (int)(image.width), (int)(image.height));
      }

      add_image.format = PNG_FORMAT_GA;
      if( !png_image_finish_read(&add_image, NULL, add_pixels, 0, NULL) )
         return fprintf(stderr, "%s: load error\n", argv[i]);

      r = add_pixels;
      w = pixels;
      for(j = 0; j < (int)(image.width * image.height); j++)
      {
         if( r[1] == 0xff )
         {
            /* Overlay pixel is opaque, so we will take its pixel value
               unconditionally.  This only works because we assert that
               all input images are black and white, so we don't need to
               do any fancy calculations with opacity.                   */
            *w++ = *r++;
            *w++ = *r++;
         }
         else
         {
            /* Overlay pixel is transparent.  Leave underlay pixel untouched. */
            w += 2;
            r += 2;
         }
      }
   }

   /* Write output.  Here we set the flags to optimize for encoding speed
      rather than output size so that we can iterate faster.  This is fine
      since the output of this tool are intermediate files that are used
      only in the build process, and are not the final PNGs that will be
      committed.                                                           */
   image.flags |= PNG_IMAGE_FLAG_FAST;
   if( !png_image_write_to_stdio(&image, stdout, 0, pixels, 0, NULL) )
   {
      fputs("Error writing to stdout\n", stderr);
      return 1;
   }

   free(pixels);
   free(add_pixels);
   return 0;
}
