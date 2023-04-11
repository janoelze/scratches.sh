#!/usr/bin/env bash

# find real path to current script entry point
SCRATCHES_SRC_PATH="$( cd "$(dirname "$0")" ; pwd -P )"
SCRATCHES_SRC_PARENT_PATH="$(dirname "$SCRATCHES_SRC_PATH")"

if [[ "$SCRATCHES_SRC_PARENT_PATH" == "." ]]; then
  SCRATCHES_SRC_PARENT_PATH=$(realpath "$path")
fi

# Config defaults
SCRATCHES_HOME="$SCRATCHES_SRC_PARENT_PATH"
SCRATCHES_DIRECTORY="$SCRATCHES_SRC_PARENT_PATH/env" # e.g. /Users/xyz/scratches
SCRATCHES_HOST_NAME="scratch" # e.g. http://xyz.scratch
SCRATCHES_AUTOSTART=1 # start scratch after creation
SCRATCHES_AUTOOPEN=1 # open scratch in browser after creation
SCRATCHES_AUTOEDIT=1 # open scratch in editor after creation

# Helpers

function sudo_exec(){
  local cmd=$1
  sudo -- sh -c -e "$cmd"
}

function update_scratches(){
  sh $SCRIPT_PATH/install.sh
}

function is_installed(){
  # Check if the command in $1 is installed
  if ! which $1 > /dev/null; then
    echo "0"
  else
    echo "1"
  fi
}

