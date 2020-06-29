; NOTE: Assertions have been autogenerated by utils/update_analyze_test_checks.py
; RUN: opt -analyze -scalar-evolution < %s | FileCheck %s

; The semanics of this example are a bit subtle.  The loop is required
; execute some number of times up to 1999.  The compiler is free to reduce
; the number of said iterations to zero (or any value in between) if desired,
; but if it does so, the return value and the last value stored to G must
; agree.  For SCEV, this translates as widenable conditions preventing exact
; exit counts from being computed, but not restricting max exit counts.
; It's tempting to say that SCEV should return a precise exit count here, but
; would result in miscompiles if transformations such as RLEV ran before
; widening of the WC.
define i32 @wc_max() {
; CHECK-LABEL: 'wc_max'
; CHECK-NEXT:  Classifying expressions for: @wc_max
; CHECK-NEXT:    %iv = phi i32 [ 0, %entry ], [ %iv.next, %loop ]
; CHECK-NEXT:    --> {0,+,1}<%loop> U: [0,2000) S: [0,2000) Exits: <<Unknown>> LoopDispositions: { %loop: Computable }
; CHECK-NEXT:    %iv.next = add i32 %iv, 1
; CHECK-NEXT:    --> {1,+,1}<%loop> U: [1,2001) S: [1,2001) Exits: <<Unknown>> LoopDispositions: { %loop: Computable }
; CHECK-NEXT:    %widenable_cond3 = call i1 @llvm.experimental.widenable.condition()
; CHECK-NEXT:    --> %widenable_cond3 U: full-set S: full-set Exits: <<Unknown>> LoopDispositions: { %loop: Variant }
; CHECK-NEXT:    %exiplicit_guard_cond4 = and i1 %cond_1, %widenable_cond3
; CHECK-NEXT:    --> %exiplicit_guard_cond4 U: full-set S: full-set Exits: <<Unknown>> LoopDispositions: { %loop: Variant }
; CHECK-NEXT:  Determining loop execution counts for: @wc_max
; CHECK-NEXT:  Loop %loop: Unpredictable backedge-taken count.
; CHECK-NEXT:  Loop %loop: max backedge-taken count is 1999
; CHECK-NEXT:  Loop %loop: Unpredictable predicated backedge-taken count.
;
entry:
  br label %loop
loop:
  %iv = phi i32 [0, %entry], [%iv.next, %loop]
  %iv.next = add i32 %iv, 1
  store i32 %iv, i32 *@G
  %cond_1 = icmp slt i32 %iv.next, 2000
  %widenable_cond3 = call i1 @llvm.experimental.widenable.condition()
  %exiplicit_guard_cond4 = and i1 %cond_1, %widenable_cond3
  br i1 %exiplicit_guard_cond4, label %loop, label %exit

exit:
  ret i32 %iv
}

@G = external global i32
declare i1 @llvm.experimental.widenable.condition()
