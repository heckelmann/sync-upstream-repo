#!/bin/sh -l

# Enable Debug Mode
set -x

# Get command line arguments
REMOTE_REPO=$1
REMOTE_REF=$2
TARGET_REPO=$3
TARGET_REF=$4
GH_PAT=$5
REBASE=$6

# Return value
SYNC_STATUS="failed"

# Setting GH Action Output Colors
RED="\033[91m"
YELLOW="\033[93m"
GREEN="\033[32m"
BOLD="\033[1m"
DEFAULT="\033[m"

# get action directory for sourcing subscripts
ACTION_PARENT_DIR=$(dirname "$(dirname "$0")")

write_log() {
    case $1 in  
    # Bold/Green
    [Gg])
        echo "${BOLD}${GREEN}$2${DEFAULT}" 1>&1
        ;;        
    
    # Bold/Yellow
    [Gg])
        echo "${BOLD}${GREEN}$2${DEFAULT}" 1>&1
        ;;                

    # Default log message
    [Dd])
        echo "$2" 1>&1
        ;;
    
    # Exit without issues
    [Ee]
        echo "${BOLD}${GREEN}$2${DEFAULT}" 1>&2
        echo "::set-output name=sync-status::Failed"
        exit 0
        ;;
    # If something failed, exit with red
    *)
        echo "${BOLD}${RED}ERROR: ${DEFAULT} exit $1" 1>&2
        echo "::set-output name=sync-status::${SYNC_STATUS}"
        exit "$1"
        ;;
    esac                
}

git_config() {    
    # Configure git client
    git config --global user.name "GitHub Sync Bot"
    git config --global user.email "action@github.com"
    git config --global pull.rebase $REBASE
    log "g" "git client configured"
}

set_upstream() {    
    # Add the upstream repository
    git remote add upstream "${REMOTE_REPO}"
    log "g" "Remote added to repository"
}

checkout() {
    # Show all branches
    git branch -v

    # Checkout our target branch (should be already done within the checkout stage)
    echo "Checking out ${TARGET_REF}"
    git checkout ${TARGET_REF}
    STATUS=$?
    if [ "${STATUS}" != 0 ]; then
        # checkout failed
        log "$STATUS" "Target branch '${TARGET_REF}' could not be checked out."        
    fi
    
    log "g" "Checked out ${TARGET_REF}"
}

sync_branches() {

    git pull --no-edit upstream "${REMOTE_REF}"
    STATUS=$?

    if [ "${STATUS}" != 0 ]; then
        # exit on commit pull fail
        log "$STATUS" "Could not get commits"        
    fi

    git remote set-url origin "https://${GITHUB_ACTOR}:${GH_PAT}@github.com/${TARGET_REPO}.git"
    git push origin "${TARGET_REF}"
    STATUS=$?

    if [ "${STATUS}" != 0 ]; then
        # exit on commit pull fail
        log "$STATUS" "Could not push changes to target"        
    fi
}

check_updates() {

    git fetch upstream ${REMOTE_REF}

    LOCAL_COMMIT_HASH=$(git rev-parse "${TARGET_REF}")
    UPSTREAM_COMMIT_HASH=$(git rev-parse "upstream/${REMOTE_REF}")

    if [ -z "${LOCAL_COMMIT_HASH}" ] || [ -z "${UPSTREAM_COMMIT_HASH}" ]; then
        log "1" "Error on checking for new commits"
    elif [ "${LOCAL_COMMIT_HASH}" = "${UPSTREAM_COMMIT_HASH}" ]; then
        log "e" "Nothing to do, no new commits to sync."
    else
        git log upstream/"${REMOTE_REF}" "${LOCAL_COMMIT_HASH}"..HEAD --pretty=oneline
        log "g" "Found new commits, will sync the branches"
        sync_branches
    fi

    exit 0
}

git_config
checkout
set_upstream
check_updates

echo "::set-output name=sync-status::$SYNC_STATUS"