#lang racket
(require eopl)
(provide (all-defined-out))


; custom datatype checking
(define access-specifier?
  (lambda (x)
    (match x
      [(or "+" "--" "\\#") #t]
      [_ #f])))

(define statetype?
  (lambda (x)
    (match x
      [(or "initial" "final") #t]
      [_ #f])))

; AST definition
(define-datatype ast ast?
  [program (expression (list-of ast?))]
  [class (classname string?) (attributelist (list-of ast?)) (methodlist (list-of ast?))]
  [attribute (name string?) (datatype string?) (access-specifier access-specifier?)]	
  [method (name string?) (returntype string?) (access-specifier access-specifier?) (paramlist (list-of ast?))]
  [param (name string?) (datatype string?)]
  [position (classname string?) (x number?) (y number?)]
  [associate (classname1 string?) (cardinality1 string?) (classname2 string?) (cardinality2 string?)]
  [inherit (childclass string?) (parentclass string?)]

  [state (statename string?) (label string?) (statelist (list-of ast?)) (transitionlist (list-of ast?))]
  [basicstate (statename string?) (statetype statetype?)]
  [transition (statename1 string?) (statename2 string?) (label string?)])
