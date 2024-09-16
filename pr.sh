#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
  local level=$1
  local message=$2
  case $level in
    "INFO") echo -e "${GREEN}[INFO]${NC} $message" ;;
    "WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
    "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
  esac
}

# Function to display a spinning animation
spin_animation() {
  spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  while true; do
    for i in "${spinner[@]}"; do
      tput civis # Hide the cursor
      tput el1 # Clear the line from the cursor to the beginning
      printf "\r${YELLOW}%s${NC} %s..." "$i" "$1"
      sleep 0.1
      tput cub $(( ${#1} + 5 )) # Move the cursor back
    done
  done
}

# Function to handle interrupts
cleanup() {
  echo -e "\n${RED}Script interrupted. Cleaning up...${NC}"
  tput cnorm # Show the cursor
  exit 1
}

# Git-related functions
get_current_branch() {
  git rev-parse --abbrev-ref HEAD
}

get_default_base_branch() {
  local current_branch=$(get_current_branch)
  local main_branch=$(git remote show origin | sed -n '/HEAD branch/s/.*: //p')
  local ancestor_branches=$(git branch --all --contains $(git merge-base $current_branch $main_branch) | sed 's/^\s*//' | grep -v "^*" | grep -v "$current_branch")

  if [ $(echo "$ancestor_branches" | wc -l) -gt 1 ]; then
    echo "$ancestor_branches" | grep -v "$main_branch" | head -n 1 | sed 's/^remotes\/origin\///'
  else
    echo $main_branch
  fi
}

check_unpushed_commits() {
  local current_branch=$(get_current_branch)
  local remote_branch="origin/$current_branch"

  if ! git rev-parse --verify $remote_branch >/dev/null 2>&1; then
    log "WARN" "Remote branch $remote_branch does not exist."
    return 1
  fi

  local unpushed=$(git log $remote_branch..$current_branch --oneline)
  if [ -n "$unpushed" ]; then
    log "WARN" "Unpushed commits found:"
    echo "$unpushed"
    return 1
  fi
  return 0
}

generate_diff() {
  git diff $1..$2
}

# GitHub-related functions
get_github_remote() {
  git remote -v | grep -E '^[^[:space:]]+\s+(https?://github\.com/|git@github\.com:)' | awk '{print $1}' | uniq
}

get_repo_info() {
  gh repo view --json defaultBranchRef,nameWithOwner --jq '{ nameWithOwner: .nameWithOwner, defaultBranchRef: .defaultBranchRef.name }'
}

check_existing_pr() {
  gh pr list --repo "$1" --head "$2" --json number --jq '.[0].number'
}

# Main script execution
main() {
  trap cleanup SIGINT

  log "INFO" "Fetching git remotes..."
  if ! git remote -v > /dev/null 2>&1; then
    log "ERROR" "Are you sure this is a git repo? Are you sure you have git installed?"
    exit 1
  fi

  # Check for unpushed commits
  if ! check_unpushed_commits; then
    read -p "Do you want to push these commits before creating the PR? (Y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
      log "INFO" "Pushing commits..."
      if ! git push; then
        log "ERROR" "Failed to push commits. Please resolve any issues and try again."
        exit 1
      fi
      log "INFO" "Commits pushed successfully."
    else
      log "WARN" "Proceeding without pushing commits. This may affect the PR creation process."
    fi
  fi

  # Set up GitHub-related variables
  GITHUB_REMOTE=$(get_github_remote)
  if [ -z $GITHUB_REMOTE ]; then
    log "WARN" "No GitHub remote found. Using 'origin' as default."
    GITHUB_REMOTE="origin"
    IS_GITHUB="false"
    BASE_BRANCH="HEAD"
  else
    IS_GITHUB="true"
    log "INFO" "GitHub remote found: $GITHUB_REMOTE"
    log "INFO" "Fetching repository information..."
    REPO_INFO=$(get_repo_info)
    if [ $? -ne 0 ]; then
      log "ERROR" "Failed to fetch repository information. Is the gh CLI tool installed and authenticated?"
      exit 1
    fi
    REPO_NAME=$(echo "$REPO_INFO" | jq -r '.nameWithOwner')
    DEFAULT_BASE_BRANCH=$(echo "$REPO_INFO" | jq -r '.defaultBranchRef')
    log "INFO" "Repository: $REPO_NAME, Default base branch: $DEFAULT_BASE_BRANCH"

    # Prompt for base branch
    local default_base=$(get_default_base_branch)
    read -p "Enter the base branch (default: $default_base): " BASE_BRANCH
    BASE_BRANCH=${BASE_BRANCH:-$default_base}
    log "INFO" "Using base branch: $BASE_BRANCH"
  fi

  # Get the current branch name
  HEAD_BRANCH=$(get_current_branch)
  log "INFO" "Current branch: $HEAD_BRANCH"

  # Check for remote branch
  log "INFO" "Checking for remote branch..."
  if ! git ls-remote --exit-code --heads $GITHUB_REMOTE $HEAD_BRANCH > /dev/null 2>&1; then
    log "WARN" "No remote branch found for $HEAD_BRANCH"
    read -p "Would you like to push the current branch to remote? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      log "INFO" "Pushing branch $HEAD_BRANCH to $GITHUB_REMOTE..."
      if ! git push -u $GITHUB_REMOTE $HEAD_BRANCH; then
        log "ERROR" "Failed to push the branch. Please check your permissions and try again."
        exit 1
      fi
      log "INFO" "Branch pushed successfully."
    else
      log "WARN" "Cannot proceed without a remote branch. Exiting."
      exit 1
    fi
  else
    log "INFO" "Remote branch found for $HEAD_BRANCH"
  fi

  # Check for uncommitted changes
  UNCOMMITTED_CHANGES=$(git status --porcelain | wc -l)
  if [ $UNCOMMITTED_CHANGES -gt 0 ]; then
    log "WARN" "$UNCOMMITTED_CHANGES uncommitted changes"
  fi

  # Generate PR title and body
  log "INFO" "Generating PR title..."
  spin_animation "Generating PR Title" &
  spin_pid=$!
  DIFF=$(generate_diff "$GITHUB_REMOTE/$BASE_BRANCH" "$GITHUB_REMOTE/$HEAD_BRANCH")
  if [ -z "$DIFF" ]; then
    log "ERROR" "No diff found between $BASE_BRANCH and $HEAD_BRANCH"
    kill $spin_pid
    wait $spin_pid 2>/dev/null
    tput cnorm
    exit 1
  fi
  TITLE=$(echo "$DIFF" | llm -s "$(cat ~/.config/prompts/pr-title-prompt.txt)")
  kill $spin_pid
  wait $spin_pid 2>/dev/null
  tput cnorm
  echo

  log "INFO" "Generating PR body..."
  spin_animation "Generating PR Body" &
  spin_pid=$!
  BODY=$(echo "$DIFF" | llm -s "$(cat ~/.config/prompts/pr-body-prompt.txt)")
  kill $spin_pid
  wait $spin_pid 2>/dev/null
  tput cnorm
  echo

  # Prompt for draft PR
  read -p "Create as draft PR? (y/N): " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]; then
    DRAFT_OPTION="--draft"
    TITLE="[DRAFT] $TITLE"
  else
    DRAFT_OPTION=""
  fi

  # Create or update PR
  if [ "$IS_GITHUB" == "true" ]; then
    log "INFO" "Checking for existing PR..."
    EXISTING_PR=$(check_existing_pr "$REPO_NAME" "$HEAD_BRANCH")
    if [ -n "$EXISTING_PR" ]; then
      log "INFO" "Updating the existing PR (#$EXISTING_PR) on ${REPO_NAME}."
      gh pr edit "$EXISTING_PR" --repo "$REPO_NAME" --title "$TITLE" --body "$BODY"
    else
      log "INFO" "No existing PR found, creating a new one."
      gh pr create --repo "$REPO_NAME" --base "$BASE_BRANCH" --head "$HEAD_BRANCH" --title "$TITLE" --body "$BODY" $DRAFT_OPTION
    fi
  else
    log "WARN" "Not GitHub, not creating the PR automatically."
  fi

  # Display the generated PR message
  echo -e "${BLUE}=== Generated PR Message ===${NC}"
  echo -e "${BLUE}Title:${NC}\n${GREEN}$TITLE${NC}\n"
  echo -e "${BLUE}Body:${NC}\n${GREEN}$BODY${NC}"
  echo -e "${BLUE}=================================${NC}"

  log "INFO" "Script completed successfully."
}

main
