#!/bin/bash -l

# see if there is not a gollum process running
if [ "$(ps ax | grep gollum | grep -v grep)" ]; then
  # gollum is running
  echo "Gollum is running"
else
  echo "Starting gollum"
  cd $HOME/wiki
  bundle exec gollum &> /dev/null &
fi

