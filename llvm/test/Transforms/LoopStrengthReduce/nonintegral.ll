; RUN: opt -S -loop-reduce < %s | FileCheck %s

; Address Space 10 is non-integral. The optimizer is not allowed to use
; ptrtoint/inttoptr instructions. Make sure that this doesn't happen
target datalayout = "e-m:e-i64:64-f80:128-n8:16:32:64-S128-ni:10:11:12:13"
target triple = "x86_64-unknown-linux-gnu"

define void @japi1__unsafe_getindex_65028(i64 addrspace(10)* %arg) {
; CHECK-NOT: inttoptr
; CHECK-NOT: ptrtoint
; How exactly SCEV chooses to materialize isn't all that important, as
; long as it doesn't try to round-trip through integers. As of this writing,
; it emits a byte-wise gep, which is fine.
; CHECK: getelementptr i64, i64 addrspace(10)* {{.*}}, i64 {{.*}}
top:
  br label %L86

L86:                                              ; preds = %L86, %top
  %i.0 = phi i64 [ 0, %top ], [ %tmp, %L86 ]
  %tmp = add i64 %i.0, 1
  br i1 undef, label %L86, label %if29

if29:                                             ; preds = %L86
  %tmp1 = shl i64 %tmp, 1
  %tmp2 = add i64 %tmp1, -2
  br label %if31

if31:                                             ; preds = %if38, %if29
  %"#temp#1.sroa.0.022" = phi i64 [ 0, %if29 ], [ %tmp3, %if38 ]
  br label %L119

L119:                                             ; preds = %L119, %if31
  %i5.0 = phi i64 [ %"#temp#1.sroa.0.022", %if31 ], [ %tmp3, %L119 ]
  %tmp3 = add i64 %i5.0, 1
  br i1 undef, label %L119, label %if38

if38:                                             ; preds = %L119
  %tmp4 = add i64 %tmp2, %i5.0
  %tmp5 = getelementptr i64, i64 addrspace(10)* %arg, i64 %tmp4
  %tmp6 = load i64, i64 addrspace(10)* %tmp5
  br i1 undef, label %done, label %if31

done:                                             ; preds = %if38
  ret void
}

; This is a bugpoint-reduced regression test - It doesn't make too much sense by itself,
; but creates the correct SCEV expressions to reproduce the issue. See
; https://github.com/JuliaLang/julia/issues/31156 for the original bug report.
define void @"japi1_permutedims!_4259"(i64 %a, i64 %b, i64 %c, i64 %d, i64 %e, i64 %f, i1 %g, i8 addrspace(13)* %base) #0 {
; CHECK-NOT: inttoptr
; CHECK-NOT: ptrtoint
; CHECK: getelementptr i8, i8 addrspace(13)* {{.*}}, i64 {{.*}}
top:
  br label %L42.L46_crit_edge.us

L42.L46_crit_edge.us:                             ; preds = %L82.us.us.loopexit, %top
  %value_phi11.us = phi i64 [ %a, %top ], [ %2, %L82.us.us.loopexit ]
  %0 = sub i64 %value_phi11.us, %b
  %1 = add i64 %0, %c
  %spec.select = select i1 %g, i64 %d, i64 0
  br label %L62.us.us

L82.us.us.loopexit:                               ; preds = %L62.us.us
  %2 = add i64 %e, %value_phi11.us
  br label %L42.L46_crit_edge.us

L62.us.us:                                        ; preds = %L62.us.us, %L42.L46_crit_edge.us
  %value_phi21.us.us = phi i64 [ %6, %L62.us.us ], [ %spec.select, %L42.L46_crit_edge.us ]
  %3 = add i64 %1, %value_phi21.us.us
  %4 = getelementptr inbounds i8, i8 addrspace(13)* %base, i64 %3
  %5 = load i8, i8 addrspace(13)* %4, align 1
  %6 = add i64 %f, %value_phi21.us.us
  br i1 %g, label %L82.us.us.loopexit, label %L62.us.us, !llvm.loop !1
}

!1 = distinct !{!1, !2}
!2 = !{!"llvm.loop.isvectorized", i32 1}
