#lang racket
(require redex)

(provide run-basic-tests)

(define (run-basic-tests cc-red test)
    (test cc-red (term (add1 1)) 2)
    (test cc-red (term (+ 1 4)) 5)
    (test cc-red (term ((λ x (sub1 x)) 4)) 3)
    (test cc-red (term (+ 1 ((λ x (add1 (add1 x))) 2))) 5)
    ; Test rule cc1
    (test cc-red (term (((λ x (λ y x)) 5) 3)) 5)
    ; Test rule cc2 and cc4
    (test cc-red (term ((λ x (add1 x)) (+ 2 3))) 6)
    ; Test operators (implemented in δ)
    (test cc-red (term ((((iszero 0) (λ x (+ x 4))) (λ x (+ x 5))) 1)) 5)
    (test cc-red (term ((((iszero 1) (λ x (+ x 4))) (λ x (+ x 5))) 1)) 6)
    (test cc-red (term (- 4 2)) 2)
    (test cc-red (term (* 4 2)) 8)
    (test cc-red (term (** 4 2)) 16)
    ; Test subst rules 
    (test cc-red (term ((λ x ((λ x 1) x)) 2)) 1)
    (test cc-red (term (((λ x (λ y (+ y x))) 2) 3)) 5)
    ; Test subst-var rules
    ;(test (term (
    (test-results))
