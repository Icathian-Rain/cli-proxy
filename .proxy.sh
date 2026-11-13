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

_proxy_color_red='\033[31m'
_proxy_color_green='\033[32m'
_proxy_color_blue='\033[34m'
_proxy_color_dim='\033[2m'
_proxy_color_reset='\033[0m'

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
  local result
  local curl_exit

  result=$(curl -x "$proxy_url" -o /dev/null -sS --connect-timeout 5 --max-time 10 -w '%{http_code} %{time_total}' "$url" 2>/dev/null)
  curl_exit=$?

  if [ "$curl_exit" -eq 0 ]; then
    printf '%s %s\n' "$result" "$curl_exit"
  else
    printf '000 0 %s\n' "$curl_exit"
  fi
}

_proxy_target_name() {
  local url="$1"
  local name

  name="${url#*://}"
  name="${name#www.}"
  name="${name%%/*}"
  printf '%s\n' "$name"
}

_proxy_duration_ms() {
  awk -v seconds="$1" 'BEGIN {
    if (seconds ~ /^[0-9]+(\.[0-9]+)?$/) {
      printf "%.0fms\n", seconds * 1000
    } else {
      print "0ms"
    }
  }'
}

_proxy_failure_reason() {
  case "$1" in
    5) printf '%s\n' 'dns failed' ;;
    6) printf '%s\n' 'host not found' ;;
    7) printf '%s\n' 'connect failed' ;;
    28) printf '%s\n' 'timeout' ;;
    35) printf '%s\n' 'tls failed' ;;
    52) printf '%s\n' 'empty reply' ;;
    56) printf '%s\n' 'connection reset' ;;
    *)
      if [ "$1" = "0" ]; then
        printf '%s\n' 'request failed'
      else
        printf 'curl exit %s\n' "$1"
      fi
      ;;
  esac
}

_proxy_print_summary() {
  local success="$1"
  local total="$2"
  local failed="$3"

  if [ "$failed" -eq 0 ]; then
    printf '%b✔%b summary: %b%s/%s success%b, %s failed\n' \
      "$_proxy_color_green" "$_proxy_color_reset" \
      "$_proxy_color_green" "$success" "$total" "$_proxy_color_reset" \
      "$failed"
  else
    printf '%b✘%b summary: %s/%s success, %b%s failed%b\n' \
      "$_proxy_color_red" "$_proxy_color_reset" \
      "$success" "$total" \
      "$_proxy_color_red" "$failed" "$_proxy_color_reset"
  fi
}

_proxy_print_header() {
  local label="$1"
  local value="$2"

  printf '%b›%b %b%s%b %s\n' \
    "$_proxy_color_blue" "$_proxy_color_reset" \
    "$_proxy_color_dim" "$label" "$_proxy_color_reset" \
    "$value"
}

_proxy_print_value_line() {
  local label="$1"
  local value="$2"

  printf '  %b%-12s%b %s\n' \
    "$_proxy_color_dim" "$label" "$_proxy_color_reset" \
    "$value"
}

_proxy_print_action() {
  local action="$1"
  local detail="$2"

  printf '%b✔%b %b%s%b %s\n' \
    "$_proxy_color_green" "$_proxy_color_reset" \
    "$_proxy_color_dim" "$action" "$_proxy_color_reset" \
    "$detail"
}

_proxy_print_status_value() {
  if [ "$1" = "未设置" ]; then
    printf '%b%s%b\n' "$_proxy_color_dim" "$1" "$_proxy_color_reset"
  else
    printf '%s\n' "$1"
  fi
}

