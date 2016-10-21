#!/usr/bin/env python
import os
import sys

gq_val = '20'
if len(sys.argv) > 1:
    gq_val = sys.argv[1]

for line in sys.stdin:
    print line,
    if line[0:6] == '#CHROM': break

for line in sys.stdin:
    vals = line.strip('\r\n').split('\t')
    format_codes = vals[8].split(':')

    for i in xrange(9,len(vals)):
        if vals[i] == '.':
            fields = []
            for j in xrange(0,len(format_codes)):
                if format_codes[j] == 'GT':
                    fields.append('0/0')
                elif format_codes[j] == 'GQ':
                    fields.append(gq_val)
                else:
                    fields.append('.')
            vals[i] = ':'.join(fields)
        else:
            missing = False
            fields = vals[i].split(':')
            for j in xrange(0,len(fields)):
                if format_codes[j] == 'GT':
                    if fields[j] == './.':
                        fields[j] = '0/0'
                        missing = True
                    elif fields[j] == '.|.':
                        fields[j] = '0|0'
                        missing = True
            if missing == True:
                for j in xrange(0,len(fields)):
                    if format_codes[j] == 'GQ': fields[j] = gq_val
            
            vals[i] = ':'.join(fields)
    
    print '\t'.join(vals)

