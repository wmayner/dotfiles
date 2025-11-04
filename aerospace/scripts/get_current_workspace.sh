#!/usr/bin/env bash
aerospace list-workspaces --focused --json | jq -r '.[0].workspace // .[0].name // ""'
