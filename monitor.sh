#!/bin/bash

LOG_PATH = monitor.log

# Define cache file to temporarily record the latest log so as to write new log at the beginning of monitor.log 
# cache.log will be cleared after every logging loop so it contains the latest one log at most
CACHE_PATH = cache.log

# Define the time interval between a log finishes and the next one starts
TIME = 5

# Log id number
# It represents the ID number of a log. 
LOG_ID = 0

# Get the information that we need including current processes, current login
# user, plugged USB devices, internet states and interface, memory and swap usage,
# disks usage, home directory, other key directories, installed applications, file
# changes of the user in 24 hours.
# Write the latest log into cache file in ordinary order.
function get_info()
{
    # Record log id and time and write into cache.log
    echo >> ${CACHE_PATH} "Log identity: ${LOG_ID}"
    echo >> ${CACHE_PATH} "Time: `date` "
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}

    # Get current processes information and write into cache.log
    echo >> ${CACHE_PATH} "                    ===========Processes=========="
    # If fail to run command, write failed log
    ps -e >> ${CACHE_PATH} || echo "Fail to get information" >> ${CACHE_PATH}
    echo >> ${CACHE_PATH} 
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}

    # Get current user information and write into cache.log
    echo >> ${CACHE_PATH} "                    =============User===========:"
    # If fail to run command, write failed log
    w >> ${CACHE_PATH} || echo "Fail to get information" >> ${CACHE_PATH}
    echo >> ${CACHE_PATH} 
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}

    # Get plugged USB devices and write into cache.log
    echo >> ${CACHE_PATH} "                    =======Plugged devices======:"
    # If fail to run command, write failed log
    lsusb  >> ${CACHE_PATH} || echo "Fail to get information" >> ${CACHE_PATH}
    echo >> ${CACHE_PATH} 
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}

    # Get internet interface and states and write into cache.log
    # ping google to check if internet is connected
    echo >> ${CACHE_PATH} "                    =======Internet states=======:"
    ping -c 5 www.google.com && echo >> ${CACHE_PATH} "Internet connected." || echo >> ${CACHE_PATH} "Internet disconnected."
    # If fail to run command, write failed log
    ifconfig >> ${CACHE_PATH} || echo "Fail to get information" >> ${CACHE_PATH}
    echo >> ${CACHE_PATH} 
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}

    # Get usage of memory and swap and write into cache.log
    echo >> ${CACHE_PATH} "                    =======Memory and swap======:"
    # If fail to run command, write failed log
    free -m  >> ${CACHE_PATH} || echo "Fail to get information" >> ${CACHE_PATH}
    echo >> ${CACHE_PATH} 
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}

    # Get disk usage information and write into cache.log
    # If fail to run command, write failed log
    echo >> ${CACHE_PATH} "                    ============Disks===========:"
    df -h | grep 'Filesystem\|/dev/sda*' >> ${CACHE_PATH} || echo "Fail to get information" >> ${CACHE_PATH}
    echo >> ${CACHE_PATH} 
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}

    # Get the user's home directory disk usage and write into cache.log
    echo >> ${CACHE_PATH} "                    ========Home directories=======:"
    df -h >> ${CACHE_PATH} || echo "Fail to get information" >> ${CACHE_PATH}
    echo >> ${CACHE_PATH} 
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}

    # Get other key directories disk usage and write into cache.log
    echo >> ${CACHE_PATH} "                    ======Other key directory=====:"
    # If fail to run command, write failed log
    df -h /bin >> ${CACHE_PATH}  || echo "Fail to get information" >> ${CACHE_PATH}
    df -h /dev >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}  
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}
    
    # Find installed applications and output their .desktop name and write into cache.log
    echo >> ${CACHE_PATH} "                    ====Installed applications====:"
    # If fail to run command, write failed log
    ls /usr/share/applications/  >> ${CACHE_PATH} || echo "Fail to get information" >> ${CACHE_PATH}
    echo >> ${CACHE_PATH} 
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}

    # Find paths of files that change in the past 24 hr
    # List their infomation and write into cache.log.
    echo >> ${CACHE_PATH} "                 ====User's changed files in the past 24 hr====:"
    # Find changed files' paths of the current user
    # using grep and regular expression to filter useless information.
    user=`whoami`
    # Get the files' information and write into cache.log 
    # if user is root, show changed files in /root,
    # if user is not root, show changed files in /home/user
    if [ -d "/home/${user}" ]; then
        files=`find  /home/${user} -mmin 60 -type f| grep -v "No such file or directory$ | Permission denied$"`
        while read line ; do
            ls ${line} -lh >> ${CACHE_PATH} 
        done <<< "$files"
    elif [[ ${user} = 'root' ]]; then
        files=`find /root -mmin 60 -type f| grep -v "No such file or directory$ | Permission denied$"`
        while read line ; do
            ls ${line} -lh >> ${CACHE_PATH} 
        done <<< "$files"
    else
        echo "No directory /home/${user} found." >> ${CACHE_PATH} 
    fi

    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}
    echo "             ===============================================">> ${CACHE_PATH}

    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}
    echo >> ${CACHE_PATH}
}

# Update the latest log at the beginning of monitor.log
# For details, first reverse all lines in cache.log. 
# Then read lines in cache.log and write it into the 1st line of monitor.log, 
# so the content in monitor.log will be in ordinary order.
 function update_log()
 {
    # Reverse the content of cache
    sed -i 'x;1!H;$!d;x' ${CACHE_PATH}

    # Change local IFS to '\n', so the spaces in front of each line won't be deleted
    # and for IFS is local, we don't need to reset it.
    local IFS=$'\n'

    # Using exec to make cache.log as stdin.
    exec 0<${CACHE_PATH} 
    # Read lines from cache.log and write latest log at the beginning of monitor log.
    # Test if a input line is a blank line, if it is, use a space to insert.
    # If a input line is not blank, put a '-symbol-' at the beginning
    # so the spaces at the front of line will be written in monitor.log.
    while read line ; do
        test -z "${line}" && sed -i '1 {x;p;x;}' ${LOG_PATH} || sed -i '1i -symbol-'"${line}" ${LOG_PATH} 
    done

    # Remove all '-symbol-' at the start of a line in monitor.log so that every line will be original format.
    sed -i 's/^-symbol-//' ${LOG_PATH}
    

    # Clear the cache file, keeping the cache file contains at most one latest log
    # and empty after a log is written successfully.
    echo > ${CACHE_PATH}
 }


# Create or clear the files when started program in case it has some 
# old content left in the last run.
echo "" > ${CACHE_PATH}
echo "" > ${LOG_PATH}

while true; do
    # Increase LOG_ID by 1
    LOG_ID = $(($LOG_ID+1))
    echo "Log ${LOG_ID} is written..."

    # Write latest log into cache file waiting for being written.
    get_info    
    
    # Update latest log in monitor.log and the order of logs is from new to old with their log ID.
    update_log

    echo "Log ${LOG_ID} done."

    # Remove some sed files produced during program.
    chmod 777 sed*
    rm sed* 

    # Sleep for a time interval.
    sleep ${TIME}
done

