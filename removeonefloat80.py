from __future__ import print_function
import sys
linestoskip = int(sys.argv[3])
with open(sys.argv[1], "r") as infile:
	indata = infile.read().split("\n")
with open(sys.argv[2], "w") as outfile:
	l = 0
	while l < len(indata):
		if "Float80" in indata[l]:
			l += linestoskip
			continue
		print(indata[l], file=outfile)
		l += 1
