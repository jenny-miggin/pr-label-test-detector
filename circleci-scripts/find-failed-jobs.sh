#!/bin/bash

##########
# Summary:
# Compile a list of job names and IDs that have failed. The list is generated from a list of pipelines for the current project, and current branch. 
##########

### Set your GitHub repository owner and name
ORG="$CIRCLE_PROJECT_USERNAME"
REPO="$CIRCLE_PROJECT_REPONAME"
BRANCH="$CIRCLE_BRANCH"

### Other Variables
API_TOKEN="$CIRCLECI_API_TOKEN"
FAILED_JOB_INFO="failed_job_info.json"
WORKFLOW_RESPONSE="workflow_response.json"

### Process

echo "Getting a list of CircleCI pipelines for this branch"

# Get pipelines that have run for the current branch
PIPELINES_URL="https://circleci.com/api/v2/project/gh/$ORG/$REPO/pipeline?branch=$BRANCH"

# To get all pipeline IDs for pipelines on this branch, this snippet could be useful
# PIPELINES_IDS=$(curl -s -H "Circle-Token: $API_TOKEN" "$PIPELINES_URL" | jq -r '.items[].id')
# # current Pipeline ID appears in the list, so remove it
# PREV_PIPE_IDS=$(echo "$PIPELINES_IDS" | sed "\|$CIRCLE_PIPELINE_ID|d")

### Bonus: Just get the ID for the pipeline that ran on the last commit
PREVIOUS_COMMIT_SHA=$(git log -n 2 --pretty=%H | tail -1)

echo "$PREVIOUS_COMMIT_SHA"

PREV_PIPE_IDS=$(curl -s -H "Circle-Token: $CIRCLECI_API_TOKEN" "$PIPELINES_URL" | jq -r --arg prev_sha "$PREVIOUS_COMMIT_SHA" '.items[] | select(.vcs.revision == $prev_sha) .id')

if [ -n "$PREV_PIPE_IDS" ]; then
    # Get info on these workflows and save the responses
    echo "Previous Pipeline IDs for this branch found"
    while IFS= read -r line; do
        WORKFLOW_URL="https://circleci.com/api/v2/pipeline/$line/workflow"
        curl -s -H "Circle-Token: $API_TOKEN" "$WORKFLOW_URL" >> $WORKFLOW_RESPONSE

    done <<< "$PREV_PIPE_IDS"
    # Get a list of all the IDs for workflows that failed
    echo "Checking if any workflows in this pipeline failed"
    FAILED_WORKFLOW_IDS=$(jq -r '.items[] | select(.status == "failed") | .id' "$WORKFLOW_RESPONSE" )

    if [ -z "$FAILED_WORKFLOW_IDS" ]; then
        echo "No failed workflows found. Exiting..."
        exit 0
    else
        echo "Failed workflows found. Continuing..."
    fi    
    while IFS= read -r id; do
        WORKFLOW_JOB_URL="https://circleci.com/api/v2/workflow/$id/job"
        WORKFLOW_JOB_RESPONSE=$(curl -s -H "Circle-Token: $API_TOKEN" "$WORKFLOW_JOB_URL")

        # Now that we have info on failed workflows, lets get the information for the jobs that failed in that workflow
        # Retrieve failed job details from WORKFLOW_JOB_RESPONSE
        FAILED_JOB_DETAILS=$(echo "$WORKFLOW_JOB_RESPONSE" | jq -r '.items[] | select(.status == "failed") | {job_number: .job_number, id: .id, name: .name}')

        # Extract individual values from FAILED_JOB_DETAILS
        FAILED_JOB_NO=$(echo "$FAILED_JOB_DETAILS" | jq -r '.job_number')
        FAILED_JOB_ID=$(echo "$FAILED_JOB_DETAILS" | jq -r '.id')
        FAILED_JOB_NAME=$(echo "$FAILED_JOB_DETAILS" | jq -r '.name')
        FAILED_JOB_NAME_AND_NO='{"'job_name'":"'"$FAILED_JOB_NAME"'", "'job_no'":"'"$FAILED_JOB_NO"'"}'
        echo "$FAILED_JOB_NAME failed."

        # Build json file with failed job information
        if [ -f "$FAILED_JOB_INFO" ]; then
            ORIG_FAILED_JOB_INFO=$(cat "$FAILED_JOB_INFO")
        else
            ORIG_FAILED_JOB_INFO="[]"
        fi

        UPDATED_FAILED_JOB_INFO=$(echo "$ORIG_FAILED_JOB_INFO" | jq -n --argjson a "$ORIG_FAILED_JOB_INFO" --argjson b "$FAILED_JOB_NAME_AND_NO" '$a + [$b]')
        echo "$UPDATED_FAILED_JOB_INFO" > "$FAILED_JOB_INFO"
                
        # Optional: print the curl command to rerun the job that failed. This will use the same commit SHA as the job that failed.
        cat <<EOF

To rerun this job, execute this command: 

curl --request POST \\
    --url https://circleci.com/api/v2/workflow/$FAILED_WORKFLOW_ID/rerun \\
    --header "Circle-Token: <CIRCLECI_TOKEN>" \\
    --data '{"jobs":["$FAILED_JOB_ID"]}'
EOF
        echo "export FAILED_JOB_INFO=$FAILED_JOB_INFO" >> "$BASH_ENV"

    done <<< "$FAILED_WORKFLOW_IDS"

else 
    echo "No pipelines found."
fi