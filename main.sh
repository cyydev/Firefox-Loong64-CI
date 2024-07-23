#!/bin/bash

# Mozilla firefox for loong64 continuous integration and release processes.

PROJECT_PATH=`dirname $(readlink -f "$0")`

FIREFOX_SOURCEDIR="mozilla-unified" # firefox source dir.
LOG_CI_FILE="$PROJECT_PATH/$FIREFOX_SOURCEDIR/CI_LOG"

PACKAGE_BAKS_DIRS="/tmp/MyFirefoxBin/" # package backed up.


BUILD_TYPE="Time"       # Time Patch
BUILD_TIME_NUM=1h        # s:second m:minute h:hour d:day
BUILD_PATCH_NUM=100

ADMIN_MAIL_LIST="chengyangyang-hf@loongson.cn  18895622670@163.com"

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
