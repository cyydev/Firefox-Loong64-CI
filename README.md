# Firefox-Loong64-CI

## 一, 如何运行

./main.sh

## 二, 变量说明

* FIREFOX_SOURCEDIR: 项目使用mercurial来管理mozilla firefox源码，该变量即hg clone的源码目录名。
* LOG_CI_FILE: 记录脚本日志，该日志内容会在构建完成时或出错时发邮件通知管理员；在下次构建之前，该文件内容会自动清空。
* LOCAL_BAKS_DIRS： firefox二进制备份目录。目前仅支持本地备份。
* BUILD_TYPE: 可选值：Time：持续集成构建, 通过设置BUILD_TIME_NUM，表示间隔多长时间触发一次构建； 
                    Patch： 过去式构建，通过设置BUILD_PATCH_NUM，表示间隔多少个patch触发一次构建。目前不支持该模式。
* ADMIN_MAIL_LIST: 管理员邮箱，用于接收Firefox-Loong64-CI脚本的状态信息，内容见LOG_CI_FILE。支持多管理员邮箱。

## 三, API介绍
```shell
logPrint: 日志打印
  输出格式: "[[当前时间  LINE:行号]]----消息内容"
  接收3个参数: 参数1： 行号，可用$LINENO表示，自动获取调用时的行号
               参数2： 消息内容
               参数3： 严重错误，该消息标记是否会发邮件通知，并退出Firefox-Loong64-CI。
```

```shell
testToolsInstalled: 依赖工具安装
```

```shell
updateFirefoxSrc： 更新源码。若未clone，则clone； 若已clone，则pull最新源码。
```

```shell
buildFirefox： 执行configure，build，package过程。
```

```shell
copyPackage： 二进制备份。
              <1>会在LOCAL_BAKS_DIRS目录中按递增的顺序以数字命名创建目录, 用于存放做包产生的firefox-*.linux-*.tar.bz2
                 和firefox-*.linux-*.txt文件。
              <2>LOCAL_BAKS_DIRS/MAPS文件的每一行都记录一个三元组信息，即"目录名  firefox版本号 CommitID”, 方便测试。
```

```shell
taskStartCondition: 用于判断是否开启下一次构建。当前仅实现Time模式，采用sleep函数延时。
```

## 四, 问题说明
  1, 邮件功能不可用。
  答：可能需要设置白名单，如loongson@loongson-pc.mail.ntes53.netease.com, 这即在我的163邮箱发件人的显示
