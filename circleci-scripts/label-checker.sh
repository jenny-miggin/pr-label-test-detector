#!/bin/bash

##########
# Summary:
# Checks and displays the labels associated with the open pull requests and compares them to parameters in the continuation configuration file. 
# If a label matches a parameter, it updates the parameters file with the corresponding JSON.
##########

# Set your GitHub repository owner and name
ORG="$CIRCLE_PROJECT_USERNAME"
REPO="$CIRCLE_PROJECT_REPONAME"
COMMIT_SHA="$CIRCLE_SHA1"

# GitHub API endpoint to check pull requests for a specific commit
PR_URL="https://api.github.com/repos/$ORG/$REPO/commits/$COMMIT_SHA/pulls"

# Call GitHub API to get labels for the PR
PR_RESPONSE=$(curl -s -H "Accept: application/vnd.github.v3+json" "$PR_URL")

# Extract and display the labels for the open pull request
LABELS=$(echo "$PR_RESPONSE" | jq -r '.[].labels[].name')
if [ -n "$LABELS" ]; then
    echo "Labels for the pull request in $ORG/$REPO:"
    echo "$LABELS"
    # Compare the labels to parameters in config file as the workflow will fail if the label is not also a parameter
    # Load up the parameters declared in the config file
    CONFIG_PARAMS=$(yq -p yaml -o json "$CONFIG_PATH" | jq -r '.parameters | keys[]')

    # Transform the labels into pipeline parameters, if the parameters exist in the config
    # If parameters are already in the file after path-filtering, then that file will be updated
    ## TODO: Add logic to remove other parameters when in rerun mode
    while IFS= read -r line; do
        if [[ $CONFIG_PARAMS == *"$line"* ]] ; then
            echo "$line label has a matching parameter. Adding to parameters file..."
            label_param='{"'"$line"'":true}'
            orig_param_file=$(cat "$PARAM_FILE")
            updated_param_file=$(jq -n --argjson a "$orig_param_file" --argjson b "$label_param" '$a + $b')
            echo "$updated_param_file" > "$PARAM_FILE"
        else
            echo "$line label is not set as a parameter. Skipping..."
        fi
    done <<< "$LABELS"

else
    echo "No labels found for the pull request."
fi