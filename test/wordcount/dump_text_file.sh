sudo rm -rf /dev/app01.txt /dev/app02.txt
# download a text of a book
#wget -O book01.t http://www.gutenberg.org/files/52185/52185-0.txt
#wget -O book01.t http://www.textfiles.com/etext/NONFICTION/bacon-essays-92.txt
sudo cp book01.t /dev/app01.txt
# 14 -> 5.1GB = fileszie * (2^14)
# 13 -> 19M
# 12 -> 38
# 11 -> 19M
# 2 -> 
for i in {1..14}; do sudo cat /dev/app01.txt /dev/app01.txt > temp1.txt && sudo mv temp1.txt /dev/app01.txt; done

# download a text of a book
#wget -O book02.t http://www.gutenberg.org/files/52184/52184-0.txt
#wget -O book02.t http://www.textfiles.com/etext/NONFICTION/common_sense
sudo cp book02.t /dev/app02.txt
# 16 -> 6.1GB
# 14 -> 1.5G
# 12 -> 38M
# 11 -> 19M
# 2
for i in {1..16}; do sudo cat /dev/app02.txt /dev/app02.txt > temp2.txt && sudo mv temp2.txt /dev/app02.txt; done

~/hadoop-2.7.0/bin/hadoop fs -rmr -skipTrash hdfs:///.../app01.txt
~/hadoop-2.7.0/bin/hadoop fs -rmr -skipTrash hdfs:///.../app02.txt

sudo ~/hadoop-2.7.0/bin/hadoop fs -copyFromLocal /dev/app01.txt hdfs:///...
sudo ~/hadoop-2.7.0/bin/hadoop fs -copyFromLocal /dev/app02.txt hdfs:///...
