#!/bin/bash

PATH_CMD=$(dirname $0)
PQ="0"
MaxTripleNumber=10000
OUTPATH="."
case "$1" in
    --print-query | -p )
	PQ="1"
	shift
	;;
    -o )
	shift
	OUTPATH="$1"
	if [ ! -d $OUTPATH ]; then mkdir $OUTPATH ; fi
	shift
	;;
    --max-triple-number )
	shift
	MaxTripleNumber=$1
	shift
	;;
    --help | -h )
	echo "Usage: bash $0 [[--help | -h]|[--print-query | -p]|[-o out_path/]|[--max-triple-number 1234]] path/to/dataset.nt [path/to/query.rq ... ]"
	exit 0
	;;
esac

if [[ $# -lt 1 ]];
then
    echo "Usage: bash $0 [[--help | -h]|[--print-query | -p]|[-o out_path/]|[--max-triple-number 1234]] path/to/dataset.nt [path/to/query.rq ... ]"
    exit 1
fi

dataset=$1 ; shift # The 'shift' to reach the query paths…

if [ ! -d "$OUTPATH/sparub-benchmark/" ]; then
    mkdir $OUTPATH/sparub-benchmark/
fi

### Various Counters.
nbquery=1  # The number of the future generated query.
nbstep=1   # The number of the future benchmark step.
bufquery=$nbquery # A buffer on the query number.
###

### Utils.
function isVar {
    # Usage: isVar string
    str1=$1
    if [[ ${str1:0:1} == "?" ]]; #|| [[ ${str1:0:1} == "\$" ]] ; 
    then echo 1 ; 
    else echo 0 ;
    fi
}
function transformVar {
    # Usage: transformVar number variable
    if [[ $(isVar "$2") == "1" ]];
    then echo "<http://tyrex.inria.fr/sparub/$2-$1>" ;
    else echo "$2" ;
    fi
}
function BGPtoTriples {
    # Usage: BGPtoTriples number query
    n="$1"; shift;
    flag=0
    shopt -s nocasematch
    while true; do
	case "$1" in
	    "where" | "where{" )
		flag=1
		shift
		;;
	    "{" ) shift ;;
            "" | "}" ) break ;;
	    * )
		if [[ $flag == 0 ]];
		then shift
		else 
                    # Warn: Strings as objects are currently NOT handled!
		    echo -e "$(transformVar $n $1) $(transformVar $n $2) $(transformVar $n $3) ."
		    if [[ $4 == "." ]];
		    then shift 4
		    else shift 3
		    fi
		fi
		;;
	esac
    done
    shopt -u nocasematch
}
###

