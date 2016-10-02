#! /bin/sh
### BEGIN INIT INFO
# Provides:          
# Required-Start:    networking
# Required-Stop:     
# Should-Start:      glibc
# Default-Start:     S
# Default-Stop:
# Short-Description: Display webpage with discovered nodes on network
# Description:       Display webpage with discovered nodes on network
### END INIT INFO

SCRIPT_LOCATION=/home/pi/host-discover
PYENV_NAME=pyenv
PIDFILE=/var/run/host-discover.pid

PATH=$SCRIPT_LOCATION/$PYENV_NAME/bin

do_start () {
	su pi -c 'python3 $SCRIPT_LOCATION/src/host_discover_server.py &'
	echo $! > $PIDFILE
}

do_status () {
	if [ -f "$PIDFILE" ]; then
		return 0;
	else
		return 4;
	fi
}

do_stop () {
	if [ -f "$PIDFILE" ]; then
		kill "$(cat $PIDFILE)"
		return 0;
	fi
	return 4;
}

force_stop () {
	if [ -f "$PIDFILE" ]; then
		kill -9 "$(cat $PIDFILE)"
		return 0;
	fi
	return 4;
}

case "$1" in
  start|"")
	do_start
	;;
  restart|reload)
	do_stop
	do_start
	;;
  force-reload)
	force_stop
	do_start
	;;
  stop)
	do_stop
	;;
  status)
	do_status
	exit $?
	;;
  *)
	echo "Usage: hostname.sh [start|stop]" >&2
	exit 3
	;;
esac

:
