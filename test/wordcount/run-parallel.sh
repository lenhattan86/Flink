rm -rf *.out
dstat --time --cpu --disk --net --mem --output usage.csv & 
./run01.sh > run01.log &
wait
