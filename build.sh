#!/bin/bash

#
# Builds spark libraries and uploads them to HDFS
#

usage="\n
-r, --rebuild \t issue a clean build\n
-h, --help \t this usage information message\n"

# Parse command line arguments
for i in "$@"
do
case $i in
    -r | --REBUILD)  
    CLEAN="clean"
    ;;

    -h | --help)
        echo -e $usage
        exit
        ;;

    *)                  # unknown option
    echo "Unkown Option: $i"
    echo -e $usage
    exit
    ;;
esac
done


dir=$(dirname "$0")
dir=$(realpath "$dir")

# Stop history server, it interferes with the build process
$dir/sbin/stop-history-server.sh

# Build spark
$dir/build/mvn -Pyarn -Dhadoop.version=2.8.5 -DskipTests $CLEAN package 

# Install packages to local maven repo
$dir/build/mvn install

# Upload jars to HDFS
# TODO
