#!/bin/bash

# How functions work in bash
# @see https://linuxize.com/post/bash-functions/

# Lowercase a string
function lowercase() {
  echo "$1" | tr '[:upper:]' '[:lower:]'
}

# Uppercase first character of a string
# @see https://stackoverflow.com/a/12487469/2124254
function titleCase() {
  echo "$(tr '[:lower:]' '[:upper:]' <<< ${1:0:1})${1:1}"
}