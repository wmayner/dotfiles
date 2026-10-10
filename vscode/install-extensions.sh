#!/bin/sh

xargs -I % code --install-extension % < "$(dirname "$0")/extensions.txt"
