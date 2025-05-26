#!/usr/bin/ruby -w
# Generate all permutations of [0..5]

print "PERMUTATIONS6 =\n{\n"
count = 0
[0, 1, 2, 3, 4, 5].permutation().each{|p|
   print "\t{", (p * ", "), "},\n"
   count += 1
}
print "}\n",
      "PERMUTATIONS6_COUNT = #{count}\n"
