#!/usr/bin/env bash

# Config defaults
SCRATCHES_CONFIG_FILE="$HOME/.scratches-config" # e.g. /Users/xyz/.scratches-config
SCRATCHES_DIRECTORY="$HOME/scratches" # e.g. /Users/xyz/scratches
SCRATCHES_HOST_NAME="scratch" # e.g. http://xyz.scratch
SCRATCHES_AUTOSTART=1 # start scratch after creation
SCRATCHES_AUTOOPEN=1 # open scratch in browser after creation
SCRATCHES_AUTOEDIT=1 # open scratch in editor after creation

# Check if the config file exists; if not, create it with default values
if [ ! -f "$SCRATCHES_CONFIG_FILE" ]; then
  echo "Creating new scratches config file at $SCRATCHES_CONFIG_FILE"
  echo "SCRATCHES_CONFIG_FILE=\"$SCRATCHES_CONFIG_FILE\"" > "$SCRATCHES_CONFIG_FILE"
  echo "SCRATCHES_DIRECTORY=\"$SCRATCHES_DIRECTORY\"" >> "$SCRATCHES_CONFIG_FILE"
  echo "SCRATCHES_HOST_NAME=\"$SCRATCHES_HOST_NAME\"" >> "$SCRATCHES_CONFIG_FILE"
  echo "SCRATCHES_AUTOSTART=$SCRATCHES_AUTOSTART" >> "$SCRATCHES_CONFIG_FILE"
  echo "SCRATCHES_AUTOOPEN=$SCRATCHES_AUTOOPEN" >> "$SCRATCHES_CONFIG_FILE"
  echo "SCRATCHES_AUTOEDIT=$SCRATCHES_AUTOEDIT" >> "$SCRATCHES_CONFIG_FILE"
fi

# Load the config file
source "$SCRATCHES_CONFIG_FILE"

function sudo_exec(){
  local cmd=$1
  # Execute the supplied command as sudo
  sudo -- sh -c -e "$cmd"
}

function register_hostname(){
  local scr_uuid=$1
  local host="127.0.0.1"
  local domain="$scr_uuid.$SCRATCHES_HOST_NAME"

  # Check if host is already registered"
  if grep -q "$domain" /etc/hosts; then
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
  local dir="$SCRATCHES_DIRECTORY/$scr_uuid"

  if [ -d "$dir" ]; then
    return 0
  fi

  return 1
}

function create_assets() {
  local scr_uuid=$1
  local dir="$SCRATCHES_DIRECTORY/$scr_uuid"

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

  local dir="$SCRATCHES_DIRECTORY/$scr_uuid"

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

  if [ "$SCRATCHES_AUTOSTART" == "1" ]; then
    start_scratch "$scr_uuid"
  fi

  if [ "$SCRATCHES_AUTOOPEN" == "1" ]; then
    open_scratch "$scr_uuid"
  fi

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
  local dir="$SCRATCHES_DIRECTORY/$scr_uuid"
  local open_port=$(get_open_port)
  local tmp_file=$(mktemp)

  if [ -z "$pid" ]; then
    local address="$scr_uuid.$SCRATCHES_HOST_NAME:$open_port"
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
  code "$SCRATCHES_DIRECTORY/$scr_uuid"
}

function remove_scratch(){
  local scr_uuid=$1
  local dir=$SCRATCHES_DIRECTORY/$scr_uuid
  local pid=$(get_scratch_pid $scr_uuid)

  if [ -n "$pid" ]; then
    echo "Stopping scratch '$scr_uuid'"
    stop_scratch $scr_uuid
  fi

  if [ ! -d "$dir" ]; then
    echo "Scratch '$scr_uuid' does not exist"
    return
  fi

  unregister_hostname $scr_uuid
  rm -rf "$dir"
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
  for pid in $(pgrep -f "$SCRATCHES_DIRECTORY"); do
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
    printf "%-$1s" "$2"
  }

  local all_scratches=$(list_all_scratches_json)
  local n=0
  local longest_id=0

  for scratch in $(echo "$all_scratches" | jq -r '.[] | @base64'); do
    n=$((n+1))
  done

  for scratch in $(echo "$all_scratches" | jq -r '.[] | @base64'); do
    local id=$(_jq '.id')
    local id_length=${#id}

    if [ $id_length -gt $longest_id ]; then
      longest_id=$id_length
    fi
  done

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

    line="$(_pad 3 "$n")"
    line="$line $(_pad 9 "$status")"
    line="$line $(_pad 7 "$pid")"
    line="$line $(_pad $((longest_id+2)) "$id")"
    line="$line $address"

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

function is_installed(){
  if ! which $1 > /dev/null; then
    echo "0"
  else
    echo "1"
  fi
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
elif [ "$1" = "ls" ]; then
  list_all_scratches
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
  echo "  jsonls - lists all scratches as json"
  echo "  open - opens a scratch in your default browser"
  echo "  start - starts all scratches"
  echo "  stop - stops all scratches"
  echo "  edit - opens a scratch in visual studio code (requires vscode)"
  if [ $(is_installed "ngrok") -eq 1 ]; then
    echo "  tunnel - tunnel a scratch (requires ngrok)"
  fi
fi