import sys

if len(sys.argv) == 2:
	input = open(sys.argv[1], "rU")
	bytes = ''
	for line in input.read().split('\n'):
		if line[7:9] == "00":
			line = line[9:-2]
			for i in range(0, len(line), 2):
				bytes += chr(int("%s%s" % (line[i], line[i+1]), 16))
	result = "prog_uchar sketch[] PROGMEM = {"
	i = 0
	for byte in bytes:
		result += "0x"
		byte = "%x" % ord(byte)
		if len(byte) == 1:
			byte = "0%s" % byte
		result += byte
		i += 1
		if not i == len(bytes):
			result += ','
	result += '};\n'
	result += 'int sketchLength = %i;' % len(bytes)
	print
	print result
	print
else:
	print "usage:"
	print
	print "embed-arduino.py input.hex"
	print
	print "where input.hex is the file you wish to embed."
	print