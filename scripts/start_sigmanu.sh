#!/bin/bash -l

# see if there is not a gollum process running
if [ "$(ps ax | grep "bin/sigmanu" | grep -v grep)" ]; then
  # sigmanu is running
  echo "sigmanu is running"
else
  echo "Starting sigmanu"
  cd $HOME/sigmanuweb/snweb
  bundle exec bin/sigmanu &> /dev/null &
fi

