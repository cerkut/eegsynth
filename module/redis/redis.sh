#!/bin/bash

PATH=/opt/anaconda2/bin:/sbin:/bin:/usr/bin:/usr/local/bin

DIR=`dirname "$0"`
NAME=`basename "$0" .sh`

# include library with helper functions
. "$DIR/../../lib/EEGsynth.sh"

# helper files are stored in the directory containing this script
PIDFILE="$DIR"/"$NAME".pid
LOGFILE="$DIR"/"$NAME".log
INIFILE="$DIR"/"$NAME".ini

if [ -e "/usr/bin/redis-server" ]; then
  # on raspberry pi
  COMMAND="/usr/bin/redis-server"
else
  # on maci64, with macports
  COMMAND="/opt/local/bin/redis-server"
fi

shini_parse $INIFILE
OPTIONS="--port "$ini_redis_port

do_start () {
  status_led red
  log_action_msg "Starting $NAME"
  check_running_process && log_action_err "Error: $NAME is already started" && exit 1
  # start the process in the background
  date > "$LOGFILE"
  ( "$COMMAND" $OPTIONS >> "$LOGFILE" ) &
  echo $! > "$PIDFILE"
  status_led green
}

do_stop () {
  status_led red
  log_action_msg "Stopping $NAME"
  check_running_process || log_action_err "Error: $NAME is already stopped"
  check_running_process || exit 1
  kill -9 `cat "$PIDFILE"`
  rm "$PIDFILE"
  status_led green
}

do_status () {
  check_running_process && YESNO=" " || YESNO=" not "
  log_action_msg "$NAME is${YESNO}running"
}

case "$1" in
  start)
        do_start
        ;;
  restart)
        check_running_process && do_stop
        do_start
        ;;
  stop)
        do_stop
        ;;
  status)
        do_status
        ;;
  *)
        echo "Usage: $0 start|stop|restart|status" >&2
        exit 3
        ;;
esac
