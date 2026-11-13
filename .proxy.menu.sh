# ~/.proxy.menu.sh
#
# 交互式代理管理菜单，复用 .proxy.sh 的全部能力。
#
# 用法：
#   source ~/.proxy.menu.sh
#   proxy menu          # 进入菜单（无 fzf 时自动回退数字菜单）
#
# 依赖：
#   .proxy.sh 须与本文件在同一目录
#   fzf 可选，未安装时自动使用数字菜单

# 找到本脚本的目录，source 同目录的 .proxy.sh
_proxy_menu_dir="${${(%):-%x}:A:h}"
if [ ! -f "${_proxy_menu_dir}/.proxy.sh" ]; then
  echo "找不到 ${_proxy_menu_dir}/.proxy.sh，菜单脚本需要与 .proxy.sh 放在同一目录" >&2
  return 1 2>/dev/null || exit 1
fi
source "${_proxy_menu_dir}/.proxy.sh"
unset _proxy_menu_dir

# ---------------------------------------------------------------------------
# 菜单动作
# ---------------------------------------------------------------------------

_proxy_menu_has_fzf() {
  command -v fzf >/dev/null 2>&1
}

_proxy_menu_prompt() {
  printf '%b按回车返回菜单%b' "$_proxy_color_dim" "$_proxy_color_reset"
  read -r _
  printf '\033[1A\033[2K\r'
}

_proxy_menu_read_url() {
  local input
  printf '输入代理地址 (如 http://127.0.0.1:7897 或 socks5 127.0.0.1:7897): '
  read -r input
  case "$input" in
    'socks5 '*|'socks5h '*)
      local addr="${input#socks5h }"
      addr="${addr#socks5 }"
      proxy set socks5 "$addr"
      ;;
    socks5|socks5h)
      echo "用法: proxy set socks5 <host:port>" >&2
      return 1
      ;;
    '')
      return 1
      ;;
    *)
      proxy set "$input"
      ;;
  esac
}

_proxy_menu_change_defaults() {
  local host http_port socks5_port
  printf 'PROXY_HOST [%s]: ' "${PROXY_HOST}"
  read -r host
  [ -n "$host" ] && PROXY_HOST="$host"
  printf 'PROXY_HTTP_PORT [%s]: ' "${PROXY_HTTP_PORT}"
  read -r http_port
  [ -n "$http_port" ] && PROXY_HTTP_PORT="$http_port"
  printf 'PROXY_SOCKS5_PORT [%s]: ' "${PROXY_SOCKS5_PORT}"
  read -r socks5_port
  [ -n "$socks5_port" ] && PROXY_SOCKS5_PORT="$socks5_port"
  _proxy_print_action "defaults" "host=${PROXY_HOST}, http=${PROXY_HTTP_PORT}, socks5=${PROXY_SOCKS5_PORT} (仅当前会话)"
}

_proxy_menu_confirm_off() {
  local answer
  printf '退出前关闭当前代理? [y/N] '
  read -r answer
  case "$answer" in
    y|Y|yes|YES)
      proxy off
      ;;
    *)
      _proxy_print_action "keep" "代理保留在当前会话"
      ;;
  esac
}

# ---------------------------------------------------------------------------
# 菜单主体
# ---------------------------------------------------------------------------

_proxy_menu_actions() {
  local choice="$1"

  case "$choice" in
    "开启 HTTP 代理"|on) proxy on ;;
    "开启 SOCKS5 代理"|socks5) proxy socks5 ;;
    "自定义代理地址"|set) _proxy_menu_read_url ;;
    "关闭代理"|off) proxy off ;;
    "查看状态"|status) proxy status ;;
    "测试当前代理"|test) proxy test ;;
    "批量测试"|test_all) proxy test_all ;;
    "Git 代理开启"|git-on) proxy git on ;;
    "Git 代理关闭"|git-off) proxy git off ;;
    "Git 代理状态"|git-status) proxy git status ;;
    "修改默认地址"|defaults) _proxy_menu_change_defaults ;;
    "帮助"|help) proxy help ;;
    *) return 2 ;;
  esac
}

_proxy_menu_fzf() {
  local choice
  choice=$(printf '%s\n' \
    '开启 HTTP 代理' \
    '开启 SOCKS5 代理' \
    '自定义代理地址' \
    '关闭代理' \
    '查看状态' \
    '测试当前代理' \
    '批量测试' \
    'Git 代理开启' \
    'Git 代理关闭' \
    'Git 代理状态' \
    '修改默认地址' \
    '帮助' \
    '退出' \
    | fzf --height 40% --reverse --border --prompt 'proxy ❯ ' --header '选择操作 (Enter 确认, Esc 退出)') || {
    # Esc / Ctrl-C 退出
    if _proxy_current >/dev/null 2>&1; then
      printf '\n'
      _proxy_menu_confirm_off
    fi
    return 0
  }

  [ "$choice" = "退出" ] && {
    if _proxy_current >/dev/null 2>&1; then
      _proxy_menu_confirm_off
    fi
    return 0
  }

  _proxy_menu_actions "$choice"
  local rc=$?
  if [ "$rc" -eq 2 ]; then
    echo "未知选项: ${choice}" >&2
  else
    printf '\n'
    _proxy_menu_prompt
  fi
  _proxy_menu_fzf
}

_proxy_menu_numeric() {
  local choice
  while true; do
    printf '\n'
    _proxy_print_header "proxy menu" "输入数字选择操作"
    cat <<EOF
  1) 开启 HTTP 代理      ${PROXY_HOST}:${PROXY_HTTP_PORT}
  2) 开启 SOCKS5 代理    ${PROXY_HOST}:${PROXY_SOCKS5_PORT}
  3) 自定义代理地址
  4) 关闭代理
  5) 查看状态
  6) 测试当前代理
  7) 批量测试
  8) Git 代理开启
  9) Git 代理关闭
  10) Git 代理状态
  11) 修改默认地址
  12) 帮助
  0) 退出
EOF
    printf '选择: '
    read -r choice
    case "$choice" in
      1) _proxy_menu_actions '开启 HTTP 代理' ;;
      2) _proxy_menu_actions '开启 SOCKS5 代理' ;;
      3) _proxy_menu_actions '自定义代理地址' ;;
      4) _proxy_menu_actions '关闭代理' ;;
      5) _proxy_menu_actions '查看状态' ;;
      6) _proxy_menu_actions '测试当前代理' ;;
      7) _proxy_menu_actions '批量测试' ;;
      8) _proxy_menu_actions 'Git 代理开启' ;;
      9) _proxy_menu_actions 'Git 代理关闭' ;;
      10) _proxy_menu_actions 'Git 代理状态' ;;
      11) _proxy_menu_actions '修改默认地址' ;;
      12) _proxy_menu_actions '帮助' ;;
      0)
        if _proxy_current >/dev/null 2>&1; then
          _proxy_menu_confirm_off
        fi
        _proxy_print_action "menu" "已退出"
        return 0
        ;;
      *)
        echo "无效选择: ${choice}" >&2
        ;;
    esac
  done
}

_proxy_menu() {
  # fzf 需要交互 TTY，非 TTY（管道/脚本）或未装 fzf 时回退数字菜单
  if _proxy_menu_has_fzf && [ -t 0 ] && [ -t 1 ]; then
    _proxy_menu_fzf
  else
    _proxy_menu_numeric
  fi
}

# proxy.sh 的 proxy() 在 menu 分支检测到本函数已定义时委托到这里。
# 不用 functions[] 复制原 proxy 函数——zsh 该机制会损坏函数体里的多字节 UTF-8。
