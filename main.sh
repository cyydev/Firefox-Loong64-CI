#!/bin/bash

# Mozilla firefox for loong64 continuous integration and release processes.

CUR_FILENAME=`basename $0`
PROJECT_PATH=`dirname $(readlink -f "$0")`

FIREFOX_SOURCEDIR="mozilla-unified" # The directory for clone newer firefox source.
PACKAGE_BAKS_DIRS="/mnt/chengyangyang/MyFirefoxBin/" # package备份路径

LOG_LEVEL=""  # ERROR FILE INFO未实现
LOG_CI_FILE="$PROJECT_PATH/$FIREFOX_SOURCEDIR/CI_LOG"

BUILD_TYPE="Time"       # Time Patch
BUILD_TIME_NUM=10        # s:second m:minute h:hour d:day
BUILD_PATCH_NUM=100


source start.sh

#set -x # print command


testToolsInstalled


first_start="TRUE"
taskStartCondition
while [ $? -eq 0 ]
do
  updateFirefoxSrc
  buildFirefox
  copyPackage
  taskStartCondition
done
