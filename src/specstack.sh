#!/bin/bash
# Parser stack
#
#  Copyright (C) 2014 Mike Gerwitz
#
#  This file is part of shspec.
#
#  shspec is free software: you can redistribute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation, either version 3 of the License, or
#  (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.
#
#  You should have received a copy of the GNU General Public License
#  along with this program.  If not, see <http://www.gnu.org/licenses/>.
##

[ -z $__INC_SPECSTACK ] || return
__INC_SPECSTACK=1

declare -a __sstack=()
declare -i __sstackp=0


##
# Push a frame onto the stack
shspec::stack::_push()
{
  local -r type="$1"
  local -r srcline="$2"
  local -r srcfile="$3"
  shift 3

  __sstack[$__sstackp]="$type|$srcline|$srcfile|$*"
  ((__sstackp++))
}


##
# Pop a frame from the stack
#
# It is possible to recover the most recently popped frame.
shspec::stack::_pop()
{
  [ "$__sstackp" -gt 0 ] || return 1

  # notice that we unset before we decrease the pointer; this allows for a
  # single level of un-popping
  unset __sstack[$__sstackp]
  ((__sstackp--))
}


##
# Recover the most recently popped frame
#
# Note that this should never be called more than once in an attempt to
# recover additional frames; it will not work, and you will make bad things
# happen, and people will hate you.
shspec::stack::_unpop()
{
  ((__sstackp++))
}


##
# Return with a non-zero status only if the stack is non-empty
shspec::stack::_empty()
{
  test "$__sstackp" -eq 0
}


##
# Output the current size of the stack
shspec::stack::_size()
{
  echo "$__sstackp"
}


##
# Output the current stack frame
shspec::stack::_head()
{
  local -ri headi=$((__sstackp-1))
  echo "${__sstack[$headi]}"
}


##
# Output the type of the current stack frame
shspec::stack::_head-type()
{
  _shspec::stack::_headn 0
}


##
# Output the Nth datum of the current stack frame
_shspec::stack::_headn()
{
  local -ri i="$1"
  local parts

  shspec::stack::_read -a parts <<< "$(shspec::stack::_head)"
  echo "${parts[$i]}"
}


##
# Deconstruct stack frame from stdin in a `read`-like manner
shspec::stack::_read()
{
  IFS=\| read "$@"
}


##
# Deconstruct current stack frame in a `read`-like manner
#
# Return immediately with a non-zero status if there are no frames on the
# stack.
shspec::stack::_read-pop()
{
  local -r head="$(shspec::stack::_pop)" || return 1
   shspec::stack::_read "$@" <<< "$head"
}


##
# Assert that the immediately preceding frame is of the given type
#
# Conceptually, this allows determining if the parent node in a tree-like
# structure is of a certain type.
shspec::stack::_assert-within()
{
  local -r in="$1"
  local -r chk="$2"
  local -ri line="$3"
  local -r file="$4"
  local -r phrase="${5:-be contained within}"

  local -r head="$(shspec::stack::_head-type)"

  [ "$head" == "$in" ] \
    || shspec::bail \
      "\`$chk' must $phrase \`$head'; found \`$head' at $file:$line"
}


##
# Alias for shspec::stack::_assert-within with altered error message
#
# This is intended to convey a different perspective: that a given node is a
# sibling, not a child, in a tree-like structure.
shspec::stack::_assert-follow()
{
  shspec::stack::_assert-within "$@" follow
}

