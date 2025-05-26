/* Given a center value surrounded by six neighbor values, where all values
   are 4 bits, is it possible to pick a center value such that:

      (center ^ neighbor) != 0x0 && (center ^ neighbor) != 0xf

   Intuitively, the answer should be yes, because for any fixed A, there are
   14 choices for X such at (A^X)!=0 and (A^X)!=15.  Now if we pick a second
   fixed B such that B!=A, there are also 14 choices to satisfy (B^X)!=0 and
   (B^X)!=15, 12 of which will overlap with the 14 choices for A.  In other
   words, we lose at most 2 choices for each neighbor.  There are only six
   neighbors, and 14-2*6=2, so we will always have at least 2 choices of X
   remaining.

   Instead of the intuition above, we can also just brute force through all
   (2**4)**6 possible neighbor values to see if we can pick a valid center,
   which is what this code does, and it only takes about one second to run.
   This code also collects some statistics, so that we know how lucky we
   need to be to pick a random center that would work.
*/

#include<stdio.h>

#define NEIGHBOR_COUNT 6

int main(int argc, char **argv)
{
   unsigned int center, neighbors, n;
   int i, choices, all_choices = 0, min_choices = 16;

   for(neighbors = 0; neighbors < (1 << (NEIGHBOR_COUNT * 4)); neighbors++)
   {
      choices = 0;
      for(center = 1; center < 15; center++)
      {
         for(i = 0; i < NEIGHBOR_COUNT; i++)
         {
            n = (neighbors >> (i * 4)) & 0xf;
            if( (center ^ n) == 0x0 || (center ^ n) == 0xf )
               break;
         }
         if( i == NEIGHBOR_COUNT )
            choices++;
      }
      all_choices += choices;

      if( min_choices > choices )
      {
         min_choices = choices;
         printf("%0*x: minimum = %d\n", NEIGHBOR_COUNT, neighbors, min_choices);
         if( min_choices == 0 )
            puts("Need more bits!");
      }
   }
   printf("Average = %.3f\n",
          (double)all_choices / (1 << (NEIGHBOR_COUNT * 4)));
   return 0;
}
