SPARUB
======

> The SPARQL UPDATE Benchmark generator.

Description
-----------

__SPARUB__ is a simple tool to generate additional scenarios of test
from an already existing N-Triples dataset and some
[SPARQL](https://www.w3.org/TR/sparql11-query/) queries while focusing
on the [SPARQL UPDATE](https://www.w3.org/TR/sparql11-update/)
fragment (which is part of SPARQL 1.1). It simply extends already
existing benchmarking methods taking an
[RDF](https://www.w3.org/TR/2004/REC-rdf-primer-20040210/) dataset and
(optionally) SPARQL queries to provide a complete scenario of
test. Moreover, a list of predefined metrics is also available to
extract interesting figures of the tests.

Technically, __SPARUB__ is a bash script `sparub.sh` which takes a
triple file and an optional list of SPARQL queries as arguments. It
will then generate a scenario divided into several steps to benchmark
an RDF storage system allowing the SPARQL evaluation on the various
functionalities of the SPARQL UPDATE standard extension.

To have an idea of what is going one, you can run `bash example.sh`
and get a very basic scenario. Furthermore, a complete testing
environment is also available under a reproducible context thanks to
[docker](https://www.docker.com/): an image (see `Dockerfile`) can
be built with `docker build -t sparub .` and then run (with various
pre-installed state-of-the-art evaluators and popular benchmarks) with
`docker run -it sparub`.

A basic man page is also available: `man ./manual.troff` and more
details are written in `details.txt`.

License
-------

This project is under the [CeCILL](http://www.cecill.info/index.en.html) license.

