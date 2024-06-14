#!/bin/bash

if pgrep "s76-disable-sus" &>/dev/null; then
    exit
fi

while true; do
    sleep $(( ( RANDOM % 180 ) + 60 )) # Sleep for a random time between 1-3 minutes

    # Get the current mouse position
    eval $(xdotool getmouselocation --shell)

    # Move the mouse
    xdotool mousemove --sync $((X+1)) $((Y+1))
    xdotool mousemove --sync $X $Y
done
