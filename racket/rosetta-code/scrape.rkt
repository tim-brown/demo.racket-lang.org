#lang racket

(require racket/runtime-path
         xml
         xml/path
         net/url
         net/head
         racket/date
         (prefix-in 19: srfi/19)
         net/uri-codec)

(define-logger rc-scrape)

(define-runtime-path rt:download "download")

(define-runtime-path rt:extract "../../scrapings")

(define current-do-download? (make-parameter #t))

(define rc-base-url "http://rosettacode.org")

(define rc-Cat:Racket-url (string-append rc-base-url "/wiki/Category:Racket"))

(define rc-Cat:Racket-xml (xml->xexpr
                           (document-element
                            (read-xml (get-pure-port (string->url rc-Cat:Racket-url))))))

(define all-hrefs (se-path*/list '(a #:href) rc-Cat:Racket-xml))

(define href-filter
  (match-lambda
    [(not (regexp #px"^/wiki")) #f]
    ["/wiki/Rosetta_Code" #f]
    [(regexp #px"wiki/Rosetta_Code:") #f]
    [(regexp #px"wiki/Category:") #f]
    [(regexp #px"wiki/Special:") #f]
    [(regexp #px"wiki/Reports:") #f]
    [(regexp #px"wiki/Help:") #f]
    [(regexp #px"wiki/Category_talk:") #f]
    ;[(not (or (regexp #px"Brain"))) #f]
    [_ #t]))

(define (recursive-make-directory path-bits (keep 1))
  (define d (apply build-path (take path-bits keep)))
  (unless (directory-exists? d)
    (log-rc-scrape-info "making ~s" d)
    (make-directory d))
  (when (< keep (length path-bits))
    (recursive-make-directory path-bits (add1 keep))))

(define (safer-file-name f)
  (regexp-replaces f (list (list #px"[^[:word:]]" "="))))

(define (get-file-name href)
  (let ()
    (define u (string->url (string-append rc-base-url href "?action=edit")))
    (define dest-path-bits (drop (map (compose uri-encode path/param-path) (url-path u)) 1))
    (define download-path (apply build-path (list* rt:download (drop-right dest-path-bits 1))))
    (define extract-path (apply build-path (list* rt:extract (drop-right dest-path-bits 1))))
    (define f-base-name (safer-file-name (last dest-path-bits)))
    (define dest.html (build-path download-path (string-append f-base-name ".html")))
    (define dest.rfc822 (build-path download-path (string-append f-base-name ".rfc822")))
    (define dest.rkt.wt (build-path extract-path (string-append f-base-name ".rkt.wt")))
    (define dest.task.wt (build-path extract-path (string-append f-base-name ".task.wt")))
    
    (define hsh# (hash
                  'download-url u
                  'download-path-bits dest-path-bits
                  'download-dest-path download-path
                  'base-name f-base-name
                  'dest.html dest.html
                  'dest.rfc822 dest.rfc822
                  'extract-dest-path extract-path
                  'dest.rkt.wt dest.rkt.wt
                  'dest.task.wt dest.task.wt))
    (λ (k) (hash-ref hsh# k))))

(define (download-href href)
  (log-rc-scrape-info "downloading ~s" href)
  (define (sub-download-href href ec)
    (unless (href-filter href) (ec))
    (unless (current-do-download?) (ec))
    (define gfn (get-file-name href))
    (define u (gfn 'download-url))
    (define dest-path (gfn 'download-dest-path))
    (define dest.html (gfn 'dest.html))
    (define dest.head (gfn 'dest.rfc822))
  
    (log-rc-scrape-info "~s -> ~s" (url->string u) (path->string dest.html))
    (define local-last-modified-time
      (let/ec ec
        (unless (file-exists? dest.head) (ec #f))
        ;(log-rc-scrape-debug "~a" (file->string dest.head))
        (rfc822->last-modified-time ec (file->string dest.head))))

    (define raw-remote-headers (purify-port (head-impure-port u)))
    (log-rc-scrape-debug "headers (raw): ~s" raw-remote-headers)
    (define remote-hdrs (regexp-replace "^[^\n]*\n(.*)$" raw-remote-headers "\\1"))
    (define remote-last-modified-time
      (let/ec ec
        (unless (file-exists? dest.head) (ec #f))
        (rfc822->last-modified-time ec remote-hdrs)))
  
    (recursive-make-directory (explode-path dest-path))
    (log-rc-scrape-debug "calculating refresh? from ~s ~s"
                         local-last-modified-time remote-last-modified-time)
    (define refresh?
      (cond
        [(not (file-exists? dest.html))
         (log-rc-scrape-debug "refreshing: file ~s does not exist" dest.html)
         #t]
        [(not (file-exists? dest.head))
         (log-rc-scrape-debug "refreshing: head file ~s does not exist" dest.head)
         #t]
        [(not local-last-modified-time)
         (log-rc-scrape-debug "refreshing: local lmt is #f")
         #t]
        [(< local-last-modified-time remote-last-modified-time)
         (log-rc-scrape-debug "refreshing: lmt (local:~a < remote:~a)"
                              local-last-modified-time remote-last-modified-time)
         #t]
        [else
         (log-rc-scrape-info "not refreshing")
         #t]))
  
    (when
        refresh?     
      (with-output-to-file dest.html #:exists 'replace
        (λ () (copy-port (get-pure-port u) (current-output-port))))
      (with-output-to-file dest.head #:exists 'replace (λ () (display remote-hdrs)))))

  (let/ec ec (sub-download-href href ec)))

(define (extract-title-and-racket-source href)
  (define gfn (get-file-name href))
  (define extract-path (gfn 'extract-dest-path))
  (define html-source (gfn 'dest.html))
  (log-rc-scrape-info "extracting: ~s" href)
  (recursive-make-directory (explode-path extract-path))
  (define textarea (se-path*/list '(html body div div div div div div textarea)
                                  (string->xexpr (file->string html-source))))
  ;(pretty-print (filter (match-lambda ((regexp "=={{header\|") #t) (_ #f)) (cdr textarea)))
  (let extract-task ((t (string-split (string-join textarea "") "\n")) (task null))
    (match t
      [(list) (values gfn (reverse task) null)]
      [(cons (regexp "=={{header") _)
       (values gfn
               (reverse task)
               (let skip-to-racket ((t t))
                 (match t
                   [(list) null]
                   [(cons (regexp #rx"=={{header..acket}}==") tl)
                    (let consume-racket ((t tl) (rkt null))
                      (match t
                        [(list) (reverse rkt)]
                        [(cons (regexp "=={{header") _) (reverse rkt)]
                        [(cons h t) (consume-racket t (cons h rkt))]))]
                   [(cons _ t) (skip-to-racket t)])))]
      [(cons h t) (extract-task t (cons h task))])))

(define (reconstruct-task gfn task rkt)
  (define task.wt (gfn 'dest.task.wt))
  (define rkt.wt (gfn 'dest.rkt.wt))

  (log-rc-scrape-debug "reconstruct ~s ~s~%" task rkt)

  (with-output-to-file task.wt #:exists 'replace
    (λ () (display (string-join task "\n"))))

  (with-output-to-file rkt.wt #:exists 'replace
    (λ () (display (string-join rkt "\n")))))

(define LM-date-format-string "~a, ~e ~b ~Y ~H:~M:~S GMT")

(define (rfc822->last-modified-time ec hdrs)
  ; (log-rc-scrape-debug "validating: ~s~%" hdrs)
  (validate-header hdrs)
  (define lm (extract-field "last-modified" hdrs))
  (unless lm (ec #f))
  (log-rc-scrape-debug "last-modified: ~s from ~s" lm hdrs)
  (date->seconds (19:string->date lm LM-date-format-string)))

;; ---------------------------------------------------------------------------------------------------
(module+ main
  (for/last ((h all-hrefs) #:when (href-filter h))
    (download-href h)
    (log-rc-scrape-info "extracting title and source from ~s" h)
    (call-with-values
     (λ () (extract-title-and-racket-source h))
     reconstruct-task)))

;; ---------------------------------------------------------------------------------------------------
(module+ test
  (require rackunit)
  (check-not-exn (λ () (19:string->date "Tue, 28 Jun 2016 14:24:53 GMT" LM-date-format-string)))
  )


#|
(require net/url
         json)

(define-logger wm-query)

(define current-api-base-url (make-parameter "http://rosettacode.org/mw/api.php"))

(define (query-parts category)
  (list "action=query"
        "list=categorymembers"
        (format "cmtitle=Category:~a" category)
        "format=json"
        "cmlimit=500"))


;; input: query-parts ...
;; output: (list query-hashes)
(define (full-wikimedia-query #:cmlimit (cmlimit 500) . parts)
  (define parts′ (list* "format=json"
                        "formatversion=2"
                        "action=query"
                        (format "cmlimit=~a" cmlimit)
                        parts))
  
  (define (inr continue acc)
    (define parts′′ (append (hash-map continue  (λ (k v) (format "~a=~a" k v))) parts′))
    (eprintf "parts′ : ~s~%~s~%" parts′′ continue)
    
    (define query-url (string->url
                       (string-append
                        (current-api-base-url)
                        "?"
                        (string-join parts′′ ";"))))
    (define rsp (read-json (get-pure-port query-url)))
    (printf "qry: ~s~%" (url->string query-url))
    (eprintf "rsp: ~s~%" (hash-remove rsp 'query))
    (if (hash-has-key? rsp 'continue)
        (inr (hash-ref rsp 'continue) (append acc (list (hash-ref rsp 'query))))
        acc))
  (inr (hash) null))

(full-wikimedia-query "list=categorymembers"
                      (format "cmtitle=Category:~a" "racket"))
|#