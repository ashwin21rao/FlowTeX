#lang racket
(require eopl)
(require rackunit)
(require racket/match)
(require rackunit/text-ui)
(require "ast.rkt")
(require "parser.rkt")
(require "evaluator.rkt")
(require "create-uml.rkt")


; functions to read and write from files
(define (read-test-input filename)
  (call-with-input-file filename
    (lambda (in) (read in))))

(define (read-test-output filename)
  (call-with-input-file filename
    (lambda (in)
      (port->string in))))

; TEST 1: no attributes or methods
(define program1 (read-test-input "tests/input/program1.txt"))
(define program1-evaluated (read-test-output "tests/gt-output/output1.txt"))

(define program1-ast (program (list (class "test-class" empty empty))))

; TEST 2: list of attributes
(define program2 (read-test-input "tests/input/program2.txt"))
(define program2-evaluated (read-test-output "tests/gt-output/output2.txt"))

(define program2-ast (program (list
  (class "test-class" (list (attribute "a" "int" "+")
                            (attribute "b" "float" "--"))
                       empty))))

; TEST 3: list of methods (with and without parameters)
(define program3 (read-test-input "tests/input/program3.txt"))
(define program3-evaluated (read-test-output "tests/gt-output/output3.txt"))

(define program3-ast (program (list
  (class "test-class" (list (attribute "a" "int" "\\#")
                            (attribute "b" "float" "--"))
                       (list (method "func1" "double" "+"
                                     (list (param "p1" "int")
                                           (param "p2" "bool")))
                             (method "func2" "char" "\\#" empty))))))

; TEST 4: association relationship
(define program4 (read-test-input "tests/input/program4.txt"))
(define program4-evaluated (read-test-output "tests/gt-output/output4.txt"))

(define program4-ast (program (list
  (associate "test-class1" "0..1" "test-class2" "*"))))

; TEST 5: inheritance relationship
(define program5 (read-test-input "tests/input/program5.txt"))
(define program5-evaluated (read-test-output "tests/gt-output/output5.txt"))

(define program5-ast (program (list
  (inherit "test-class1" "test-class2"))))

; TEST 6: program with multiple expressions
(define program6 (read-test-input "tests/input/program6.txt"))
(define program6-evaluated (read-test-output "tests/gt-output/output6.txt"))

(define program6-ast (program (list
  (class "test-class1" empty empty)
  (class "test-class2" (list (attribute "a" "int" "+")
                             (attribute "b" "float" "--"))
    empty)
  (class "test-class3" (list (attribute "a" "int" "\\#")
                             (attribute "b" "float" "--"))
    (list (method "func1" "double" "+"
                  (list (param "p1" "int")
                        (param "p2" "bool")))
          (method "func2" "char" "\\#" empty)))
  (associate "test-class1" "0..1" "test-class2" "*")
  (inherit "test-class3" "test-class2")
  (position "test-class2" 0 -5)
  (position "test-class3" 10 -5))))

;;; Tests for parsing
(define ts-parsing
  (test-suite "parsing"
              (test-case "1" (check-equal?
                              (parse program1)
                              program1-ast))
              
              (test-case "2" (check-equal?
                              (parse program2)
                              program2-ast))
              
              (test-case "3" (check-equal?
                              (parse program3)
                              program3-ast))

              (test-case "4" (check-equal?
                              (parse program4)
                              program4-ast))

              (test-case "5" (check-equal?
                              (parse program5)
                              program5-ast))

              (test-case "6" (check-equal?
                              (parse program6)
                              program6-ast))))

;;; Tests for evaluation
(define ts-evaluation
  (test-suite
    "evaluation"
    (test-case "1" 
               (check-equal?
                (evaluate (parse program1))
                program1-evaluated))
    
    (test-case "2" 
               (check-equal?
                (evaluate (parse program2))
                program2-evaluated))

    (test-case "3" 
               (check-equal?
                (evaluate (parse program3))
                program3-evaluated))

    (test-case "4" 
               (check-equal?
                (evaluate (parse program4))
                program4-evaluated))

    (test-case "5" 
               (check-equal?
                (evaluate (parse program5))
                program5-evaluated))

    (test-case "6"
               (check-equal?
                (evaluate (parse program6))
                program6-evaluated))))

;;; Tests for full pipeline
(define ts-pipeline
  (test-suite
    "pipeline"
    (test-case "1" (create-uml "tests/input/program1.txt" "tests/output/output1.txt")
               (check-equal?
                (read-test-output "tests/output/output1.txt")
                program1-evaluated))

    (test-case "2" (create-uml "tests/input/program2.txt" "tests/output/output2.txt")
               (check-equal?
                (read-test-output "tests/output/output2.txt")
                program2-evaluated))

    (test-case "3" (create-uml "tests/input/program3.txt" "tests/output/output3.txt")
               (check-equal?
                (read-test-output "tests/output/output3.txt")
                program3-evaluated))

    (test-case "4" (create-uml "tests/input/program4.txt" "tests/output/output4.txt")
               (check-equal?
                (read-test-output "tests/output/output4.txt")
                program4-evaluated))
    
    (test-case "5" (create-uml "tests/input/program5.txt" "tests/output/output5.txt")
               (check-equal?
                (read-test-output "tests/output/output5.txt")
                program5-evaluated))
    
    (test-case "6" (create-uml "tests/input/program6.txt" "tests/output/output6.txt")
               (check-equal?
                (read-test-output "tests/output/output6.txt")
                program6-evaluated))))

; ADD ADDITIONAL TESTS HERE
(define ts-alltests
  (test-suite
    "alltests"
    (test-case "alltests-1" (create-uml "tests/input/program6.txt" "tests/output/output6.txt")
               (check-equal?
                (read-test-output "tests/output/output6.txt")
                (read-test-output "tests/gt-output/output6.txt")))
    
    (test-case "alltests-2" (create-uml "tests/input/program7.txt" "tests/output/output7.txt")
               (check-equal?
                (read-test-output "tests/output/output7.txt")
                (read-test-output "tests/gt-output/output7.txt")))
    
    (test-case "alltests-3" (create-uml "tests/input/program8.txt" "tests/output/output8.txt")
               (check-equal?
                (read-test-output "tests/output/output8.txt")
                (read-test-output "tests/gt-output/output8.txt")))
    
    (test-case "alltests-4" (create-uml "tests/input/program9.txt" "tests/output/output9.txt")
               (check-equal?
                (read-test-output "tests/output/output9.txt")
                (read-test-output "tests/gt-output/output9.txt")))))

(define run-all-tests 
  (lambda ()
    (run-tests ts-parsing)
    (run-tests ts-evaluation)
    (run-tests ts-pipeline)
    (run-tests ts-alltests)))

(module+ test
  (run-all-tests))