#!/bin/bash

awk -v version="1.0.2" '
BEGIN {
    in_version = 0
    in_changes = 0
    section = ""
    in_array = 0
}
/version = "/ {
    if ($0 ~ version) {
        in_version = 1
    }
}
in_version && /date = "/ {
    gsub(/.*date = "/, "")
    gsub(/".*/, "")
    print "DATE:" $0
}
in_version && /highlights = {/ {
    section = "highlights"
    in_array = 1
    # Extract inline content
    line = $0
    while (match(line, /"[^"]+"/)) {
        text = substr(line, RSTART+1, RLENGTH-2)
        print section ":" text
        line = substr(line, RSTART+RLENGTH)
    }
    next
}
in_version && /changes = {/ {
    in_changes = 1
    next
}
in_changes && /added = {/ {
    section = "added"
    in_array = 1
    # Extract inline content
    line = $0
    while (match(line, /"[^"]+"/)) {
        text = substr(line, RSTART+1, RLENGTH-2)
        print section ":" text
        line = substr(line, RSTART+RLENGTH)
    }
    next
}
in_changes && /fixed = {/ {
    section = "fixed"
    in_array = 1
    next
}
in_changes && /changed = {/ {
    section = "changed"
    in_array = 1
    next
}
in_changes && /upcoming = {/ {
    section = "upcoming"
    in_array = 1
    next
}
in_array && /"/ {
    # Extract all quoted strings from the line
    line = $0
    while (match(line, /"[^"]+"/)) {
        text = substr(line, RSTART+1, RLENGTH-2)
        if (text != "") {
            print section ":" text
        }
        line = substr(line, RSTART+RLENGTH)
    }
}
in_array && /}/ {
    if ($0 ~ /^[[:space:]]*}[[:space:]]*$/ || $0 ~ /^[[:space:]]*}[[:space:]]*,/) {
        in_array = 0
        if (section == "upcoming") {
            in_changes = 0
            in_version = 0
            exit
        }
        section = ""
    }
}
' version.lua
