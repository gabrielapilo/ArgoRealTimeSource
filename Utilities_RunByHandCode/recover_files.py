#COPYRIGHT CSIRO, FEBRUARY, 2018
# AUTHOR: Roger Scott (Roger.Scott@csiro.au)
#!/usr/bin/env python3

import sys
import os
import datetime
import re

class LogRecord:
    __slots__ = ['date', 'priority', 'name', 'data']
    def __init__(self, date, priority, name, data):
        self.date = date
        self.priority = priority
        self.name = name
        self.data = data

class LogFile:
    def __init__(self, filename):
        self.records = []
        with open(filename) as f:
            for line in f:
                try:
                    dt = datetime.datetime.strptime(line[0:22], '(%b %d %Y %H:%M:%S,')
                    mission_time = int(line[23:31])
                    name = line[36:55].strip()
                    data = line[56:].strip()
                except:
                    continue
                # Remove any trailing parentheses
                if '(' in name:
                    idx = name.index('(')
                    name = name[:idx]
                # Chop any data records at NUL's
                if chr(0) in data:
                    idx = data.index(chr(0))
                    data = data[:idx]
                    #logging.warning('NUL detected in log file')
                    print('NUL detected in log file')
                self.records.append(LogRecord(dt, -1, name, data))


if len(sys.argv) < 2:
    print('Usage: '+sys.argv[0]+' <rxlogfile>')
    sys.exit(1)

l = LogFile(sys.argv[1])
bfname = os.path.basename(sys.argv[1])

output = None

lp_r = re.compile('0x[0-9a-f]{2} 0x[0-9a-f]{2} 0x[0-9a-f]{2}  \[(.*)\]   0x[0-9a-f]{2} 0x[0-9a-f]{2}')

hex_r = re.compile('\[0x[0-9a-f]{2}\]')

for r in l.records:
    if r.name == 'rx':
        if r.data.startswith('cmd line: '):
            filename = r.data.split()[-1]
            dtstr = datetime.datetime.utcnow().strftime('%y%m%d_%H%M%S')
            output_filename = '%s_%s_from_%s' % (dtstr,filename,bfname)
            if output is not None:
                output.close()
            n = 1
            while os.path.exists(output_filename):
                output_filename = '%s_%s_from_%s.%d' % (dtstr,filename,bfname,n)
                n += 1
            output = open(output_filename,'w')
            print('Looks like we\'re trying to recover %s (writing to %s)' % (filename,output_filename))
    elif r.name == 'LogPacket':
        v = lp_r.split(r.data)
        assert len(v) == 3
        d = v[1]
        ds = hex_r.split(d)
        df = hex_r.findall(d)
        assert len(ds) == len(df)+1
        output.write(ds[0])
        for i in range(len(df)):
            if int(df[i][1:-1],16) != 0:
                output.write(chr(int(df[i][1:-1],16)))
            output.write(ds[i+1])
        #output.write('\n')
    # else skip it

# Check the last line to see if we can get anything more out of it...
if len(l.records) > 1:
    r = l.records[-1]
    if r.name == 'RxStartByte' and r.data.startswith('Sync error ['):
        d = r.data[12:]
        ds = hex_r.split(d)
        df = hex_r.findall(d)
        assert len(ds) == len(df)+1
        output.write(ds[0])
        print('Dumping:',ds[0])
        for i in range(len(df)):
            if int(df[i][1:-1],16) != 0:
                output.write(chr(int(df[i][1:-1],16)))
            output.write(ds[i+1])
            print('Dumping:',ds[i+1])

if output is not None:
    output.close()
