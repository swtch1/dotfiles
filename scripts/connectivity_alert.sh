#!/usr/bin/env bash

check() {
  ping 8.8.8.8 -c 1 -t 5 &> /dev/null
  return $?
}

consecutive_failures=0
while true
do
  if [ $consecutive_failures -gt 3 ]; then
    echo "$(date) - connectivity lost"
		osascript -e 'display notification "the internet is down" with title "connectivity"'
		osascript -e 'say "the internet is down"'
	fi

  if check; then
    if [ $consecutive_failures -gt 3 ]; then
  	  consecutive_failures=0
		  echo "$(date) - connectivity restored"
		  osascript -e 'say "were back online"'
	  fi
    sleep 5
  else
    consecutive_failures=$((consecutive_failures+1))
  fi
done