_proxy_print_probe_result() {
  local url="$1"
  local http_code="$2"
  local time_total="$3"
  local curl_exit="$4"
  local name
  local duration_ms
  local reason

  name="$(_proxy_target_name "$url")"
  duration_ms="$(_proxy_duration_ms "$time_total")"

  if _proxy_is_success "$http_code"; then
    printf '%b✔%b %-18s %b%s%b  %s\n' \
      "$_proxy_color_green" "$_proxy_color_reset" \
      "$name" \
      "$_proxy_color_dim" "$http_code" "$_proxy_color_reset" \
      "$duration_ms"
  else
    reason="$(_proxy_failure_reason "$curl_exit")"
    printf '%b✘%b %-18s %b%s%b  %b%s%b\n' \
      "$_proxy_color_red" "$_proxy_color_reset" \
      "$name" \
      "$_proxy_color_dim" "$http_code" "$_proxy_color_reset" \
      "$_proxy_color_dim" "$reason" "$_proxy_color_reset"
  fi
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
  PROXY_AUTO_ON           source 时自动开启代理 (1/http=on, socks5=socks5)
EOF
}

proxy() {
  local command="${1:-help}"
  shift 2>/dev/null || true

  case "$command" in
    menu)
      # 委托给 .proxy.menu.sh（若已 source）；不用 functions[] 复制函数，zsh 会损坏多字节 UTF-8
      if [ "$(whence -w _proxy_menu 2>/dev/null)" = "_proxy_menu: function" ]; then
        shift 2>/dev/null || true
        _proxy_menu "$@"
      else
        echo "菜单未加载，请先 source .proxy.menu.sh" >&2
        return 1
      fi
      ;;
    on)
      _proxy_apply "$(_proxy_http_url)" "$(_proxy_socks5_url)"
      _proxy_print_action "proxy on" "http=${PROXY_HOST}:${PROXY_HTTP_PORT}, socks5=${PROXY_HOST}:${PROXY_SOCKS5_PORT}"
      ;;
    socks5)
      local socks_url
      socks_url="$(_proxy_socks5_url)"
      _proxy_apply "$socks_url" "$socks_url"
      _proxy_print_action "proxy socks5" "${PROXY_HOST}:${PROXY_SOCKS5_PORT}"
      ;;
    set)
      if [ $# -eq 1 ]; then
        if [ "$1" = "socks5" ] || [ "$1" = "socks5h" ]; then
          echo "用法: proxy set socks5 <host:port>" >&2
          return 1
        fi
        _proxy_apply "$1" "$1"
        _proxy_print_action "proxy set" "$1"
      elif [ $# -eq 2 ] && [ "$1" = "socks5" ]; then
        local socks_url="${2}"
        case "$socks_url" in
          socks5://*|socks5h://*) ;;
          *) socks_url="socks5://${socks_url}" ;;
        esac
        _proxy_apply "$socks_url" "$socks_url"
        _proxy_print_action "proxy set socks5" "$socks_url"
      else
        echo "用法: proxy set <url> | proxy set socks5 <host:port>" >&2
        return 1
      fi
      ;;
    off|unset)
      unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
      unset all_proxy ALL_PROXY
      unset no_proxy NO_PROXY
      _proxy_print_action "proxy off" "cleared current shell"
      ;;
    status)
      local current_http_proxy
      local current_https_proxy
      local current_all_proxy
      local current_no_proxy

      current_http_proxy="${http_proxy:-${HTTP_PROXY:-未设置}}"
      current_https_proxy="${https_proxy:-${HTTPS_PROXY:-未设置}}"
      current_all_proxy="${all_proxy:-${ALL_PROXY:-未设置}}"
      current_no_proxy="${no_proxy:-${NO_PROXY:-未设置}}"

      _proxy_print_header "status" "current shell"
      _proxy_print_value_line "http_proxy" "$(_proxy_print_status_value "$current_http_proxy")"
      _proxy_print_value_line "https_proxy" "$(_proxy_print_status_value "$current_https_proxy")"
      _proxy_print_value_line "all_proxy" "$(_proxy_print_status_value "$current_all_proxy")"
      _proxy_print_value_line "no_proxy" "$(_proxy_print_status_value "$current_no_proxy")"
      ;;
    test)
      local proxy_url
      local url='https://www.google.com'
      local http_code
      local time_total
      local curl_exit
      proxy_url="$(_proxy_current)" || {
        echo "未设置代理，请先运行 proxy on / proxy socks5 / proxy set ..." >&2
        return 1
      }
      read -r http_code time_total curl_exit <<EOF
