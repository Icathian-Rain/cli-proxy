# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## 项目概述

这是一个用于管理代理设置的 Shell 工具仓库，包含两个主要入口：

- `proxy.sh`：底层 CLI 与核心逻辑
- `.proxy.zsh`：zsh 包装层，向用户暴露 `proxy ...` 函数

## 当前行为模型

- `proxy.sh` 提供核心实现，既可被执行，也可被 source 后复用 `proxy_main`
- `.proxy.zsh` 负责注册 `proxy` 函数，提供更自然的日常交互
- `set` / `unset` 只作用于**当前 Shell 会话**
- `status` / `test` / `test_all` / `git on|off|status` 可以直接执行
- 默认**不会**写入 `~/.zshrc`、`~/.bashrc`、`~/.profile`
- 默认**不会**创建或读取本地代理配置文件

## 常用命令

### CLI 模式

```bash
source ./proxy.sh set http://127.0.0.1:7890
source ./proxy.sh set socks5 127.0.0.1:1080
source ./proxy.sh unset
./proxy.sh status
./proxy.sh test
./proxy.sh test_all
./proxy.sh git on
./proxy.sh git off
./proxy.sh git status
```

### zsh 函数模式

```zsh
source ./.proxy.zsh
proxy on
proxy socks5
proxy off
proxy status
proxy test
proxy test_all
proxy git on
proxy git off
proxy git status
```

## 技术实现

- **Shell 兼容性**: 目标是支持 `bash` 和 `zsh`，不承诺 POSIX `sh` 兼容
- **代理类型**: 支持 HTTP、HTTPS、SOCKS5、SOCKS5H
- **状态来源**: 以当前 Shell 环境变量为唯一真实来源
- **zsh 包装层**: `.proxy.zsh` 通过 source `proxy.sh` 并复用 `proxy_main`
- **Git 集成**: 使用 `git config --global` 设置 Git HTTP/HTTPS 代理
