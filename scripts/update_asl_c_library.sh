#!/bin/bash

# c_library repository update script
# Author: Thomas Mantel <thomas.mantel@mavt.ethz.ch>
#
# Main contribution by Thomas Gubler (update_c_library.sh)
#
#
# This script has 2 use cases:
# update_asl_c_library.sh [branch]
# A) Generate from currently checked out branch / commit
#    Current branch will be pushed to remote first.
# B) Generate c headers for _specified branch_ on github.com/ethz-asl/fw_mavlink.git
#
#
# See update_asl_clibrary.md for more information
#


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

if (( $# < 1 )); then
	GIT_BRANCH=$(git symbolic-ref HEAD | sed -e 's,.*/\(.*\),\1,')
	echo -e "\0033[34mUsing current branch ($GIT_BRANCH)\0033[0m\n"
	git push $MAVLINK_GIT_REMOTENAME $GIT_BRANCH
else
	GIT_BRANCH=$1
	echo -e "\0033[34mUsing branch $GIT_BRANCH\0033[0m\n"
	echo -e "\0033[34mcloning into temporary directory\0033[0m\n"
	cd /tmp
	rm -rf fw_mavlink
	git clone https://github.com/ethz-asl/fw_mavlink.git --branch $GIT_BRANCH --recursive || exit 1
	cd fw_mavlink
	MAVLINK_PATH=/tmp/fw_mavlink
fi

# save git hashes
MAVLINK_GITHASH=$(git rev-parse HEAD)
MAVLINK_GITHASH_PARENT=$(git rev-parse HEAD~1)

for MAVLINK_VERSION in 1 2
do
	# Prepare directories
	echo -e "\0033[34mPreparing directories for v$MAVLINK_VERSION\0033[0m\n"
	# version specific settings
	MAVLINK_GIT_BRANCHNAME=$GIT_BRANCH
	CLIBRARY_PATH=$MAVLINK_PATH/include/mavlink/v$MAVLINK_VERSION.0
	CLIBRARY_GIT_BRANCHNAME=$GIT_BRANCH

	cd $MAVLINK_PATH

	if ( (($# == 1)) || [ ! -d "$CLIBRARY_PATH" ] ); then
		mkdir -p include/mavlink
		cd include/mavlink
		git clone git@github.com:ethz-asl/fw_mavlink_c_library_v$MAVLINK_VERSION.git v$MAVLINK_VERSION.0
	else
		cd $CLIBRARY_PATH
		git fetch $CLIBRARY_GIT_REMOTENAME
	fi

	cd $CLIBRARY_PATH
	CLIBRARY_PARENT=$(git log --grep="$MAVLINK_GITHASH_PARENT" --all --format="%H" -n 1)
	git checkout -B $GIT_BRANCH $CLIBRARY_PARENT

	cd $MAVLINK_PATH

	# delete old c headers
	rm -rf $CLIBRARY_PATH/*

	# generate new c headers
	echo -e "\0033[34mStarting to generate c headers for v$MAVLINK_VERSION\0033[0m\n"

	generate_headers ASLUAV $MAVLINK_VERSION
	mkdir -p $CLIBRARY_PATH/message_definitions
	cp message_definitions/v1.0/* $CLIBRARY_PATH/message_definitions/.
	echo -e "\0033[34mFinished generating c headers for v$MAVLINK_VERSION\0033[0m\n"

	# git add and git commit in local c_library repository
	cd $CLIBRARY_PATH
	git add --all :/ || exit 1
	COMMIT_MESSAGE="generated headers for rev https://github.com/ethz-asl/fw_mavlink/tree/"$MAVLINK_GITHASH
	git commit -m "$COMMIT_MESSAGE"

	# push to c_library repository
	# git push $CLIBRARY_GIT_REMOTENAME $CLIBRARY_GIT_BRANCHNAME || exit 1
	# echo -e "\0033[34mHeaders updated and pushed successfully\0033[0m"
done
