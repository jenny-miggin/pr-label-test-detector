# Dynamic Config using Pull Requests

This repo outlines how to use the presence and status of Github' Pull Requests to progress a CircleCI Pipeline

## Introduction

The `path-filtering/filter` job is very useful to determine what parameters to set, based off of file changes.

However, there may be a case to stop a build if the current commit does not have an associated open pull request (PR) or if it is in draft mode. Labels attached to the PR can also be used to set pipeline parameters used to target and trigger specific workflows.

### The Steps

1. After code is checked out, the `pr-checker` script checks if the current commit has an open PR associated with it. If it does not, then the job ends here

2. If there is an open PR, the `draft-checker` script checks if the open PR is in a [draft mode](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests/proposing-changes-to-your-work-with-pull-requests/about-pull-requests#draft-pull-requests).

3. At this stage, directories are scanned for code changes, using the `path-filtering/set-parameters` [command](https://circleci.com/developer/orbs/orb/circleci/path-filtering#commands-set-parameters). The associated parameters are set.

4. Labels attached to the open PR are now gathered using the `label-checker`. If the label matches that of a parameter in the `continue_config.yml` file, then that parameter is added to those gathered in step 3, and the file is saved for sending to CircleCI

5. The workflow is now continued, using the `continuation/continue` [command](https://circleci.com/developer/orbs/orb/circleci/continuation#commands-continue)

## But wait! There's more!

What if we could use the labels attached to the PR to reduce the amount of needless workflows/jobs/tests being executed? Introducing `rerun mode`

### Rerun Mode

If the open PR has a label `rerun-mode` attached, then rerun mode has been enabled. This will add the `"rerun-mode": true` to the list of parameters generated during the `setup-workflow`.

In the `continue_config.yml` file, there is a dedicated workflow for this parameter. This workflow:

1. Checks for failed workflows for the same project and the same branch
2. Generates a list of job names and IDs for jobs that have failed
3. Finds the name of the tests that have failed in these jobs
4. Reruns only these tests
