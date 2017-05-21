#################
## REQUIRED OS ##
#################
FROM debian:jessie



############
## LABELS ##
############
MAINTAINER Damien Graux



#####################
## NEEDED PACKAGES ##
#####################
RUN echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | \
    	 tee /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu trusty main" | \
       	 tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    apt-get update --fix-missing && \
    echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | debconf-set-selections && \
    apt-get install -y \
    	    oracle-java8-installer \
            git \
            make \
            autoconf \
            libtool \
	    pkg-config \ 
	    libncurses5-dev \ 
	    libreadline6-dev \
	    zlib1g-dev \
	    uuid-dev \
	    libxml2-dev \
	    libglib2.0-dev \
	    libraptor2-dev \
	    librasqal3-dev \
	    emacs \
	    build-essential \
	    debhelper \
	    autotools-dev \
	    autoconf \
	    automake \
	    unzip \
	    wget \
	    net-tools \
	    git \
	    libtool \
	    flex \
	    bison \
	    gperf \
	    gawk \
	    m4 \
	    libssl-dev \
	    libreadline-dev \
	    libreadline-dev \
	    openssl \
	    python-pip \
	    g++-multilib \
	    bc \
	    libboost-all-dev \
	    wamerican \		
    && apt-get clean \
    && pip install crudini \
    && rm -rf /var/lib/apt/lists/*



###########################
## SETTING THE WORKSPACE ##
###########################
# Ensure that bash is the default shell
ENV SHELL=/bin/bash
# create working directory
ADD ./sparub.sh /root/sparub/
#RUN cd /root && git clone https://github.com/tyrex-team/sparub.git
WORKDIR /sparub
#RUN git clone https://github.com/tyrex-team/sparqlgx.git



############
## 4STORE ##
############
# Set 4store SHA to a patched 1.1.6 version.
ENV COMMIT4STORE fe348295e0e20e1b2192dd08e3ef380d9750ff77
# Install 4store with github and clean up.
RUN git clone https://github.com/garlik/4store.git \
    && cd 4store \
    && git checkout ${COMMIT4STORE} \
    && ./autogen.sh \
    && ./configure \
    && make -j4 \
    && make install \
    && make clean \
    && cd ..
# Create directory for 4store logs
RUN mkdir /var/log/4store
#Expose 4s-boss default port
EXPOSE 6733



##############
## VIRTUOSO ##
##############
# Set Virtuoso commit SHA to Virtuoso 7.2.4 release (25/04/2016)
ENV VIRTUOSO_COMMIT 96055f6a70a92c3098a7e786592f4d8ba8aae214
# Get Virtuoso source code from GitHub and checkout specific commit
# Make and install Virtuoso (by default in /usr/local/virtuoso-opensource)
RUN git clone https://github.com/openlink/virtuoso-opensource.git \
    && cd virtuoso-opensource \
    && git checkout ${VIRTUOSO_COMMIT} \
    && ./autogen.sh \
    && CFLAGS="-O2 -m64" \
    && export CFLAGS \
    && ./configure --disable-bpel-vad \
       		   --enable-conductor-vad \
		   --disable-dbpedia-vad \
		   --disable-demo-vad \
		   --disable-isparql-vad \
		   --disable-ods-vad \
		   --disable-sparqldemo-vad \
		   --disable-syncml-vad \
		   --disable-tutorial-vad \
		   --with-readline \
		   --program-transform-name="s/isql/isql-v/" \
    && make -j4 \
    && make install \
    && ln -s /usr/local/virtuoso-opensource/var/lib/virtuoso/ /var/lib/virtuoso \
    && ln -s /var/lib/virtuoso/db /data \
    && cd ..
# Add Virtuoso bin to the PATH
ENV PATH /usr/local/virtuoso-opensource/bin/:$PATH
# Add Virtuoso config
ADD ./dockerfiles/virtuoso.ini /virtuoso.ini
# Add dump_nquads_procedure
ADD ./dockerfiles/dump_nquads_procedure.sql /dump_nquads_procedure.sql
# Add Virtuoso log cleaning script
ADD ./dockerfiles/clean-logs.sh /clean-logs.sh
# Add startup script
ADD ./dockerfiles/virtuoso.sh /virtuoso.sh
# Stuff.
VOLUME /data
EXPOSE 8890
EXPOSE 1111
# bash /virtuoso.sh --name test -p 8890:8890 -p 1111:1111 -e DBA_PASSWORD=myDbaPassword -e SPARQL_UPDATE=true -e DEFAULT_GRAPH=http://www.example.com/my-graph -v /my/path/to/the/virtuoso/db:/data -d tenforce/virtuoso



##########
## JENA ##
##########
# Update below according to https://jena.apache.org/download/
# and .sha1 from https://www.apache.org/dist/jena/binaries/
ENV JENA_SHA1 c055dbbe7d18e665adf757a713aa7fcdc4717c85
ENV JENA_VERSION 3.2.0
ENV JENA_MIRROR http://www.eu.apache.org/dist/
ENV JENA_ARCHIVE http://archive.apache.org/dist/
#WORKDIR /tmp
# sha1 checksum
RUN echo "$JENA_SHA1  jena.tar.gz" > jena.tar.gz.sha1
# Download/check/unpack/move in one go (to reduce image size)
RUN     wget -O jena.tar.gz $JENA_MIRROR/jena/binaries/apache-jena-$JENA_VERSION.tar.gz || \
        wget -O jena.tar.gz $JENA_ARCHIVE/jena/binaries/apache-jena-$JENA_VERSION.tar.gz && \
	sha1sum -c jena.tar.gz.sha1 && \
	tar zxf jena.tar.gz && \
	mv apache-jena* /jena && \
	rm jena.tar.gz* && \
	cd /jena && rm -rf *javadoc* *src* bat && \
	cd -
# Add to PATH
ENV PATH $PATH:/jena/bin



######################
## WATDIV BENCHMARK ##
######################
RUN wget "http://dsg.uwaterloo.ca/watdiv/watdiv_v06.tar" && \
    tar xvf watdiv_v06.tar && \
    rm watdiv_v06.tar && \
    cd watdiv/ && \
    make -j4 && \
    cd ./bin/Release && \
    ./watdiv -d ../../model/wsdbm-data-model.txt 1 | tr '\t' ' ' > dataset.nt && \
    for i in $(ls ../../testsuite/*.txt); do ./watdiv -q ../../model/wsdbm-data-model.txt $i 1 1 > $(basename $i) ; done



########################
## SP2BENCH BENCHMARK ##
########################
RUN mkdir sp2bench/ && \
    cd sp2bench/ && \
    wget "http://dbis.informatik.uni-freiburg.de/content/projects/SP2B/docs/sp2b-v1_01-full.tar.gz" && \
    tar zxvf sp2b-v1_01-full.tar.gz && \
    rm sp2b-v1_01-full.tar.gz && \
    cd sp2b/src/ && \
    for i in $(ls *.h); \
        do \
	   # It appears that some library are missing to compile SP2BENCH sources.
	   # This is a *dirty* hack to get rid of! ^^
    	   sed -i 's|\(#endif\)|#include <stdlib.h>\n#include <stdio.h>\n#include <string.h>\n\1|' $i ; \
	done && \
    make -j4



#########################
## PREPARING WORKSPACE ##
#########################
ADD ./dockerfiles/start-script.sh /root/.start-script.sh
ADD ./dockerfiles/generate-benchmarks.sh /root/generate-benchmarks.sh
RUN echo "\nbash /root/.start-script.sh\n" >> /root/.profile



#####################
## DEFAULT COMMAND ##
#####################
CMD ["/bin/bash","--login"]
