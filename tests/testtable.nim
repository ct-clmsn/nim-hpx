#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
include ../hpx/hpx

# register partitionedSeq types before
# instantiating them
#

registerPartitionedTable(CppString, cint)

# globally scoped partitionedTables cause segfaults at this time
#
#var t : partitionedTable[CppString, cint] = newPartitionedTable[CppString,cint]()
#var futt : future[void] = t.registerAs("t")
#futt.get()
#echo "0 ptable size\t", t.size()

proc main() =
    var t : partitionedTable[CppString, cint] = newPartitionedTable[CppString,cint]()
    var zz : string = "t"
    var zzz : cstring = cstring(zz) 
    var futv : future[void] = t.registerAs("t")
    futv.get()
    var futc = t.connectTo("t")
    futc.get()
    echo "0 ptable size\t", t.size()

main()
