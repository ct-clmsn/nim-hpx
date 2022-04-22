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

var v2dist : container_distribution = newContainerDistribution(10)
var v2 : partitioned_seq[int] = newPartitionedSeq[int](10, 0, v2dist)
var futv2 : future[void] = v2.register_as("v3")
futv2.get()
echo "2 pseq size\t", v2.size()

var idents : seq[id_type] = find_all_localities()
for id in idents:
    var gid = id.gid()
    echo gid.msb(), ' ', gid.lsb()

var fval : future[cuint] = get_num_localities()

echo "get_num_localities\t", fval.get
echo "get_locality_id\t", get_locality_id()
echo "get_os_thread_count\t", get_os_thread_count()
echo "get_worker_thread_num\t", get_worker_thread_num()

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
proc fnhello() {.plain_action.} =
   echo "hello"

proc fnval() : int {.cdecl.} =
   result = 1

var f : future[void] = async(fnhello)
f.get()

var g : future[int] = async(fnval)
echo g.get()
