#!/bin/bash

##########
# Summary:
# Injests a list of failed jobs to create a list of tests that have failed in those jobs
##########

### Set your GitHub repository owner and name
ORG="$CIRCLE_PROJECT_USERNAME"
REPO="$CIRCLE_PROJECT_REPONAME"

### Other Variables
API_TOKEN="$CIRCLECI_API_TOKEN"
FAILED_JOB_INFO="failed_job_info.json"
TEST_OUTPUT="test_output.json"
FAILED_TESTS_LIST="list_of_failed_tests.txt"

# Ingest the failed job numbers from the file generated from find-failed-jobs.sh

FAILED_JOB_IDS=$(jq -r '.[].job_no' $FAILED_JOB_INFO)

# Getting any test results for this job

while IFS= read -r line; do
    echo "Finding test results for job number $line"
    TESTS_URL="https://circleci.com/api/v2/project/gh/$ORG/$REPO/$line/tests"
    TEST_OUTPUT="$(curl -s -H "Circle-Token: $API_TOKEN" "$TESTS_URL" | jq -r '.items[]')"
    
    # Process the results, and find failed test information
    # For yarn test, the "file" parameter is the required input to selectively execute a test. 
    # Depending on test suite, a different parameter e.g. classname could be required
    if [ -n "$TEST_OUTPUT" ]; then
        FAILED_TESTS=$(echo "$TEST_OUTPUT" | jq -r ' select(.result == "failure") | .file')
        echo "$FAILED_TESTS"
        while IFS= read -r test; do        
            if [ ! -f "$FAILED_TESTS_LIST" ] || ! grep -qxF "$test" "$FAILED_TESTS_LIST"; then
                echo "Test Results found. Saving the name of the failed tests."
                echo "$test" >> "$FAILED_TESTS_LIST"
            else
                echo "Test already in file, moving on..."
            fi
        done <<< "$FAILED_TESTS"
    else 
        echo "No test results found."
    fi
    echo "export FAILED_TESTS_LIST=$FAILED_TESTS_LIST" >> "$BASH_ENV"
done <<< "$FAILED_JOB_IDS"