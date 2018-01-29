#!/bin/bash

set -e

function err_quit() {
  echo "Error: $1" 1>&2
  exit 1
}

function notexists_quit() {
  if [ ! -f "$1" ]
  then
    err_quit "\"$1\" doesn't exist - $2"
  fi
}

function exists_quit() {
  if [ -f "$1" ]
  then
    err_quit "\"$1\" already exists - $2"
  fi
}
