#!/bin/bash

versions=($(curl -L -s https://joverse.us/spigot | grep -oP '(?<=href=")[^"]*' | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?' | grep -v '-' | sed 's/.json//' | sort -V))

echo $versions

classify_java_version() {
    version="$1"
    IFS='.' read -r major minor patch <<<"$version"

    if ((major == 1 && minor < 17)); then
        echo "JAVA8"
    elif ((major == 1 && minor >= 17 && minor < 20)); then
        echo "JAVA17"
    elif ((major == 1 && minor >= 20)); then
        echo "JAVA21"
    fi
}

generate_readme() {
    declare -A version_families
    declare -A version_count

    for version in "${versions[@]}"; do
        IFS='.' read -r major minor patch <<<"$version"
        family="${major}.${minor}"
        version_families["$family"]+="$version "
        ((version_count["$family"]++))
    done

    max_versions=0
    for count in "${version_count[@]}"; do
        if (( count > max_versions )); then
            max_versions=$count
        fi
    done

    header="| Version Family |"
    for ((i=0; i<max_versions; i++)); do
        header+=" |"
    done
    echo "$header" > output/README.md

    separator="|:---:"
    for ((i=0; i<max_versions; i++)); do
        separator+="|---:"
    done
    separator+="|"
    echo "$separator" >> output/README.md

    for family in $(echo "${!version_families[@]}" | tr ' ' '\n' | sort -V -r); do
        echo -n "| $family " >> output/README.md
        
        versions_in_family=(${version_families["$family"]})
        count=0
        for version in "${versions_in_family[@]}"; do
            echo -n "| [${version}](https://github.com/doandat943/spigot-build/releases/download/20241028/spigot-${version}.jar) " >> output/README.md
            ((count++))
        done

        while ((count < max_versions)); do
            echo -n "| " >> output/README.md
            ((count++))
        done

        echo "|" >> output/README.md
    done
}

for version in $(printf "%s\n" "${versions[@]}" | sort -V); do
    classification=$(classify_java_version "$version")

    # Check if the classification matches the available Java versions
    if [[ "$classification" == "JAVA8" && -d "$JAVA_HOME_8" ]]; then
        export JAVA_HOME="$JAVA_HOME_21_X64"
    elif [[ "$classification" == "JAVA17" && -d "$JAVA_HOME_17" ]]; then
        export JAVA_HOME="$JAVA_HOME_17_X64"
    elif [[ "$classification" == "JAVA21" && -d "$JAVA_HOME_21" ]]; then
        export JAVA_HOME="$JAVA_HOME_21_X64"
    fi

    # Check if JAVA_HOME is set and run the build command
    if [[ -n "$JAVA_HOME" ]]; then
        export PATH="$JAVA_HOME/bin:$PATH"
        echo "Using Java at $JAVA_HOME for version $version"
        java -jar BuildTools.jar --rev "$version" --output-dir output
    fi
done

generate_readme
