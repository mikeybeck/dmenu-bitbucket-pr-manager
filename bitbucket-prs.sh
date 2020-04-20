#!/bin/bash
# shellcheck disable=SC2034
# shellcheck disable=SC2154
# shellcheck source=/dev/null

# Relevant documentation for BitBucket: http://web.archive.org/web/20150530151816/https://confluence.atlassian.com/display/BITBUCKET/pullrequests+Resource#pullrequests

USERNAME=
PASSWORD=

REPO_OWNER=
REPO_SLUG=

NUM_APPROVALS_REQ=2  # Number of approvals required for pull request

file_location=""

# Export PATH
export PATH="/usr/local/bin:/usr/bin:$PATH"

max_num_prs=20

# Base64 icon to use in system bar
icon="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"
icon="iVBORw0KGgoAAAANSUhEUgAAABQAAAAWCAYAAADAQbwGAAAAAXNSR0IArs4c6QAAACBjSFJNAAB6JgAAgIQAAPoAAACA6AAAdTAAAOpgAAA6mAAAF3CculE8AAAACXBIWXMAAAsTAAALEwEAmpwYAAABWWlUWHRYTUw6Y29tLmFkb2JlLnhtcAAAAAAAPHg6eG1wbWV0YSB4bWxuczp4PSJhZG9iZTpuczptZXRhLyIgeDp4bXB0az0iWE1QIENvcmUgNS40LjAiPgogICA8cmRmOlJERiB4bWxuczpyZGY9Imh0dHA6Ly93d3cudzMub3JnLzE5OTkvMDIvMjItcmRmLXN5bnRheC1ucyMiPgogICAgICA8cmRmOkRlc2NyaXB0aW9uIHJkZjphYm91dD0iIgogICAgICAgICAgICB4bWxuczp0aWZmPSJodHRwOi8vbnMuYWRvYmUuY29tL3RpZmYvMS4wLyI+CiAgICAgICAgIDx0aWZmOk9yaWVudGF0aW9uPjE8L3RpZmY6T3JpZW50YXRpb24+CiAgICAgIDwvcmRmOkRlc2NyaXB0aW9uPgogICA8L3JkZjpSREY+CjwveDp4bXBtZXRhPgpMwidZAAACK0lEQVQ4EbWUO2tUQRSAb2K0CMgGsVCUoCCBlCIqNlY+QImPxsLaH5AiIhYWQsDSQgSxsRHUwsJGLYRNFbXRgGDtgqKCqEl8Jz6+b3bO3SFeDRYe+PY85txzZs7euVXVkxU9M1nh9+f4AHprtvuyXlYNk7Ef1uRMi4Rcw7iUHePSWDh2cIaEj9CBOTgOIRcxfsK5CBQ6TlKEqmo3ng8czNEJ9CdYBxfAtR/wAqZhCk7DKlB+KzpJsJ2Wej8zmA/BYgvwPdv6wX3s1aDESZMzxu9nGE1eVR1Bf4AdcAui6Dy2I/kC7tj4DVDqgjHYKwSd3R34Bh5J8Ti3wYfPg7IdnoExc2Mj6ehRucXCu5z0GK2Us3mEfzlFuz/+4xaUvd1QNVC+FoMEPfYQODOLOTdzFmEPOIImsWiS2J2OwfDVzkixmMXfwl1YCX+Ucod1F7JL2xm702gWjRqLRlLj4pKghf5azPx/KbikfrP7Xws6+Jidc1uuWby/brV+vcqHZl3JElct/FLHM971kHg2NYmEk6y6Qz8A6kOg1N0Lewv2K3gD5sb1w+zKLpSvxuHsn0LbdW32bVoe0VtzM8dG0N6wcahlEmuq9rpGB3U0x3xf4yQbsN/DxrymOgttjUjy7u6ETaDsg/XwVAfxWKK8BD/EJ3SyHEPPhBP6OoafLDt5fLsq0VQ75ulovsIDeA5PoAVpLn3o6H4AexvcAz+eTWIDb8xmcGev4Sp45/t/AVL9dQ7qDO64AAAAAElFTkSuQmCC"
response=$(curl -s -X GET --user $USERNAME:$PASSWORD "https://bitbucket.org/api/2.0/repositories/$REPO_OWNER/$REPO_SLUG/pullrequests/?pagelen=$max_num_prs")
json=$(echo $response | jq -r -c '[.values[] | {id: .id, title: .title, author: .author.display_name, num_comments: .comment_count, link_html: .links.html.href, link_status: .links.statuses.href, link_self: .links.self.href, created_at: .created_on, last_updated: .updated_on}]')
prs=$(echo $response | jq -r -c '(.size|tostring)')

#echo -e $response;
#exit;
pr_count=0
max_pr_count=$(( prs < max_num_prs ? prs : max_num_prs ))

num_approved_by_me=0
declare -a lines

