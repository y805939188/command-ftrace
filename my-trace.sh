#!/bin/bash

# 获取时间戳
CURRENT_TIMESTAMP=`date +%s`
DPATH="/sys/kernel/debug/tracing"
TEMP="$( cd "$( dirname "$0"  )" && pwd  )"
TEMP_TRACE_PATH=$TEMP/temp-log.txt
TEMP_CMD_PATH=$TEMP/trace-tmp-$CURRENT_TIMESTAMP
CMD_OPERATIONS="--"

rm -rf $TEMP_TRACE_PATH

if [[ ! $* =~ $CMD_OPERATIONS ]]
then
  echo "需要通过 $CMD_OPERATIONS 指定命令参数"
  exit 0
fi

getFilterParams() {
  for arg in $*                   
  do
    array=(${arg//=/ })
    _TEMP_KEY=${array[@]:0:1}
    if [ $_TEMP_KEY = "filter" ]; then
      echo ${array[@]:1:2}
    fi
  done
}

getCommand() {
  _TEMP_PARAMS=$*
  _TEMP_CMD=${_TEMP_PARAMS#*$CMD_OPERATIONS}
  echo $_TEMP_CMD
}

# 尝试获取过滤用的参数
FILTER_PARAMS=$(getFilterParams $*)
if [ "$FILTER_PARAMS" ]; then
  echo "tracer 过滤条件是: $FILTER_PARAMS"
fi

# 获取要执行的命令
CURRENT_CMD=$(getCommand $*)
echo "tracer 要执行的命令是: $CURRENT_CMD"
if [ ! -n "$CURRENT_CMD" ]; then
  echo "至少需要一个 cmd 参数"
  exit 0
fi

# 设置 trace
echo /dev/null > $DPATH/trace
echo nop > $DPATH/current_tracer
echo 0 > $DPATH/tracing_on
echo "" > $DPATH/set_ftrace_filter
# 设置要使用哪种 trace
echo function_graph > $DPATH/current_tracer

# 创建一个新的临时脚本用来执行命令
# 把要执行的脚本的 PID 设置给 tracer
echo "echo \$\$ > $DPATH/set_ftrace_pid" > $TEMP_CMD_PATH
if [ "$FILTER_PARAMS" ]; then
  echo "echo $FILTER_PARAMS > $DPATH/set_ftrace_filter" > $TEMP_CMD_PATH
fi
echo "echo \"当前进程是 \$\$\"" >> $TEMP_CMD_PATH
# 启动 tracer
echo "echo 1 > $DPATH/tracing_on" >> $TEMP_CMD_PATH
echo "exec \"\$@\"" >> $TEMP_CMD_PATH

# 加权
chmod u+x $TEMP_CMD_PATH
# 执行脚本并把命令传进去
$TEMP_CMD_PATH $CURRENT_CMD

# 输出 trace 日志
`cat /$DPATH/trace > $TEMP_TRACE_PATH`
rm -rf $TEMP_CMD_PATH
echo -e "\033[32m 输出 trace 日志路径是 $TEMP_TRACE_PATH \033[0m"
# echo "输出 trace 日志路径是 $TEMP_TRACE_PATH"
echo "" > $DPATH/set_ftrace_filter
echo 0 > $DPATH/tracing_on
echo nop > $DPATH/current_tracer
