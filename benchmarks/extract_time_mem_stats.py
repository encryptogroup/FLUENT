#!/usr/bin/env python

import os.path
import re
import statistics
import sys

if (len(sys.argv) < 2):
    print("Usage: %s [file...]" % sys.argv[0], file=sys.stderr)
    sys.exit(1)

if (os.path.exists("stats.csv") == False):
    print("New Stat File")
    stat_file = open('stats.csv','w')
    stat_file.write("file,setup_time_mean,setup_time_stdev,online_time_mean,online_time_stdev,comm_setup,conn_online,runs\n")
else:
    stat_file = open('stats.csv','a')

for file_path in sys.argv[1:]:
    print("file:", file_path, file=sys.stderr)

    with open(file_path) as file_stream:
        detected_runs = len([line for line in file_stream if line.startswith("Evaluating Universal circuit")])
        print("runs:", detected_runs, file=sys.stderr)

        file_stream.seek(0)
        setup_stats = [line for line in file_stream if line.startswith("Setup time / comm")]
        file_stream.seek(0)
        online_stats = [line for line in file_stream if line.startswith("Online time / comm")]

        setup_time_mean = statistics.mean([float(line.split()[4]) for line in setup_stats])
        setup_time_stdev = statistics.stdev([float(line.split()[4]) for line in setup_stats])

        online_time_mean = statistics.mean([float(line.split()[4]) for line in online_stats])
        online_time_stdev = statistics.stdev([float(line.split()[4]) for line in online_stats])

        setup_comm = [int(line.split()[7]) for line in setup_stats][0]

        online_comm = [int(line.split()[7]) for line in online_stats][0]

        stat_file.write(",".join(map(str, [file_path,setup_time_mean,setup_time_stdev,online_time_mean,online_time_stdev,setup_comm,online_comm,detected_runs])))
        stat_file.write('\n')

stat_file.close()
