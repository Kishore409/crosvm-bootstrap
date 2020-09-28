# error_handler_internal.sh
# Used for unmounting and cleaning up failed builds.
#Original source https://stackoverflow.com/questions/64786/error-handling-in-bash and modified for our use.

set -o pipefail  # trace ERR through pipes
set -o errtrace  # trace ERR through 'time command' and other functions
set -o nounset   ## set -u : exit the script if you try to use an uninitialised variable
set -o errexit   ## set -e : exit the script if any statement returns a non-true return value

lib_name='error_handler_internal'
LOG_DIR=${1}
ERR_LOG_NAME=${2}
MOUNT_DIR=${3}

echo "error_handler_internal: Recieved Arguments...."
echo "LOG_DIR:" $LOG_DIR
echo "ERR_LOG_NAME:" $ERR_LOG_NAME
echo "MOUNT_DIR:" $MOUNT_DIR
echo "--------------------------"

mkdir -p $LOG_DIR
stderr_log=$LOG_DIR/$ERR_LOG_NAME
if [ -e $stderr_log ]; then
  rm $stderr_log
fi

LOCAL_ROOTFS_BASE=rootfs_base
LOCAL_ROOTFS_MOUNT_DIR=$MOUNT_DIR/images/rootfs_base-temp
LOCAL_ROOTFS_COMMON=$MOUNT_DIR/images/rootfs_common
LOCAL_ROOTFS_COMMON_MOUNT_DIR=$MOUNT_DIR/images/rootfs_common-temp

echo "error_handler_internal: Using Arguments...."
echo "LOG_DIR:" $LOG_DIR
echo "ERR_LOG_NAME:" $ERR_LOG_NAME
echo "--------------------------"

exec 2>"$stderr_log"


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: EXIT_HANDLER
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

