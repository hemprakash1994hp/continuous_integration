#!/bin/bash
CWD=$(pwd)
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $DIR
git pull
cd $CWD

PACKAGE="--all"
DEPENDENCIES=""

for i in "$@"
do
case $i in
    -p=*|--packages=*)
    PACKAGES="${i#*=}"
    ;;
    -d=*|--dependencies=*)
    DEPENDENCIES="${i#*=}"
    ;;
    *)
       echo "Usage: run_build [{-d|--dependencies}=dependency.git] [{-p|--packages}=packages]"
    ;;
esac
done
echo PACKAGES = "${PACKAGES}"
echo DEPENDENCIES = "${DEPENDENCIES}"

CPPCHECK_PARAMS="--enable=all "

mkdir -p $WORKSPACE/src && cd $WORKSPACE/src
for dependencies in ${DEPENDENCIES}
do
    foldername_w_ext=${dependencies##*/}
    foldername=${foldername_w_ext%.*}
    if [ -d $foldername ]; then
      echo Folder "$foldername" exists, running git pull on "$dependencies"
      cd "$foldername" && git pull && cd ..
    else
      echo Folder "$foldername" does not exists, running git clone "$dependencies"
      git clone "$dependencies" --recursive
    fi  
    CPPCHECK_PARAMS="$CPPCHECK_PARAMS -i$foldername"
done
cd $WORKSPACE

$DIR/run_build_catkin_or_rosbuild ${PACKAGES}

# Run cppcheck excluding dependencies.
cd $CWD
cppcheck $CPPCHECK_PARAMS > cppcheck-result.xml
