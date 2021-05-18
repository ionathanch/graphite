#lang racket
(require fancy-app pict plot/utils
         (prefix-in plot: plot/pict)
         "contracts.rkt" "util.rkt")
(provide
 (contract-out [density (->* ()
                             (#:x-min (or/c rational? #f)
                              #:x-max (or/c rational? #f)
                              #:y-min (or/c rational? #f)
                              #:y-max (or/c rational? #f)
                              #:samples (and/c exact-integer? (>=/c 2))
                              #:color plot-color/c
                              #:width (>=/c 0)
                              #:style plot-pen-style/c
                              #:alpha (real-in 0 1)
                              #:label (or/c string? pict? #f)
                              #:mapping (aes-containing/c #:x string?
                                                          #:discrete-color (or/c string? #f)
                                                          #:facet (or/c string? #f)))
                             graphite-renderer/c)]))

(define-renderer (density #:kws kws #:kw-args kw-args
                          #:mapping [local-mapping (make-hash)]) ()
  (define aes (mapping-override (gr-global-mapping) local-mapping))

  (define tbl (make-hash))
  (for ([(x strat facet)
         (in-data-frame* (gr-data) (hash-ref aes 'x) (hash-ref aes 'discrete-color #f)
                         (hash-ref aes 'facet #f))]
        #:when x
        #:when (equal? facet (gr-group)))
    (hash-update! tbl strat (cons ((gr-x-conv) x) _) null))

  (let ([color-n -1])
    (hash-map tbl
              (λ (strat pts)
                (set! color-n (add1 color-n))
                (run-renderer #:renderer plot:density #:kws kws #:kw-args kw-args
                              #:color (->pen-color color-n) #:label strat
                              pts))
              #t)))
