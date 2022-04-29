#  Copyright (c) 2022 Christopher Taylor
#
#  SPDX-License-Identifier: BSL-1.0
#  Distributed under the Boost Software License, Version 1.0. *(See accompanying
#  file LICENSE_1_0.txt or copy at http://www.boost.org/LICENSE_1_0.txt)
#
{.deadCodeElim: on.}
{.experimental: "dynamicBindSym".}
{.passC: gorge("pkg-config --cflags hwloc hpx_application").}
{.passL: gorge("pkg-config --libs hwloc hpx_application").}
{.passL: "-lhpx_iostreams -lhpx_component_storage -lhpx_partitioned_vector -lhpx_unordered".}

{.emit: """
#include <hpx/config.hpp>
#define HPX_COMPUTE_HOST_CODE
#include <hpx/hpx_main.hpp>
#include <hpx/logging/manipulator.hpp>
#include <hpx/logging/format/destinations.hpp>
#include <hpx/iostream.hpp>
#include <hpx/include/actions.hpp>
#include <hpx/include/components.hpp>
#include <hpx/include/lcos.hpp>
#include <hpx/include/parallel_executors.hpp>
#include <hpx/include/runtime.hpp>
#include <hpx/include/util.hpp>
#include <hpx/include/partitioned_vector.hpp>
#include <hpx/modules/distribution_policies.hpp>
#include <hpx/modules/actions_base.hpp>
#include <hpx/modules/executors.hpp>
#include <hpx/modules/algorithms.hpp>
#include <hpx/modules/async_distributed.hpp>
#include <hpx/modules/executors_distributed.hpp>
#include <hpx/modules/runtime_distributed.hpp>
#include <hpx/iostream.hpp>
#include <hpx/serialization/serialization_fwd.hpp>
#include <hpx/serialization/traits/is_bitwise_serializable.hpp>

#include <mutex>
#include <cstddef>
#include <string>
#include <cassert>

using namespace hpx;
using namespace hpx::lcos;
using namespace hpx::lcos::local;
using namespace hpx::naming;
using namespace hpx::execution;

using std_lock_guard = std::lock_guard<hpx::lcos::local::spinlock>;

void find_all_localities_ptr(size_t value, hpx::id_type * iidents) {
    std::vector<hpx::id_type> idents = hpx::find_all_localities();
    assert(idents.size() == value);
    for(std::size_t i = 0; i < value; ++i) {
        (*(iidents+i)) = idents[i];
    }
}

hpx::container_distribution_policy create_distribution(int c) {
    return std::move(hpx::container_layout(c, hpx::find_all_localities()));
}

""".}

import std/macros
import std/strutils

template registerPartitionedSeq*(V:typedesc) =
    {.emit: ["""HPX_REGISTER_PARTITIONED_VECTOR(""", V,""")"""].}

template registerUnorderedMap*(K : typedesc, V:typedesc) =
    {.emit: ["""HPX_REGISTER_UNORDERED_MAP(""", K, """,""", V,""")"""].}

type
   idType* {.importcpp: "hpx::id_type", header: "<hpx/naming_base/id_type.hpp>".} = object
   gidType* {.importcpp: "hpx::naming::gid_type", header: "<hpx/naming_base/gid_type.hpp>".} = object

   spinlock* {.importcpp: "hpx::locs::local::spinlock".} = object
   lockguard* {.importcpp: "std_lock_guard".} = object

   future*[V] {.importcpp: "hpx::future<'0>", header: "<hpx/future.hpp>".} = object

   partitionedSeq*[V] {.importcpp: "hpx::partitioned_vector<'0>", header: "<hpx/include/partitioned_vector.hpp>".} = object
   unorderedMap*[K, V] {.importcpp: "hpx::unordered_map<'0, '1>", header: "<hpx/include/unordered_map.hpp>".} = object

   #containerDistribution* {.importcpp: "hpx::container_distribution_policy", header: "<hpx/modules/distribution_policies.hpp>".} = object

   sequencedPolicy* {.importcpp: "hpx::execution::sequenced_policy", header: "<hpx/modules/executors.hpp>".} = object
   parallelPolicy* {.importcpp: "hpx::execution::parallel_policy", header: "<hpx/modules/executors.hpp>".} = object
   parallelUnsequencedPolicy* {.importcpp: "hpx::execution::parallel_unsequenced_policy", header: "<hpx/modules/executors.hpp>".} = object
   unsequencedPolicy* {.importcpp: "hpx::execution::unsequenced_policy", header: "<hpx/modules/executors.hpp>".} = object

