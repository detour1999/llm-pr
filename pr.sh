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
      printf "\r${YELLOW}%s${NC} $1..." "$i"

      sleep 0.1
      tput cub 32 # Move the cursor back 32 columns
    done
  done
}

# Get the list of remotes and their URLs
REMOTES=$(git remote -v)

if [ $? -ne 0 ]; then
  echo -e "${RED}Are you sure this is a git repo? Are you sure you have git installed?${NC}"
  exit 1
fi

# Use a regular expression to find the remote that points to a GitHub URL
GITHUB_REMOTE=$(echo "$REMOTES" | grep -E '^[^[:space:]]+\s+(https?://github\.com/|git@github\.com:)' | awk '{print $1}' | uniq)

if [ -z $GITHUB_REMOTE ]; then
  echo -e "${YELLOW}No github remotes configured for this repo.${NC}"
  exit 1
fi


# Get the repository information using the gh tool
REPO_INFO=$(gh repo view --json defaultBranchRef,nameWithOwner --jq '{ nameWithOwner: .nameWithOwner, defaultBranchRef: .defaultBranchRef.name }')

# Check the exit status of the command
# Extract the repository owner and name from the JSON output
REPO_NAME=$(echo "$REPO_INFO" | jq -r '.nameWithOwner')
BASE_BRANCH=$(echo "$REPO_INFO" | jq -r '.defaultBranchRef')

# Get the current branch name
HEAD_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Start the spinning animation
spin_animation "Generating PR Title" &
spin_pid=$!
# Generate the title and body using git diff and llm
TITLE=$(git diff $HEAD_BRANCH $GITHUB_REMOTE/$BASE_BRANCH | llm -s "$(cat ~/.config/prompts/pr-title-prompt.txt)")
# Stop the spinning animation
kill $spin_pid
wait $spin_pid 2>/dev/null

# Start the spinning animation
spin_animation "Generating PR Body" &
spin_pid=$!
BODY=$(git diff $HEAD_BRANCH $GITHUB_REMOTE/$BASE_BRANCH| llm -s "$(cat ~/.config/prompts/pr-body-prompt.txt)")
if [ $? -ne 0 ]; then
  echo -e "${RED}Something went wrong with the LLM generation!${NC}"
  echo -e "${YELLOW}It's probably just your quota - maybe chill for a minute${NC}"
  exit 1
fi
kill $spin_pid
wait $spin_pid 2>/dev/null
# Move the cursor to the next line and show the cursor
tput cnorm
echo

# Create the pull request
echo gh pr create \
  --repo "$REPO_NAME" \
  --base "$BASE_BRANCH" \
  --head "$HEAD_BRANCH" \
  --title "$TITLE" \
  --body "$BODY"


# Display the generated commit message with colors and formatting
echo -e "${BLUE}=== Generated PR Message ===${NC}"
echo -e "${BLUE}Title:${NC}"
echo -e "${GREEN}$TITLE${NC}"
echo
echo -e "${BLUE}Body:${NC}"
echo -e "${GREEN}$BODY${NC}"
echo -e "${BLUE}=================================${NC}"
echo
