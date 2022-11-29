#lang racket
(require eopl)
(require rackunit)
(require racket/match)
(require "ast.rkt")
(provide (all-defined-out))


; error handlers
(struct exn:parse-error exn:fail ())
(define raise-parse-error 
 (lambda (err-msg)
   (raise (exn:parse-error err-msg (current-continuation-marks)))))

; custom datatype checking
(define concrete-access-specifier?
  (lambda (x)
    (match x
      [(or 'public 'private 'protected) #t]
      [_ #f])))

; parsing helper functions
(define access-specifier-parse
  (lambda (as)
    (match as
      ['public "+"]
      ['private "--"]
      ['protected "\\#"]
      [_ error 'access-specifier-parse "unknown access specifier"])))

(define state-type-parse
  (lambda (as)
    (match as
      ['initial "initial"]
      ['final "final"]
      [_ error 'state-type-parse "unknown state type"])))

(define variable-name-parse
  (lambda (name)
    (cond
      [(number? name) error 'variable-name-parse "invalid variable/type name"]
      [else (symbol->string name)])))

(define cardinality-parse
  (lambda (cardinality)
    (cond
      [(number? cardinality) (number->string cardinality)]
      [else (symbol->string cardinality)])))

; parser
;;; parse :: any/c -> ast?  Raises exception exn:parse-error?
(define (parse exp)
  (match exp
    ; match program (parse each expression in the program in order)
    [(list 'flowtex exp-list ...)
     (program (map (lambda (exp) (parse exp)) exp-list))]
    
    ; match class
    ; empty class
    [(list 'class classname)
     (class (variable-name-parse classname) empty empty)]

    ; class has attributes and methods
    [(or (list 'class classname (list 'attributelist attributelist ...) (list 'methodlist methodlist ...))
         (list 'class classname (list 'methodlist methodlist ...) (list 'attributelist attributelist ...)))
     (class (variable-name-parse classname) (parse attributelist) (parse methodlist))]

    ; class has attributes only
    [(list 'class classname (list 'attributelist attributelist ...))
     (class (variable-name-parse classname) (parse attributelist) empty)]

    ; class has methods only
    [(list 'class classname (list 'methodlist methodlist ...))
     (class (variable-name-parse classname) empty (parse methodlist))]
    
    ; match attribute list
    [(list (list (? concrete-access-specifier? access-specifier)
                 datatype name) ...)
     (map (lambda (p-name p-datatype p-access-specifier)
            (attribute (variable-name-parse p-name)
                       (variable-name-parse p-datatype)
                       (access-specifier-parse p-access-specifier)))
          name datatype access-specifier)]

    ; match method list
    [(list (list (? concrete-access-specifier? access-specifier)
                 returntype name paramlist) ...)
     (map (lambda (p-name p-returntype p-access-specifier p-paramlist)
            (method (variable-name-parse p-name)
                    (variable-name-parse p-returntype)
                    (access-specifier-parse p-access-specifier)
                    (parse p-paramlist)))
          name returntype access-specifier paramlist)]

    ; match method params
    [(list 'params (list datatype name) ...)
     (map (lambda (p-name p-datatype)
            (param (variable-name-parse p-name)
                   (variable-name-parse p-datatype)))
          name datatype)]

    ; match association relationship
    [(list 'associate (list classname1 classname2)
                      (list cardinality1 cardinality2))
     (associate (variable-name-parse classname1) (cardinality-parse cardinality1)
                (variable-name-parse classname2) (cardinality-parse cardinality2))]
    
    ; match inheritance relationship
    [(list 'inherit childclass 'from parentclass)
     (inherit (variable-name-parse childclass)
              (variable-name-parse parentclass))]

    ; match state
    [(list 'state statename statelabel subexps ...)
     (let ([substates (filter (lambda (exp)
                                (or (eq? (car exp) 'state)
                                    (eq? (car exp) 'basicstate))) subexps)]
           [transitions (filter (lambda (exp) (eq? (car exp) 'transition)) subexps)])
       (state (variable-name-parse statename) statelabel
              (map (lambda (substate) (parse substate)) substates)
              (map (lambda (transition) (parse transition)) transitions)))]

    ; match basic state
    [(list 'basicstate statename statetype)
     (basicstate (variable-name-parse statename) (state-type-parse statetype))]

    ; match state transition
    [(list 'transition statename1 'to statename2 label)
     (transition (variable-name-parse statename1) (variable-name-parse statename2) label)]
    
    ; match position
    [(list 'position name x y) (position (variable-name-parse name) x y)]

    [_ (raise-parse-error "invalid concrete syntax")]))
