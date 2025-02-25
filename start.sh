#!/bin/bash

function logToMail() {
  for receiver in $ADMIN_MAIL_LIST
  do
    cat $LOG_CI_FILE | mail -s "Firefox CI" $receiver
    if [ $? != 0 ]
    then
      cat $LOG_CI_FILE | mail -s "Firefox CI" $receiver
      if [ $? != 0 ]
      then
        echo "[[$date  start.sh:$LINENO]]----Mail Failed！" | tee -a $LOG_CI_FILE
        exit
      fi
    fi
  done
}

function logPrint() {
  lineNo=$1
  date=`date +"%Y-%m-%d %H:%M:%S"`
  messages=$2  # message for print
  status=$3
  # Loognix-serer 似乎不支持 "\033[41;37m", cat打开的文件中只要含有这些符号，
  # 管道中的流会自动转存到一个文件，然后通过mail发送
  #echo -e "\n\033[41;37m [[$date  LINE:$lineNo]]----$messages \033[0m" | tee -a $LOG_CI_FILE
  echo -e "\n\033[41;37m [[$date  LINE:$lineNo]]----$messages \033[0m"
  echo -e "\n[[$date  LINE:$lineNo]]----$messages" >> $LOG_CI_FILE

  if [ $status = "ERROR" ]
  then
    logToMail  # Inform by mail
    exit
  fi
}

function testToolsInstalled(){
  hg version > /dev/null
  if [ $? != 0 ]
  then
    sudo apt-get install python3.8 libpython3.8
    if [ $? != 0 ]
    then
      # For python>=3.8 build from source.
      sudo apt-get install libsqlite3-dev libreadline-dev libssl-dev  tk-dev libbz2-dev libgdbm-dev liblzma-dev libgdbm-compat-dev
      sudo apt-get install terminator sshpass
      logPrint $LINENO "Install Python>=3.8 failed!" "INFO"
    fi
    sudo apt-get install sendmail mutt # email tools.
    sudo hostname smtp.163.com
    sudo apt-get install libgtk-3-dev libstartup-notification0-dev libjpeg-dev libreadline-dev
    sudo apt-get install libdbus-glib-1-dev libevent-dev libpulse-dev libasound2-dev yasm
    sudo apt-get install llvm-dev libclang-dev clang lld nodejs fonts-dejima-mincho cmake
    cargo install cbindgen
    python3 -m pip install --user mercurial # mozilla firefox clone
    hg version
    if [ $? != 0 ]
    then
      logPrint $LINENO "Mercurial installed failed." "ERROR"
    fi
  else
    sudo hostname smtp.163.com
    logPrint $LINENO "Mercurial tools check passed!" "INFO"
  fi
}

function printBuildSysInfo() {
  ldd /usr/bin/ls | grep ld-linux-loongarch-lp64d
  if [ $? == 0 ]
  then
    logPrint $LINENO "loongarch64 Abi2.0 Builds" "INFO"
  fi

  ldd /usr/bin/ls | grep ld.so.1
  if [ $? == 0 ]
  then
    logPrint $LINENO "loongarch64 Abi1.0 Builds" "INFO"
  fi

  uname -m | grep x86_64
  if [ $? == 0 ]
  then
    logPrint $LINENO "X86_64 Builds" "INFO"
  fi
}

#在任何目录下都可执行，放在哪里呢？？？
function updateFirefoxSrc(){
  if [ -d $FIREFOX_SOURCEDIR ]
  then
    logPrint $LINENO "Will Update Firefox Source..." "INFO"
    cd $FIREFOX_SOURCEDIR
    hg pull
    hg update central #Use central bookmark可以更及时发现并解决问题
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
  # bin dir check.
  arch=`uname -m`
  objdir="$FIREFOX_SOURCEDIR/obj-$arch*/dist"
  echo $objdir
  if [ ! -d $objdir ]
  then
    logPrint $LINENO "firefox bin dirs not exist !!! Please check \"$objdir\"." "ERROR"
  fi

  # abi2.0 for loongarch64.
  ldd /usr/bin/ls | grep ld-linux-loongarch-lp64d
  if [ $? == 0 ]
  then
    arch="abi2_0_loongarch64"
  fi

  pushd $objdir
    # package check.
    package_name=`ls | egrep ".tar.xz"`
    if [ $? != 0 ]
    then
      logPrint $LINENO "Not found firefox package." "ERROR"
    fi
    build_id=${package_name%tar.xz*}
    build_id="${build_id}txt"

    # saveas package.
    if [ -d $LOCAL_BAKS_DIRS ]
    then
      location_dir=`ls $LOCAL_BAKS_DIRS | sort -n | tail -n 1`
    else #从服务器获取当前已编译的firefox数量
      mkdir $LOCAL_BAKS_DIRS
      sshpass -p "firefoxci" scp "$REMOTE_BAKS_DIRS$arch/Maps" $LOCAL_BAKS_DIRS
      location_dir=`tail -1 "$LOCAL_BAKS_DIRS/Maps"`
      location_dir=${location_dir%% *}
    fi
    location_dir=`expr $location_dir + 1`
    location_dir="$LOCAL_BAKS_DIRS$location_dir"

    mkdir -p $location_dir
    cp $package_name $location_dir
    cp $build_id $location_dir
    if [ $? != 0 ]
    then
      logPrint $LINENO "Local Backed Up Failed. Please Check!" "ERROR"
    fi

    # Firefox-Version
    version_number=`bin/firefox --version`
    version_number=${version_number#*Mozilla Firefox }

    # CommitID
    patch_number=`hg id -i`
    patch_number=${patch_number:0:10}
    patch_number=`hg log -r ${patch_number}`
    patch_number=${patch_number#*changeset: }
    patch_number=${patch_number:0:21}

    #  write triple. "Dirs-Name Version  CommitID"
    maps_file="${LOCAL_BAKS_DIRS}Maps"
    if [ ! -e $maps_file ]
    then
      touch $maps_file
    fi
    date=`date +"%Y-%m-%d %H:%M:%S"`
    triple_info="${location_dir##*/}  $version_number  $patch_number   [$date]"
    echo $triple_info >> $maps_file
    logPrint $LINENO "[[$triple_info]] Local have been backed up." "INFO"

    sshpass -p "firefoxci" scp -r $location_dir "$REMOTE_BAKS_DIRS$arch/"
    sshpass -p "firefoxci" scp $maps_file "$REMOTE_BAKS_DIRS$arch/"
    if [ $? != 0 ]
    then
      logPrint $LINENO "Remote Backed Up Failed. Please Check!" "ERROR"
    fi
    logPrint $LINENO "Remote have been backed up." "INFO"

    logToMail  # Inform Admin this build success.
  popd
}

function taskStartCondition() {
  rm $LOG_CI_FILE # delete CI_LOG for next build.

  if [ $first_start = "TRUE" ]
  then
    first_start="FALSE"
    return 0 # 0 true
  fi

  if [ $BUILD_TYPE = "Time" ]
  then
    #Build Cycle.
    sleep $BUILD_TIME_NUM

    #Build Start Time in 0-1 o'clock.
    cur_dateTime=`date +%H`
    sleep_time=`expr 24 - $cur_dateTime`
    sleep_time="${sleep_time}h"
    sleep $sleep_time

    return 0 # 0 true
  else
    echo "Patch"
  fi
}


