#!/bin/bash

# 获取时间戳
CURRENT_TIMESTAMP=`date +%s`
DPATH="/sys/kernel/debug/tracing"
TEMP="$( cd "$( dirname "$0"  )" && pwd  )"
TEMP_TRACE_PATH=$TEMP/temp-log.txt
TEMP_CMD_PATH=$TEMP/trace-tmp-$CURRENT_TIMESTAMP

rm -rf $TEMP_TRACE_PATH

# 获取要执行的命令
CURRENT_CMD=$@

# 设置 trace
echo /dev/null > $DPATH/trace
echo nop > $DPATH/current_tracer
echo 0 > $DPATH/tracing_on
# 设置要使用哪种 trace
echo function_graph > $DPATH/current_tracer

# 创建一个新的临时脚本用来执行命令
# 把要执行的脚本的 PID 设置给 tracer
echo "echo \$\$ > $DPATH/set_ftrace_pid" > $TEMP_CMD_PATH
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
echo 0 > $DPATH/tracing_on
echo nop > $DPATH/current_tracer
