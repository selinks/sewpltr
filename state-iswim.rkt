#lang racket
(require redex)
(require "iswim.rkt")
(require "set.rkt")
(require "store.rkt")
(require "basic-iswim-test.rkt")
(require "state-iswim-test.rkt")

(define-extended-language state-iswim
  iswim
  ((M N L K) .... (set X M) (seq M M_i ...) (let ((X = M_v) ...) in M))
  (E .... (set X E))
  (St Uninit S)
  )

(define-metafunction/extension FV state-iswim
  [(FVs (set X M)) ,(set-union (list (term (FVs M)) (set-singleton (term X))))]
  [(FVs (seq M ...)) ,(set-union (term ((FVs M) ...)))]
  [(FVs (let ((X = M_v) ...) in M))
   ,(set-diff (set-union (term ((FVs M_v) ... (FVs M)))) (set-list (term (X ...))))]
  )

(define-metafunction state-iswim
  [(AV X) ,(set-empty)]
  [(AV (λ X M)) ,(set-diff (term (AV M)) (set-singleton (term X)))]
  [(AV (M N)) ,(set-union (term ((AV M) (AV N))))]
  [(AV (set X M)) ,(set-union (list (term (AV M)) (set-singleton (term X))))]
  [(AV b) ,(set-empty)]
  [(AV (o M ...)) ,(set-union (term ((AV M) ...)))]
  [(AV (seq M ...)) ,(set-union (term ((AV M ...))))]
  [(AV (let ((X = M_v) ...) in M)) ,(set-union (term ((AV M_v) ... (AV M))))]
  )

(define Store (store-make))

(define (update-and-return-prior! var val store)
  (begin0
    (store-lookup var store)
    (store-update! var val store)))

(define cs-red
  (reduction-relation
   state-iswim
   (--> (any Uninit)
        (any S)
        init-store
        (side-condition
         (begin (set! Store (store-make)) #t)))
   (--> ((in-hole E ((λ X M) V)) S)
        ((in-hole E (subst M X V)) S)
        csfiv
        (side-condition
         (not (set-lookup (term X) (term (AV M))))))
   (--> ((in-hole E ((λ X M) V)) S)
        ((in-hole E (subst M X Y)) S)
        csfis
        (side-condition
         (set-lookup (term X) (term (AV M))))
        (where Y ,(variable-not-in
                   (term 
                     (,(store-vars Store)
                      (FVs (in-hole E M))))
                     (term X)))
        (side-condition
         (begin (store-update! (term Y) (term V) Store) #t)))
   (--> ((in-hole E X) S)
        ((in-hole E ,(store-lookup (term X) Store)) S)
        cseq)
   (--> ((in-hole E (set X V)) S)
        ((in-hole E ,(update-and-return-prior! (term X) (term V) Store)) S)
        cs!)
   (--> ((in-hole E (o V ...)) S)
        ((in-hole E (δ (o V ...))) S)
        csffi)
   (--> ((in-hole E (seq M)) S)
        ((in-hole E M) S)
        seq-last)
   (--> ((in-hole E (seq M M_i ...)) S)
        ((in-hole E ((λ Y (seq M_i ...)) M)) S)
        seq-n
        (fresh Y)
        (side-condition
         (<= 1 (length (term (M_i ...))))))
   (--> ((in-hole E (let () in M)) S)
        ((in-hole E M) S)
        let-empty)
   (--> ((in-hole E (let ((X = M_v) (X_i = M_i) ...) in M)) S)
        ((in-hole E ((λ X (let ((X_i = M_i) ...) in M)) M_v)) S)
        let-n)
   ))

; ------ Testing  tools -----

(define (test-AV)
  ; Expressions with no assignable variables
  (test-equal (term (AV x)) (set-empty))
  (test-equal (term (AV (λ x (+ y z)))) (set-empty))
  (test-equal (term (AV ((+ 2 1) (x y)))) (set-empty))
  (test-equal (term (AV (set x (+ y z)))) (set-singleton (term x)))
  (test-equal (term (AV 0)) (set-empty))
  (test-equal (term (AV (+ x y))) (set-empty))
  
  ; Expressions with assignable variables
  (test-equal (term (AV (λ y (set x (add1 y))))) (set-singleton (term x)))
  (test-equal (term (AV (λ x (set x (add1 z))))) (set-empty))
  (test-equal (term (AV ((set x y) (set z q)))) (set-list (term (x z))))
  (test-results))

(define (run-cs-test tm val)
  (run-test cs-red tm val))

(define (run-test red tm val)
  (let [(res (apply-reduction-relation* red
                                        (term (,tm Uninit))))
        (same? (lambda (res)
                 (and
                  (equal? (length res) 1)
                  (equal? (caar res) val))))]
    
    (test-predicate same? res)))

(define (test-basics)
  (run-basic-tests run-cs-test))

(define (test-state)
  (run-state-tests run-cs-test))
