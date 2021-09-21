#!/bin/sh -l

# Enable Debug Mode
set -x

# Enable color output
export TERM=xterm-color

# Get command line arguments
REMOTE_REPO=$1
REMOTE_REF=$2
TARGET_REF=$3
GH_PAT=$4
REBASE=$5
EXCLUDE=$6
TARGET_REPO=$GITHUB_REPOSITORY

# Return value
SYNC_STATUS="failed"

# Setting GH Action Output Colors
RED="\033[91m"
YELLOW="\033[93m"
GREEN="\033[32m"
BOLD="\e[1m"
DEFAULT="\033[m"

# get action directory for sourcing subscripts
ACTION_PARENT_DIR=$(dirname "$(dirname "$0")")

write_log() {
    case $1 in  
    # Bold/Green
    [Gg])
        echo -e "${BOLD}${GREEN}$2${DEFAULT}" 1>&1
        ;;        
    
    # Bold/Yellow
    [Yy])
        echo -e "${BOLD}${YELLOW}$2${DEFAULT}" 1>&1
        ;;                

    # Default log message
    [Dd])
        echo "$2" 1>&1
        ;;
    
    # Exit without issues
    [Ee])
        echo -e "${BOLD}${GREEN}$2${DEFAULT}" 1>&2
        echo "::set-output name=sync-status::${2}"
        exit 0
        ;;
    # If something failed, exit with red
    *)
        echo -e "${BOLD}${RED}ERROR: ${DEFAULT} exit $1" 1>&2
        echo "::set-output name=sync-status::${$2}"
        exit "$1"
        ;;
    esac                
}

git_config() {    
    # Configure git client
    git config --global user.name "GitHub Sync Bot"
    git config --global user.email "action@github.com"
    git config --global pull.rebase $REBASE
    write_log "g" "git client configured"
}

set_upstream() {    
    # Add the upstream repository
    git remote add upstream "${REMOTE_REPO}"
    write_log "g" "Remote added to repository"
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
        write_log "$STATUS" "Target branch '${TARGET_REF}' could not be checked out."        
    fi
    
    write_log "g" "Checked out ${TARGET_REF}"
}

sync_branches() {

    MAIN=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
    STATUS=$?
    if [ "${STATUS}" != 0 ]; then
        # exit on commit pull fail
        write_log "$STATUS" "Could not get main branch from project"        
    fi

    #git checkout $MAIN
    #git branch -d ${TARGET_REF}
    #git push origin --delete ${TARGET_REF}
    #git checkout -b keptn-master upstream/${REMOTE_REF}

    git pull --no-edit upstream "${REMOTE_REF}" || true
    #STATUS=$?
    #if [ "${STATUS}" != 0 ]; then
        # exit on commit pull fail
    #    write_log "$STATUS" "Could not get commits"        
    #fi

    if [ "${EXCLUDE}" != "" ]; then
        write_log "y" "Excluding folders ${EXCLUDE}"
        # Get current default branch
        MAIN=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
        STATUS=$?
        if [ "${STATUS}" != 0 ]; then
            # exit on commit pull fail
            write_log "$STATUS" "Could not get main branch from project"        
        fi
        write_log "g" "Main branch ${MAIN}"

        # Loop through the directories which should be excluded
        for EXFOLDER in $(echo $EXCLUDE | tr "," "\n")
        do
            write_log "y" "Get master version of ${EXFOLDER}"
            # Delete current directory
            rm -rf ${EXFOLDER}

            # Get directory from the default branch
            git checkout ${MAIN} ${EXFOLDER}

            # Add changes
            git add .

            # Commit changes
            git commit -m "SyncBot - Keep ${EXFOLDER} from ${MAIN}"            
        done      
    fi

    git remote set-url origin "https://${GITHUB_ACTOR}:${GH_PAT}@github.com/${TARGET_REPO}.git"
    git push origin "${TARGET_REF}"
    STATUS=$?

    if [ "${STATUS}" != 0 ]; then
        # exit on commit pull fail
        write_log "$STATUS" "Could not push changes to target"        
    fi
    write_log "e" "Sync successful!"

}

check_updates() {

    git fetch upstream ${REMOTE_REF}

    LOCAL_COMMIT_HASH=$(git rev-parse "${TARGET_REF}")
    UPSTREAM_COMMIT_HASH=$(git rev-parse "upstream/${REMOTE_REF}")

    if [ -z "${LOCAL_COMMIT_HASH}" ] || [ -z "${UPSTREAM_COMMIT_HASH}" ]; then
        write_log "1" "Error on checking for new commits"
    elif [ "${LOCAL_COMMIT_HASH}" = "${UPSTREAM_COMMIT_HASH}" ]; then        
        write_log "e" "Nothing to do, no new commits to sync."
    else
        git log upstream/"${REMOTE_REF}" "${LOCAL_COMMIT_HASH}"..HEAD --pretty=oneline
        write_log "g" "Found new commits, will sync the branches"
        sync_branches
    fi

    exit 0
}

write_log "d" "Sync action running..."

write_log "d" "REMOTE_REPO $REMOTE_REPO"
write_log "d" "REMOTE_REF $REMOTE_REF"
write_log "d" "TARGET_REF $TARGET_REF"
write_log "d" "TARGET_REPO $TARGET_REPO"
write_log "d" "REBASE $REBASE"
write_log "d" "EXCLUDE $EXCLUDE"

git_config
checkout
set_upstream
check_updates

echo "::set-output name=sync-status::${SYNC_STATUS}"