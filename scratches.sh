#!/usr/bin/env bash

scr_dir=$HOME/scratches
scr_hostname="scratch"
scr_hosts_file="/etc/hosts"
scr_scratch_file=".scratch"

function sudo_exec(){
  local cmd=$1
  sudo -- sh -c -e "$cmd"
}

function register_hostname(){
  local scr_uuid=$1
  local host="127.0.0.1"
  local domain="$scr_uuid.$scr_hostname"

  if grep -q "$domain" $scr_hosts_file; then
    return
  fi

  sudo_exec "echo $host $domain >> /etc/hosts"
}

function unregister_hostname(){
  sudo_exec "sed -i '' '/$1/d' /etc/hosts"
}

function slugify() {
  echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

function scratch_is_duplicate(){
  local scr_uuid=$1
  local dir="$scr_dir/$scr_uuid"

  if [ -d "$dir" ]; then
    echo "Scratch '$scr_uuid' already exists"
    return 0
  fi

  return 1
}

function create_assets() {
  local scr_uuid=$1
  local dir="$scr_dir/$scr_uuid"

  touch "$dir/index.js"
  touch "$dir/index.css"

  echo "function main(){\n\tconsole.log('Hello World')\n}" > "$dir/index.js"
  echo "body { background-color: #000; color: #fff; }" > "$dir/index.css"
}

function new_scratch(){
  read -p "Enter a name for the scratch (optional): " scr_name
  scr_uuid=$(slugify "$scr_name")

  if [ -z "$scr_uuid" ]; then
    scr_uuid=$(uuidgen | cut -d'-' -f1)
  fi

  if scratch_is_duplicate "$scr_uuid"; then
    echo "Scratch '$scr_uuid' already exists"
    return
  fi

  local dir="$scr_dir/$scr_uuid"

  read -p "Want me to set up simple JS and CSS files? (y/n): " create_assets

  # copy blueprint files to target directory
  if [ "$create_assets" == "y" ]; then
    cp -r "$HOME/src/gh-scratches//blueprints/simple" "$dir"
  else
    cp -r "$HOME/src/gh-scratches//blueprints/raw" "$dir"
  fi

  # create log files
  touch "$dir/error.log"

  # replace placeholders
  local escaped_dir=$(echo "$dir" | sed 's/\//\\\//g')
  sed -i '' "s/%DIRECTORY%/$escaped_dir/g" "$dir/index.php"
  sed -i '' "s/%TITLE%/$scr_uuid/g" "$dir/index.php"

  register_hostname "$scr_uuid"
  start_scratch "$scr_uuid"

  echo "Created scratch '$scr_uuid'"
}

function get_open_port() {
  local low_bount=49152
  local range=16384
  while true; do
    local port=$((low_bount + (RANDOM % range)))
    (echo "" >/dev/tcp/127.0.0.1/${port}) >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo $port
      break
    fi
  done
}

function start_scratch(){
  local scr_uuid=$1
  local pid=$(get_scratch_pid "$scr_uuid")
  local dir="$scr_dir/$scr_uuid"
  local open_port=$(get_open_port)
  local tmp_file=$(mktemp)

  if [ -z "$pid" ]; then
    local address="$scr_uuid.$scr_hostname:$open_port"
    php -q \
      -d error_reporting=E_ALL \
      -d error_log="$dir/error.log" \
      -d access.log="$dir/access.log" \
      -S "$address" \
      -t "$dir" > "$tmp_file" 2>&1 &
  fi
}

function stop_scratch(){
  local pid=$(get_scratch_pid $1)

  if [ -n "$pid" ]; then
    sudo_exec "kill $pid"
    echo "Stopped scratch '$1'"
  else
    echo "Scratch '$1' is not running"
  fi
}

function edit_scratch(){
  local scr_uuid=$1
  code "$scr_dir/$scr_uuid"
}

function remove_scratch(){
  local scr_uuid=$1
  local scr_dir=$scr_dir/$scr_uuid

  if [ ! -d "$scr_dir" ]; then
    echo "Scratch '$scr_uuid' does not exist"
    return
  fi

  unregister_hostname $scr_uuid
  stop_scratch $scr_uuid
  rm -rf "$scr_dir/$scr_uuid"
  echo "Removed scratch '$scr_uuid'"
}

function start_all_scratches(){
  local n=0
  local scratches=$(get_all_scratches)
  for scr_uuid in $scratches; do
    start_scratch $scr_uuid
    n=$(($n+1))
  done
  echo "Started $n scratches"
}

function stop_all_scratches() {
  local n=0
  for pid in $(pgrep -f "$scr_dir"); do
    sudo_exec "kill $pid"
    n=$((n+1))
  done
  echo "Stopped $n scratches"
}


function get_scratch_address(){
  scr_uuid=$1
  address=$(ps aux | grep $scr_uuid | awk '/php/ && /-S.*\.scratch/ {for(i=1; i<=NF; i++) if ($i ~ /\.scratch/) print $i}')

  if [ -z "$address" ]; then
    echo ""
  else
    echo "http://$address"
  fi
}

function get_scratch_pid(){
  scr_uuid=$1

  ps ax | grep 'php' | while read line; do
    pid=$(echo $line | awk '{print $1}')

    if [[ $line == *$scr_uuid* ]]; then
      echo $pid
    fi
  done
}

function get_all_scratches(){
  local scratches=()
  for dir in "$scr_dir"/*; do
    if [ -f "$dir/index.php" ] || [ -f "$dir/index.html" ]; then
      scratches+=($(basename $dir))
    fi
  done
  echo ${scratches[@]}
}

function list_all_scratches(){
  local n=0
  local scratches=$(get_all_scratches)
  for scr_uuid in $scratches; do
    local pid=$(get_scratch_pid $scr_uuid)
    if [ -z "$pid" ]; then
      echo "STOPPED\t$pid\t$scr_uuid"
    else
      local url=$(get_scratch_address $scr_uuid)
      echo "RUNNING\t$pid\t$scr_uuid\t$url"
    fi
    n=$((n+1))
  done
  if [ $n -eq 0 ]; then
    echo "No scratches found"
  fi
}

function open_scratch(){
  local scr_uuid=$1
  local pid=$(get_scratch_pid $scr_uuid)

  if [ -z "$pid" ]; then
    start_scratch $scr_uuid
  fi

  local url=$(get_scratch_address $scr_uuid)

  if [ -z "$url" ]; then
    echo "Scratch '$scr_uuid' is not running"
    return
  fi

  open $url
}

function is_installed(){
  if ! which $1 > /dev/null; then
    echo "0"
  else
    echo "1"
  fi
}

function start_ngrok_tunnel(){
  local scr_uuid=$1
  local scratches=$(get_all_scratches)

  for id in $scratches; do
    if [ -n "$scr_uuid" ] && [ "$scr_uuid" != "$id" ]; then
      continue
    fi
    local url=$(get_scratch_address $scr_uuid)
    local port=$(echo $url | cut -d':' -f3)
  done

  if [ -z "$port" ]; then
    echo "Scratch '$scr_uuid' is not running"
    return
  fi

  ngrok http "$host:$port"
}

function require_param(){
  if [ -z "$1" ]; then
    echo "$2"
    exit 1
  fi
}

if [ "$1" = "tunnel" ]; then
  require_param "$2" "Please provide a scratch id."
  if [ "$(is_installed "ngrok")" -eq 1 ]; then
    start_ngrok_tunnel "$2"
  else
    echo "ngrok is not installed"
  fi
elif [ "$1" = "new" ]; then
  new_scratch
elif [ "$1" = "ls" ]; then
  list_all_scratches
elif [ "$1" = "edit" ]; then
  require_param "$2" "Please provide a scratch id."
  edit_scratch "$2"
elif [ "$1" = "open" ]; then
  require_param "$2" "Please provide a scratch id."
  open_scratch "$2"
elif [ "$1" = "rm" ]; then
  require_param "$2" "Please provide a scratch id."
  remove_scratch "$2"
elif [ "$1" = "start" ]; then
  if [ -z "$2" ]; then
    start_all_scratches
  else
    start_scratch "$2"
  fi
elif [ "$1" = "stop" ]; then
  if [ -z "$2" ]; then
    stop_all_scratches
  else
    stop_scratch "$2"
  fi
else
  echo "scratches.sh"
  echo "  new - create a new scratch"
  echo "  list - list all scratches"
  echo "  open - open a scratch in your default browser"
  echo "  start - start all scratches"
  echo "  stop - stop all scratches"
  echo "  edit - edit a scratch (requires vscode)"
  if [ $(is_installed "ngrok") -eq 1 ]; then
    echo "  tunnel - tunnel a scratch (requires ngrok)"
  fi
fi