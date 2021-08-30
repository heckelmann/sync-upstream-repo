#!/bin/sh -l

echo "Hello $1"
echo "Hello $2"
echo "Hello $3"
time=$(date)
echo "::set-output name=sync-status::$time"