# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with this repository.

## 项目概述

这是一个用于管理代理设置的 Shell 工具仓库，当前主入口是：

- `.proxy.sh`：可直接被 `source` 到 `~/.zshrc` 的简化代理脚本，对外暴露 `proxy ...` 命令

## 当前行为模型

- `.proxy.sh` 面向个人 shell 环境，优先追求简单直接
- 通过 `source /绝对路径/cli-proxy/.proxy.sh` 注册 `proxy` 函数
- `proxy on` / `proxy socks5` / `proxy set ...` / `proxy off` 只作用于**当前 Shell 会话**
- `proxy status` / `proxy test` / `proxy test_all` 读取当前会话中的代理环境变量
- `proxy git on|off|status` 管理 `git config --global` 中的代理设置
- 默认**不会**自动写入 `~/.zshrc`、`~/.bashrc`、`~/.profile`
- 默认**不会**创建或读取本地代理配置文件

## 常用命令

```zsh
source /绝对路径/cli-proxy/.proxy.sh

proxy on
proxy socks5
proxy set http://127.0.0.1:7897
proxy set socks5 127.0.0.1:7897
proxy off
proxy status
proxy test
proxy test_all
proxy git on
proxy git off
proxy git status
```

## 技术实现

- **Shell 兼容性**: 当前主要面向 `zsh` 使用场景
- **代理类型**: 支持 HTTP、HTTPS、SOCKS5、SOCKS5H
- **状态来源**: 以当前 Shell 环境变量为唯一真实来源
- **默认配置**: 通过 `PROXY_HOST`、`PROXY_HTTP_PORT`、`PROXY_SOCKS5_PORT`、`PROXY_NO_PROXY` 覆盖默认值
- **Git 集成**: 使用 `git config --global` 设置 Git HTTP/HTTPS 代理
