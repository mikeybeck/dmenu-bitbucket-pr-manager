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
json=$(echo $response | jq -r -c '[.values[] | {id: .id, title: .title, author: .author.display_name, num_comments: .comment_count, link_html: .links.html.href, link_status: .links.statuses.href, link_self: .links.self.href, destination_branch: .destination.branch.name, created_at: .created_on, last_updated: .updated_on, last_checked: 0}]')
prs=$(echo $response | jq -r -c '(.size|tostring)')

# echo -e $response > $file_location"response.txt";
# echo -e $json > $file_location"json.txt";
#exit;
pr_count=0
max_pr_count=$(( prs < max_num_prs ? prs : max_num_prs ))

num_approved_by_me=0
declare -a lines

# Only run when between 9am & 7pm
current_time=$(date +%H:%M)
if [[ "$current_time" > $END_TIME ]] || [[ "$current_time" < $START_TIME ]]; then
    echo `cat $file_location"bitbucket-prs-polybar.txt"` "$current_time"
    exit;
fi

echo $json > $file_location"bitbucket-prs-json.txt"

# Check if there are any differences.  If none, output contents of polybar status file and exit
prev_json=$file_location"bitbucket-prs-json-prev.txt"
new_json=$file_location"bitbucket-prs-json.txt"
changed=`cmp --silent $prev_json $new_json || echo "true"`
if [[ $changed != "true" ]]; then
    echo `cat $file_location"bitbucket-prs-polybar.txt"` "$current_time"
    exit;
fi

echo $json > $file_location"bitbucket-prs-json-prev.txt"

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

  PR_JSON_OLD=`cat $file_location'output.json' | jq .`

  # Find unseen value from existing output file.
  # If 0, make unseen = new comments - old comments.  Otherwise, make unseen=comments.
  old_comments=$(echo -e $PR_JSON_OLD | jq ".[] | select(.id == $(_jq '.id')) | .comments")
  old_unseen=$(echo -e $PR_JSON_OLD | jq ".[] | select(.id == $(_jq '.id')) | .unseen")

  last_updated_old=$(echo -e $PR_JSON_OLD | jq ".[] | select(.id == $(_jq '.id')) | .last_updated")
  last_updated=$(_jq '.last_updated')

  pr_changed=0

  if [[ "$last_updated_old" != "$last_updated" ]]; then
    pr_changed=1
  fi

#echo $PR_JSON

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


  title=$(_jq '.title')
  title=`echo "${title//\"}"`
  title=`echo "${title//\'}"`
#  title="zz"
#   echo $title

  line=$(echo "\"approved\":\"$approved_by_me\", " \"author\":\"$(_jq '.author')\", \"title\":\"$title\", " \"approvals\":$num_approvals, \"comments\":$(_jq '.num_comments'), \"unseen\":$unseen, \"id\":$(_jq '.id'), \"new\":$new, \"destination_branch\":\"$(_jq '.destination_branch')\", \"pr_changed\":$pr_changed, \"created_at\":\"$(_jq '.created_at')\", \"last_updated\":\"$(_jq '.last_updated')\"")

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


polybar_status=$(echo $prs "/" $num_unapproved_by_me)

echo $polybar_status > $file_location"bitbucket-prs-polybar.txt"

echo $polybar_status "$current_time *"
