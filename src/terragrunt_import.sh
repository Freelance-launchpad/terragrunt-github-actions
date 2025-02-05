#!/bin/bash

function terragruntImport {
  # Gather the output of `terragrunt import`.
  echo "import: info: importing Terragrunt configuration in ${tfWorkingDir}"
  importOutput=$(${tfBinary} import -input=false ${*} 2>&1)
  importExitCode=${?}
  importCommentStatus="Failed"

  # Exit code of 0 indicates success with no changes. Print the output and exit.
  if [ ${importExitCode} -eq 0 ]; then
    echo "import: info: successfully imported Terragrunt configuration in ${tfWorkingDir}"
    echo "${importOutput}"
    echo
    exit ${importExitCode}
  fi

  # Exit code of !0 indicates failure.
  if [ ${importExitCode} -ne 0 ]; then
    echo "import: error: failed to import Terragrunt configuration in ${tfWorkingDir}"
    echo "${importOutput}"
    echo
  fi

  # Comment on the pull request if necessary.
  if [ "$GITHUB_EVENT_NAME" == "pull_request" ] && [ "${tfComment}" == "1" ] && [ "${importCommentStatus}" == "Failed" ]; then
    importCommentWrapper="#### \`${tfBinary} import\` ${importCommentStatus}
<details><summary>Show Output</summary>

\`\`\`terraform
${importOutput}
\`\`\`

</details>

*Workflow: \`${GITHUB_WORKFLOW}\`, Action: \`${GITHUB_ACTION}\`, Working Directory: \`${tfWorkingDir}\`, Workspace: \`${tfWorkspace}\`*"

    importCommentWrapper=$(stripColors "${importCommentWrapper}")
    echo "import: info: creating JSON"
    importPayload=$(echo "${importCommentWrapper}" | jq -R --slurp '{body: .}')
    importCommentsURL=$(cat ${GITHUB_EVENT_PATH} | jq -r .pull_request.comments_url)
    echo "import: info: commenting on the pull request"
    echo "${importPayload}" | curl -s -S -H "Authorization: token ${GITHUB_TOKEN}" --header "Content-Type: application/json" --data @- "${importCommentsURL}" > /dev/null
  fi

  exit ${importExitCode}
}