var seqExec* {.importcpp: "hpx::execution::seq", header: "<hpx/modules/executors.hpp>".} : sequencedPolicy
var parExec* {.importcpp: "hpx::execution::par", header: "<hpx/modules/executors.hpp>".} : parallelPolicy
var parSeqExec* {.importcpp: "hpx::execution::par_seq", header: "<hpx/modules/executors.hpp>".} : parallelUnsequencedPolicy
var unseqExec* {.importcpp: "hpx::execution::unseq", header: "<hpx/modules/executors.hpp>".} : unsequencedPolicy

type SomeSeqPolicy* = sequencedPolicy | unsequencedPolicy
type SomeParPolicy* = parallelPolicy | parallelUnsequencedPolicy
type SomeExecutionPolicy* = SomeSeqPolicy | SomeParPolicy

##########
# id_type
#
proc gid*(self : idType) : gidType {.importcpp: "#.get_gid()", header : "<hpx/naming_base/gid_type.hpp>".}
proc getIdFromLocalityId*(value : cint) : idType {.importcpp: "hpx::naming::get_id_from_locality_id(@)", header : "<hpx/modules/naming_base.hpp>".}
proc getIdFromLocalityId*(value : int) : idType {.importcpp: "hpx::naming::get_id_from_locality_id(@)", header : "<hpx/modules/naming_base.hpp>".}

##########
# gid_type
#
proc msb*(self : gidType) : uint64 {.importcpp: "#.get_msb()", header : "<hpx/naming_base/gid_type.hpp>".}
proc lsb*(self : gidType) : uint64 {.importcpp: "#.get_lsb()", header : "<hpx/naming_base/gid_type.hpp>".}

##########
# future[V]
#
proc get*[V](self : future[V]) : V {.importcpp: "#.get()", header : "<hpx/future.hpp>".}

proc makeReadyFuture*[V](value : V) : future[V] {.importcpp: "hpx::make_ready_future(@)", header: "<hpx/modules/futures.hpp>".}

proc makeReadyFuture*() : future[void] {.importcpp: "hpx::make_ready_future()", header: "<hpx/modules/futures.hpp>".}

#[
# https://gist.github.com/oltolm/1738289b5ac866ec6a7e4ef20095178e
# https://gist.github.com/fowlmouth/48f3340b797c12cb3043
# https://web.mit.edu/nim-lang_v0.16.0/nim-0.16.0/doc/manual/pragmas.txt
# https://scripter.co/binding-nim-to-c-plus-plus-std-list/
# https://nim-lang.org/docs/manual.html#implementation-specific-pragmas-emit-pragma
#
# dynamically generate the import for async using a macro
# template async*(fn, args : varargs[expr]) : stmt =
]#

#proc newContainerDistributionImpl(seg : int) : containerDistribution {.importcpp: "create_distribution(#)", header : "<hpx/modules/distribution_policies.hpp>".}

#proc newContainerDistribution*(seg : int) : containerDistribution =
#    result = newContainerDistributionImpl(seg)

##########
# partitionedSeq
# 
proc newPartitionedSeq*[V]() : partitionedSeq[V] {.importcpp: "{}", header : "<hpx/include/partitioned_vector.hpp>".}

proc newPartitionedSeq*[V](count : int) : partitionedSeq[V] {.importcpp: "{@}", header : "<hpx/include/partitioned_vector.hpp>".}

proc newPartitionedSeq*[V](count : int, ini: V) : partitionedSeq[V] {.importcpp: "{@}", header : "<hpx/include/partitioned_vector.hpp>".}

#proc newPartitionedSeq*[V](count : int, ini : V, dist : containerDistribution) : partitionedSeq[V] {.importcpp: "{#, #, #}", header : "<hpx/include/partitioned_vector.hpp>".}

