#!/bin/bash
# Utility functions/procedures
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
#
# These algorithms will often use looping constructs in favor of recursion
# for performance reasons.
##

[ -z $__INC_UTIL ] || return
__INC_UTIL=1


##
# Array functions/procedures ("a" prefix)
#

##
# Asserts that all given values are zero
#
# This is perhaps mose useful for PIPESTATUS evaluation (the pipefail option
# may not be available). If any value is non-zero, it will immediately
# terminate with a non-zero status.
aok()
{
  local -ar arr=("$@")
  local -i i="${#arr[@]}"

  while ((i--)); do
    test "${arr[i]}" -eq 0 || return
  done &>/dev/null
}