function exit_handler ()
{   
  if [ $MOUNT_DIR != "--none" ]; then
    if [ -e $LOCAL_ROOTFS_MOUNT_DIR ]; then
      if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/build > /dev/null; then
        umount -l $LOCAL_ROOTFS_MOUNT_DIR/build
      fi
        
      if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/log/common > /dev/null; then
        umount -l $LOCAL_ROOTFS_MOUNT_DIR/log/common
      fi
      
      if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/proc > /dev/null; then
        echo "unmounting" $LOCAL_ROOTFS_MOUNT_DIR/proc
        umount -l $LOCAL_ROOTFS_MOUNT_DIR/proc
      fi
  
      if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/dev/shm > /dev/null; then
        echo "unmounting" $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
        umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/shm
      fi
  
      if mount | grep $LOCAL_ROOTFS_MOUNT_DIR/dev/pts > /dev/null; then
        echo "unmounting" $LOCAL_ROOTFS_MOUNT_DIR/dev/pts
        umount -l $LOCAL_ROOTFS_MOUNT_DIR/dev/pts
      fi
      
      if mount | grep $LOCAL_ROOTFS_MOUNT_DIR > /dev/null; then
        umount -l $LOCAL_ROOTFS_MOUNT_DIR
      fi

      rm -rf $LOCAL_ROOTFS_MOUNT_DIR
    fi
    
    if [ -e $LOCAL_ROOTFS_COMMON_MOUNT_DIR ]; then
      if mount | grep $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build > /dev/null; then
        umount -l $LOCAL_ROOTFS_COMMON_MOUNT_DIR/build
      fi
  
      if mount | grep $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common > /dev/null; then
        umount -l $LOCAL_ROOTFS_COMMON_MOUNT_DIR/log/common
      fi
        
      if mount | grep $LOCAL_ROOTFS_COMMON_MOUNT_DIR > /dev/null; then
        umount -l $LOCAL_ROOTFS_COMMON_MOUNT_DIR
      fi

      rm -rf $LOCAL_ROOTFS_COMMON_MOUNT_DIR
    fi
      
    if [ -e $MOUNT_DIR/images/rootfs_temp.tar ]; then
      rm $MOUNT_DIR/images/rootfs_temp.tar
    fi
    
    cd $MOUNT_DIR/images/
    if [ ! -e .${LOCAL_ROOTFS_BASE}_lock ] && [ -e $LOCAL_ROOTFS_BASE.ext4 ]; then
      rm $MOUNT_DIR/images/$LOCAL_ROOTFS_BASE.ext4
      echo "destroying rootfs image----- \n";
    fi
    
    if [ ! -e .${LOCAL_ROOTFS_COMMON}_lock ] && [ -e $LOCAL_ROOTFS_COMMON.ext4 ]; then
      rm $MOUNT_DIR/images/$LOCAL_ROOTFS_COMMON.ext4
      echo "destroying rootfs image----- \n";
    fi
  fi
  
    local error_code="$?"
  test $error_code == 0 && return;

    #
    # LOCAL VARIABLES:
    # ------------------------------------------------------------------
    #    
    local i=0
    local regex=''
    local mem=''

    local error_file=''
    local error_lineno=''
    local error_message='unknown'

    local lineno=''


    #
    # PRINT THE HEADER:
    # ------------------------------------------------------------------
    #
    # Color the output if it's an interactive terminal
    test -t 1 && tput bold; tput setf 4                                 ## red bold
    echo -e "\n(!) EXIT HANDLER:\n"


    #
    # GETTING LAST ERROR OCCURRED:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

    #
    # Read last file from the error log
    # ------------------------------------------------------------------
    #
    if test -f "$stderr_log"
        then
            stderr=$( tail -n 1 "$stderr_log" )
            rm "$stderr_log"
    fi

    #
    # Managing the line to extract information:
    # ------------------------------------------------------------------
    #

    if test -n "$stderr"
        then        
            # Exploding stderr on :
            mem="$IFS"
            local shrunk_stderr=$( echo "$stderr" | sed 's/\: /\:/g' )
            IFS=':'
            local stderr_parts=( $shrunk_stderr )
            IFS="$mem"

            # Storing information on the error
            error_file="${stderr_parts[0]}"
            error_lineno="${stderr_parts[1]}"
            error_message=""

            for (( i = 3; i <= ${#stderr_parts[@]}; i++ ))
                do
                    error_message="$error_message "${stderr_parts[$i-1]}": "
            done

            # Removing last ':' (colon character)
            error_message="${error_message%:*}"

            # Trim
            error_message="$( echo "$error_message" | sed -e 's/^[ \t]*//' | sed -e 's/[ \t]*$//' )"
    fi

    #
    # GETTING BACKTRACE:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #
    _backtrace=$( backtrace 2 )


    #
    # MANAGING THE OUTPUT:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

    local lineno=""
    regex='^([a-z]{1,}) ([0-9]{1,})$'

    if [[ $error_lineno =~ $regex ]]

        # The error line was found on the log
        # (e.g. type 'ff' without quotes wherever)
        # --------------------------------------------------------------
        then
            local row="${BASH_REMATCH[1]}"
            lineno="${BASH_REMATCH[2]}"

            echo -e "FILE:\t\t${error_file}"
            echo -e "${row^^}:\t\t${lineno}\n"

            echo -e "ERROR CODE:\t${error_code}"             
            test -t 1 && tput setf 6                                    ## white yellow
            echo -e "ERROR MESSAGE:\n$error_message"


        else
            regex="^${error_file}\$|^${error_file}\s+|\s+${error_file}\s+|\s+${error_file}\$"
            if [[ "$_backtrace" =~ $regex ]]

                # The file was found on the log but not the error line
                # (could not reproduce this case so far)
                # ------------------------------------------------------
                then
                    echo -e "FILE:\t\t$error_file"
                    echo -e "ROW:\t\tunknown\n"

                    echo -e "ERROR CODE:\t${error_code}"
                    test -t 1 && tput setf 6                            ## white yellow
                    echo -e "ERROR MESSAGE:\n${stderr}"

                # Neither the error line nor the error file was found on the log
                # (e.g. type 'cp ffd fdf' without quotes wherever)
                # ------------------------------------------------------
                else
                    #
                    # The error file is the first on backtrace list:

                    # Exploding backtrace on newlines
                    mem=$IFS
                    IFS='
                    '
                    #
                    # Substring: I keep only the carriage return
                    # (others needed only for tabbing purpose)
                    IFS=${IFS:0:1}
                    local lines=( $_backtrace )

                    IFS=$mem

                    error_file=""

                    if test -n "${lines[1]}"
                        then
                            array=( ${lines[1]} )

                            for (( i=2; i<${#array[@]}; i++ ))
                                do
                                    error_file="$error_file ${array[$i]}"
                            done

                            # Trim
                            error_file="$( echo "$error_file" | sed -e 's/^[ \t]*//' | sed -e 's/[ \t]*$//' )"
                    fi

                    echo -e "FILE:\t\t$error_file"
                    echo -e "ROW:\t\tunknown\n"

                    echo -e "ERROR CODE:\t${error_code}"
                    test -t 1 && tput setf 6                            ## white yellow
                    if test -n "${stderr}"
                        then
                            echo -e "ERROR MESSAGE:\n${stderr}"
                        else
                            echo -e "ERROR MESSAGE:\n${error_message}"
                    fi
            fi
    fi

    #
    # PRINTING THE BACKTRACE:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

    test -t 1 && tput setf 7                                            ## white bold
    echo -e "\n$_backtrace\n"

    #
    # EXITING:
    # ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ #

    test -t 1 && tput setf 4                                            ## red bold
    echo "Exiting!"

    test -t 1 && tput sgr0 # Reset terminal

    exit "$error_code"
}
trap exit_handler EXIT                                                  # ! ! ! TRAP EXIT ! ! !
trap exit ERR                                                           # ! ! ! TRAP ERR ! ! !


###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##
#
# FUNCTION: BACKTRACE
#
###~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~##

function backtrace
{
    local _start_from_=0

    local params=( "$@" )
    if (( "${#params[@]}" >= "1" ))
        then
            _start_from_="$1"
    fi

    local i=0
    local first=false
    while caller $i > /dev/null
    do
        if test -n "$_start_from_" && (( "$i" + 1   >= "$_start_from_" ))
            then
                if test "$first" == false
                    then
                        echo "BACKTRACE IS:"
                        first=true
                fi
                caller $i
        fi
        let "i=i+1"
    done
}

return 0
