#!/bin/bash

versions=($(curl -L -s https://hub.spigotmc.org/versions/ | grep -oP '(?<=href=")[^"]*' | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?' | sed 's/.json//'))

classify_java_version() {
    version="$1"
    IFS='.' read -r major minor patch <<<"$version"

    if ((major == 1 && minor < 17)); then
        echo "JAVA8"
    elif ((major == 1 && minor >= 17 && minor < 21)); then
        if [ -z "$patch" ]; then
            echo "JAVA17"
        elif ((patch < 5)); then
            echo "JAVA17"
        else
            echo "JAVA21"
        fi
    elif ((major == 1 && minor == 20 && patch >= 5)); then
        echo "JAVA21"
    elif ((major == 1 && minor > 20)); then
        echo "JAVA21"
    else
        echo "UNKNOWN"
    fi
}

for version in $(printf "%s\n" "${versions[@]}" | sort -V); do
    classification=$(classify_java_version "$version")
    if [[ "$classification" == "$1" ]]; then
        java -jar BuildTools.jar --rev "$version" --output-dir output
    fi
done
