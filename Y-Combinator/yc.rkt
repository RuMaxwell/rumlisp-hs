#lang racket
(define y (lambda (gen)
            ((lambda (g) (g g)) (lambda (f)
                                 (lambda (args)
                                   ((gen (f f)) args))))))

(define fact (y (lambda (fac)
                  (lambda (n)
                    (if (<= n 0) 1 (* n (fac (- n 1))))))))

(fact 6)
