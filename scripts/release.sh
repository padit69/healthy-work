#!/bin/bash

# Health Reminder Release Script
# This script automates the release process

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Function to validate version format
validate_version() {
    if [[ ! $1 =~ ^v[0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?$ ]]; then
        print_error "Invalid version format: $1"
        print_info "Version must be in format: v1.0.0 or v1.0.0-beta.1"
        exit 1
    fi
}

# Function to check if tag exists
tag_exists() {
    git rev-parse "$1" >/dev/null 2>&1
}

# Function to check git status
check_git_status() {
    if [[ -n $(git status -s) ]]; then
        print_warning "You have uncommitted changes:"
        git status -s
        echo ""
        read -p "Do you want to commit them? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git add .
            read -p "Enter commit message: " commit_msg
            git commit -m "$commit_msg"
            print_success "Changes committed"
        else
            print_error "Please commit or stash your changes before releasing"
            exit 1
        fi
    fi
}

# Function to check if branch is up to date
check_branch_sync() {
    git fetch origin
    LOCAL=$(git rev-parse @)
    REMOTE=$(git rev-parse @{u})
    
    if [ $LOCAL != $REMOTE ]; then
        print_warning "Your branch is not in sync with remote"
        read -p "Do you want to pull changes? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            git pull origin main
            print_success "Branch updated"
        else
            print_error "Please sync your branch before releasing"
            exit 1
        fi
    fi
}

# Function to test build locally
test_build() {
    print_info "Testing build locally..."
    cd HealthyWork
    
    if xcodebuild \
        -project HealthyWork.xcodeproj \
        -scheme HealthyWork \
        -configuration Release \
        -derivedDataPath ./build \
        clean build > /dev/null 2>&1; then
        print_success "Local build successful"
        cd ..
        return 0
    else
        print_error "Local build failed"
        cd ..
        return 1
    fi
}

# Function to update version.json
update_version_json() {
    local version=$1
    local message=$2
    
    # Remove 'v' prefix from version
    local clean_version=${version#v}
    
    # Get today's date
    local today=$(date +%Y-%m-%d)
    
    # Get repository info for download URL
    local repo_url=$(git config --get remote.origin.url | sed 's/\.git$//')
    if [[ $repo_url == git@github.com:* ]]; then
        repo_url=$(echo $repo_url | sed 's/git@github.com:/https:\/\/github.com\//')
    fi
    
    # Extract user/repo from URL
    local download_url="${repo_url}/releases/download/${version}/HealthyWork.dmg"
    
    # Check if jq is installed
    if ! command -v jq &> /dev/null; then
        print_warning "jq not found, skipping version.json update"
        print_info "Install jq with: brew install jq"
        return 0
    fi
    
    # Update version.json
    if [ -f "version.json" ]; then
        print_info "Updating version.json..."
        jq --arg version "$clean_version" \
           --arg date "$today" \
           --arg url "$download_url" \
           --arg notes "$message" \
           '.version = $version | .releaseDate = $date | .downloadURL = $url | .releaseNotes = $notes' \
           version.json > version.json.tmp && mv version.json.tmp version.json
        
        # Commit the change
        git add version.json
        git commit -m "chore: update version.json to $clean_version"
        print_success "version.json updated and committed"
    else
        print_warning "version.json not found, skipping update"
    fi
}

# Function to create and push tag
create_release() {
    local version=$1
    local message=$2
    
    # Update version.json before creating tag
    update_version_json "$version" "$message"
    
    # Create tag
    git tag -a "$version" -m "$message"
    print_success "Tag $version created locally"
    
    # Push commits and tag
    git push origin main
    git push origin "$version"
    print_success "Tag $version pushed to GitHub"
    
    # Get repository URL
    local repo_url=$(git config --get remote.origin.url | sed 's/\.git$//')
    if [[ $repo_url == git@github.com:* ]]; then
        repo_url=$(echo $repo_url | sed 's/git@github.com:/https:\/\/github.com\//')
    fi
    
    print_success "Release workflow triggered!"
    echo ""
    echo "📊 Monitor build: ${repo_url}/actions"
    echo "🎉 View release: ${repo_url}/releases/tag/${version}"
}

# Main script
main() {
    echo ""
    echo "╔═══════════════════════════════════════╗"
    echo "║  Health Reminder Release Script 💚   ║"
    echo "╚═══════════════════════════════════════╝"
    echo ""
    
    # Check if we're in the right directory
    if [ ! -d "HealthyWork/HealthyWork.xcodeproj" ]; then
        print_error "This script must be run from the project root directory"
        exit 1
    fi
    
    # Check if git is available
    if ! command -v git &> /dev/null; then
        print_error "Git is not installed"
        exit 1
    fi
    
    # Check if xcodebuild is available
    if ! command -v xcodebuild &> /dev/null; then
        print_error "Xcode is not installed"
        exit 1
    fi
    
    # Check if jq is available (optional but recommended)
    if ! command -v jq &> /dev/null; then
        print_warning "jq is not installed (version.json will not be updated)"
        print_info "Install with: brew install jq"
        echo ""
    fi
    
    # Get version from user
    if [ -z "$1" ]; then
        print_info "Enter version number (e.g., v1.0.0):"
        read -r version
    else
        version=$1
    fi
    
    # Validate version
    validate_version "$version"
    
    # Check if tag already exists
    if tag_exists "$version"; then
        print_error "Tag $version already exists"
        print_info "To delete and recreate: git tag -d $version && git push origin :refs/tags/$version"
        exit 1
    fi
    
    print_success "Version $version is valid"
    
    # Check git status
    print_info "Checking git status..."
    check_git_status
    
    # Check if branch is synced
    print_info "Checking branch sync..."
    check_branch_sync
    
    # Ask if user wants to test build
    echo ""
    read -p "Test build locally before releasing? (recommended) (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if ! test_build; then
            print_error "Build test failed. Fix errors before releasing."
            exit 1
        fi
    fi
    
    # Get release message
    echo ""
    print_info "Enter release message (or press Enter for default):"
    read -r release_message
    
    if [ -z "$release_message" ]; then
        release_message="Release version $version"
    fi
    
    # Confirm release
    echo ""
    print_warning "Ready to create release:"
    echo "  Version: $version"
    echo "  Message: $release_message"
    echo "  Branch: $(git branch --show-current)"
    echo "  Commit: $(git rev-parse --short HEAD)"
    echo ""
    read -p "Continue? (y/n) " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Release cancelled"
        exit 0
    fi
    
    # Create release
    echo ""
    print_info "Creating release..."
    create_release "$version" "$release_message"
    
    echo ""
    print_success "Release process completed!"
    echo ""
    print_info "Next steps:"
    echo "  1. Monitor the build in GitHub Actions"
    echo "  2. Once complete, test the release files"
    echo "  3. Announce the release to users"
    echo ""
}

# Handle script interruption
trap 'print_error "Script interrupted"; exit 130' INT

# Run main function
main "$@"