proc registerAsImpl[V](self : partitionedSeq[V], symbolic_name : cstring) : future[void] {.importcpp: "#.register_as(std::string{@})", header : "<hpx/include/partitioned_vector.hpp>".}

proc registerAs*[V](self : partitionedSeq[V], symbolic_name : string) : future[void] =
    result = registerAsImpl[V](self, cstring(symbolic_name))

proc connectToImpl[V](self : partitionedSeq[V], symbolic_name : cstring) : future[void] {.importcpp: "#.connect_to(std::string{@})", header : "<hpx/include/partitioned_vector.hpp>".}

proc connectTo*[V](self : partitionedSeq[V], symbolic_name : string) : future[void] =
    result = connectToImpl[V](self, cstring(symbolic_name))

proc getNumPartitions*[V](self : partitionedSeq[V]) : csize_t {.importcpp: "#.get_num_partitions()", header : "<hpx/include/partitioned_vector.hpp>".}

proc getValue*[V](self : partitionedSeq[V], pos : int) : future[V] {.importcpp: "#.get_value(@)", header: "<hpx/include/partitioned_vector.hpp>".}
proc getValue*[V](self : partitionedSeq[V], part : int, pos : int) : future[V] {.importcpp: "#.get_value(@)", header: "<hpx/include/partitioned_vector.hpp>".}

proc setValue*[V](self : partitionedSeq[V], pos : int, value : V) : future[void] {.importcpp: "#.set_value(@)", header: "<hpx/include/partitioned_vector.hpp>".}
proc setValue*[V](self : partitionedSeq[V], part : int, pos : int, value : V) : future[void] {.importcpp: "#.set_value(@)", header: "<hpx/include/partitioned_vector.hpp>".}

proc size*[V](self : partitionedSeq[V]) : csize_t {.importcpp: "#.size()", header: "<hpx/include/partitioned_vector.hpp>".}

proc `[]`*[V](self : partitionedSeq[V], pos : int) : V {.importcpp: "#[@]", header: "<hpx/include/partitioned_vector.hpp>".}

iterator items*[V](self : partitionedSeq[V]) : V =
    const hi : csize_t = self.size()
    for i in 0..<hi:
        yield self[i]

iterator pairs*[V](self : partitionedSeq[V]) : tuple[a : int, b : V] = 
    const hi : csize_t = self.size()
    for i in 0..<hi:
        yield (i, self[i])

##########
# unordered_map
# 
proc newUnorderedMap*[K,V]() : unorderedMap[K,V] {.importcpp: "{}", header : "<hpx/include/partitioned_vector.hpp>".}

proc newUnorderedMap*[K,V](count : int) : unorderedMap[K,V] {.importcpp: "{@}", header : "<hpx/include/partitioned_vector.hpp>".}

proc registerAsImpl[K, V](self : unorderedMap[K, V], symbolic_name : cstring) : future[void] {.importcpp: "#.register_as(std::string{@})", header : "<hpx/include/unordered_map.hpp>".}

proc registerAs*[K,V](self : unordered_map[K,V], symbolic_name : string) : future[void] =
    result = registerAsImpl[K,V](self, cstring(symbolic_name))

proc connectToImpl[K, V](self : unordered_map[K, V], symbolic_name : cstring) : future[void] {.importcpp: "#.connect_to(std::string{@})", header : "<hpx/include/unordered_map.hpp>".}

proc connectTo*[K,V](self : unordered_map[K,V], symbolic_name : string) : future[void] =
    result = connectToImpl[K,V](self, cstring(symbolic_name))

proc getNumPartitions*[K,V](self : unorderedMap[K,V]) : csize_t {.importcpp: "#.get_num_partitions()", header : "<hpx/include/unordered_map.hpp>".}

proc getValue*[K,V](self : unorderedMap[K,V], pos : K) : future[V] {.importcpp: "#.get_value(@)", header: "<hpx/include/unordered_map.hpp>".}
proc getValue*[K,V](self : unorderedMap[K,V], part : int, pos : K) : future[V] {.importcpp: "#.get_value(@)", header: "<hpx/include/unordered_map.hpp>".}

