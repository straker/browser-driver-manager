#!/bin/bash

assetDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

for arg in "$@"; do
  if [[ "$arg" = "http://"* || "$arg" = "https://"*  ]]; then
    url=$arg
  fi
done

echo "$url" >> $assetDir/mock-log-file.txt

if [[ "$url" = "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_"* ]]; then
  version=$(echo "$url" | tr -dc '0-9')

  # Let version 101 fail so it can fallback to 100 for test
  if [ "$version" -lt 101 ]; then
    echo "$version.0.1234.56"
  fi
elif [[ "$url" = "https://chromedriver.storage.googleapis.com/LATEST_RELEASE_"* ]]; then
  exit 0
fi