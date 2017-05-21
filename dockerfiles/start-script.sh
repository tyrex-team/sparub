#!/bin/bash
###########################################################################
## A simple script that should be launched when starting the sparub      ##
## session after building the Dockerfile to give users some instruction. ##
###########################################################################
# Defining some colors in terminal.
RED='\033[0;31m'
GREEN='\033[0;32m'
BLACK='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'
# Printing the welcoming message.
echo -e "/--------------------------------------------------------------------------------\\"
echo -e "|                         ${BLUE}=== SPARUB Demonstrator ===${NC}"
echo -e "|"
echo -e "| ${GREEN}Overview:${NC}"
echo -e "|   The basic idea of this Docker image is to make reproducible simple usages\n|   of SPARUB -the SPARQL UPDATE Benchmark-."
echo -e "|"
echo -e "| ${GREEN}What to do?${NC}"
echo -e "|   This image contains several RDF triplestores already installed and ready to\n|   use and also various popular SPARQL benchmarks."
echo -e "|   Basically, this image allows to:"
echo -e "|      1. Run SPARUB using various benchmarks (e.g. WatDiv, SP2Bench) as seeds\n|      with ${RED}\`bash ~/generate-benchmarks.sh\`${NC}."
#echo -e "|      2. ${RED}\`bash ~/test-with-stores.sh\`${NC}."
echo -e "|"
echo -e "| ${GREEN}Credits:${NC}"
echo -e "|   Damien Graux, Tyrex Group, Inria"
echo -e "|   2017"
echo -e "\\--------------------------------------------------------------------------------/"
