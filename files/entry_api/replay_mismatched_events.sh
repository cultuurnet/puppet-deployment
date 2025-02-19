#!/bin/bash
#
# This script finds mismatched event uuids in /var/www/udb3-backend/log/web.log.1 (latest rotated logfile)
# and forces a replay via the /var/www/udb-silex/bin/udb3.php replay command

# Logfile is first and only input parameter
LOGFILE=$1

# check if input param is present
if [[ -z $LOGFILE ]]
then
  echo "ERROR: Logfile must be provided"
  exit 1
fi

# check if logfile exists
if [[ ! -f "$LOGFILE" ]]
then
  echo "ERROR: $LOGFILE not found"
  exit 1
fi

# check if logfile is plaintext or compressed
if grep -q ".gz" <<< "$LOGFILE"
then
  grep_command='zgrep'
else
  grep_command='grep'
fi

# Fetch list of uuids from logfile and count them
 UUIDS_TO_REPLAY=$($grep_command 'web.ERROR: Playhead mismatch' $LOGFILE | awk '{print $8}' | sed -e 's/\.//' | sort | uniq)
NUMBER_OF_EVENTS=$(echo $UUIDS_TO_REPLAY | wc -w)

# loop over uuids
echo "Starting replay of $NUMBER_OF_EVENTS mismatched events from logfile $LOGFILE at $(date):"

for UUID in $UUIDS_TO_REPLAY
do
  /var/www/udb3-backend/bin/udb3.php replay --force --cdbid $UUID
  sleep 4
done

echo "Replay of $NUMBER_OF_EVENTS mismatched events from logfile $LOGFILE completed at $(date):"
