# Start timming
date --rfc-3339=seconds
# run the Flink app
../../build-target/bin/flink run ../../build-target/examples/streaming/WordCount.jar --input file://`pwd`/hamlet.txt --output file://`pwd`/wordcount-result01.out
# Stop timming
date --rfc-3339=seconds
