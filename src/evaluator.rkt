#lang racket
(require eopl)
(require rackunit)
(require racket/match)
(require "ast.rkt")
(provide (all-defined-out))


; error handlers
(struct exn:eval-error exn:fail ())
(define raise-eval-error 
 (lambda (err-msg)
   (raise (exn:eval-error err-msg (current-continuation-marks)))))

; evaluator helper functions
(define (get-position name positions)
  (cond
    [(hash-has-key? positions name) (hash-ref positions name)]
    [else (raise-eval-error (format "name ~a is not defined" name))]))

(define (eval-ast a positions)
  (cases ast a
    ; evaluate class
    [class (classname attributelist methodlist)
      (let* ([attribute-exps
              (map (lambda (attribute)
                     (eval-ast attribute positions)) attributelist)] ; evaluate each attribute
             
             [method-exps
              (map (lambda (method)
                     (eval-ast method positions)) methodlist)] ; evaluate each method
             
             [attribute-string ; convert attribute-exps to string, enclose in braces
              (format "{\n~a}\n" (string-join attribute-exps ""))]

             [method-string ; convert method-exps to string, enclose in braces
              (format "{\n~a}\n" (string-join method-exps ""))]
             
             [position (get-position classname positions)] ; get position of class (x, y)
             
             [class-header ; create class header
              (format "\\umlclass[x=~a,y=~a]{~a}\n" (car position) (cadr position) classname)])

        (string-append class-header attribute-string method-string))]

    ; evaluate attribute
    [attribute (name datatype access-specifier)
               (format "~a ~a : ~a \\\\\n" access-specifier name datatype)]

    ; evaluate method
    [method (name returntype access-specifier paramlist)
            (let* ([param-exps
                    (map (lambda (param)
                           (eval-ast param positions)) paramlist)] ; evaluate each parameter

                   [param-string ; convert param-exps to string
                    (string-join param-exps ", ")])

              (format "~a ~a(~a) : ~a \\\\\n"
                      access-specifier name param-string returntype))]

    ; evaluate method params
    [param (name datatype)
           (format "~a : ~a" name datatype)]

    ; evaluate association relationship
    [associate (classname1 cardinality1 classname2 cardinality2)
               (format "\\umlassoc[mult1=~a, mult2=~a]{~a}{~a}\n"
                       cardinality1 cardinality2 classname1 classname2)]
    
    ; evaluate inheritance relationship
    [inherit (childclass parentclass)
             (format "\\umlinherit{~a}{~a}\n" childclass parentclass)]

    ; evaluate state
    [state (statename label statelist transitionlist)
           (let* ([state-exps
                   (map (lambda (substate)
                          (eval-ast substate positions)) statelist)] ; evaluate each substate
                  
                  [transition-exps
                   (map (lambda (transition)
                          (eval-ast transition positions)) transitionlist)] ; evaluate each transition
                  
                  [state-string ; convert state-exps to string
                   (cond
                     [(empty? state-exps) ""]
                     [else (format "~a" (string-join state-exps ""))])]
                  
                  [transition-string ; convert transition-exps to string
                   (cond
                     [(empty? transition-exps) ""]
                     [else (format "~a" (string-join transition-exps ""))])]
                  
                  [position (get-position statename positions)]) ; get position of state (x, y)

             (cond
               [(and (eq? state-string "") (eq? transition-string "")) ; state has no subexpressions
                (format "\\umlbasicstate[x=~a,y=~a,name=~a]{~a}\n"
                        (car position) (cadr position) statename label)]
               
               [else (format "\\begin{umlstate}[x=~a,y=~a,name=~a]{~a}\n~a\\end{umlstate}\n"
                             (car position) (cadr position) statename label
                             (string-append state-string transition-string))]))]

    ; evaluate basic state
    [basicstate (statename statetype)
                (let ([position (get-position statename positions)]) ; get position of state (x, y)
                  (format "\\umlstate~a[x=~a,y=~a,name=~a]\n"
                             statetype (car position) (cadr position) statename))]

    ; evaluate state transition
    [transition (statename1 statename2 label)
                (format "\\umltrans[arg=~a]{~a}{~a}\n" label statename1 statename2)]
    
    ; default case (if attributelist, methodlist, paramlist, statelist, transitionlist are empty)
    [_ ""]))

(define (get-position-map exp-list positions)
  (for/list ([exp exp-list])
    (cases ast exp
      [class (classname attributelist methodlist) (hash-set! positions classname (list 0 0))]
      [state (statename label statelist transitionlist)
             (hash-set! positions statename (list 0 0))
             (get-position-map statelist positions)]
      [basicstate (statename statetype) (hash-set! positions statename (list 0 0))]
      [position (name x y) (hash-set! positions name (list x y))]
      [_ empty])))

; evaluator
;;; evaluate :: ast? -> string?  Raises exception exn:eval-error?
(define (evaluate a)
  (cases ast a
    ; evaluate each expression in the program in order
    [program (exp-list)
             (define positions (make-hash)) ; maps classnames to (x, y) positions
             (get-position-map exp-list positions)
             
             (let* ([exp-strings
                     (map (lambda (exp) (eval-ast exp positions)) exp-list)])
               (format "\\begin{tikzpicture}\n~a\\end{tikzpicture}\n" ; add boilerplate
                       (string-join exp-strings "")))] ; combine into single string

    [_ (raise-eval-error "invalid abstract syntax")]))
