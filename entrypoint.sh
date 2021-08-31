#!/bin/sh -l

# Get command line arguments
REMOTE_REPO=$1
REMOTE_REF=$2
TARGET_REPO=$3
TARGET_REF=$4
GH_PAT=$5
REBASE=$6

# Setting GH Action Output Colors
RED="\033[91m"
YELLOW="\033[93m"
GREEN="\033[32m"
BLUE="\033[96m"
BOLD="\033[1m"
NORMAL="\033[m"

# get action directory for sourcing subscripts
ACTION_PARENT_DIR=$(dirname "$(dirname "$0")")

git_config() {
    git config --global user.name "GitHub Sync Bot"
    git config --global user.email "action@github.com"
    git config --global pull.rebase $REBASE
}

set_upstream() {    
    git remote add upstream "${REMOTE_REPO}"
}

checkout() {
    git branch -v
    echo "Checking out ${TARGET_REF}"
    git checkout ${TARGET_REF}
    STATUS=$?
    if [ "${STATUS}" != 0 ]; then
        # checkout failed
        echo "Target branch '${TARGET_REF}' could not be checked out."
        exit 1
    fi
    echo "SUCCESS\n"
}

sync_branches() {

    git pull --no-edit upstream "${REMOTE_REF}"
    COMMAND_STATUS=$?

    if [ "${COMMAND_STATUS}" != 0 ]; then
        # exit on commit pull fail
        echo "New commits could not be pulled."
        exit 1
    fi

     git remote set-url origin "https://${GITHUB_ACTOR}:${GH_PAT}@github.com/${TARGET_REPO}.git"
     git push origin "${TARGET_REF}"

}

check_updates() {

    git fetch upstream ${REMOTE_REF}

    LOCAL_COMMIT_HASH=$(git rev-parse "${TARGET_REF}")
    UPSTREAM_COMMIT_HASH=$(git rev-parse "upstream/${REMOTE_REF}")

    if [ -z "${LOCAL_COMMIT_HASH}" ] || [ -z "${UPSTREAM_COMMIT_HASH}" ]; then
        echo "Error on checking for new commits"
        exit 1
    elif [ "${LOCAL_COMMIT_HASH}" = "${UPSTREAM_COMMIT_HASH}" ]; then
        echo "No new commits"
        exit 0
    else
        git log upstream/"${REMOTE_REF}" "${LOCAL_COMMIT_HASH}"..HEAD --pretty=oneline
        sync_branches
    fi

    exit 0
}

git_config
checkout
set_upstream
check_updates


time=$(date)
echo "::set-output name=sync-status::$time"