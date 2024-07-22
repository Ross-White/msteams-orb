#!/bin/bash

# Ensure variables are set
: "${DEPLOYED_ENV:?Environment variable DEPLOYED_ENV is required}"
: "${WEBHOOK_URL:?Environment variable WEBHOOK_URL is required}"

# Set environment variables
# DEV="https://www-dev.ecotricity.co.uk"
# UAT="https://www-uat.ecotricity.co.uk"
# PROD="https://www.ecotricity.co.uk"

DEPLOYED_URL="$DEPLOYED_ENV"
ENV="$DEPLOYED_ENV"

SHORT_SHA1=$(echo -n "$CIRCLE_SHA1" | head -c 7)

if echo "$CIRCLE_REPOSITORY_URL" | grep -q "^git@github.com"; then
  COMMIT_LINK="[$SHORT_SHA1](https://github.com/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/commit/$CIRCLE_SHA1)"
elif echo "$CIRCLE_REPOSITORY_URL" | grep -q "^git@bitbucket.org"; then
  COMMIT_LINK="[$SHORT_SHA1](https://bitbucket.org/$CIRCLE_PROJECT_USERNAME/$CIRCLE_PROJECT_REPONAME/commit/$CIRCLE_SHA1)"
else
  >&2 echo "unknown version control system: $CIRCLE_REPOSITORY_URL"
  exit 1
fi

COMMIT_MESSAGE=$(git log --format=%B -n 1 "$CIRCLE_SHA1")

MS_TEAMS_MSG_TEMPLATE=$(cat <<EOF
{
  "@type": "MessageCard",
  "@context": "http://schema.org/extensions",
  "themeColor": "14a603",
  "summary": "CircleCI Deployment Notification",
  "sections": [
    {
      "activityTitle": "## ${CIRCLE_BRANCH} deployed to [${ENV}](${DEPLOYED_URL})",
      "facts": [
        {
          "name": "Author",
          "value": "${CIRCLE_USERNAME}"
        },
        {
          "name": "Revision",
          "value": "${COMMIT_LINK}"
        },
        {
          "name": "Commit",
          "value": "${COMMIT_MESSAGE}"
        }
      ],
      "markdown": true
    }
  ]
}
EOF
)

echo "$MS_TEAMS_MSG_TEMPLATE" > .ms_teams_message

cat .ms_teams_message

echo "$WEBHOOK_URL"

curl --fail-with-body -H "Content-Type: application/json" \
      --data-binary @.ms_teams_message \
      "$WEBHOOK_URL"

