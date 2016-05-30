# download a text of a book
wget -O temp.txt http://www.gutenberg.org/files/52185/52185-0.txt
# 14 -> 5.1GB = fileszie * (2^14)
# 10 -> 5.1GB
for i in {1..10}; do cat temp.txt temp.txt > temp2.txt && mv temp2.txt temp.txt; done
mv temp.txt text01.txt

# download a text of a book
wget -O temp.txt http://www.gutenberg.org/files/52184/52184-0.txt
# 16 -> 6.1GB
# 10 -> 
for i in {1..10}; do cat temp.txt temp.txt > temp2.txt && mv temp2.txt temp.txt; done
mv temp.txt text02.txt
