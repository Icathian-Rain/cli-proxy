# AGENTS.md

This file provides guidance to Codex (Codex.ai/code) when working with this repository.

## 项目概述

这是一个用于管理代理设置的 Shell 工具仓库，当前有两个入口：

- `.proxy.sh`：当前完整版本，带彩色输出、连通性测试、批量测试
- `.proxy.simple.sh`：新增的最简版本，保留基础代理管理和纯文本 `test`

## 当前行为模型

- `.proxy.sh` 面向个人 shell 环境，优先追求顺手和可读的输出
- `.proxy.simple.sh` 面向“尽量简单、尽量朴素”的使用场景
- 两个脚本都通过 `source /绝对路径/...` 注册 `proxy` 函数
- `proxy on` / `proxy socks5` / `proxy set ...` / `proxy off` 只作用于**当前 Shell 会话**
- `proxy git on|off|status` 管理 `git config --global` 中的代理设置
- 只有 `.proxy.sh` 提供 `proxy test_all`
- `.proxy.simple.sh` 提供纯文本 `proxy test`
- 默认**不会**自动写入 `~/.zshrc`、`~/.bashrc`、`~/.profile`
- 默认**不会**创建或读取本地代理配置文件

## 常用命令

### 完整版

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

### 最简版

```zsh
source /绝对路径/cli-proxy/.proxy.simple.sh

proxy on
proxy socks5
proxy set http://127.0.0.1:7897
proxy set socks5 127.0.0.1:7897
proxy test
proxy off
proxy status
proxy git on
proxy git off
proxy git status
```

## 技术实现

- **Shell 兼容性**:
  - `.proxy.sh` 主要面向 `zsh` 日常使用
  - `.proxy.simple.sh` 尽量使用更朴素的 shell 写法，减少额外依赖
- **代理类型**: 支持 HTTP、HTTPS、SOCKS5、SOCKS5H
- **状态来源**: 以当前 Shell 环境变量为唯一真实来源
- **默认配置**: 通过 `PROXY_HOST`、`PROXY_HTTP_PORT`、`PROXY_SOCKS5_PORT`、`PROXY_NO_PROXY` 覆盖默认值
- **Git 集成**: 使用 `git config --global` 设置 Git HTTP/HTTPS 代理
