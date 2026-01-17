#!/bin/bash

set -e

# Check for uncommitted changes
if ! git diff-index --quiet HEAD -- 2>/dev/null; then
    echo "Error: You have uncommitted changes. Please commit or stash them before tagging."
    exit 1
fi

# Get the latest version tag (assumes semver format like v1.2.3 or 1.2.3)
get_latest_tag() {
    git fetch --tags 2>/dev/null || true
    git tag --sort=-v:refname | grep -E '^v?[0-9]+\.[0-9]+\.[0-9]+$' | head -n 1
}

# Parse version components
parse_version() {
    local version="$1"
    # Remove leading 'v' if present
    version="${version#v}"

    IFS='.' read -r major minor patch <<< "$version"
    echo "$major $minor $patch"
}

# Compute next patch version
next_patch_version() {
    local major="$1"
    local minor="$2"
    local patch="$3"

    patch=$((patch + 1))
    echo "v${major}.${minor}.${patch}"
}

# Main script
echo "Fetching existing git tags..."

latest_tag=$(get_latest_tag)

if [ -z "$latest_tag" ]; then
    echo "No existing version tags found."
    new_tag="v0.1.0"
    echo "Starting with initial version: $new_tag"
else
    echo "Latest version tag: $latest_tag"

    read -r major minor patch <<< "$(parse_version "$latest_tag")"
    new_tag=$(next_patch_version "$major" "$minor" "$patch")

    echo "Next patch version: $new_tag"
fi

# Create an annotated tag
echo ""
echo "Creating tag: $new_tag"
git tag -a "$new_tag" -m "Release $new_tag"
echo "Tag $new_tag created locally."

# Ask for user consent before pushing
echo ""
read -p "Do you want to push the branch and tag '$new_tag' to the remote repository? (y/N): " consent

if [[ "$consent" =~ ^[Yy]$ ]]; then
    echo "Pushing branch and tag to remote..."
    git push --follow-tags
    echo "Branch and tag $new_tag pushed successfully!"
else
    echo "Push cancelled. The tag '$new_tag' exists locally."
    echo "You can push later with: git push --follow-tags"
fi
