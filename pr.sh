#!/bin/bash

# ANSI color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to display a spinning animation
spin_animation() {
  spinner=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
  while true; do
    for i in "${spinner[@]}"; do
      tput civis # Hide the cursor
      tput el1 # Clear the line from the cursor to the beginning
      printf "\r${YELLOW}%s${NC} %s..." "$i" "$1"
      sleep 0.1
      tput cub 32 # Move the cursor back 32 columns
    done
  done
}

# Function to handle interrupts
cleanup() {
  echo -e "\n${RED}Script interrupted. Cleaning up...${NC}"
  tput cnorm # Show the cursor
  exit 1
}

# Set up trap to handle interrupts
trap cleanup SIGINT

# Function for logging
log() {
  local level=$1
  local message=$2
  case $level in
    "INFO") echo -e "${GREEN}[INFO]${NC} $message" ;;
    "WARN") echo -e "${YELLOW}[WARN]${NC} $message" ;;
    "ERROR") echo -e "${RED}[ERROR]${NC} $message" ;;
  esac
}

# Get the list of remotes and their URLs
log "INFO" "Fetching git remotes..."
REMOTES=$(git remote -v)
if [ $? -ne 0 ]; then
  log "ERROR" "Are you sure this is a git repo? Are you sure you have git installed?"
  exit 1
fi

# Use a regular expression to find the remote that points to a GitHub URL
GITHUB_REMOTE=$(echo "$REMOTES" | grep -E '^[^[:space:]]+\s+(https?://github\.com/|git@github\.com:)' | awk '{print $1}' | uniq)
IS_GITHUB="true"
if [ -z $GITHUB_REMOTE ]; then
  GITHUB_REMOTE="origin"
  IS_GITHUB="false"
  BASE_BRANCH="HEAD"
  log "WARN" "No GitHub remote found. Using 'origin' as default."
else
    log "INFO" "GitHub remote found: $GITHUB_REMOTE"
    # Get the repository information using the gh tool
    log "INFO" "Fetching repository information..."
    REPO_INFO=$(gh repo view --json defaultBranchRef,nameWithOwner --jq '{ nameWithOwner: .nameWithOwner, defaultBranchRef: .defaultBranchRef.name }')
    # Check the exit status of the command
    if [ $? -ne 0 ]; then
      log "ERROR" "Failed to fetch repository information. Is the gh CLI tool installed and authenticated?"
      exit 1
    fi
    # Extract the repository owner and name from the JSON output
    REPO_NAME=$(echo "$REPO_INFO" | jq -r '.nameWithOwner')
    BASE_BRANCH=$(echo "$REPO_INFO" | jq -r '.defaultBranchRef')
    log "INFO" "Repository: $REPO_NAME, Base branch: $BASE_BRANCH"
fi

# Get the current branch name
HEAD_BRANCH=$(git rev-parse --abbrev-ref HEAD)
log "INFO" "Current branch: $HEAD_BRANCH"

# Check if there's a remote branch for the current local branch
log "INFO" "Checking for remote branch..."
REMOTE_BRANCH=$(git ls-remote --heads $GITHUB_REMOTE $HEAD_BRANCH)

if [ -z "$REMOTE_BRANCH" ]; then
  log "WARN" "No remote branch found for $HEAD_BRANCH"
  read -p "Would you like to push the current branch to remote? (y/n) " -n 1 -r
  echo
  if [[ $REPLY =~ ^[Yy]$ ]]
  then
    log "INFO" "Pushing branch $HEAD_BRANCH to $GITHUB_REMOTE..."
    git push -u $GITHUB_REMOTE $HEAD_BRANCH
    if [ $? -ne 0 ]; then
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

# Start the spinning animation for PR title generation
spin_animation "Generating PR Title" &
spin_pid=$!

# Generate the title using git diff and llm
log "INFO" "Generating PR title..."
TITLE=$(git diff $GITHUB_REMOTE/$BASE_BRANCH $GITHUB_REMOTE/$HEAD_BRANCH | llm -s "$(cat ~/.config/prompts/pr-title-prompt.txt)")

# Stop the spinning animation
kill $spin_pid
wait $spin_pid 2>/dev/null

# Start the spinning animation for PR body generation
spin_animation "Generating PR Body" &
spin_pid=$!

# Generate the body using git diff and llm
log "INFO" "Generating PR body..."
BODY=$(git diff $GITHUB_REMOTE/$BASE_BRANCH $GITHUB_REMOTE/$HEAD_BRANCH| llm -s "$(cat ~/.config/prompts/pr-body-prompt.txt)")
if [ $? -ne 0 ]; then
  log "ERROR" "Something went wrong with the LLM generation!"
  log "WARN" "It's probably just your quota - maybe chill for a minute"
  exit 1
fi

# Stop the spinning animation
kill $spin_pid
wait $spin_pid 2>/dev/null

# Move the cursor to the next line and show the cursor
tput cnorm
echo

if [ "$IS_GITHUB" == "true" ]; then
    # Check if there is an existing PR for the current branch
    log "INFO" "Checking for existing PR..."
    EXISTING_PR=$(gh pr list --repo "$REPO_NAME" --head "$HEAD_BRANCH" --json number --jq '.[0].number')
    if [ -n "$EXISTING_PR" ]; then
      log "INFO" "Updating the existing PR (#$EXISTING_PR) on ${REPO_NAME}."
      # Update the existing pull request
      gh pr edit "$EXISTING_PR" \
        --repo "$REPO_NAME" \
        --title "$TITLE" \
        --body "$BODY"
    else
      log "INFO" "No existing PR found, creating a new one."
      # Create the pull request
      gh pr create \
        --repo "$REPO_NAME" \
        --base "$BASE_BRANCH" \
        --head "$HEAD_BRANCH" \
        --title "$TITLE" \
        --body "$BODY"
    fi
else
  log "WARN" "Not GitHub, not creating the PR automatically."
fi

# Display the generated commit message with colors and formatting
echo -e "${BLUE}=== Generated PR Message ===${NC}"
echo -e "${BLUE}Title:${NC}"
echo -e "${GREEN}$TITLE${NC}"
echo
echo -e "${BLUE}Body:${NC}"
echo -e "${GREEN}$BODY${NC}"
echo -e "${BLUE}=================================${NC}"
echo

log "INFO" "Script completed successfully."
