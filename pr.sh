#!/bin/bash

# Get the repository information using the gh tool
REPO_INFO=$(gh repo view --json defaultBranchRef,nameWithOwner --jq '{ nameWithOwner: .nameWithOwner, defaultBranchRef: .defaultBranchRef.name }')

# Get the list of remotes and their URLs
REMOTES=$(git remote -v)

echo "remotes: " + $REMOTES
# Use a regular expression to find the remote that points to a GitHub URL
GITHUB_REMOTE=$(echo "$REMOTES" | grep -E '^[^[:space:]]+\s+(https?://github\.com/|git@github\.com:)' | awk '{print $1}' | uniq)
echo "github: " + $GITHUB_REMOTE


# Extract the repository owner and name from the JSON output
REPO_NAME=$(echo "$REPO_INFO" | jq -r '.nameWithOwner')
BASE_BRANCH=$(echo "$REPO_INFO" | jq -r '.defaultBranchRef')

# Get the current branch name
HEAD_BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Generate the title and body using git diff and llm
TITLE=$(git diff $HEAD_BRANCH $GITHUB_REMOTE/$BASE_BRANCH | llm -s "$(cat ~/.config/prompts/pr-title-prompt.txt)")
BODY=$(git diff $HEAD_BRANCH $GITHUB_REMOTE/$BASE_BRANCH| llm -s "$(cat ~/.config/prompts/pr-body-prompt.txt)")

# Create the pull request
echo gh pr create \
  --repo "$REPO_NAME" \
  --base "$BASE_BRANCH" \
  --head "$HEAD_BRANCH" \
  --title "$TITLE" \
  --body "$BODY"
