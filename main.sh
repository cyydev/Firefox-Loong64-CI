#!/bin/bash

# Mozilla firefox for loong64 continuous integration and release processes.

PROJECT_PATH=`dirname $(readlink -f "$0")`

FIREFOX_SOURCEDIR="firefox" # firefox source dir.
LOG_CI_FILE="$PROJECT_PATH/CI_LOG"

LOCAL_BAKS_DIRS="$PROJECT_PATH/localPackage/" # Local package backed up.
REMOTE_BAKS_DIRS="firefoxci@10.140.113.105:/mnt/firefoxci/package/" # Remote package backed up.


BUILD_TYPE="Time"       # Time Patch
BUILD_TIME_NUM=6d        # s:second m:minute h:hour d:day
BUILD_PATCH_NUM=100

ADMIN_MAIL_LIST="chengyangyang-hf@loongson.cn  18895622670@163.com"

source start.sh

#set -x # print command


testToolsInstalled

# Controls whether to start compiling immediately.
build_now="FALSE"
if [ $# -eq 0 ]
then
  build_now="FALSE"
else
  if [ $1 = "buildnow" ]
  then
    build_now="TRUE"
  fi
fi

first_start="TRUE"   # avoid sleep when first start.

taskStartCondition
while [ $? -eq 0 ]
do
  printBuildSysInfo

  updateFirefoxSrc
  buildFirefox
  copyPackage
  taskStartCondition
done
