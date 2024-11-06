# Fetch versions from Spigot and builds in README.md
versions_raw=$(curl -L -s https://hub.spigotmc.org/versions/ | grep -oP '(?<=href=")[^"]*' | grep -E '^[0-9]+\.[0-9]+(\.[0-9]+)?' | grep -v '-' | sed 's/.json//' | sort -V -r)
readme_content=$(curl -L -s https://raw.githubusercontent.com/doandat943/spigot-build/refs/heads/main/README.md)

builds=()
versions=()
versions_to_build=()

# Fetch builds and check against README.md
for version in $versions_raw; do
    build=$(curl -L -s "https://hub.spigotmc.org/versions/${version}.json" | jq -r '.name')

    # Add to versions and builds array if it's a new build
    if [[ ! " ${builds[@]} " =~ " ${build} " ]]; then
        builds+=("$build")
        versions+=("$version")
        
        # Check if the build is missing in README.md
        if ! echo "$readme_content" | grep -q "(${build})"; then
            versions_to_build+=("$version")
        fi
    fi
done

# Convert versions_to_build to JSON format
json_versions_to_build=$(printf '%s\n' "${versions_to_build[@]}" | jq -R . | jq -s -c .)
echo "json_versions=${json_versions_to_build}"

# Declare associative arrays for version families and counts
declare -A version_families
declare -A version_count

# Populate version families and counts
for i in "${!versions[@]}"; do
    version="${versions[i]}"
    build="${builds[i]}"
    IFS='.' read -r major minor patch <<<"$version"
    family="${major}.${minor}"
    version_families["$family"]+="$version:$build "
    version_count["$family"]=$((version_count["$family"] + 1))
done

# Determine max versions in any family
max_versions=0
for count in "${version_count[@]}"; do
    if [ "$count" -gt "$max_versions" ]; then
        max_versions=$count
    fi
done

# Create Markdown header
header="| Version Family |"
for ((i = 0; i < max_versions; i++)); do
    header+=" |"
done
echo "$header" > README.md

# Separator
separator="|:---:"
for ((i = 0; i < max_versions; i++)); do
    separator+="|:---:"
done
separator+="|"
echo "$separator" >> README.md

# Populate Markdown table with versions and builds
for family in $(echo "${!version_families[@]}" | tr ' ' '\n' | sort -V -r); do
    echo -n "| $family " >> README.md

    versions_in_family=(${version_families["$family"]})
    count=0
    for version_build in "${versions_in_family[@]}"; do
        version="${version_build%:*}"
        build="${version_build#*:}"
        echo -n "| [${version}](https://github.com/doandat943/spigot-build/releases/download/Spigot/spigot-${version}.jar) (${build}) " >> README.md
        count=$((count + 1))
    done

    # Fill remaining cells
    while [ "$count" -lt "$max_versions" ]; do
        echo -n "| " >> README.md
        count=$((count + 1))
    done

    echo "|" >> README.md
done
