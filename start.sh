#!/bin/bash
ADMIN_MAIL="chengyangyang-hf@loongson.cn"

# 待调试
function logToMail() {
  #cat $LOG_CI_FILE | mail -s "Firefox CI" chengyangyang-hf@loongson.cn
  cat $LOG_CI_FILE | mail -s "Firefox CI" 18895622670@163.com
}

# 当$3为ERROR时，代表发生错误，发邮件通知，退出CI系统
function logPrint() {
  lineNo=$1
  date=`date +"%Y-%m-%d %H:%M:%S"`
  messages=$2  # message for print
  status=$3
  echo "[[$date  start.sh:$lineNo]]----$messages" | tee -a $LOG_CI_FILE

  if [ $status = "ERROR" ]
  then
    logToMail  # 邮件通知
    exit
  fi
}

function testToolsInstalled(){
  hg version > /dev/null
  if [ $? != 0 ]
  then
    sudo apt-get install libpython3.7-dev
    sudo apt-get install sendmail #email when error.
    sudo hostname smtp.163.com
    python3 -m pip install --user mercurial
    hg version
    if [ $? != 0 ]
    then
      logPrint $LINENO "Mercurial installed failed." "ERROR"
    fi
  else
    logPrint $LINENO "Mercurial tools check passed!" "INFO"
  fi
}

#在任何目录下都可执行，放在哪里呢？？？
function updateFirefoxSrc(){
  dirs
  if [ -d $FIREFOX_SOURCEDIR ]
  then
    logPrint $LINENO "Will Update Firefox Source..." "INFO"
    cd $FIREFOX_SOURCEDIR
    hg pull
    cd ..
  else
    logPrint $LINENO "Not Clone Firefox Source, will cloneing..." "INFO"
    curl https://hg.mozilla.org/mozilla-central/raw-file/default/python/mozboot/bin/bootstrap.py -O
    #需要安装Python3.8+才能执行bootstrap.py
    python3 bootstrap.py --no-interactive
    if [ $? != 0 ]
    then
      logPrint $LINENO "mozilla firefox clone failed." "ERROR"
    else
      logPrint $LINENO "mozilla firefox clone success." "INFO"
    fi
    #pushd $FIREFOX_SOURCEDIR
    #echo "
    #ac_add_options --without-wasm-sandboxed-libraries
    #ac_add_options --disable-tests
    #export LDFLAGS=\"-Wl,--discard-locals\"
    #mk_add_options MOZ_OBJDIR=obj-la64
    #" > .mozconfig
    #popd
  fi
}

function buildFirefox() {
  pushd $FIREFOX_SOURCEDIR
    unset UNZIP
    # Configure
    ./mach configure
    if [ $? != 0 ]
    then
      logPrint $LINENO "mach configure failed." "ERROR"
    fi
    logPrint $LINENO "mach configure Success !!!." "INFO"

    # Build
    ./mach build
    if [ $? != 0 ]
    then
      logPrint $LINENO "mach build failed." "ERROR"
    fi
    logPrint $LINENO "mach build Success !!!." "INFO"

    # Package
    ./mach package
    if [ $? != 0 ]
    then
      logPrint $LINENO "mach package failed." "ERROR"
    fi
    logPrint $LINENO "mach package Success !!!." "INFO"
  popd
}

function copyPackage() {
  objdir=`uname -m`
  objdir="$FIREFOX_SOURCEDIR/obj-$objdir*/dist"
  echo $objdir
  if [ ! -d $objdir ]
  then
    logPrint $LINENO "firefox bin dirs not exist !!! Please check \"$objdir\"." "ERROR"
  fi

  pushd $objdir
    package_name=`ls | egrep ".tar.bz2"`
    if [ $? != 0 ]
    then
      logPrint $LINENO "Not found firefox package." "ERROR"
    fi
    build_id=${package_name%tar.bz2*}
    build_id="${build_id}txt"

    # saveas package. 在存储目录中新建一个目录，目录名用数字表示，以递增顺序
    location_dir=`ls $PACKAGE_BAKS_DIRS | sort -n | tail -n 1`
    location_dir=`expr $location_dir + 1`
    location_dir="$PACKAGE_BAKS_DIRS$location_dir"
    mkdir -p $location_dir
    cp $package_name $location_dir
    cp $build_id $location_dir

    #获取版本号 以及 hg version
    version_number=`bin/firefox --version`
    echo $version_number
    version_number=${version_number#*Mozilla Firefox }
    echo $version_number

    patch_number=`hg log -l 1`
    patch_number=${patch_number#*changeset: }
    patch_number=${patch_number:0:21}
    maps_file="$PACKAGE_BAKS_DIRS/Maps"
    if [ ! -e $maps_file ]
    then
      touch $maps_file
    fi
    # 目录名  版本号  commitID
    triple_info="${location_dir##*/}  $version_number  $patch_number"
    echo $triple_info >> $maps_file

    logPrint $LINENO "[[$triple_info]] have been backed up." "INFO"
    logToMail  # 邮件通知
  popd
}

# 支持两种策略
# 按时间,用于编译最新版firefox
# 按patch数,用于编译旧版firefox
function taskStartCondition() {
  rm $LOG_CI_FILE # 删除CI日志，重新开启记录下一次构建日志

  if [ $first_start = "TRUE" ]
  then
    first_start="FALSE"
    return 0 # 0 true
  fi

  if [ $BUILD_TYPE = "Time" ]
  then
    sleep $BUILD_TIME_NUM
    return 0 # 0 true
  else
    echo "Patch"
  fi
}


