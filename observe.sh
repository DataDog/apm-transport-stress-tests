

#!/bin/bash
# Description:  A wrapper script used to stop/start another script.

#--------------------------------------
# Define Global Environment Settings:
#--------------------------------------

# Name and location of a persistent PID file

PIDFILE="./observer-pid.txt"

#--------------------------------------
# Check command line option and run...
# Note that "myscript" should not
# provided by the user.
#--------------------------------------

case $1
in
    myscript)

        SPAMMER_STATS_FILE=./results/${TRANSPORT}/spammer-stats.json
        REQUEST_FORMAT="GET /containers/${SPAMMER_CONTAINER_ID}/stats HTTP/1.1\r\nUser-Agent: nc/0.0.1\r\nHost: 127.0.0.1\r\nAccept: */*\r\n\r\n"
        echo "" > $SPAMMER_STATS_FILE
        echo -ne $REQUEST_FORMAT | sudo nc -U /var/run/docker.sock >> $SPAMMER_STATS_FILE
    ;;

    start)
        # Start your script in the background.
        # (Note that this is a recursive call to the wrapper
        #  itself that effectively runs your script located above.)
        $0 myscript &

        # Save the backgound job process number into a file.
        jobs -p > $PIDFILE

        # Disconnect the job from this shell.
        # (Note that 'disown' command is only in the 'bash' shell.)
        disown %1

        # Print a message indicating the script has been started
        echo "Script has been started..."
    ;;

    stop)
        # Read the process number into the variable called PID
        read PID < $PIDFILE

        # Remove the PIDFILE
        rm -f $PIDFILE

        # Send a 'terminate' signal to process
        kill $PID

        # Print a message indicating the script has been stopped
        echo "Script has been stopped..."
    ;;

    *)
        # Print a "usage" message in case no arguments are supplied
        echo "Usage: $0 start | stop"
    ;;
esac