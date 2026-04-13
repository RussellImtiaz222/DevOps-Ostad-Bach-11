#!/bin/bash
# Rebase plan: squash and reword commits
sed -i.bak '2s/^pick/squash/' "$1"
sed -i '3s/^pick/squash/' "$1"
sed -i '4s/^pick/reword/' "$1"
