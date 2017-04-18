#!/bin/bash

################## example.sh ###################
#                                               #
# This script basically tests SPARUB. Thus, it: #
#  1. creates a test directory                  #
#  2. generates RDF triples                     #
#  3. outputs some SPARQL queries               #
#  +. provides their expected results           #
#  4. runs 'sparub.sh' on them                  #
#                                               #
# Note: the generated triples have not any      #
# sense, they are just here to show SPARUB! You #
# *definitely* should not use them to benchmark #
# your system...                                #
#                                               #
#################################################

RANDOM=0
CMD_PATH=$(dirname $0)

# A very very very dummy triple generator.
function generate_ntriple {
    nbT=$1
    nbP=$((1+($RANDOM % ($nbT/100))))
    base="http://tyrex.inria.fr/sparub/example/"
    i="1"
    s="1"
    while [[ $i -le $nbT ]]; do
	nbS=$((1+($RANDOM % 10))) # No more than 10 triples with the same subject in one time.
	for j in $(seq 1 $nbS); do
	    p="pred-$((1+($RANDOM % $nbP)))"
	    o="$((1+($RANDOM % $nbT)))" # Thereby, an object can be somewhere else a subject.
	    echo "<""$base$s""> <""$base$p""> <""$base$o""> ."
	done
	s=$(($s+1))    # increment the subject number.
	i=$(($i+$nbS)) # update the number of generated triples yet.
    done
}

# 1- Create or clean the output directory.
if [ ! -d "${CMD_PATH}/sparub-example/" ];
then
    mkdir ${CMD_PATH}/sparub-example/
else
    rm -rf ${CMD_PATH}/sparub-example/*
fi

# 2- Generate N-Triples file.
generate_ntriple 20000 > ${CMD_PATH}/sparub-example/generated.nt

# 3- Write some SPARQL queries.
echo "SELECT DISTINCT ?p WHERE { ?s ?p ?o . }" > ${CMD_PATH}/sparub-example/sparql01.rq
echo "SELECT ?s WHERE { ?s $(awk '{a[$2]+=1}END{for(key in a) print a[key],key}' ${CMD_PATH}/sparub-example/generated.nt | sort -nrk1,1 | head -n 1 | awk '{print $2}') ?o . }" > ${CMD_PATH}/sparub-example/sparql02.rq
echo "SELECT DISTINCT ?s WHERE { ?s ?p ?o . ?u ?v ?s . }" > ${CMD_PATH}/sparub-example/sparql03.rq

# +. Computes SPARQL results.
awk '{print $2}' ${CMD_PATH}/sparub-example/generated.nt | awk '!x[$0]++' > ${CMD_PATH}/sparub-example/sparql01.results ;
awk -v PRED=$(awk '{a[$2]+=1}END{for(key in a) print a[key],key}' ${CMD_PATH}/sparub-example/generated.nt | sort -nrk1,1 | head -n 1 | awk '{print $2}') '{if($2==PRED){print $1}}' ${CMD_PATH}/sparub-example/generated.nt > ${CMD_PATH}/sparub-example/sparql02.results ;
awk 'NR==FNR{a[$1]=$0;next} ($3) in a{print $3}' OFS=' ' ${CMD_PATH}/sparub-example/generated.nt ${CMD_PATH}/sparub-example/generated.nt | awk '!x[$0]++' > ${CMD_PATH}/sparub-example/sparql03.results ;

# 4- Run the SPARQL UPDATE Benchmark.
bash ${CMD_PATH}/sparub.sh -o ${CMD_PATH}/sparub-example ${CMD_PATH}/sparub-example/generated.nt ${CMD_PATH}/sparub-example/sparql01.rq ${CMD_PATH}/sparub-example/sparql02.rq ${CMD_PATH}/sparub-example/sparql03.rq

exit 0
