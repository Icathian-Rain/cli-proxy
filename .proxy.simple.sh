# ~/.proxy.simple.sh
#
# 用法：
#   source ~/.proxy.simple.sh
#   proxy on
#   proxy socks5
#   proxy set http://127.0.0.1:7897
#   proxy test
#   proxy off
#   proxy status
#   proxy git on

: "${PROXY_HOST:=127.0.0.1}"
: "${PROXY_HTTP_PORT:=7897}"
: "${PROXY_SOCKS5_PORT:=${PROXY_HTTP_PORT}}"
: "${PROXY_NO_PROXY:=localhost,127.0.0.1}"

_proxy_simple_http_url() {
  printf '%s\n' "http://${PROXY_HOST}:${PROXY_HTTP_PORT}"
}

_proxy_simple_socks5_url() {
  printf '%s\n' "socks5://${PROXY_HOST}:${PROXY_SOCKS5_PORT}"
}

_proxy_simple_apply() {
  export http_proxy="$1"
  export https_proxy="$1"
  export HTTP_PROXY="$1"
  export HTTPS_PROXY="$1"
  export all_proxy="$2"
  export ALL_PROXY="$2"
  export no_proxy="$PROXY_NO_PROXY"
  export NO_PROXY="$PROXY_NO_PROXY"
}

_proxy_simple_current() {
  if [ -n "${http_proxy:-}" ]; then
    printf '%s\n' "$http_proxy"
  elif [ -n "${HTTP_PROXY:-}" ]; then
    printf '%s\n' "$HTTP_PROXY"
  elif [ -n "${all_proxy:-}" ]; then
    printf '%s\n' "$all_proxy"
  elif [ -n "${ALL_PROXY:-}" ]; then
    printf '%s\n' "$ALL_PROXY"
  else
    return 1
  fi
}

_proxy_simple_probe() {
  curl -x "$1" -o /dev/null -sS --connect-timeout 5 --max-time 10 -w '%{http_code} %{time_total}' "$2" 2>/dev/null
}

_proxy_simple_help() {
  cat <<EOF
proxy 用法:
  proxy on
  proxy socks5
  proxy set <url>
  proxy set socks5 <host:port>
  proxy off
  proxy status
  proxy test
  proxy git on|off|status

可选环境变量:
  PROXY_HOST
  PROXY_HTTP_PORT
  PROXY_SOCKS5_PORT
  PROXY_NO_PROXY
EOF
}

proxy() {
  proxy_cmd="${1:-help}"
  shift 2>/dev/null || true

  case "$proxy_cmd" in
    on)
      _proxy_simple_apply "$(_proxy_simple_http_url)" "$(_proxy_simple_socks5_url)"
      printf '%s\n' "proxy on: http=${PROXY_HOST}:${PROXY_HTTP_PORT}, socks5=${PROXY_HOST}:${PROXY_SOCKS5_PORT}"
      ;;
    socks5)
      proxy_socks_url="$(_proxy_simple_socks5_url)"
      _proxy_simple_apply "$proxy_socks_url" "$proxy_socks_url"
      printf '%s\n' "proxy socks5: ${PROXY_HOST}:${PROXY_SOCKS5_PORT}"
      ;;
    set)
      if [ $# -eq 1 ]; then
        _proxy_simple_apply "$1" "$1"
        printf '%s\n' "proxy set: $1"
      elif [ $# -eq 2 ] && [ "$1" = "socks5" ]; then
        proxy_socks_url="$2"
        case "$proxy_socks_url" in
          socks5://*|socks5h://*) ;;
          *) proxy_socks_url="socks5://${proxy_socks_url}" ;;
        esac
        _proxy_simple_apply "$proxy_socks_url" "$proxy_socks_url"
        printf '%s\n' "proxy set socks5: ${proxy_socks_url}"
      else
        printf '%s\n' '用法: proxy set <url> | proxy set socks5 <host:port>' >&2
        return 1
      fi
      ;;
    off|unset)
      unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
      unset all_proxy ALL_PROXY
      unset no_proxy NO_PROXY
      printf '%s\n' 'proxy off'
      ;;
    status)
      printf '%s\n' "http_proxy=${http_proxy:-${HTTP_PROXY:-未设置}}"
      printf '%s\n' "https_proxy=${https_proxy:-${HTTPS_PROXY:-未设置}}"
      printf '%s\n' "all_proxy=${all_proxy:-${ALL_PROXY:-未设置}}"
      printf '%s\n' "no_proxy=${no_proxy:-${NO_PROXY:-未设置}}"
      ;;
    test)
      proxy_test_url='https://www.google.com'
      proxy_test_proxy="$(_proxy_simple_current)" || {
        printf '%s\n' '未设置代理，请先运行 proxy on / proxy socks5 / proxy set ...' >&2
        return 1
      }
      proxy_test_result="$(_proxy_simple_probe "$proxy_test_proxy" "$proxy_test_url")"
      proxy_test_exit=$?
      if [ "$proxy_test_exit" -eq 0 ]; then
        read -r proxy_test_code proxy_test_time <<EOF
$proxy_test_result
EOF
        printf '%s\n' "proxy=${proxy_test_proxy}"
        printf '%s\n' "url=${proxy_test_url}"
        printf '%s\n' "http_code=${proxy_test_code}"
        printf '%s\n' "time=${proxy_test_time}s"
      else
        printf '%s\n' "proxy=${proxy_test_proxy}"
        printf '%s\n' "url=${proxy_test_url}"
        printf '%s\n' "error=curl exit ${proxy_test_exit}"
        return 1
      fi
      ;;
    git)
      case "${1:-}" in
        on)
          proxy_git_url="$(_proxy_simple_current)" || {
            printf '%s\n' '未设置代理，请先运行 proxy on / proxy socks5 / proxy set ...' >&2
            return 1
          }
          git config --global http.proxy "$proxy_git_url"
          git config --global https.proxy "$proxy_git_url"
          printf '%s\n' "git proxy on: ${proxy_git_url}"
          ;;
        off)
          git config --global --unset http.proxy 2>/dev/null || true
          git config --global --unset https.proxy 2>/dev/null || true
          printf '%s\n' 'git proxy off'
          ;;
        status)
          printf '%s\n' "git http.proxy=$(git config --global --get http.proxy || printf '%s' '未设置')"
          printf '%s\n' "git https.proxy=$(git config --global --get https.proxy || printf '%s' '未设置')"
          ;;
        *)
          printf '%s\n' '用法: proxy git on|off|status' >&2
          return 1
          ;;
      esac
      ;;
    help|-h|--help)
      _proxy_simple_help
      ;;
    *)
      printf '%s\n' "未知命令: ${proxy_cmd}" >&2
      _proxy_simple_help >&2
      return 1
      ;;
  esac
}
