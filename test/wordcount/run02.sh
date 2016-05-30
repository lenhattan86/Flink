# Start timming
rm -rf *.out
date --rfc-3339=seconds
# run the Flink app
../../build-target/bin/flink run ../../build-target/examples/streaming/WordCount.jar --input file://`pwd`/text5.1GB.txt --output file://`pwd`/wordcount-result01.out
# Stop timming
date --rfc-3339=seconds
