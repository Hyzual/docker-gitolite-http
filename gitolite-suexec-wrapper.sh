#!/bin/bash
#
# Suexec wrapper for gitolite-shell
# Needed because suexec needs the command to be in httpd's document root

export GIT_PROJECT_ROOT="/repositories"
export GITOLITE_HTTP_HOME="/data"

exec /usr/local/bin/gitolite-shell