proc setValue*[K,V](self : unorderedMap[K,V], pos : K, value : V) : future[void] {.importcpp: "#.set_value(@)", header: "<hpx/include/unordered_map.hpp>".}
proc setValue*[K,V](self : unorderedMap[K,V], part : int, pos : K, value : V) : future[void] {.importcpp: "#.set_value(@)", header: "<hpx/include/unordered_map.hpp>".}

proc `[]`*[K,V](self : unorderedMap[K,V], pos : K) : V {.importcpp: "#[@]", header: "<hpx/include/unordered_map.hpp.hpp>".}

proc erase*[K,V](self : unorderedMap[K,V], pos : K) : future[csize_t] {.importcpp: "#.erase(@)", header: "<hpx/include/unordered_map.hpp>".}

proc size*[K,V](self : unorderedMap[K,V]) : csize_t {.importcpp: "#size()", header: "<hpx/include/unordered_map.hpp>".}

proc sizeAsync*[K,V](self : unorderedMap[K,V]) : future[csize_t] {.importcpp: "#size_async()", header: "<hpx/include/unordered_map.hpp>".}

##########
# get runtime information
#
proc getWorkerThreadNum*() : csize_t {.importcpp: "hpx::get_worker_thread_num", header: "<hpx/runtime_local/get_worker_thread_num.hpp>".}
proc getOsThreadCount*()   : csize_t {.importcpp: "hpx::get_os_thread_count", header: "<hpx/runtime_local/get_worker_thread_num.hpp>".}
proc getLocalityId*()       : cuint {.importcpp: "hpx::get_locality_id", header: "<hpx/runtime_local/get_locality_id.hpp>".}
proc getNumLocalities*()    : future[cuint] {.importcpp: "hpx::get_num_localities", header: "<hpx/runtime_local/runtime_local.hpp>".}

proc findAllLocalitiesImpl(sz : csize_t, idents : ptr idType) {.importcpp: "find_all_localities_ptr(@)", header: "<hpx/runtime_local/get_num_all_localities.hpp>".}

proc findHere*() : idType {.importcpp: "hpx::find_here()", header: "hpx/modules/runtime_distributed.hpp".}

template `+`(p: ptr id_type, off: int): ptr idType =
  cast[ptr type(p[])]( cast[ByteAddress](p) +% (off * sizeof(p[])) )

template `[]`(p: ptr id_type, off: int): idType =
  (p + off)[]

proc findAllLocalities*() : seq[id_type] =
   var numl = getNumLocalities()
   var sz : csize_t = csize_t(numl.get())
   result = newSeq[id_type](sz)
   findAllLocalitiesImpl(sz, result[0].addr)

##########
# parallel algorithms
#
# proc par_foreachn_impl[V]( vals : ptr V, n : int, fn : proc(v: var V) {.cdecl.} ) {.importcpp: "hpx::for_each_n(par, #, #, #)", header : "hpx/modules/algorithms.hpp".}
#
# proc par_foreach*[V]( vals : var openArray[V], fn : proc(v: var V) {.cdecl.} ) = 
#     par_foreachn_impl[V](cast[ptr V](vals[0].addr), vals.len, fn)
#
# proc par_foreach_n*[V]( vals : var openArray[V], n : int, fn : proc(v: var V) {.cdecl.} ) = 
#     par_foreachn_impl[V](cast[ptr V](vals[0].addr), n, fn)
#
# proc seq_foreachn_impl[V]( vals : ptr V, n : int, fn : proc(v: var V) {.cdecl.} ) {.importcpp: "hpx::for_each_n(seq, #, #, #)", header : "hpx/modules/algorithms.hpp".}
#
# proc seq_foreach*[V]( vals : var openArray[V], fn : proc(v: var V) {.cdecl.} ) = 
#     seq_foreachn_impl[V](cast[ptr V](vals[0].addr), vals.len, fn)
#
# proc seq_foreach_n*[V]( vals : var openArray[V], n : int, fn : proc(v: var V) {.cdecl.} ) = 
#     seq_foreachn_impl[V](cast[ptr V](vals[0].addr), n, fn)
#

proc foreachnImpl[V]( policy : SomeExecutionPolicy, vals : ptr V, n : int, fn : proc(v: var V) {.cdecl.} ) {.importcpp: "hpx::for_each_n(@)", header : "hpx/modules/algorithms.hpp".}

