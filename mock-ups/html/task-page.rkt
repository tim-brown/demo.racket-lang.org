#lang racket
(require xml)
(with-output-to-file "task-page.html" #:exists 'replace
  (lambda ()
    (write-xexpr
     `(html
       (head
        
        )
       (body
        (h1 "A* Search Algorithm") ; TODO: we don't actually seem to have this scraped!
        (div
         ((id "description"))
         (h2 "Description")
         (pre
          ,(file->string "../../scrapings/A=_search_algorithm.task.wt")
          )
         )
        (div
         ((id "source"))
         (h2 "Source")
         (pre
          ,(file->string "../../scrapings/A=_search_algorithm.rkt.wt")
          )
         )
        (div
         ((id "tests-examples"))
         (h2 "Tests and Examples")

         (h3 "raco test <filename.rkt>")
         (p "Runs the "(tt "main")" submodule")
         (p "no output")

         (h3 "racket <filename.rkt>")
         (p "Runs the "(tt "main")" submodule")
         (h4 "Output:")
         (pre
          #<<<
visited 35 nodes
cpu time: 94 real time: 97 gc time: 15
path is 11 long
path is: ((1 . 1) (1 . 1) (1 . -1) (1 . 0) (1 . 0) (1 . 1) (1 . 1) (0 . 1) (-1 . 1) (1 . 1) (0 . 1))
<
          ))
        (div
         ((id "info"))
         (h2 "More Info")
         (ul
          (li "Origin: RosettaCode "(a ((href "http://rosettacode.org/..."))
                                           "http://rosettacode.org/...#racket")
              (ul
               (li "Author: Joe Bloggs")
               (li "Licence: PD")
               (li "Revision: 1.1")))
          (li "Canonical source: origin -- make sure that changes there are reflected here"
              (ul
               (li (input ((type "checkbox"))
                          (label "report demo.racket-lang.org version as out of date")))
               (li (input ((type "checkbox"))
                          (label "report original version (on RosettaCode) as out of date")))))
          (li "Safety:"
              (ul (li (input ((type "checkbox") (checked "checked") (disabled "disabled"))
                             (label "safe to run at home")))
                  (li (input ((type "checkbox") (checked "checked") (disabled "disabled"))
                             (label "safe to run on server")))
                  (li (input ((type "checkbox") (disabled "disabled")) (label "reads filesystem")))
                  (li (input ((type "checkbox") (disabled "disabled")) (label "writes filesystem")))
                  (li (input ((type "checkbox") (disabled "disabled")) (label "uses network")))
                  (li (input ((type "checkbox")
                              (value "true")
                              (disabled "disabled")) (label "runs quickly")))
                  )))
          ))
       ))))
