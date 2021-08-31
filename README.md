# sync-upstream-repo

This action will pull changes from a remote repository and merge/rebase a local branch to keep it up to date with the remote one.

## Inputs

## `remote-repository`

**Required** The git url of the upstream repository. Default `https://github.com/heckelmann/test-src.git`.

## `remote-ref`

The remote reference (branch or tag) to sync the changes from. Default `master`.

## target-repository

**Required** The GitHub project path to sync the changes to, like `heckelmann/test-target`. Default `heckelmann/test-target`

## target-ref: 

The local reference (branch or tag) to sync the changes to. Default `master`.

## auth-token:    

**Required** GitHub Token with access to the target repository

## rebase
    
Perform a rebase or not. Default `false`

## Outputs

## `sync-status`

Was the sync successful

## Example usage

uses: actions/hello-world-docker-action@v1
with:
  who-to-greet: 'Mona the Octocat'