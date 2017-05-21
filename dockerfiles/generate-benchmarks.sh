#!/bin/bash

# Init.
mkdir /root/watdiv
mkdir /root/sp2bench

# WatDiv
for param in $(echo "1 20 100"); do
    echo "------------------------------" >> ~/results.txt
    echo "------------------------------" >> ~/results.txt
    echo "param=$param" >> ~/results.txt
    echo "dataset" >> ~/results.txt
    mkdir /root/watdiv/$param
    cd /sparub/watdiv/bin/Release/
    time (./watdiv -d ../../model/wsdbm-data-model.txt $param | tr '\t' ' ' > /root/watdiv/$param/watdiv-dataset-$param.nt) 2>> ~/results.txt
    wc -l /root/watdiv/$param/watdiv-dataset-$param.nt >> ~/results.txt
    du -h /root/watdiv/$param/watdiv-dataset-$param.nt >> ~/results.txt
    echo "queries" >> ~/results.txt
    time (for i in $(ls ../../testsuite/*.txt); do
	./watdiv -q ../../model/wsdbm-data-model.txt $i 1 1 > /root/watdiv/$param/watdiv-dataset-$param-query-$(basename $i) ;
    done) 2>> ~/results.txt
    cd /root/watdiv/$param/
    echo "sparub" >> ~/results.txt
    time (bash /root/sparub/sparub.sh /root/watdiv/$param/watdiv-dataset-$param.nt) 2>> ~/results.txt
    du -sh ./sparub-benchmark/ >> ~/results.txt
    echo "" >> ~/results.txt
done

# SP2Bench
for param in $(echo "100000 2000000 10000000"); do
    echo "------------------------------" >> ~/results.txt
    echo "------------------------------" >> ~/results.txt
    echo "param=$param" >> ~/results.txt
    echo "dataset" >> ~/results.txt
    mkdir /root/sp2bench/$param
    cd /sparub/sp2bench/sp2b/src/
    time (/sparub/sp2bench/sp2b/src/sp2b_gen -t $param) 2>> ~/results.txt
    mv sp2b.n3 /root/sp2bench/$param/dataset.n3
    wc -l /root/sp2bench/$param/dataset.n3 >> ~/results.txt
    du -h /root/sp2bench/$param/dataset.n3 >> ~/results.txt
    cd /root/sp2bench/$param/
    echo "queries" >> ~/results.txt
    time (cp /sparub/sp2bench/sp2b/queries/* .) 2>> ~/results.txt
    echo "sparub" >> ~/results.txt
    time (bash /root/sparub/sparub.sh /root/sp2bench/$param/dataset.n3) 2>> ~/results.txt
    du -sh ./sparub-benchmark/ >> ~/results.txt
    echo "" >> ~/results.txt
done
