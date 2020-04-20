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

START_TIME="09:00" # Only run after this time (24 hr time)
END_TIME="19:00" # Only run before this time (24 hr time)

file_location=""

# Export PATH
export PATH="/usr/local/bin:/usr/bin:$PATH"

max_num_prs=20

response=$(curl -s -X GET --user $USERNAME:$PASSWORD "https://bitbucket.org/api/2.0/repositories/$REPO_OWNER/$REPO_SLUG/pullrequests/?pagelen=$max_num_prs")
json=$(echo $response | jq -r -c '[.values[] | {id: .id, title: .title, author: .author.display_name, num_comments: .comment_count, link_html: .links.html.href, link_status: .links.statuses.href, link_self: .links.self.href, created_at: .created_on, last_updated: .updated_on}]')
prs=$(echo $response | jq -r -c '(.size|tostring)')

#echo -e $response;
#exit;
pr_count=0
max_pr_count=$(( prs < max_num_prs ? prs : max_num_prs ))

num_approved_by_me=0
declare -a lines

# Only run when between 9am & 7pm
currenttime=$(date +%H:%M)
if [[ "$currenttime" > $END_TIME ]] || [[ "$currenttime" < $START_TIME ]]; then
    exit;
fi


for pr in $(echo "${json}" | jq -r '.[] | @base64'); do
    _jq() {
     echo ${pr} | base64 --decode | jq -r ${1}
    }

#   build_state=$(curl -s -X GET --user $USERNAME:$PASSWORD $(_jq '.link_status') | jq -r '.values[].state')
   self=$(curl -s -X GET --user $USERNAME:$PASSWORD $(_jq '.link_self'))
   num_approvals=$(echo $self | jq -r '[select(.participants[].approved)] | length')
   colour="red"
#   if [[ $build_state == "SUCCESSFUL" ]]; then
#    colour="green" # Colour to show if PR is good to go (approved & build passed)
#    if [ "$num_approvals" -lt "$NUM_APPROVALS_REQ" ]; then
#      colour="black" # Colour to show if PR build passed but not approved
#    fi
#   fi

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
