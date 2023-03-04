#lang racket
(require eopl)
(require racket/cmdline)
(require "create-uml.rkt")
(provide (all-defined-out))


; parse command line arguments
(define parse-command-line
  (command-line
   #:args (infile outfile)
   (create-uml infile outfile)))
