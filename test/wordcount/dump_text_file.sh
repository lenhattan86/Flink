rm -rf app01.txt app02.txt
# download a text of a book
#wget -O book01.t http://www.gutenberg.org/files/52185/52185-0.txt
#wget -O book01.t http://www.textfiles.com/etext/NONFICTION/bacon-essays-92.txt
cp book01.t app01.txt
# 14 -> 5.1GB = fileszie * (2^14)
# 13 -> 19M
# 12 -> 38
# 11 -> 19M
# 2 -> 
for i in {1..10}; do cat app01.txt app01.txt > temp1.txt && mv temp1.txt app01.txt; done

# download a text of a book
#wget -O book02.t http://www.gutenberg.org/files/52184/52184-0.txt
#wget -O book02.t http://www.textfiles.com/etext/NONFICTION/common_sense
cp book02.t app02.txt
# 16 -> 6.1GB
# 14 -> 1.5G
# 12 -> 38M
# 11 -> 19M
# 2
for i in {1..11}; do cat app02.txt app02.txt > temp2.txt && mv temp2.txt app02.txt; done

