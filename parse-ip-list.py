#!/usr/bin/env python3

import sys
# import re

n = len(sys.argv)

if (n != 2):
    sys.exit("The script expects only one parameter")

ipList = sys.argv[1].split(" ")

# To split dashes, I have yet to generate every ip on the range:
# ipList = re.split(', |-| ', sys.argv[1])

print("\nCreating an empty output text file...\n")
file = open("iplist.txt", "w")

print("\nWriting the resulting list:\n")

for ip in ipList:
    file.write("%s\n" % ip)
    print(ip)

print("\n")