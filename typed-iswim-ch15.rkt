#lang racket
(require "compiled/chapter-16_rkt.zo")

(define-extended-language t-iswim iswim
  (M X (λ X T M) (M M) b (o2 M M) (o1 M))
  (V b X (λ X T M))
  ((T S) (-> T T) num)
  (Γ ((X T) ...)))

(define t-iswim-red
  (reduction-relation
   t-iswim
   (--> (in-hole E ((λ X T M) V))
        (in-hole E (t-subst M X V))
        βv)
   (--> (in-hole E (o b ...))
        (in-hole E (δ (o b ...)))
        δ)))

(define-metafunction t-iswim
  t-subst : any X any -> any
  ;; 1. X_1 bound, so don't continue in λ body
  [(t-subst (λ X_1 T any_1) X_1 any_2)
   (λ X_1 T any_1)] 
  ;; 2. do capture-avoiding substitution
  ;;    by generating a fresh name
  [(t-subst (λ X_1 T any_1) X_2 any_2)
   (λ X_3 T
     (t-subst (t-subst-var any_1 X_1 X_3) X_2 any_2))
   (where X_3 (variable-not-in (term (X_2 any_1 any_2))
                                (term X_1)))] 
  ;; 3. replace X_1 with any_1
  [(t-subst X_1 X_1 any_1) any_1] 
  ;; the last two cases just recur on
  ;; the tree structure of the term
  [(t-subst (any_2 ...) X_1 any_1)
   ((t-subst any_2 X_1 any_1) ...)]
  [(t-subst any_2 X_1 any_1) any_2])

(define-metafunction t-iswim
  t-subst-var : any X Y -> any
  [(t-subst-var (any_1 ...) variable_1 variable_2)
   ((t-subst-var any_1 variable_1 variable_2) ...)]
  [(t-subst-var variable_1 variable_1 variable_2) variable_2]
  [(t-subst-var any_1 variable_1 variable_2) any_1])

(define-metafunction t-iswim
  Β : any -> num or #f
  [(Β number) num]
  [(Β any) #f]
  )

(define-metafunction t-iswim
  Δ : any -> num or (-> num (-> num num)) or #f
  [(Δ (iszero num)) (-> num (-> num num))]
  [(Δ (add1 num)) num]
  [(Δ (sub1 num)) num]
  [(Δ (+ num num)) num]
  [(Δ (- num num)) num]
  [(Δ (* num num)) num]
  [(Δ (/ num num)) num]
  [(Δ (** num num)) num]
  [(Δ any) #f]
  )

(define-metafunction t-iswim
  TC : ((X T) ...) M -> T or #f
  [(TC Γ b)
   (Β b)]
  [(TC Γ X)
   (TCvar Γ X)]
  [(TC ((Y S) ...) (λ X T M))
   (TCλ T (TC ((Y S) ... (X T)) M))]
  [(TC Γ (M N))
   (TCapp (TC Γ M) (TC Γ N))]
  [(TC Γ (o M ...))
   (TCo (o (TC Γ M) ...))])

(define-metafunction t-iswim
  TCvar : ((X T) ...) X -> T or #f
  [(TCvar ((X T_1) ... (Y T_2) (Z T_3) ...) Y)
   T_2
   (side-condition (not (member (term Y) (term (Z ...)))))]
  [(TCvar Γ X) #f])

(define-metafunction t-iswim
  TCλ : T any -> (-> T S) or #f
  [(TCλ T S) (-> T S)]
  [(TCλ T #f) #f])

(define-metafunction t-iswim
  TCapp : any any -> T or #f
  [(TCapp (-> S T) S) T]
  [(TCapp any_1 any_2) #f])

(define-metafunction t-iswim
  TCo : (o any ...) -> T or #f
  [(TCo (o T ...)) (Δ (o T ...))]
  [(TCo (o any ...)) #f])

(define testTC
  (lambda ()
    (test-equal
     (term (TC () ((λ x (-> num num) x) 5)))
     (term #f))
    (test-equal
     (term (TC () (+ x y)))
     (term #f))
    (test-equal
     (term (TC () (+ 1 2)))
     (term num))
    (test-equal
     (term (TC () (((λ x num (λ y num x)) 2) 3)))
     (term num))
    (test-equal
     (term (TC () ((λ x num 2) 4)))
     (term num))
    (test-equal
     (term (TC () (+ ((λ x num x) 1) 2)))
     (term num))
    
    (test-results)))

(define testProg
  (λ ()
    (test-->> t-iswim-red
              (term ((λ x num 2) 4)) 2)
    (test-->> t-iswim-red
              (term (((λ x num (λ y num x)) 2) 3)) 2)
    (test-->> t-iswim-red
              (term (+ ((λ x num x) 1) 2)) 3)
    
    (test-results)))

(define all-tests
  (λ ()
    (testTC)
    (testProg)))
                   