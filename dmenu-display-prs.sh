#!/bin/zsh

file_location=""
url=""

# Update output file with current status of PR
# mark_seen () {
#     # Look for $1 (line) in file and update it.
#     line=$1
#     echo -e $line > line.txt

#     # Update line in file
#     sed -i 's/unseen=.* |/unseen=0 |/g' line.txt

#     updated_line=`cat line.txt`

#     sed -i 's#'"$line"'#'"$updated_line"'#g' output.txt # Note that /'s break this so might need to strip them?
# }

mark_seen () {
    # Set unseen to 0 for PRID $1
    PRID=$1

    PR_JSON=`cat $file_location'output.json' | jq .`

    PR_JSON_UPDATED=`echo -e $PR_JSON | (jq "(.[] | select(.id == $PRID) | .unseen, .new) |= 0")`

    echo -e $PR_JSON_UPDATED

    echo -e $PR_JSON_UPDATED > $file_location"output.json"
}

declare -a lines


# echo -e $LINES | jq '.' > output.json

JSON=`cat "$file_location"output.json`

#MENU=`echo -e $JSON | jq '.[] | .approved, (.approvals|tostring) + " | " + .title + " | " + .author + " | Comments: " + (.comments|tostring) + " | Unseen: " + (.unseen|tostring)  + " | ID: " + (.id|tostring) + " # " + (.new|tostring) + "\n"'`
#MENU=`echo -e $JSON | jq '.[] "\"" + .approved + "\" + " | " + .title + " | " + .author + " | Comments: " + (.comments|tostring) + " | Unseen: " + (.unseen|tostring)  + " | ID: " + (.id|tostring) + " # " + (.new|tostring) + "\n"'`
MENU=`echo -e $JSON | jq -r '.[] | [.approved, .author, .title, "Comments: " + (.comments|tostring), "Unseen: " + (.unseen|tostring), "ID: " + (.id|tostring) + "#", "New: " + (.new|tostring), .approvals, "Created at: " + .created_at, "Last updated: " + .last_updated] | @csv'`

MENU=`echo -e $MENU | awk -v FS="," 'BEGIN{print "============"}
{approved=substr($1,2,1)}
{author=FS $2}
{author=substr(author,3,length(author) - 3)}
{title=FS $3}
length(title) > 40 {title=substr(title,0,37)"...."}
{title=substr(title,3,length(title) - 3)}
{comments=FS $4}
{comments=substr(comments,3,length(comments) - 3)}
{unseen=FS $5}
{unseen=substr(unseen,3,length(unseen) - 3)}
{id=FS $6}
{id=substr(id,3,length(id) - 3)}
{new=FS $7}
{new=substr(new,3,length(new) - 3)}
{approvals=FS $8}
{approvals=substr(approvals,2,1)}
{created=FS $9}
{created=substr(created,3,length(created) - 19)}
{updated=FS $10}
{updated=substr(updated,3,length(updated) - 19)}
{printf "%-2s %-3s %-40s %-20s %-15s %10s %15s %10s %30s %35s %20s", approved, approvals, title, author, comments, unseen, id, new, created, updated, ORS}'`

selected=$(echo -e $MENU | dmenu -l 10)

echo $selected

#selected=$(echo -e "${LINES[@]}" | dmenu -l 10)
pr_id=$(echo -e $selected | grep -o -P '(?<=ID: ).*(?=#)')

# echo '----'
# echo $pr_id
# sleep 100

# exit;

action=$(echo -e "Open link\nMark as seen\nDo nothing" | dmenu -l 3)

case "$action" in
    "Open link")
        echo "Opening " $url$pr_id
        xdg-open $url$pr_id
        sleep 1 # In case of error messages
        mark_seen "$pr_id"
        sleep 2
        ;;
    "Mark as seen")
        echo "marking seen"
        mark_seen "$pr_id"
        ;;
    "Do nothing")
        echo "exiting"
        ;;
esac


