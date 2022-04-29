#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
import ../hpx/hpx

# register partitionedSeq types before
# instantiating them
#
registerPartitionedSeq(int)

var v : partitionedSeq[int] = newPartitionedSeq[int](10)
var futv : future[void] = v.registerAs("v")
futv.get()
echo "0 pseq size\t", v.size()

var v1 : partitionedSeq[int] = newPartitionedSeq[int](10, 0)
var futv1 : future[void] = v1.registerAs("v1")
futv1.get()
echo "1 pseq size\t", v1.size()

var idents : seq[id_type] = findAllLocalities()
for id in idents:
    var gid = id.gid()
    echo gid.msb(), ' ', gid.lsb()

var fval : future[cuint] = getNumLocalities()
let numLocalities : int = int(fval.get)

echo "\ngetNumLocalities\t", numLocalities
echo "getLocalityId\t", getLocalityId()
echo "getOsThreadCount\t", getOsThreadCount()
echo "getWorkerThreadNum\t", getWorkerThreadNum()

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

foreach(parExec, values, fn)
echo(values)

foreach_n(parExec, values, values.len, fn)
echo(values)

foreach(seqExec, values, fn)
echo(values)

foreach_n(seqExec, values, values.len, fn)
echo(values)

var arrvalues : array[10, int]

for i in 0..<10:
    arrvalues[i] = i
echo(arrvalues)

foreach(seqExec, arrvalues, fn)
echo(arrvalues)

foreach_n(seqExec, arrvalues, arrvalues.len, fn)
echo(arrvalues)

foreach(parExec, arrvalues, fn)
echo(arrvalues)

foreach_n(parExec, arrvalues, arrvalues.len, fn)
echo(arrvalues)

var farrvalues : array[10, float]

proc ap(a:float, b:float) : float {.cdecl.} =
    result = a + b

proc xsfm(a:int) : float {.cdecl.} =
    result = float(a)

echo farrvalues

transform(seqExec, arrvalues, farrvalues, xsfm)

echo farrvalues

var trf : float = transformReduce(seqExec, arrvalues, 0.0, ap, xsfm)
echo trf

var fftrm : float = transformReduce(parExec, arrvalues, 0.0, ap, xsfm)
echo fftrm

var farrvals : array[10, float]

for i in 0..<10:
    farrvals[i] = float(i)

var redo : float = reduce(parExec, farrvalues, 0.0, ap)
echo farrvals, '\t', redo

# the 'plainAction' macro exposes
# the nim function to C/C++ and the
# hpx; this is mandatory for remote,
# asynchronous, function execution
#

# action does something takes no input and returns no output
proc fnhello() {.plainAction.} =
   echo "hello"

# synchronous exection of plain action
#
fnhello()

# asynchronous execution of an action
# on different localities
#
for i in 0..<numLocalities:
    var f : future[void] = async(fnhello, getIdFromLocalityId(i))
    f.get()

# function accepts no input, returns output
proc fnval() : int {.plainAction.} =
   result = 1

# asynchronous execution of action that returns
# a value
#
var g : future[int] = async(fnval, findHere())
echo g.get()

# function accepts input, returns output
proc fnargval(a : int, b : int) : int {.plainAction.} =
    result = 1

var h : future[int] = async(fnargval, findHere(), 1, 1)
echo h.get()

# function accepts input, returns no output
proc fnargnval(a : int, b : int) {.plainAction.} =
    echo a, '\t', b

var i : future[void] = async(fnargnval, findHere(), 1, 1)
i.get()

#var j : future[void] = async(fnhello, idents[1], 1, 1)
#j.get()
