#!/usr/bin/env bash

[[ $# -eq 2 ]] || (echo 'Usage: $0 <ip> <port>' && exit 1)

# Check that davil image exists
sudo docker inspect davil &> /dev/null

# Build it if not
[[ $? -eq 0 ]] || sudo docker build -t davil .
[[ $? -eq 0 ]] && sudo docker run --rm --network host -p $2:$2 davil ruby server.rb $1 $2

