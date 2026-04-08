# proxy.sh

一个尽量简单的代理配置方案。

如果你主要是在自己的 `zsh` 里使用，推荐直接用仓库里的 `.proxy.sh`，把它 `source` 到 `~/.zshrc`。这样之后你就可以直接用 `proxy on/off/status/test/git ...`。

## 推荐用法：`.proxy.sh`

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

### 手动指定代理

```zsh
proxy set http://127.0.0.1:7897
proxy set socks5 127.0.0.1:7897
```

## 命令说明

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

- `proxy test`
  - 用当前代理测试 Google 连通性

- `proxy test_all`
  - 并行测试多个常用站点

- `proxy git on|off|status`
  - 管理 `git config --global` 里的代理

## 可选环境变量

- `PROXY_HOST`
- `PROXY_HTTP_PORT`
- `PROXY_SOCKS5_PORT`
- `PROXY_NO_PROXY`

## 说明

- `.proxy.sh` 只影响当前 shell 会话和 Git 全局配置
- 不会自动写入 `~/.zshrc`，需要你自己 `source`
- 不会创建本地配置文件
- 这是给个人 shell 环境用的简化版本，优先追求顺手，不追求复杂抽象