$(_proxy_probe "$proxy_url" "$url")
EOF
      _proxy_print_header "proxy" "$proxy_url"
      _proxy_print_probe_result "$url" "$http_code" "$time_total" "$curl_exit"
      _proxy_is_success "$http_code"
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
      local curl_exit
      local targets_data
      local target_count=0
      local -a probe_pids=()
      local probe_pid

      targets_data="$(_proxy_test_all_targets)"

      _proxy_print_header "proxy" "$proxy_url"
      while IFS= read -r url; do
        [ -n "$url" ] || continue
        target_count=$((target_count + 1))
      done <<EOF
$targets_data
EOF
      _proxy_print_header "targets" "$target_count"

      {
        set +m 2>/dev/null || true
        while IFS= read -r url; do
          [ -n "$url" ] || continue
          index=$((index + 1))
          total=$((total + 1))
          (
            _proxy_probe "$proxy_url" "$url" > "${tmp_dir}/${index}.result"
          ) &
          probe_pid=$!
          probe_pids+=("$probe_pid")
          printf '%s\n' "$url" > "${tmp_dir}/${index}.url"
        done <<EOF
$targets_data
EOF

        # Only wait for probes started by this invocation.
        for probe_pid in "${probe_pids[@]}"; do
          wait "$probe_pid"
        done
      } 2>/dev/null

      index=1
      while [ "$index" -le "$total" ]; do
        url=$(cat "${tmp_dir}/${index}.url")
        result_file="${tmp_dir}/${index}.result"
        if [ -f "$result_file" ]; then
          read -r http_code time_total curl_exit < "$result_file"
        else
          http_code='000'
          time_total='0'
          curl_exit='0'
        fi

        _proxy_print_probe_result "$url" "$http_code" "$time_total" "$curl_exit"

        if _proxy_is_success "$http_code"; then
          success=$((success + 1))
        else
          failed=$((failed + 1))
        fi

        index=$((index + 1))
      done

      rm -rf "$tmp_dir"
      _proxy_print_summary "$success" "$total" "$failed"
      [ "$failed" -eq 0 ]
      ;;
    git)
      case "${1:-}" in
        on)
          local proxy_url
          local git_http_proxy
          local git_has_http_proxy=0
          proxy_url="$(_proxy_current)" || {
            echo "未设置代理，请先运行 proxy on / proxy socks5 / proxy set ..." >&2
            return 1
          }
          git_http_proxy="$(git config --global --get http.proxy 2>/dev/null)" && git_has_http_proxy=1

          if ! git config --global http.proxy "$proxy_url"; then
            echo "设置 git http.proxy 失败" >&2
            return 1
          fi

          if ! git config --global https.proxy "$proxy_url"; then
            if [ "$git_has_http_proxy" -eq 1 ]; then
              git config --global http.proxy "$git_http_proxy" >/dev/null 2>&1 || true
            else
              git config --global --unset http.proxy >/dev/null 2>&1 || true
            fi
            echo "设置 git https.proxy 失败" >&2
            return 1
          fi

          _proxy_print_action "git proxy on" "$proxy_url"
          ;;
        off)
          git config --global --unset http.proxy 2>/dev/null || true
          git config --global --unset https.proxy 2>/dev/null || true
          _proxy_print_action "git proxy off" "cleared global config"
          ;;
        status)
          local git_http_proxy
          local git_https_proxy

          git_http_proxy="$(git config --global --get http.proxy || echo 未设置)"
          git_https_proxy="$(git config --global --get https.proxy || echo 未设置)"

          _proxy_print_header "git" "global config"
          _proxy_print_value_line "http.proxy" "$(_proxy_print_status_value "$git_http_proxy")"
          _proxy_print_value_line "https.proxy" "$(_proxy_print_status_value "$git_https_proxy")"
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

# source 时按 PROXY_AUTO_ON 自动开启代理: 1/http -> proxy on, socks5 -> proxy socks5
case "${PROXY_AUTO_ON:-}" in
  1|http|on)
    proxy on
    ;;
  socks5)
    proxy socks5
    ;;
esac
