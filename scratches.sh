scr_dir=$HOME/scratches
scr_hostname="scratch"
scr_hosts_file="/etc/hosts"
scr_scratch_file=".scratch"
scr_user=$(ls -ld $HOME | awk '{print $3}')

function sudo_exec(){
  local cmd=$1
  sudo -- sh -c -e $cmd
}

function register_hostname(){
  local scr_uuid=$1
  local host="127.0.0.1"
  local domain="$scr_uuid.$scr_hostname"

  sudo_exec "echo $host\t$domain >> /etc/hosts"
}

function unregister_hostname(){
  sudo_exec "sed -i '' '/$1/d' /etc/hosts"
}

function random_id(){
  echo $(uuidgen | cut -d'-' -f1)
}

function slugify() {
  echo $1 | tr '[:upper:]' '[:lower:]' | tr ' ' '-'
}

function scaffold_directory(){
  local scr_uuid=$1
  local dir="$scr_dir/$scr_uuid"

  mkdir -p "$dir"

  touch $dir/index.html
  touch $dir/$scr_scratch_file
  touch $dir/error.log

  echo "Hello World" > $dir/index.html
}

function scratch_is_duplicate(){
  local scr_uuid=$1
  local dir="$scr_dir/$scr_uuid"

  if [ -d "$dir" ]; then
    echo "Scratch '$scr_uuid' already exists."
    return 0
  fi

  return 1
}

function new_scratch(){
  read -p "Enter a name for the scratch (optional): " scr_name
  scr_uuid=$(slugify "$scr_name")

  if [ -z "$scr_uuid" ]; then
    scr_uuid=$(random_id)
  fi

  if scratch_is_duplicate $scr_uuid; then
    echo "Scratch '$scr_uuid' already exists."
    return
  fi

  scaffold_directory $scr_uuid
  register_hostname $scr_uuid
  start_scratch $scr_uuid

  echo "Created scratch '$scr_uuid'."
}

function get_open_port() {
  local low_bount=49152
  local range=16384
  while true; do
    local port=$[$low_bount + ($RANDOM % $range)]
    (echo "" >/dev/tcp/127.0.0.1/${port}) >/dev/null 2>&1
    if [ $? -ne 0 ]; then
      echo $port
      break
    fi
  done
}

function start_scratch(){
  local scr_uuid=$1
  local pid=$(get_scratch_pid $scr_uuid)
  local dir=$scr_dir/$scr_uuid
  local open_port=$(get_open_port)

  if [ -z "$pid" ]; then
    local address="$scr_uuid.$scr_hostname:$open_port"
    php -q \
      -d error_reporting=E_ALL \
      -d error_log=$dir/error.log \
      -d access.log=$dir/access.log \
      -S $address \
      -t $dir > $dir/server.log 2>&1 &
  fi
}

function stop_scratch(){
  local pid=$(get_scratch_pid $1)

  if [ ! -z "$pid" ]; then
    kill $pid
  fi
}

function edit_scratch(){
  local scr_uuid=$1
  code $scr_dir/$scr_uuid
}

function remove_scratch(){
  local scr_uuid=$1
  local scr_dir=$scr_dir/$scr_uuid

  if [ ! -d "$scr_dir" ]; then
    echo "Scratch '$scr_uuid' does not exist."
    return
  fi

  unregister_hostname $scr_uuid
  stop_scratch $scr_uuid
  rm -rf $scr_dir/$scr_uuid
  echo "Removed scratch '$scr_uuid'."
}

function start_all_scratches(){
  local n=0
  local scratches=$(get_all_scratches)
  for scr_uuid in $scratches; do
    start_scratch $scr_uuid
    n=$[$n+1]
  done
  echo "Started $n scratches."
}

function stop_all_scratches(){
  local n=0
  ps aux | grep 'php' | while read line; do
    pid=$(echo $line | awk '{print $2}')
    if [[ $line == *$scr_dir* ]]; then
      kill $pid
      n=$[$n+1]
    fi
  done
  echo "Stopped $n scratches."
}

function get_scratch_address(){
  scr_uuid=$1
  address=$(ps aux | grep $scr_uuid | awk '/php/ && /-S.*\.scratch/ {for(i=1; i<=NF; i++) if ($i ~ /\.scratch/) print $i}')
  echo "http://$address"
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
  for dir in $scr_dir/*; do
    if [ ! -f $dir/$scr_scratch_file ]; then
      continue
    fi
    scratches+=($(basename $dir))
  done
  echo ${scratches[@]}
}

function list_all_scratches(){
  local n=0
  local scratches=$(get_all_scratches)
  for scr_uuid in $scratches; do
    local pid=$(get_scratch_pid $scr_uuid)
    local url=$(get_scratch_address $scr_uuid)
    if [ -z "$pid" ]; then
      echo "STOPPED\t$pid\t$scr_uuid"
    else
      echo "RUNNING\t$pid\t$scr_uuid\t$url"
    fi
    n=$[$n+1]
  done
  if [ $n -eq 0 ]; then
    echo "No scratches found."
  fi
}

function is_installed(){
  if ! which $1 > /dev/null; then
    echo "0"
  else
    echo "1"
  fi
}

function ensure_scratches_dir(){
  if [ ! -d $scr_dir ]; then
    mkdir $scr_dir
  fi
}

function start_ngrok_tunnel(){
  scr_uuid=$1
  local scratches=$(get_all_scratches)
  for id in $scratches; do
    if [ ! -z "$scr_uuid" ] && [ "$scr_uuid" != "$id" ]; then
      continue
    fi

    local url=$(get_scratch_address $scr_uuid)
    local port=$(echo $url | cut -d':' -f3)
    local host=$(echo $url | cut -d':' -f2 | cut -d'/' -f3)

    ngrok http $host:$port
  done
}

if [ "$1" = "tunnel" ]; then
  if [ $(is_installed "ngrok") -eq 1 ]; then
    start_ngrok_tunnel $2
  else
    echo "ngrok is not installed"
  fi
elif [ "$1" = "new" ]; then
  new_scratch
elif [ "$1" = "ls" ]; then
  list_all_scratches
elif [ "$1" = "edit" ]; then
  edit_scratch $2
elif [ "$1" = "rm" ]; then
  remove_scratch $2
elif [ "$1" = "start" ]; then
  if [ -z "$2" ]; then
    start_all_scratches
  else
    start_scratch $2
  fi
elif [ "$1" = "stop" ]; then
  if [ -z "$2" ]; then
    stop_all_scratches
  else
    stop_scratch $2
  fi
else
  echo "scratches.sh"
  echo "  install - install scratches.sh"
  echo "  new - create a new scratch"
  echo "  list - list all scratches"
  echo "  start - start all scratches"
  echo "  stop - stop all scratches"
  echo "  edit - edit a scratch (requires vscode)"
  if [ $(is_installed "ngrok") -eq 1 ]; then
    echo "  tunnel - tunnel all scratches (requires ngrok)"
  fi
fi