proc foreach*[V]( policy : SomeExecutionPolicy, vals : var openArray[V], fn : proc(v: var V) {.cdecl.} ) =
    foreachnImpl[V](policy, cast[ptr V](vals[0].addr), vals.len, fn)

proc foreachN*[V]( policy : SomeExecutionPolicy, vals : var openArray[V], n : int, fn : proc(v: var V) {.cdecl.} ) =
    foreachnImpl[V](policy, cast[ptr V](vals[0].addr), n, fn)

proc transformImpl[V, W]( policy : SomeSeqPolicy, valbeg : ptr V, valend : ptr V, ovalbeg : ptr W, fn : proc(v: V) : W {.cdecl.} ) {.importcpp: "hpx::transform(#, #, #, #, #)", header : "hpx/modules/algorithms.hpp".}

proc transform*[V, W]( policy : SomeSeqPolicy, vals : var openArray[V], ovals : var openArray[W], fn : proc(v: V) : W {.cdecl.} ) =
    assert(vals.len == ovals.len)
    transformImpl[V,W](policy, vals[0].addr, vals[vals.len-1].addr, ovals[0].addr, fn)

proc transformReduceImpl*[V, W]( policy : SomeExecutionPolicy, valbeg : ptr V, valend : ptr V, initVal : W, binfn : proc(v : W, w : W) : W {.cdecl.}, fn : proc(v : V) : W {.cdecl.} ) : W {.importcpp: "hpx::transform_reduce(#, #, #, #, #, #)", header : "hpx/modules/algorithms.hpp".}

proc transformReduce*[V, W]( policy : SomeExecutionPolicy, vals : var openArray[V], initVal : W, binfn : proc(v : W, w : W) : W {.cdecl.}, fn : proc(v: V) : W {.cdecl.} ) : W =
    result = transformReduceImpl[V,W](policy, cast[ptr V](vals[0].addr), cast[ptr V](vals[vals.len-1].addr), initVal, binfn, fn)

#[
proc transformReduceImpl*(policy : NimNode, vals : NimNode, initVal : NimNode, binfn: NimNode, fn : NimNode) : NimNode = 
        var valueStr : string
   
        case initVal.kind:
        of nnkNone, nnkEmpty, nnkNilLit:
            error("initVal is None, Empty or Nil")
        of nnkCharLit..nnkUInt64Lit:
            valueStr = $(initVal.intVal)
        of nnkFloatLit..nnkFloat64Lit:
            valueStr = $(initVal.floatVal)
        of nnkStrLit..nnkTripleStrLit, nnkCommentStmt, nnkIdent, nnkSym:
            valueStr = initVal.strVal
        else:
            error("initVal is not an int, float, or string")

        let policys = policy.strVal 
        let valss = vals.strVal
        let binfns = binfn.strVal
        let fns = fn.strVal

        if(policys == "seqExec" or policys == "unseqExec"):
            echo("seqTransformReduceImpl(" & policys & ", " & valss & "[0].addr, " & valss & "[" & valss & ".len-1].addr, " & valueStr & ", " & binfns & ", " & fns & ")")
            result = parseExpr("seqTransformReduceImpl(" & policys & ", " & valss & "[0].addr, " & valss & "[" & valss & ".len-1].addr, " & valueStr & ", " & binfns & ", " & fns & ")")
        elif(policys == "parExec" or policys == "parUnseqExec"):
            echo("parTransformReduceImpl(" & policys & ", " & valss & "[0].addr, " &  valss & "[" & valss & ".len-1].addr, " & valueStr & ", " & binfns & ", " & fns & ")")
            result = parseExpr("parTransformReduceImpl(" & policys & ", " & valss & "[0].addr, " &  valss & "[" & valss & ".len-1].addr, " & valueStr & ", " & binfns & ", " & fns & ")")
        else:
            error("unsupported SomeExecutionPolicy")

macro transformReduce*(policy : typed, vals : typed, initVal : typed, binfn: typed, fn : typed) : untyped = 
    transformReduceImpl(policy, vals, initVal, binfn, fn)
]#

