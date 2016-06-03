# Start timming
#flink="../../build-target"
flink="../../flink-1.0.3"
rm -rf app02.log
rm -rf app02.debug.log
~/hadoop-2.7.0/bin/hadoop fs -rmr -skipTrash hdfs:///.../app02.out
sleep 30
for i in `seq 1 5`;
do
	rm -rf app02.out	
	date --rfc-3339=seconds >> app02.log
	# run the Flink app
	$flink/bin/flink run $flink/examples/batch/WordCount.jar --input hdfs:/// .../app02.txt --output hdfs:/// .../app02.out
	# Stop timming
	date --rfc-3339=seconds >> app02.log
	sleep 60
done
