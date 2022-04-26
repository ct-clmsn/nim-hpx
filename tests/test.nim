#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
import ../hpx/hpx

# register partitioned_seq types before
# instantiating them
#
register_partitioned_seq(int)

var v : partitioned_seq[int] = newPartitionedSeq[int](10)
var futv : future[void] = v.register_as("v")
futv.get()
echo "0 pseq size\t", v.size()

var v1 : partitioned_seq[int] = newPartitionedSeq[int](10, 0)
var futv1 : future[void] = v1.register_as("v1")
futv1.get()
echo "1 pseq size\t", v1.size()

var idents : seq[id_type] = findAllLocalities()
for id in idents:
    var gid = id.gid()
    echo gid.msb(), ' ', gid.lsb()

var fval : future[cuint] = getNumLocalities()
let numLocalities : int = int(fval.get)

echo "\ngetNumLocalities\t", numLocalities
echo "getLocalityId\t", get_locality_id()
echo "getOsThreadCount\t", get_os_thread_count()
echo "getWorkerThreadNum\t", get_worker_thread_num()

var values = newSeq[int](10)
for i in 0..<10:
    values[i] = i

# the 'cdecl' pragma exposes the
# nim function to C/C++; this is
# mandatory for using hpx parallel
# algorithms
#
proc fn(x : var int) {.cdecl.} =
    x+=1

echo(values)

foreach(par_exec, values, fn)
echo(values)

foreach_n(par_exec, values, values.len, fn)
echo(values)

foreach(seq_exec, values, fn)
echo(values)

foreach_n(seq_exec, values, values.len, fn)
echo(values)

var arrvalues : array[10, int]

for i in 0..<10:
    arrvalues[i] = i
echo(arrvalues)

foreach(seq_exec, arrvalues, fn)
echo(arrvalues)

foreach_n(seq_exec, arrvalues, arrvalues.len, fn)
echo(arrvalues)

foreach(par_exec, arrvalues, fn)
echo(arrvalues)

foreach_n(par_exec, arrvalues, arrvalues.len, fn)
echo(arrvalues)

# the 'plain_action' macro exposes
# the nim function to C/C++ and the
# hpx; this is mandatory for remote,
# asynchronous, function execution
#

# action does something takes no input and returns no output
proc fnhello() {.plain_action.} =
   echo "hello"

for i in 0..<numLocalities:
    var f : future[void] = async(fnhello, getIdFromLocalityId(i))
    f.get()

# function accepts no input, returns output
proc fnval() : int {.plain_action.} =
   result = 1

var g : future[int] = async(fnval, findHere())
echo g.get()

# function accepts input, returns output
proc fnargval(a : int, b : int) : int {.plain_action.} =
    result = 1

var h : future[int] = async(fnargval, findHere(), 1, 1)
echo h.get()

# function accepts input, returns no output
proc fnargnval(a : int, b : int) {.plain_action.} =
    echo a, '\t', b

var i : future[void] = async(fnargnval, findHere(), 1, 1)
i.get()

#var j : future[void] = async(fnhello, idents[1], 1, 1)
#j.get()
