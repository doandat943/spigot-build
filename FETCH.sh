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

# Convert output to JSON format
builds=$(printf '%s\n' "${builds[@]}" | jq -R . | jq -s -c .)
versions=$(printf '%s\n' "${versions[@]}" | jq -R . | jq -s -c .)
versions_to_build=$(printf '%s\n' "${versions_to_build[@]}" | jq -R . | jq -s -c .)
echo "builds=${builds}" >> $GITHUB_OUTPUT
echo "versions=${versions}" >> $GITHUB_OUTPUT
echo "versions_to_build=${versions_to_build}" >> $GITHUB_OUTPUT