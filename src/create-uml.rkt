#lang racket
(require eopl)
(require "parser.rkt")
(require "evaluator.rkt")
(provide (all-defined-out))


; the full pipeline
; 1) reads a program from a file
; 1) parses the program
; 2) evaluates the abstract syntax tree
; 3) writes the generated output to a file
(define (create-uml infile outfile)
  (let ([program (call-with-input-file infile
                   (lambda (in) (read in)))])
    (call-with-output-file outfile #:exists 'truncate
      (lambda (out)
        (display (evaluate (parse program)) out)))))
