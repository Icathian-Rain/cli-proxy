# proxy.sh

一个用于个人 shell 日常使用的代理脚本仓库，当前同时提供两个版本：

- `.proxy.sh`：当前完整版本，带彩色输出、连通性测试、批量测试
- `.proxy.simple.sh`：最简版本，保留基础代理管理和 `test`，不带彩色输出

## 推荐用法

### 完整版：`.proxy.sh`

把下面这行加入 `~/.zshrc`：

```zsh
source /绝对路径/cli-proxy/.proxy.sh
```

如果你想自定义默认代理地址，也可以一起加上：

```zsh
export PROXY_HOST=127.0.0.1
export PROXY_HTTP_PORT=7897
export PROXY_SOCKS5_PORT=7897
export PROXY_NO_PROXY=localhost,127.0.0.1
source /绝对路径/cli-proxy/.proxy.sh
```

重新打开终端后可直接使用：

```zsh
proxy on
proxy socks5
proxy off
proxy status
proxy test
proxy test_all
proxy git on
proxy git status
proxy git off
```

### 最简版：`.proxy.simple.sh`

如果你只想要最基础的代理开关和 Git 代理管理，可以使用：

```zsh
source /绝对路径/cli-proxy/.proxy.simple.sh
```

可用命令：

```zsh
proxy on
proxy socks5
proxy set http://127.0.0.1:7897
proxy set socks5 127.0.0.1:7897
proxy test
proxy off
proxy status
proxy git on
proxy git status
proxy git off
```

## 命令说明

### `.proxy.sh`

- `proxy on`
  - 使用默认 HTTP 代理 `http://${PROXY_HOST}:${PROXY_HTTP_PORT}`
  - 同时把 `all_proxy` 设为默认 SOCKS5 地址

- `proxy socks5`
  - 使用默认 SOCKS5 代理 `socks5://${PROXY_HOST}:${PROXY_SOCKS5_PORT}`
  - 会把 `http_proxy/https_proxy/all_proxy` 都设成这个 SOCKS5 地址

- `proxy set <url>`
  - 手动设置代理 URL

- `proxy set socks5 <host:port>`
  - 手动设置 SOCKS5 代理

- `proxy off`
  - 清除当前会话代理

- `proxy status`
  - 查看当前会话代理变量
  - 使用统一的彩色状态输出

- `proxy test`
  - 用当前代理测试 Google 连通性
  - 成功/失败使用符号和颜色表示
  - 耗时以 `ms` 显示

- `proxy test_all`
  - 并行测试多个常用站点
  - 不打印 zsh 后台任务进程信息
  - 失败时会显示常见原因，如 `timeout`、`connect failed`

- `proxy git on|off|status`
  - 管理 `git config --global` 里的代理
  - `proxy git status` 也使用统一的状态输出风格

### `.proxy.simple.sh`

- 保留：`on`、`socks5`、`set`、`off`、`status`、`test`、`git on|off|status`
- 不包含：彩色输出、`test_all`
- `test` 使用纯文本输出，适合更老一点的 shell 环境
- 输出为纯文本，尽量使用更朴素的 shell 写法，适合更老一点的 shell 环境

## 输出示例

### `.proxy.sh` 的 `proxy test`

```text
› proxy http://127.0.0.1:7897
✔ google.com         302  1329ms
```

### `.proxy.sh` 的 `proxy test_all`

```text
› proxy http://127.0.0.1:7897
› targets 5
✔ google.com         302  1389ms
✔ github.com         200  4050ms
✔ gitlab.com         301  4056ms
✔ cloudflare.com     200  4247ms
✔ microsoft.com      200   754ms
✔ summary: 5/5 success, 0 failed
```

### `.proxy.simple.sh` 的 `proxy status`

```text
http_proxy=未设置
https_proxy=未设置
all_proxy=未设置
no_proxy=未设置
```

## 可选环境变量

- `PROXY_HOST`
- `PROXY_HTTP_PORT`
- `PROXY_SOCKS5_PORT`
- `PROXY_NO_PROXY`
- `PROXY_AUTO_ON`
  - source 时自动开启代理，不设置则不自动开启
  - `1` / `http` / `on` → 自动 `proxy on`
  - `socks5` → 自动 `proxy socks5`
  - 示例：`export PROXY_AUTO_ON=1` 后再 `source` 脚本

## 说明

- 两个脚本都只影响当前 shell 会话和 Git 全局配置
- 都不会自动写入 `~/.zshrc`，需要你自己 `source`
- 都不会创建本地配置文件
- `.proxy.sh` 更偏向日常使用体验
- `.proxy.simple.sh` 更偏向最小实现和更简单的兼容性
