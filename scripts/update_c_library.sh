#!/bin/bash

# c_library repository update script
# Author: Thomas Gubler <thomasgubler@gmail.com>
#
# This script can be used together with a github webhook to automatically
# generate new c header files and push to the c_library repository whenever
# the message specifications are updated.
# The script assumes that the git repositories in MAVLINK_GIT_PATH and
# CLIBRARY_GIT_PATH are set up prior to invoking the script.
#
# Usage, for example:
# cd ~/src
# git clone git@github.com:mavlink/mavlink.git
# cd mavlink
# git remote rename origin upstream
# mkdir -p include/mavlink/v1.0
# cd include/mavlink/v1.0
# git clone git@github.com:mavlink/c_library_v1.git
# cd ~/src/mavlink
# ./scripts/update_c_library.sh 1
#
# A one-liner for the TMP directory (e.g. for crontab)
# cd /tmp; git clone git@github.com:mavlink/mavlink.git &> /dev/null; \
# cd /tmp/mavlink && git remote rename origin upstream &> /dev/null; \
# mkdir -p include/mavlink/v1.0 && cd include/mavlink/v1.0 && git clone git@github.com:mavlink/c_library_v1.git &> /dev/null; \
# cd /tmp/mavlink && ./scripts/update_c_library.sh &> /dev/null

function generate_headers() {
python pymavlink/tools/mavgen.py \
    --output $CLIBRARY_PATH \
    --lang C \
    --wire-protocol $2.0 \
    message_definitions/v1.0/$1.xml
}

# settings
MAVLINK_GIT_REMOTENAME=origin
CLIBRARY_GIT_REMOTENAME=origin
MAVLINK_PATH=$PWD

if (( $# < 1 ));
then
	GIT_BRANCH=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
	echo -e "\0033[34mUsing current branch ($GIT_BRANCH)\0033[0m\n"
else
	GIT_BRANCH=$1
	echo -e "\0033[34mUsing branch $GIT_BRANCH\0033[0m\n"
	echo -e "\0033[34mcloning into temporary directory\0033[0m\n"
	cd /tmp
	git clone https://github.com/ethz-asl/fw_mavlink.git --branch $GIT_BRANCH --recursive || exit 1
	cd fw_mavlink
	MAVLINK_PATH=/tmp/fw_mavlink
fi

for MAVLINK_VERSION in 1 2
do
	cd $MAVLINK_PATH

	if (($# == 1));
	then
		mkdir -p include/mavlink/v$MAVLINK_VERSION.0
		cd include/mavlink/v$MAVLINK_VERSION.0
		git clone git@github.com:ethz-asl/fw_mavlink_c_library_v$MAVLINK_VERSION.git c_library_v$MAVLINK_VERSION
		cd MAVLINK_PATH
	fi
	# version specific settings	
	MAVLINK_GIT_BRANCHNAME=$GIT_BRANCH
	CLIBRARY_PATH=$MAVLINK_PATH/include/mavlink/v$MAVLINK_VERSION.0/c_library_v$MAVLINK_VERSION
	CLIBRARY_GIT_BRANCHNAME=$GIT_BRANCH

	cd $MAVLINK_PATH

	# save git hash
	MAVLINK_GITHASH=$(git rev-parse HEAD)

	# delete old c headers
	rm -rf $CLIBRARY_PATH/*

	# generate new c headers
	echo -e "\0033[34mStarting to generate c headers for v$MAVLINK_VERSION\0033[0m\n"

	generate_headers ASLUAV $MAVLINK_VERSION
	generate_headers ardupilotmega $MAVLINK_VERSION
	generate_headers autoquad $MAVLINK_VERSION
	generate_headers matrixpilot $MAVLINK_VERSION
	generate_headers minimal $MAVLINK_VERSION
	generate_headers slugs $MAVLINK_VERSION
	generate_headers test $MAVLINK_VERSION
	generate_headers standard $MAVLINK_VERSION
	mkdir -p $CLIBRARY_PATH/message_definitions
	cp message_definitions/v1.0/* $CLIBRARY_PATH/message_definitions/.
	echo -e "\0033[34mFinished generating c headers for v$MAVLINK_VERSION\0033[0m\n"

	# git add and git commit in local c_library repository
	cd $CLIBRARY_PATH
	git checkout -B $GIT_BRANCH
	git add --all :/ || exit 1
	COMMIT_MESSAGE="generated headers for rev https://github.com/ethz-asl/fw_mavlink/tree/"$MAVLINK_GITHASH
	git commit -m "$COMMIT_MESSAGE"

	# push to c_library repository
	# git push $CLIBRARY_GIT_REMOTENAME $CLIBRARY_GIT_BRANCHNAME || exit 1
	# echo -e "\0033[34mHeaders updated and pushed successfully\0033[0m"
done