#template transformReduce*(policy : SomeSeqPolicy, vals, initVal, binfn, fn : typed) =
#   seqTransformReduceImpl(policy, vals[0].addr, vals[vals.len-1].addr, initVal, binfn, fn)
        

##########
# asynchronous function execution
#
import jsony
include cppstl

proc nim_hpx_marshal*[T](value : T) : CppString =
    var ostr : string = value.toJson
    result = ostr.toCppString

proc nim_hpx_unmarshal*[T](data : CppString) : T =
    var valuestr : string = $data
    result = valuestr.fromJson(typeof(T))

proc generic_support(n : NimNode) : ( bool, string, string ) =
    assert(n.kind == nnkProcDef)
    var generic_str : string = ""
    var template_str : string = ""
    if n[2].kind == nnkGenericParams:
        for j in 0..<n[2].len:
            var c = n[2][j]
            for i in 0..<c.len:
                if c[i].kind == nnkIdent:
                    if i == 0:
                        generic_str = generic_str & c[i].strVal 
                        template_str = template_str & c[i].strVal
                    else:
                        generic_str = generic_str & " : " & c[i].strVal 

            if j != n[2].len-1:
                template_str = template_str & ", "

        result = (true, generic_str, template_str)
    else:
        result = (false, generic_str, template_str)
  
proc arglist_totuple(n : NimNode) : ( int, string, string, string ) =
    assert(n.kind == nnkProcDef)

    # 3, nnkFormalParams
    #
    var varidents : string = ""
    var vartypes : string = ""
    var varidentswtypes : string = ""

    var sargs : seq[string] = newSeq[string]()
    for i in 1..<n[3].len:
       let arg = n[3][i]
       if arg.kind == nnkIdentDefs:
           if arg[1].kind != nnkEmpty:
               sargs.add( arg[0].strVal & " : " & arg[1].strVal )
           else:
               sargs.add( arg[0].strVal )

    var skipcount : int = 0
    for i in 0..<sargs.len:
        let has_type_seq : bool = sargs[i].find(':') != -1
        let add_comma : bool = i != sargs.len-1

        if has_type_seq:
            var splt : seq[string] = sargs[i].split(':')
            if add_comma:
                varidents = varidents & splt[0] & ", "
            else:
                varidents = varidents & splt[0]

            if skipcount > 0:
                for i in 0..<skipcount:
                    if add_comma:
                        vartypes = vartypes & splt[1] & ", "
                        varidentswtypes = varidentswtypes & sargs[i] & ", "
                    else:
                        vartypes = vartypes & splt[1]
                        varidentswtypes = varidentswtypes & sargs[i]

                skipcount = 0

            if add_comma:
                vartypes = vartypes & splt[1] & ", "
                varidentswtypes = varidentswtypes & sargs[i] & ", "
            else:
                vartypes = vartypes & splt[1]
                varidentswtypes = varidentswtypes & sargs[i]

        else:
            if add_comma:
                varidents = varidents & sargs[i] & ", "
                skipcount = skipcount + 1
            else:
                varidents = varidents & sargs[i]
                skipcount = skipcount + 1
        
    result = ( sargs.len, varidents, vartypes, varidentswtypes )

proc ret_args(n : NimNode) : ( bool, string ) =
    assert(n.kind == nnkProcDef)

    # 3, nnkFormalParams
    #
    if n[3][0].kind == nnkEmpty:
        result = (false, "")
    else: 
        result = (true, n[3][0].strVal)

