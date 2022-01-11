# Command ftrace util

> This is a shell to trace system calls executed from the command line

## Usage
```bash
./my-trace.sh -- ping 8.8.8.8 -c 1
```
```bash
./my-trace.sh filter=*icmp* -- ping 8.8.8.8 -c 1
```
