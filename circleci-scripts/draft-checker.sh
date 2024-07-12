#!/bin/bash

##########
# Summary:
# Check if a PR is in draft mode. If it is, then the job will end here
##########

# Set your GitHub repository owner and name
ORG="$CIRCLE_PROJECT_USERNAME"
REPO="$CIRCLE_PROJECT_REPONAME"
COMMIT_SHA="$CIRCLE_SHA1"

echo "Checking if open PRs are a draft..."

# GitHub API endpoint to check pull requests for a specific commit
PR_URL="https://api.github.com/repos/$ORG/$REPO/commits/$COMMIT_SHA/pulls"

# Call GitHub API to check the open pull requests for the commit
PR_RESPONSE=$(curl -s -H "Accept: application/vnd.github.v3+json" "$PR_URL")

# Check if the open PR is still a draft
if [ "$(echo "$PR_RESPONSE" | jq -r '.[].draft')" == 'false' ]; then
    echo "Open pull request not a draft. Continuing..."
else
    echo "Open pull request is still a draft. Exiting this job."
    # this part is optional. If PR is still a draft, then exit the job
    circleci-agent step halt
fi