function slugify() {
  echo "$@" | tr '[:upper:]' '[:lower:]' | sed -E 's/[^a-zA-Z0-9]+/-/g' | sed -E 's/(^-+)|(-+$)//g'
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

# /etc/hosts management

function hostname_is_registered(){
  local scr_uuid=$1
  local domain="$scr_uuid.$SCRATCHES_HOST_NAME"

  if grep -q "$domain" /etc/hosts; then
    return 0
  fi

  return 1
}

function register_hostname(){
  local scr_uuid=$1
  local host="127.0.0.1"
  local domain="$scr_uuid.$SCRATCHES_HOST_NAME"
  sudo_exec "echo $host $domain >> /etc/hosts"
}

function unregister_hostname(){
  sudo_exec "sed -i '' '/$1/d' /etc/hosts"
}

# Scratch management

function scratch_is_duplicate(){
  local scr_uuid=$1

  if [ -d "$SCRATCHES_DIRECTORY/$scr_uuid" ]; then
    return 0
  fi

  return 1
}

function new_scratch(){
  read -p "Enter a name for the scratch (optional): " scr_name

  local scr_uuid=$(slugify "$scr_name")

  if [ -z "$scr_uuid" ]; then
    scr_uuid=$(uuidgen | cut -d'-' -f1)
  fi

  if scratch_is_duplicate "$scr_uuid"; then
    echo "Scratch '$scr_uuid' already exists"
    return
  fi

  local SCRATCH_DIR="$SCRATCHES_DIRECTORY/$scr_uuid"
  local BLUEPRINT_DIR="$SCRATCHES_SRC_PATH/blueprints/default"

  # create directory
  cp -r "$BLUEPRINT_DIR" "$SCRATCH_DIR"

  # rename files
  mv "$SCRATCH_DIR/default.js" "$SCRATCH_DIR/$scr_uuid.js"
  mv "$SCRATCH_DIR/default.css" "$SCRATCH_DIR/$scr_uuid.css"

  # replace placeholders
  sed -i '' "s/default.css/$scr_uuid.css/g" "$SCRATCH_DIR/index.php"
  sed -i '' "s/default.js/$scr_uuid.js/g" "$SCRATCH_DIR/index.php"

  # create log files
  touch "$SCRATCH_DIR/error.log"

  # replace placeholders
  local escaped_dir=$(echo "$SCRATCH_DIR" | sed 's/\//\\\//g')
  sed -i '' "s/%DIRECTORY%/$escaped_dir/g" "$SCRATCH_DIR/index.php"
  sed -i '' "s/%TITLE%/$scr_uuid/g" "$SCRATCH_DIR/index.php"

  if ! hostname_is_registered "$scr_uuid"; then
    register_hostname "$scr_uuid"
  fi

  if [ "$SCRATCHES_AUTOSTART" == "1" ]; then
    start_scratch "$scr_uuid"
  fi

  if [ "$SCRATCHES_AUTOOPEN" == "1" ]; then
    open_scratch "$scr_uuid"
  fi

  echo "Created scratch '$scr_uuid'"
}

function start_scratch(){
  local scr_uuid=$1
  local pid=$(get_scratch_pid "$scr_uuid")
  local dir="$SCRATCHES_DIRECTORY/$scr_uuid"
  local open_port=$(get_open_port)
  local tmp_file=$(mktemp)

  if [ -z "$pid" ]; then
    local address="$scr_uuid.$SCRATCHES_HOST_NAME:$open_port"
    php -q \
      -d error_reporting=E_ALL \
      -d error_log="$dir/error.log" \
      -S "$address" \
      -t "$dir" > "$tmp_file" 2>&1 &
  fi
}

function stop_scratch(){
  local pid=$(get_scratch_pid $1)

  if [ -n "$pid" ]; then
    sudo_exec "kill $pid"
  fi
}

function edit_scratch(){
  local scr_uuid=$1
  code "$SCRATCHES_DIRECTORY/$scr_uuid"
}

function remove_scratch(){
  local scr_uuid=$1
  local dir=$SCRATCHES_DIRECTORY/$scr_uuid
  local pid=$(get_scratch_pid $scr_uuid)

  if [ -n "$pid" ]; then
    echo "Stopping scratch"
    stop_scratch $scr_uuid
  fi

  if [ -d "$dir" ]; then
    echo "Removing scratch directory"
    rm -rf "$dir"
  fi

  if hostname_is_registered $scr_uuid; then
    echo "Removing hostname from /etc/hosts"
    unregister_hostname $scr_uuid
  fi
}

function scratch_pid_is_running() {
  local res=$(ps -p $1 | grep "php")
  # if res is empty, the process is not running
  if [ -z "$res" ]; then
    echo "0"
  else
    echo "1"
  fi
}

function start_all_scratches(){
  local scratches=$(list_all_scratches_json)
  local n=0

  for scratch_id in $(echo "$scratches" | jq -r '.[] | select(.status != "running") | .id'); do
    start_scratch $scratch_id
    n=$((n+1))
  done

  echo "Started $n scratches"
}

function stop_all_scratches() {
  local n=0
  local tmp_file=$(mktemp)

  ps aux | grep 'php' | grep -v "grep" > "$tmp_file"

  while read line; do
    pid=$(echo $line | awk '{print $2}')
    sudo_exec "kill $pid"
    n=$((n+1))
  done < "$tmp_file"

  rm "$tmp_file"
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
  for dir in "$SCRATCHES_DIRECTORY"/*; do
    if [ -f "$dir/index.php" ] || [ -f "$dir/index.html" ]; then
      scratches+=($(basename $dir))
    fi
  done
  echo ${scratches[@]}
}

function list_all_scratches(){
  _jq() {
    echo ${scratch} | base64 --decode | jq -r ${1}
  }

  _pad(){
    # pad left
    local string=$2
    local length=$1
    local pad_char=" "
    echo "$string" | awk -v len=$length -v pad="$pad_char" '{ printf "%-" len "s", $0 }'
  }

  local all_scratches=$(list_all_scratches_json)
  local n=0
  local longest_id=0

  for scratch_id in $(echo "$all_scratches" | jq -r '.[] | .id'); do
    local string_length=$(echo -n "$scratch_id" | wc -m)
    local string_length=$((string_length))

    if [ $string_length -gt $longest_id ]; then
      longest_id=$string_length
    fi
  done

  longest_id=$((longest_id-2))

  for scratch in $(echo "$all_scratches" | jq -r '.[] | @base64'); do
    n=$((n+1))

    local line=""
    local id=$(_jq '.id')
    local pid=$(_jq '.pid')
    local host=$(_jq '.host')
    local port=$(_jq '.port')
    local status=$(_jq '.status')
    local address="http://$host:$port"

    if [ "$status" == "stopped" ]; then
      address="n/a"
      pid="n/a"
    fi

    line+="$(_pad 3 $n)"
    line+="$(_pad $longest_id $id)"
    line+="$(_pad 11 "pid $pid")"
    line+="$(_pad 9 $status)"
    line+="$(_pad 30 $address)"

    echo "$line"
  done
}

function get_scratch_field () {
  local all_scratches=$1
  local scratch_id=$2
  local field=".$3"
  echo "$all_scratches" | jq -r ".[] | select(.id == \"$scratch_id\") | $field"
}

function open_scratch(){
  local scratch_id=$1
  local all_scratches=$(list_all_scratches_json)
  local scratch_status=$(get_scratch_field "$all_scratches" "$scratch_id" "status")

  if [ "$scratch_status" == "stopped" ]; then
    start_scratch $scratch_id
  fi

  local scratch_host=$(get_scratch_field "$all_scratches" "$scratch_id" "host")
  local scratch_port=$(get_scratch_field "$all_scratches" "$scratch_id" "port")

  if [ -z "$scratch_host" ] || [ -z "$scratch_port" ]; then
    echo "Scratch '$scratch_id' is not running"
    return
  fi

  open "http://$scratch_host:$scratch_port"
}

function start_ngrok_tunnel(){
  local scratch_id=$1
  local all_scratches=$(list_all_scratches_json)

  local scratch_host=$(get_scratch_field "$all_scratches" "$scratch_id" "host")
  local scratch_port=$(get_scratch_field "$all_scratches" "$scratch_id" "port")

  if [ -z "$scratch_port" ]; then
    echo "Scratch '$scratch_id' is not running"
    return
  fi

  ngrok http $scratch_host:$scratch_port
}

function get_scratch_dir(){
  local scr_uuid=$1
  echo "$SCRATCHES_DIRECTORY/$scr_uuid"
}

function list_all_scratches_json(){
  local scratches=$(get_all_scratches)

  if [ -z "$scratches" ]; then
    echo "[]"
    return
  fi

  local json="["
  for scr_uuid in $scratches; do
    local pid=$(get_scratch_pid $scr_uuid)
    local dir=$(get_scratch_dir $scr_uuid)
    if [ -z "$pid" ]; then
      json="$json{\"id\":\"$scr_uuid\",\"status\":\"stopped\",\"directory\":\"$dir\"},"
    else
      local url=$(get_scratch_address $scr_uuid)
      local port=$(echo $url | cut -d':' -f3)
      local host=$(echo $url | cut -d':' -f2 | cut -d'/' -f3)
      local protocol=$(echo $url | cut -d':' -f1)
      json="$json{\"id\":\"$scr_uuid\",\"status\":\"running\",\"protocol\":\"$protocol\",\"host\":\"$host\",\"url\":\"$url\",\"pid\":$pid,\"port\":$port,\"directory\":\"$dir\"},"
    fi
  done
  json="${json%?}]"
  echo $json | jq
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
elif [ "$1" = "update" ]; then
  update_scratches
elif [ "$1" = "ls" ]; then
  list_all_scratches
elif [ "$1" = "ps" ]; then
  list_processes_json
elif [ "$1" = "jsonls" ]; then
  list_all_scratches_json
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
  echo "  new - creates a new scratch"
  echo "  ls - lists all scratches"
  echo "  open - opens a scratch in your default browser"
  echo "  start - starts all scratches"
  echo "  stop - stops all scratches"
  echo "  edit - opens a scratch in visual studio code (requires vscode)"
  if [ $(is_installed "ngrok") -eq 1 ]; then
    echo "  tunnel - tunnel a scratch (requires ngrok)"
  fi
fi