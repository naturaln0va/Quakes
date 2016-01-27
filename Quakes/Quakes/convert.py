#! /usr/bin/env python
# converts a txt file in the format
#	AB, Some Value
# to
# 	<key>AB</key>
#	<string>Some Value</string>

import os

def main():
	fo = open("countrytocode.txt")
	print "Name of the file: ",fo.name, "\n"

	for line in fo:
		clean = line.strip('\n')
		replaced = clean.replace("&", "&amp;")
		comps = replaced.split(', ')
		print "<key>{!s}</key>".format(comps[1])
		print "<string>{!s}</string>".format(comps[0])

	fo.close()


if __name__ == '__main__':
    main()