proc plain_action_code(n : NimNode) : NimNode =
    result = newStmtList()

    let fnname : string = $name(n)

    var newn = n.copy
    newn.addPragma( newIdentNode("cdecl") )
    newn.addPragma( newNimNode(nnkExprColonExpr).add( newIdentNode("exportc"), newLit($fnname)) )

    result.add(newn)

    let (carg, arg_ident_str, argtype_str, argidentwtype_str) = arglist_totuple(n)
    let (hasretval, ret_args_str) = ret_args(n)
    let (hasgeneric, generic_str, template_param_str) = generic_support(n)

    var inner_exec_str : string = ""

    if hasretval:
        if carg < 1:
            inner_exec_str = "proc " & $fnname & "_wrapper(strvalue : CppString) : CppString {.cdecl, exportc : \""& $fnname & "_wrapper\".} = \n" &
                "    var res : "  & ret_args_str & " = " & $fnname & "()\n" &
                "    result = nim_hpx_marshal[" & ret_args_str & "](res)\n"
        else:
            inner_exec_str = "proc " & $fnname & "_wrapper(strvalue : CppString) : CppString {.cdecl, exportc : \""& $fnname & "_wrapper\".} = \n" &
                "    var (" & arg_ident_str & ") = nim_hpx_unmarshal[ (" & argtype_str & ") ](strvalue)\n" &
                "    var res : " & ret_args_str & " = " & $fnname & "(" & arg_ident_str & ")\n" &
                "    result = nim_hpx_marshal[" & ret_args_str & "](res)"
    else:
        if carg < 1:
            inner_exec_str = "proc " & $fnname & "_wrapper(strvalue : CppString) : CppString {.cdecl, exportc : \""& $fnname & "_wrapper\".} = \n" &
                "    " & $fnname & "()\n" &
                "    result = \"\".toCppString"
        else:
             inner_exec_str = "proc " & $fnname & "_wrapper(strvalue : CppString) : CppString {.cdecl, exportc : \""& $fnname & "_wrapper\".} = \n" &
                "    var (" & arg_ident_str & ") = nim_hpx_unmarshal[ (" & argtype_str & ") ](strvalue)\n" &
                "    " & $fnname & "(" & arg_ident_str & ")\n" &
                "    result = \"\".toCppString"

    #echo inner_exec_str
    result.add( parseStmt(inner_exec_str) )

    # preserve as artifact for possible future use...
    #
    #let cxx_src : string  = "{.emit : \"std::string " & $fnname & "_wrapper_cxx( std::string const& str ) { return std::move(" & $fnname & "_wrapper( str ) ); }\".}"
    #result.add( parseStmt(cxx_src) )
    #let val : string = "HPX_PLAIN_ACTION(" & $fnname & "_wrapper_cxx, " & $fnname & "_wrapper_action)"

    let val : string = "HPX_PLAIN_ACTION(" & $fnname & "_wrapper, " & $fnname & "_wrapper_action)"

    #echo "{.emit : [\"" & val & "\"].}"
    result.add( parseStmt("{.emit : [\"" & val & "\"].}") )

    if hasretval:
        if carg < 1:
            var inner_async_sig : string = "proc async_" & $fnname & "_wrapper_action(ident : idType) : future[CppString] {.importcpp: \"hpx::async<" & $fnname & "_wrapper_action>(#,std::string{})\".}"

            var async_sig : string = ""
            if hasgeneric:
                async_sig = async_sig & 
                    "proc async(self : proc[" & generic_str & "]() : " & ret_args_str & " {.cdecl, gcsafe, locks: \"unknown\".}, ident : idType ) : future[ " & ret_args_str & " ] = \n"
            else:
                async_sig = async_sig & 
                    "proc async(self : proc() : " & ret_args_str & " {.cdecl, gcsafe, locks: \"unknown\".}, ident : idType ) : future[ " & ret_args_str & " ] = \n"

            async_sig = async_sig &
                "    proc inner(ident : idType) : " & ret_args_str & " {.cdecl.} =\n" &
                "        var res : future[CppString] = async_" & $fnname & "_wrapper_action(ident)\n" &
                "        var strvalue : CppString = res.get()\n" &
                "        result = nim_hpx_unmarshal[" & ret_args_str & "](strvalue)\n\n" &
                "    proc inner_async(fn : proc(ident:idType) : " & ret_args_str & " {.cdecl, gcsafe, locks: \"unknown\".}, ident : idType) : future[" & ret_args_str & "] {.importcpp: \"hpx::async(@)\".}\n\n" &
                "    result = inner_async(inner, ident)" 

            #echo inner_async_sig
            result.add( parseStmt( inner_async_sig ) )
            #echo async_sig 
            result.add( parseStmt( async_sig ) )

        else:
            var inner_async_sig : string = "proc async_" & $fnname & "_wrapper_action(ident : idType, strvalue : CppString) : future[CppString] {.importcpp: \"hpx::async<" & $fnname & "_wrapper_action>(@)\".}"

            var async_sig : string = ""
            if hasgeneric:
                async_sig = async_sig & 
                    "proc async(self : proc[" & generic_str & "](" & argtype_str & ") : " & ret_args_str & " {.cdecl, gcsafe, locks: \"unknown\".}, ident : idType, " & argidentwtype_str & ") : future[ " & ret_args_str & " ] = \n"
            else: 
                async_sig = async_sig & 
                    "proc async(self : proc(" & argidentwtype_str & ") : " & ret_args_str & " {.cdecl, gcsafe, locks: \"unknown\".}, ident : idType, " & argidentwtype_str & ") : future[ " & ret_args_str & " ] = \n"

            async_sig = async_sig &
                "    proc inner(ident : idType, arg_ident_str : CppString) : " & ret_args_str & " {.cdecl.} =\n" &
                "        var res : future[CppString] = async_" & $fnname & "_wrapper_action(ident, arg_ident_str)\n" &
                "        var strvalue : CppString = res.get()\n" &
                "        result = nim_hpx_unmarshal[" & ret_args_str & "](strvalue)\n\n" &
                "    proc inner_async( fn : proc(ident : idType, arg_ident_str : CppString) : " & ret_args_str & " {.cdecl.}, ident : idType, arg_ident_str : CppString ) : future[ " & ret_args_str & "] {.importcpp: \"hpx::async(@)\".}\n\n" &
                "    var ivalue : CppString = nim_hpx_marshal[ (" & argtype_str & ") ]( (" & arg_ident_str & ") )\n" & 
                "    result = inner_async(inner, ident, ivalue)"

            #echo inner_async_sig
            result.add( parseStmt( inner_async_sig ) )
            #echo async_sig 
            result.add( parseStmt( async_sig ) )

    else:
        if carg < 1:
            var inner_async_sig : string = "proc async_" & $fnname & "_wrapper_action(ident : idType) : future[CppString] {.importcpp: \"hpx::async<" & $fnname & "_wrapper_action>(#, std::string{})\".}"

            var async_sig : string = ""
            if hasgeneric:
                async_sig = async_sig &
                    "proc async(self : proc[" & generic_str & "]() {.cdecl, gcsafe, locks: \"unknown\".}, ident : idType) : future[void] = \n"
            else:
                async_sig = async_sig &
                    "proc async(self : proc() {.cdecl, gcsafe, locks: \"unknown\".}, ident : idType) : future[void] = \n"

            async_sig = async_sig &
                "    var val : future[CppString] = async_" & $fnname & "_wrapper_action(ident)\n" &
                "    discard val.get()\n" &
                "    result = makeReadyFuture()"

            #echo inner_async_sig
            result.add( parseStmt( inner_async_sig ) )
            #echo async_sig 
            result.add( parseStmt( async_sig ) )

        else:
            var inner_async_sig : string = "proc async_" & $fnname & "_wrapper_action(ident : idType, strvalue : CppString) : future[CppString] {.importcpp: \"hpx::async<" & $fnname & "_wrapper_action>(#, #)\".}"

            var async_sig : string = ""
            if hasgeneric:
                async_sig = async_sig &
                    "proc async(self : proc[" & generic_str & "](" & argidentwtype_str & ") {.cdecl, gcsafe, locks: \"unknown\".}, ident : idType, " & argidentwtype_str & ") : future[ void ] = \n"
            else: 
                async_sig = async_sig &
                    "proc async(self : proc(" & argidentwtype_str & ") {.cdecl, gcsafe, locks: \"unknown\".}, ident : idType, " & argidentwtype_str & ") : future[ void ] = \n"

            async_sig = async_sig & "    var strargs : CppString = nim_hpx_marshal[ (" & argtype_str & ") ]( (" & arg_ident_str & ") )\n" &
                "    var val : future[CppString] = async_" & $fnname & "_wrapper_action(ident, strargs)\n" &
                "    discard val.get()\n" &
                "    result = makeReadyFuture()"

            #echo inner_async_sig
            result.add( parseStmt( inner_async_sig ) )
            #echo async_sig 
            result.add( parseStmt( async_sig ) )

macro plainAction*(n : typed) : untyped = n.plain_action_code
