#/bin/bash

# Function that executes a given command and compares its return command with a given one.
# In case the expected and the actual return codes are different it exits
# the script.
# Parameters:
#               $1: Command to be executed (string)
#               $2: Expected return code (number), may be undefined.
function executeCommand()
{
    # gets the command
    CMD=$1
    # sets the return code expected
    # if it's not definedset it to 0
    OK_CODE=$2
    if [ -n $2 ]
    then
        OK_CODE=0
    fi
    # executes the command
    ${CMD}

    # checks if the command was executed successfully
    RET_CODE=$?
    if [ $RET_CODE -ne $OK_CODE ]
    then
	echo ""
        echo "ERROR executing command: \"$CMD\""
        echo "Exiting..."
        exit 1
    fi
}

# ******************************************************************************
# *                                   MAIN                                     *
# ******************************************************************************

if [ $# -ne 3 ]
then
    echo "usage: $0 APP_NAME FRAMEWORK_CHROOT SERIES_CHROOT"
    exit 1
fi

APP_NAME=$1
CHROOT=$2
SERIES=$3

#CURRENT_DIR=`pwd`
CURRENT_DIR="/home/dawndiy/workspace/golang/"
GOROOT="/usr/local/lib/go/"

echo -n "Removing $APP_NAME directory... "
executeCommand "rm -rf ./$APP_NAME"
echo "Done"

echo -n "Creating clean $APP_NAME directory... "
executeCommand "mkdir $APP_NAME"
echo "Done"

echo -n "Copying files... "
executeCommand "cp manifest.json $APP_NAME/"
executeCommand "cp apparmor.json $APP_NAME/"
executeCommand "cp ${APP_NAME}.desktop $APP_NAME/"
executeCommand "cp ${APP_NAME}.png $APP_NAME/"
executeCommand "cp ${APP_NAME}.qml $APP_NAME/"
executeCommand "cp -R data/ $APP_NAME/"
executeCommand "cp -R ui/ $APP_NAME/"
executeCommand "cp -R components/ $APP_NAME/"
executeCommand "cp -R images/ $APP_NAME/"
executeCommand "cp channels.json $APP_NAME/"
echo "Done"

echo -n "Cross compiling $APP_NAME..."
executeCommand "click chroot -a armhf -f $CHROOT -s $SERIES run CGO_ENABLED=1 GOARCH=arm GOARM=7 PKG_CONFIG_LIBDIR=/usr/lib/arm-linux-gnueabihf/pkgconfig:/usr/lib/pkgconfig:/usr/share/pkgconfig GOROOT=$GOROOT GOPATH=$CURRENT_DIR CC=arm-linux-gnueabihf-gcc CXX=arm-linux-gnueabihf-g++ go build -ldflags '-extld=arm-linux-gnueabihf-g++' -o $APP_NAME/$APP_NAME"
echo "Done"

echo -n "Building click package ... "
# executeCommand "click build ./"
executeCommand "click build $APP_NAME/"
echo "Done"
