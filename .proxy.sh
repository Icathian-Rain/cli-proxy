# ~/.proxy.sh
#
# 用法：
#   source ~/.proxy.sh
#   proxy on
#   proxy socks5
#   proxy off
#   proxy status
#   proxy test
#   proxy git on

: "${PROXY_HOST:=127.0.0.1}"
: "${PROXY_HTTP_PORT:=7897}"
: "${PROXY_SOCKS5_PORT:=${PROXY_HTTP_PORT}}"
: "${PROXY_NO_PROXY:=localhost,127.0.0.1}"

_proxy_http_url() {
  printf '%s\n' "http://${PROXY_HOST}:${PROXY_HTTP_PORT}"
}

_proxy_socks5_url() {
  printf '%s\n' "socks5://${PROXY_HOST}:${PROXY_SOCKS5_PORT}"
}

_proxy_current() {
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

_proxy_apply() {
  local http_url="$1"
  local socks_url="$2"

  export http_proxy="$http_url"
  export https_proxy="$http_url"
  export HTTP_PROXY="$http_url"
  export HTTPS_PROXY="$http_url"
  export all_proxy="$socks_url"
  export ALL_PROXY="$socks_url"
  export no_proxy="$PROXY_NO_PROXY"
  export NO_PROXY="$PROXY_NO_PROXY"
}

_proxy_is_success() {
  case "$1" in
    2??|3??) return 0 ;;
    *) return 1 ;;
  esac
}

_proxy_probe() {
  local proxy_url="$1"
  local url="$2"

  curl -x "$proxy_url" -o /dev/null -sS --connect-timeout 5 --max-time 10 -w '%{http_code} %{time_total}' "$url" 2>/dev/null || printf '%s' 'FAILED 0'
}

_proxy_test_all_targets() {
  printf '%s\n' \
    'https://www.google.com' \
    'https://github.com' \
    'https://gitlab.com' \
    'https://www.cloudflare.com' \
    'https://www.microsoft.com'
}

_proxy_help() {
  cat <<EOF
proxy 用法:
  proxy on                  使用默认 HTTP 代理 ${PROXY_HOST}:${PROXY_HTTP_PORT}
  proxy socks5              使用默认 SOCKS5 代理 ${PROXY_HOST}:${PROXY_SOCKS5_PORT}
  proxy set <url>           手动设置代理 URL
  proxy set socks5 <addr>   手动设置 SOCKS5 代理
  proxy off                 清除当前会话代理
  proxy status              查看当前状态
  proxy test                测试当前代理
  proxy test_all            并行测试多个站点
  proxy git on|off|status   管理 Git 代理

可选环境变量:
  PROXY_HOST
  PROXY_HTTP_PORT
  PROXY_SOCKS5_PORT
  PROXY_NO_PROXY
EOF
}

proxy() {
  local command="${1:-help}"
  shift 2>/dev/null || true

  case "$command" in
    on)
      _proxy_apply "$(_proxy_http_url)" "$(_proxy_socks5_url)"
      echo "proxy on: http=${PROXY_HOST}:${PROXY_HTTP_PORT}, socks5=${PROXY_HOST}:${PROXY_SOCKS5_PORT}"
      ;;
    socks5)
      local socks_url
      socks_url="$(_proxy_socks5_url)"
      _proxy_apply "$socks_url" "$socks_url"
      echo "proxy socks5: ${PROXY_HOST}:${PROXY_SOCKS5_PORT}"
      ;;
    set)
      if [ $# -eq 1 ]; then
        _proxy_apply "$1" "$1"
        echo "proxy set: $1"
      elif [ $# -eq 2 ] && [ "$1" = "socks5" ]; then
        local socks_url="${2}"
        case "$socks_url" in
          socks5://*|socks5h://*) ;;
          *) socks_url="socks5://${socks_url}" ;;
        esac
        _proxy_apply "$socks_url" "$socks_url"
        echo "proxy set socks5: ${socks_url}"
      else
        echo "用法: proxy set <url> | proxy set socks5 <host:port>" >&2
        return 1
      fi
      ;;
    off|unset)
      unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
      unset all_proxy ALL_PROXY
      unset no_proxy NO_PROXY
      echo "proxy off"
      ;;
    status)
      echo "http_proxy=${http_proxy:-${HTTP_PROXY:-未设置}}"
      echo "https_proxy=${https_proxy:-${HTTPS_PROXY:-未设置}}"
      echo "all_proxy=${all_proxy:-${ALL_PROXY:-未设置}}"
      echo "no_proxy=${no_proxy:-${NO_PROXY:-未设置}}"
      ;;
    test)
      local proxy_url
      proxy_url="$(_proxy_current)" || {
        echo "未设置代理，请先运行 proxy on / proxy socks5 / proxy set ..." >&2
        return 1
      }
      echo "testing: ${proxy_url}"
      curl -x "$proxy_url" -I -sS --connect-timeout 5 --max-time 10 https://www.google.com | head -n 1
      ;;
    test_all)
      local proxy_url
      proxy_url="$(_proxy_current)" || {
        echo "未设置代理，请先运行 proxy on / proxy socks5 / proxy set ..." >&2
        return 1
      }

      local tmp_dir
      tmp_dir=$(mktemp -d)
      local url
      local index=0
      local total=0
      local success=0
      local failed=0
      local result_file
      local http_code
      local time_total

      echo "testing all via: ${proxy_url}"

      while IFS= read -r url; do
        [ -n "$url" ] || continue
        index=$((index + 1))
        total=$((total + 1))
        (
          _proxy_probe "$proxy_url" "$url" > "${tmp_dir}/${index}.result"
        ) &
        printf '%s\n' "$url" > "${tmp_dir}/${index}.url"
      done <<EOF
$(_proxy_test_all_targets)
EOF

      wait

      index=1
      while [ "$index" -le "$total" ]; do
        url=$(cat "${tmp_dir}/${index}.url")
        result_file="${tmp_dir}/${index}.result"
        if [ -f "$result_file" ]; then
          read -r http_code time_total < "$result_file"
        else
          http_code='FAILED'
          time_total='0'
        fi

        if _proxy_is_success "$http_code"; then
          echo "[${http_code}] ${url} ${time_total}s"
          success=$((success + 1))
        else
          echo "[${http_code}] ${url}"
          failed=$((failed + 1))
        fi

        index=$((index + 1))
      done

      rm -rf "$tmp_dir"
      echo "done: ${success}/${total} success, ${failed} failed"
      [ "$failed" -eq 0 ]
      ;;
    git)
      case "${1:-}" in
        on)
          local proxy_url
          proxy_url="$(_proxy_current)" || {
            echo "未设置代理，请先运行 proxy on / proxy socks5 / proxy set ..." >&2
            return 1
          }
          git config --global http.proxy "$proxy_url"
          git config --global https.proxy "$proxy_url"
          echo "git proxy on: ${proxy_url}"
          ;;
        off)
          git config --global --unset http.proxy 2>/dev/null || true
          git config --global --unset https.proxy 2>/dev/null || true
          echo "git proxy off"
          ;;
        status)
          echo "git http.proxy=$(git config --global --get http.proxy || echo 未设置)"
          echo "git https.proxy=$(git config --global --get https.proxy || echo 未设置)"
          ;;
        *)
          echo "用法: proxy git on|off|status" >&2
          return 1
          ;;
      esac
      ;;
    help|-h|--help)
      _proxy_help
      ;;
    *)
      echo "未知命令: ${command}" >&2
      _proxy_help >&2
      return 1
      ;;
  esac
}
