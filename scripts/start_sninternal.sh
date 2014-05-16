#!/bin/bash -l

# see if there is not a gollum process running
if [ "$(ps ax | grep "bin/sninternal" | grep -v grep)" ]; then
  # sninternal is running
  echo "sninternal is running"
else
  echo "Starting sninternal"
  cd $HOME/snweb
  bundle exec bin/sninternal &> /dev/null &
fi

