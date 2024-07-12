#!/bin/bash

##########
# Summary:

##########

# Set your GitHub repository owner and name
ORG="$CIRCLE_PROJECT_USERNAME"
REPO="$CIRCLE_PROJECT_REPONAME"
COMMIT_SHA="$CIRCLE_SHA1"

echo "Checking for open PRs..."

# GitHub API endpoint to check pull requests for a specific commit
PR_URL="https://api.github.com/repos/$ORG/$REPO/commits/$COMMIT_SHA/pulls"

# Call GitHub API to check if there are open pull requests for the commit
PR_RESPONSE=$(curl -s -H "Accept: application/vnd.github.v3+json" "$PR_URL")

# Check if there are any open pull requests for the commit
if [ "$(echo "$PR_RESPONSE" | jq '. | length')" -gt 0 ]; then
    echo "Open pull requests exist for commit $COMMIT_SHA in repository $ORG/$REPO. Continuing..."
else
    echo "No open pull requests found for commit $COMMIT_SHA in repository $ORG/$REPO. Exiting this job."
    # this part is optional. If no open PRs, then exit the job
    circleci-agent step halt
fi