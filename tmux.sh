#!/bin/zsh

SESSIONNAME="sob"
WORKDIR="/Users/binajmen/Developer/sob"

# Check if session exists
tmux has-session -t $SESSIONNAME &> /dev/null

if [ $? != 0 ]
then
    tmux new-session -s $SESSIONNAME -n code -c $WORKDIR -d
    tmux new-window -t $SESSIONNAME -n term -c $WORKDIR
    tmux new-window -t $SESSIONNAME -n git -c $WORKDIR

    tmux select-window -t "${SESSIONNAME}:code"

    sleep 1

    tmux send-keys -t "${SESSIONNAME}:code" "nvim ." C-m

    tmux split-window -v -t "${SESSIONNAME}:term" -c $WORKDIR
    tmux send-keys -t "${SESSIONNAME}:term.1" "cd client && just dev" C-m
    tmux send-keys -t "${SESSIONNAME}:term.2" "cd server && just run" C-m

    tmux send-keys -t "${SESSIONNAME}:git" "lazygit" C-m
fi

# Attach to session
tmux attach -t $SESSIONNAME
