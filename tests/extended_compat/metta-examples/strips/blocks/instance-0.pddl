(define (problem BLOCKS-3-0)
(:domain BLOCKS)
(:objects A B C )
(:init (clear C) (clear A) (clear B) (ontable C) (ontable A)
 (ontable B) (handempty))
(:goal (and (on C B) (on B A)))
)