#!/bin/bash

#
# Builds spark libraries and uploads them to HDFS
#

usage="\n
-c, --clean \t issue a clean build\n
-i, --install \t install to local mvn cache\n
-h, --help \t this usage information message\n"

# Defaults
ACTION="package"

# Parse command line arguments
for i in "$@"
do
case $i in
    -c | --clean)  
    CLEAN="clean"
    ;;
    
    -i | --install)  
    ACTION="install"
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

# Build jol library first so that it's latest in local repo. Current version is 0.15-SNAPSHOT
if [[ $CLEAN ]]; then
    # Rebuild jol only when clean build for spark is requested. Rebuilding it every time prevents 
    # incremental build for spark
    CFLAG='--clean' 
    bash $dir/../jol/build.sh $CFLAG --install
fi

# Increase memory to maven for faster build. Options depend on the available memory on the server.
hname=`hostname | cut -d"." -f1`
if [ $hname == "spark-29" ];then
    export MAVEN_OPTS="-Xms10240M -Xmx65536M -Xss512M -XX:MaxMetaspaceSize=10240M"
fi

# Build spark
pushd "$dir"
./build/mvn -Pyarn -Phive -Dhadoop.version=2.8.5 -DskipTests -Dmaven.test.skip=true $CLEAN $ACTION 
popd "$dir"

