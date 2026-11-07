# Flowrensic CLI

The command line client of Flowrensic. A pipeline runs it to fetch replay sets and to print the summary of
its ephemeral run, failing the step when the outcome is failed.

Each Flowrensic release puts the binaries here. This repo is written by the release and is not edited by
hand.

## Install

    curl -fsSL https://github.com/flowrensic/flowrensic-cli/releases/latest/download/install.sh | sh

The script picks the binary for Linux x86_64, Linux arm64 or macOS arm64, checks its sha256 against
checksums.txt, and installs it as flowrensic in /usr/local/bin when it can write there, else in
$HOME/.local/bin. It works with curl or wget.

    FLOWRENSIC_VERSION       a release such as 1.2.3, the newest when unset
    FLOWRENSIC_INSTALL_DIR   the folder to install into

A fixed version:

    curl -fsSL https://github.com/flowrensic/flowrensic-cli/releases/download/v1.2.3/install.sh | FLOWRENSIC_VERSION=1.2.3 sh

The binaries and checksums.txt are also on each release page, to download by hand.

## Summary of an ephemeral run

At the end of the job:

    export FLOWRENSIC_SERVER_BASE_URL=https://flowrensic.example.com
    export FLOWRENSIC_CURRENT_ENV=ci-e2e
    export FLOWRENSIC_ENV_ACCESS_KEY=...
    export FLOWRENSIC_CURRENT_EPHEMERAL_RUN=$BUILD_ID
    flowrensic summary

It prints the replay results of the run and ends with 1 when the outcome is failed.

## Docker

The same CLI is in the image flowrensic/flowrensic-cli:

    docker run --rm -e FLOWRENSIC_SERVER_BASE_URL -e FLOWRENSIC_CURRENT_ENV \
      -e FLOWRENSIC_ENV_ACCESS_KEY -e FLOWRENSIC_CURRENT_EPHEMERAL_RUN \
      flowrensic/flowrensic-cli:latest summary