for pr in $(echo "${json}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${pr} | base64 --decode | jq -r ${1}
    }

   build_state=$(curl -s -X GET --user $USERNAME:$PASSWORD $(_jq '.link_status') | jq -r '.values[].state')
   self=$(curl -s -X GET --user $USERNAME:$PASSWORD $(_jq '.link_self'))
   num_approvals=$(echo $self | jq -r '[select(.participants[].approved)] | length')
   colour="red"
   if [[ $build_state == "SUCCESSFUL" ]]; then
    colour="green" # Colour to show if PR is good to go (approved & build passed)
    if [ "$num_approvals" -lt "$NUM_APPROVALS_REQ" ]; then
      colour="black" # Colour to show if PR build passed but not approved
    fi
   fi

   approved_by_me=$(echo $self | jq -r --arg USERNAME "$USERNAME" '.participants[] | select(.user.nickname == $USERNAME) | .approved')

#   participants=$(echo $self | jq -r --arg USERNAME "$USERNAME" '.participants[]')
#   me=$(echo $self | jq -r --arg USERNAME "$USERNAME" '.participants[] | select(.user.nickname == $USERNAME)')
#   echo -e "self: $self"  >> output-test.json
#   echo -e "participants: $participants"  >> output-test.json
#   echo -e "me: $me"  >> output-test.json
#   echo -e "approved_by_me: $approved_by_me"  >> output-test.json

   if [[ $approved_by_me == "true" ]]; then
    approved_by_me="Y"
    ((num_approved_by_me++))
   else
    approved_by_me="-"
   fi

  # Find unseen value from existing output file.
  # If 0, make unseen = new comments - old comments.  Otherwise, make unseen=comments.
  PR_JSON=`cat $file_location'output.json' | jq .`
  old_comments=$(echo -e $PR_JSON | jq ".[] | select(.id == $(_jq '.id')) | .comments")
  old_unseen=$(echo -e $PR_JSON | jq ".[] | select(.id == $(_jq '.id')) | .unseen")

  comments=$(_jq '.num_comments')
  new=0

#  echo -e "$(_jq '.id')" >> output-test.json
  if [[ "$old_unseen" == '"0"' || "$old_unseen" == '""0""' || "$old_unseen" == '0' || "$old_unseen" == 0 ]]; then
#   echo -e "good" >> output-test.json
    unseen=$(( comments - old_comments ))
  else
#     echo -e "bad" >> output-test.json
#     echo -e "$old_unseen" >> output-test.json
    unseen=$comments
    new=1
  fi

  line=$(echo "\"approved\":\"$approved_by_me\", " \"author\":\"$(_jq '.author')\", \"title\":\"$(_jq '.title')\", " \"approvals\":$num_approvals, \"comments\":$(_jq '.num_comments'), \"unseen\":$unseen, \"id\":$(_jq '.id'), \"new\":$new, \"created_at\":\"$(_jq '.created_at')\", \"last_updated\":\"$(_jq '.last_updated')\"")

  let pr_count++

  if [[ $pr_count == $max_pr_count ]]; then
      lines+=("{$line}")
  else
      lines+=("{$line},\n")
  fi

done

echo -e "[${lines[@]}]" > $file_location"output.json"

num_unapproved_by_me=$((prs - num_approved_by_me))

echo $prs "/" $num_unapproved_by_me > $file_location"bitbucket-prs.txt"

current_time=`date +"%T"`

echo $prs "/" $num_unapproved_by_me $current_time

#exit;

# Print everything out

# num_unapproved_by_me=$((prs - num_approved_by_me))
# echo $prs "/" $num_unapproved_by_me " | templateImage=$icon dropdown=false" # Display number of PRs in menu bar
# # if [[ $num_unapproved_by_me != 0 ]]; then
# #   echo "($num_unapproved_by_me unapproved) | dropdown=false" # Cycle number of PRs not approved by me in menu bar, if > 0
# # fi
# echo "---"
# echo "View all open pull requests | href=https://bitbucket.org/$REPO_OWNER/$REPO_SLUG/pull-requests/"
# echo "---"

#for line in "${lines[@]}"
#do
#  echo "$line" # Display open PRs in dropdown
#done

#dmenu -l 10 <<< "${LINES[@]}"

#menu=$("${lines[@]}" | dmenu -l 10)
#list=("1\n2\n3\n4\n5")
#echo -e "${lines[@]}" | dmenu -l 10












# selected=$(echo -e "${lines[@]}" | dmenu -l 10)
# link=$(echo -e $selected | grep -o -P '(?<=href=).*(?= color)')

# action=$(echo -e "Open link\nMark as seen\nDo nothing" | dmenu -l 3)

# case "$action" in
#     "Open link")
#         xdg-open $link
#         ;;
#     "Mark as seen")
#         echo "marking seen"
#         echo $selected
#         ;;
#     "Do nothing")
#         echo "exiting"
#         ;;
# esac
