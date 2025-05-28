/* This program uses brute force simulation to try to answer the question:
   What's the chance of a player completing a chain when playing randomly?

   Naively, the probably should be 2/16 for 4 bit modes and 2/256 for 8 bit
   modes, assuming a random starting position and a random neighbor with the
   right bits.  But this assumes that numbers are evenly distributed, which
   is not how we generated the target numbers.  So what happens if we take
   the generation process into account?  That's what this tool is trying to
   do.

   Intuitively, the numbers will converge on 2/16 and 2/256, because despite
   generating numbers with only limited number of bits set, a multi-step
   expansion will cause those numbers to resemble even distributions.  For
   example, these should turn out to be roughly equal:

   + A random 4-bit number with up to 4 one bits set.
   + XOR of four random 4-bit numbers, each with up to 1 one bit set.

   But we can just run those numbers and see what happens.  What we find is
   that the numbers converge at slightly higher than 2/16 in 4bit modes,
   while converging at much lower than 2/256 in 8bit modes:

   + Level 1: 0.13370841
   + Level 2: 0.13944977
   + Level 3: 0.13333332
   + Level 4: 0.12499999
   + Level 5: 0.00683478
   + Level 6: 0.00708700
   + Level 7: 0.00726962
   + Level 8: 0.00724638
*/

#include<inttypes.h>
#include<stdio.h>

#include<map>
#include<utility>
#include<vector>

namespace {

// Odds of getting an all-zero target.
static constexpr int kOddsOfAllZeroes = 13;

// Level definitions.  See generate_bit_table.pl.
typedef struct
{
   int width;        // Bit width.
   int max_bits;     // Maximum number of bits set.
} LevelInfo;

static constexpr LevelInfo kLevels[8] =
{
   {4, 1}, {4, 2}, {4, 3}, {4, 4},
   {8, 1}, {8, 2}, {8, 5}, {8, 8},
};

// List of value candidates for a single level.
using ValueList = std::vector<int>;

// Pair of result counts: (accepted, total).
using SimulationResult = std::pair<uint64_t, uint64_t>;

// Memoized result for each (start, depth).
using MemoizedResult = std::map<std::pair<int, int>, SimulationResult>;

// Count number of bits set.
static int BitCount(int x)
{
   x = (x & 0x55) + ((x >> 1) & 0x55);
   x = (x & 0x33) + ((x >> 2) & 0x33);
   x = (x & 0x0f) + ((x >> 4) & 0x0f);
   return x;
}

// Generate list of value candidates for a single level.
static ValueList GenerateBitTable(const LevelInfo &level)
{
   ValueList r;

   for(int i = 0; i < (1 << level.width); i++)
   {
      if( BitCount(i) <= level.max_bits )
         r.push_back(i);
   }

   const int zero_padding = static_cast<int>(r.size() / (kOddsOfAllZeroes - 1));
   for(int i = 0; i < zero_padding; i++)
      r.push_back(0);

   return r;
}

// Get results for chains up to a certain depth.
//
// This function answers the question: given a fixed starting position,
// how many expansions from this position will result in a completed chain?
static const SimulationResult &SimulateRecursive(const ValueList &values,
                                                 int all_ones,
                                                 int start,
                                                 int depth,
                                                 MemoizedResult *cache)
{
   std::pair<MemoizedResult::iterator, bool> p = cache->insert(
      std::make_pair(std::make_pair(start, depth), SimulationResult()));
   if( !p.second )
      return p.first->second;

   SimulationResult r = {0, 0};

   for(int i : values)
   {
      if( (start ^ i) == 0 || (start ^ i) == all_ones )
      {
         r.first++;
         r.second++;
      }
      else
      {
         if( depth > 0 )
         {
            const SimulationResult &r1 = SimulateRecursive(
               values, all_ones, start ^ i, depth - 1, cache);
            r.first += r1.first;
            r.second += r1.second;
         }
         else
         {
            r.second++;
         }
      }
   }
   p.first->second = r;
   return p.first->second;
}

// For all starting positions, count number acceptable outcomes when
// traversing up to depth number of steps.
//
// This function answers the question: for all starting positions, how many
// expansions from those positions will result in a completed chain?
static SimulationResult SimulateStep(const ValueList &values,
                                     int all_ones,
                                     int depth,
                                     MemoizedResult *cache)
{
   SimulationResult r = {0, 0};

   // Try all starting values except those with all zero or one bits.
   for(int i = 1; i < all_ones; i++)
   {
      const SimulationResult &r1 =
         SimulateRecursive(values, all_ones, i, depth, cache);
      r.first += r1.first;
      r.second += r1.second;
   }
   return r;
}

// Print formatted result to stdout.
static void PrintResult(const SimulationResult &r)
{
   printf("%" PRIu64 " / %" PRIu64 " = %.8f\n",
          r.first, r.second,
          static_cast<double>(r.first) / static_cast<double>(r.second));
}

}  // namespace

int main(int argc, char **argv)
{
   for(int level = 0; level < 8; level++)
   {
      const ValueList values = GenerateBitTable(kLevels[level]);
      const int all_ones = (1 << kLevels[level].width) - 1;
      printf("Level %d, %d values:\n",
             level + 1, static_cast<int>(values.size()));

      MemoizedResult cache;
      for(int depth = 0; depth < 6; depth++)
      {
         printf("   Step(%d): ", depth);
         PrintResult(SimulateStep(values, all_ones, depth, &cache));
      }
   }
   return 0;
}
