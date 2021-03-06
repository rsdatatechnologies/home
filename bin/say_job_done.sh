#!/bin/bash
#Sam Gleske
#Sat Jan 23 14:15:22 PST 2016

#say command
#Mac OSX 10.11.2
#Darwin 15.2.0 x86_64

#espeak command
#Ubuntu 16.04.1 LTS
#Linux 4.4.0-36-generic x86_64

#DESCRIPTION:
#  Script to say when the job is done.  Useful in programming loops and when
#  programs exit without needing to regularly check the terminal window.  It
#  will say when the job is done.

PHRASE="${1:-Job done.}"

if type -P espeak &> /dev/null;then
  espeak -v en-german <<< "${PHRASE}"
elif type -P say &> /dev/null;then
  say -v Daniel "${PHRASE}"
else
  echo "No speaking command available." 1>&2
  exit 1
fi