(
echo -e "\t\t--SPARUB Steps--"
echo -e "\t\t================\n"

echo -e "I/ Init."
echo -e "--------"
# Number of triples.
NbTriples=$(cat $dataset | wc -l)
if [[ $NbTriples -lt 1000 ]];
then
    echo "The dataset you are using seems to small to generate a correct benchmark..."
    exit 1
fi
echo -e "$nbstep. Creation of whole the needed graphs." ; nbstep=$(($nbstep+1))
echo -e "CREATE GRAPH <http://tyrex.inria.fr/sparub/reference>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CREATE GRAPH <http://tyrex.inria.fr/sparub/fullGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CREATE GRAPH <http://tyrex.inria.fr/sparub/emptyGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "-->Run queries from q$bufquery.rq to q$((nbquery-1)).rq" ; bufquery=$nbquery
echo -e "\n"

echo -e "II/ Reference Run"
echo -e "-----------------"
echo -e "$nbstep. Run the initial benchmark to have reference times." ; nbstep=$(($nbstep+1))
echo -e "LOAD $dataset INTO GRAPH <http://tyrex.inria.fr/sparub/reference>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
for i in $@ ; do
    cp $i $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
done
echo -e "-->Run queries from q$bufquery.rq to q$((nbquery-1)).rq" ; bufquery=$nbquery
echo -e "Notice that you might add a 'FROM' clause in the SPARQL queries to specify the queried graph."
echo -e "\n"

echo -e "III/ Inserting and deleting pieces of data (and checking results)"
echo -e "-----------------------------------------------------------------"
OneTriple=$(head -n 1 $dataset | awk '{print "\t",$0}')
TwentyTriple=$(head -n 20 $dataset | awk '{print "\t",$0}')
FHTriple=$(head -n 500 $dataset | awk '{print "\t",$0}')
TenPerTriple=$(head -n $(($NbTriples/10)) $dataset | awk '{print "\t",$0}')
echo -e "$nbstep. Copying the reference graph." ; nbstep=$(($nbstep+1))
echo -e "COPY GRAPH <http://tyrex.inria.fr/sparub/reference> TO GRAPH <http://tyrex.inria.fr/sparub/fullGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. Dealing with one triple." ; nbstep=$(($nbstep+1))
echo -e "INSERT DATA { GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> { \n$OneTriple\n} }" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "DELETE DATA { GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> { \n$OneTriple\n} }" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. Dealing with twenty triples. (i.e. ≈$(echo "scale=2; (20*100)/$NbTriples" | bc -l)%)" ; nbstep=$(($nbstep+1))
echo -e "INSERT DATA { GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> { \n$TwentyTriple\n} }" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "DELETE DATA { GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> { \n$TwentyTriple\n} }" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. Dealing with 500 triples. (i.e. ≈$(echo "scale=2; (500*100)/$NbTriples" | bc -l)%)" ; nbstep=$(($nbstep+1))
echo -e "INSERT DATA { GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> { \n$FHTriple\n} }" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "DELETE DATA { GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> { \n$FHTriple\n} }" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. Dealing with $(($NbTriples/10)) triples. (i.e. ≈10%)" ; nbstep=$(($nbstep+1))
echo -e "INSERT DATA { GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> { \n$TenPerTriple\n} }" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "DELETE DATA { GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> { \n$TenPerTriple\n} }" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. Stress insertion..." ; nbstep=$(($nbstep+1))
for i in $(seq 0 19); do
    echo -e "INSERT DATA { GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> { \n$(echo "$TwentyTriple" | tail -n $((20-$i)) | head -n 1)\n} }" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
done
echo -e "-->Run queries from q$bufquery.rq to q$((nbquery-1)).rq" ; bufquery=$nbquery
echo -e "\n"

echo -e "IV/ Moving blocks from the initial dataset"
echo -e "------------------------------------------"
DistPred=$(awk '{a[$2]+=1}END{for( key in a) print a[key],key}' $dataset | sort -nr | head -n 1 | awk '{print $2}')
DistPredObj=$(awk '{a[$2," ",$3]+=1}END{for( key in a) print a[key],key}' $dataset | sort -nr | head -n 1 | awk '{print $2,$3}')
echo -e "$nbstep. Deleting triples dealing with the most common predicate." ; nbstep=$(($nbstep+1))
echo -e "WITH <http://tyrex.inria.fr/sparub/fullGraph>\nDELETE ?s $DistPred ?o WHERE {\n\t?s $DistPred ?o .\n}" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. Moving the triples related to the most represented couple (pred,obj)." ; nbstep=$(($nbstep+1))
echo -e "WITH <http://tyrex.inria.fr/sparub/fullGraph>\nDELETE ?s ?p ?o WHERE {\n\t?s $DistPredObj .\n\t?s ?p ?o .\n}" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
#echo -e "$nbstep. Renaming a list of elements" ; nbstep=$(($nbstep+1))
echo -e "-->Run queries from q$bufquery.rq to q$((nbquery-1)).rq" ; bufquery=$nbquery
echo -e "\n"

# We start splitting the initial dataset into the needed
# parts. Moreover, in order not to fill the disks and to limit the
# size of datasets involved, we consider an hard-coded limit in terms
# of triple number set at 10000 stored in the variable:
# $MaxTripleNumber. Obviously, it can be modified using the
# '--max-triple-number 123456' sequence in the command line.
echo -e "V/ Tradeoff between updating and loading again everything"
echo -e "---------------------------------------------------------"
if [[ $MaxTripleNumber -ge $NbTriples ]];
then 
    MaxTripleNumber="$NbTriples" ;
    echo -e "\$MaxTripleNumber was larger that the dataset set size, so:"
fi
echo -e "(\$MaxTripleNumber=$MaxTripleNumber)"
head -n $MaxTripleNumber $dataset > $OUTPATH/sparub-benchmark/dataset-100.nt
head -n $(($MaxTripleNumber/100)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-1.nt
tail -n $(($MaxTripleNumber - $MaxTripleNumber/100)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-99.nt
head -n $(($MaxTripleNumber/10)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-10.nt
tail -n $(($MaxTripleNumber - $MaxTripleNumber/10)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-90.nt
head -n $(($MaxTripleNumber/4)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-25.nt
tail -n $(($MaxTripleNumber - $MaxTripleNumber/4)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-75.nt
head -n $(($MaxTripleNumber/2)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-50.nt
head -n $(($MaxTripleNumber/4)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-25.nt
tail -n $(($MaxTripleNumber - $MaxTripleNumber/4)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-75.nt
head -n $(($MaxTripleNumber*4/5)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-80.nt
tail -n $(($MaxTripleNumber - $MaxTripleNumber*4/5)) $OUTPATH/sparub-benchmark/dataset-100.nt > $OUTPATH/sparub-benchmark/dataset-20.nt
# Reference.
echo -e "$nbstep. Reference time with 100% of \$MaxTripleNumber." ; nbstep=$(($nbstep+1))
echo -e "CREATE GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-100.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAR GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
# 1% update.
echo -e "$nbstep. With 1% of \$MaxTripleNumber. (i.e. $(($MaxTripleNumber/100)))" ; nbstep=$(($nbstep+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-99.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-1.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAR GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
# 10% update.
echo -e "$nbstep. With 10% of \$MaxTripleNumber. (i.e. $(($MaxTripleNumber/10)))" ; nbstep=$(($nbstep+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-90.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-10.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAR GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
# 25% update.
echo -e "$nbstep. With 25% of \$MaxTripleNumber. (i.e. $(($MaxTripleNumber/4)))" ; nbstep=$(($nbstep+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-75.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-25.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAR GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
# 50% update.
echo -e "$nbstep. With 50% of \$MaxTripleNumber. (i.e. $(($MaxTripleNumber/2)))" ; nbstep=$(($nbstep+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-50.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-50.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAR GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
# 80% update.
echo -e "$nbstep. With 80% of \$MaxTripleNumber. (i.e. $(($MaxTripleNumber*4/5)))" ; nbstep=$(($nbstep+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-20.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "LOAD $OUTPATH/sparub-benchmark/dataset-80.nt INTO GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAR GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "-->Run queries from q$bufquery.rq to q$((nbquery-1)).rq" ; bufquery=$nbquery
echo -e "\n"

echo -e "VI/ Impact of updates to evaluate queries"
echo -e "-----------------------------------------"
if [[ ! $# -eq 0 ]]; # We check the number of remaining arguments.
then
    set -f
    for i in $@; do # Loop on the remaining arguments.
	# Triples Generation related to the considered BGP.
	for j in $(echo "2 30 400"); do
	    for k in $(seq 1 $j); do
		BGPtoTriples $k $(cat $i) ;
	    done > $OUTPATH/sparub-benchmark/triples-$(basename "$i")-$j.nt ;
	done & # To speed up the process.
	# Query Generation.
	echo -e "$nbstep. Generating a scenario with [$i]."
	for j in $(echo "2 30 400"); do
	    nbsubstep=1
	    echo -e "    $nbstep-$nbsubstep. Adding $j sets of solutions."
	    echo -e "       Add $OUTPATH/sparub-benchmark/triples-$(basename "$i")-$j.nt"
	    echo -e "       Evaluate $i"
	    echo -e "       Remove $OUTPATH/sparub-benchmark/triples-$(basename "$i")-$j.nt"
	    nbsubstep=$(($nbsubstep+1))
	done
	nbstep=$(($nbstep+1))
    done
    wait
    set +f
    #echo -e "-->Run queries from q$bufquery.rq to q$((nbquery-1)).rq" ; 
    bufquery=$nbquery
else
    echo -e "There is no special scenario because no query was given..."
fi
echo -e "\n"

echo -e "VII/ Graph manipulations"
echo -e "------------------------"
# 1. We copy reference into fullgraph.
# 2. We move fullgraph into emptygraph.
# 3. We add emptygraph to fullgraph.
# => At the end reference, full graph and emptygraph should be the same.
echo -e "$nbstep. Setting up." ; nbstep=$(($nbstep+1))
echo -e "CLEAR GRAPH <http://tyrex.inria.fr/sparub/emptyGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAR GRAPH <http://tyrex.inria.fr/sparub/fullGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. COPY." ; nbstep=$(($nbstep+1))
echo -e "COPY GRAPH <http://tyrex.inria.fr/sparub/reference> TO GRAPH <http://tyrex.inria.fr/sparub/fullGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. MOVE." ; nbstep=$(($nbstep+1))
echo -e "MOVE GRAPH <http://tyrex.inria.fr/sparub/fullGraph> TO GRAPH <http://tyrex.inria.fr/sparub/emptyGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. ADD." ; nbstep=$(($nbstep+1))
echo -e "ADD GRAPH <http://tyrex.inria.fr/sparub/emptyGraph> TO GRAPH <http://tyrex.inria.fr/sparub/fullGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "-->Run queries from q$bufquery.rq to q$((nbquery-1)).rq" ; bufquery=$nbquery
echo -e "[optional] Check." ;
echo -e "Run the following SPARQL query on the three graph (reference,"
echo -e "fullGraph, emptyGraph) to check if the results are the same:"
echo -e "SELECT ?s ?p ?o FROM <...> WHERE { ?s ?p ?o . } ORDER BY ?s ?p ?o"
echo -e "\n"

echo -e "VIII/ Cleaning everything"
echo -e "-------------------------"
echo -e "$nbstep. Cleaning graphs." ; nbstep=$(($nbstep+1))
echo -e "CLEAN GRAPH <http://tyrex.inria.fr/sparub/reference>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAN GRAPH <http://tyrex.inria.fr/sparub/fullGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAN GRAPH <http://tyrex.inria.fr/sparub/emptyGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "CLEAR GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "$nbstep. Dropping graphs." ; nbstep=$(($nbstep+1))
echo -e "DROP GRAPH <http://tyrex.inria.fr/sparub/reference>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "DROP GRAPH <http://tyrex.inria.fr/sparub/fullGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "DROP GRAPH <http://tyrex.inria.fr/sparub/emptyGraph>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "DROP GRAPH <http://tyrex.inria.fr/sparub/subpart>" > $OUTPATH/sparub-benchmark/q$nbquery.rq ; nbquery=$(($nbquery+1))
echo -e "--> Run queries from q$bufquery.rq to q$((nbquery-1)).rq" ; bufquery=$nbquery
echo -e "\n"

if [[ $PQ -eq "1" ]];
then
    echo "Printing (one at a time) the generated queries:"
    for i in $(seq 1 $(($nbquery-1))); do
	echo ">>> q$i.rq <<<"
	if [[ $(cat $OUTPATH/sparub-benchmark/q$i.rq | wc -l) -ge 13 ]];
	then
	    head -n 10 $OUTPATH/sparub-benchmark/q$i.rq
	    echo -e "\t[. . .]"
	else
	    cat $OUTPATH/sparub-benchmark/q$i.rq
	fi
	echo ""
	read
    done
fi
) > $OUTPATH/sparub-benchmark/sparub-process.txt

echo "== SPARUB =="
echo "Evaluation process is available in '$OUTPATH/sparub-benchmark/sparub-process.txt'"
date "+DATE: %Y-%m-%d%nTIME: %T"
exit 0
