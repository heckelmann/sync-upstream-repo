# sync-upstream-repo

This action will sync (merge/rebase) a local branch from a remote repository.

## Inputs

## `remote-repository`

**Required** The git url of the upstream repository. Default `https://github.com/heckelmann/test-src.git`.

## `remote-ref`

The remote reference (branch or tag) to sync the changes from. Default `master`.

## `target-ref`

The local reference (branch or tag) to sync the changes to. Default `master`.

## `auth-token`

**Required** GitHub Token with access to the target repository. You can use the default `${{ secrets.GITHUB_TOKEN }}`.

## `rebase`
    
Perform a rebase or not. Default `false`

## Outputs

## `sync-status`

Was the sync successful

## Example usage

```yaml
on:
  # Manual triggered workflow
  workflow_dispatch:

jobs:  
  sync_latest_from_upstream:
    runs-on: ubuntu-latest
    name: Sync latest commits from upstream repo

    steps:
    # REQUIRED step
    # Step 1: run a standard checkout action, provided by github
    - name: Checkout target repo
      uses: actions/checkout@v2
      with:
        # set the branch to checkout,
        ref:  main
        persist-credentials: false

    # REQUIRED step
    # Step 2: run the sync action
    - name: Sync upstream changes
      id: sync
      uses: heckelmann/sync-upstream-repo@main
      with:
        remote-repository: https://github.com/heckelmann/test-src.git
        remote-ref: main
        target-ref: mylocal-main
        auth-token: ${{ secrets.GITHUB_TOKEN }}

```