#!/usr/bin/env bash

### Supported Platforms

# - darwin
# 	- amd64
# 	- arm64
# - linux
# 	- amd64
# 	- arm64
# - windows
# 	- amd64
# 	- arm64


github_release_command () {
    local command=$(echo $THO_PAT_RELEASE | openssl enc -d -aes-256-cbc -pbkdf2 -iter 1000000 -nosalt -base64 -k pass:$THO_PAT_DECENC)
    echo $command
}
# source env

github_release_upload () {
    # release tar
    gh release create $VERSION -R softdist/docker.client --title $TITLE -F ./release-notes.md /app/release.tar
    tar -xvf /app/release.tar
    gh release create $VERSION -R softdist/docker.client --title $TITLE -F ./release-notes.md /app/*
    gh release create $VERSION -R softdist/docker.client --title $TITLE -F ./release-notes.md /app/aarch64-apple-darwin/*
    gh release create $VERSION -R softdist/docker.client --title $TITLE -F ./release-notes.md /app/x86_64-apple-darwin/*
}



# automagic encrypted login
cmd=$(github_release_command) && status=$($cmd) && echo $status

# gh auth status verify
gh auth status
github_release_upload


