
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; MODULE      : generic-widgets.scm
;; DESCRIPTION : widgets for general purpose editing
;; COPYRIGHT   : (C) 2013  Joris van der Hoeven
;;
;; This software falls under the GNU general public license version 3 or later.
;; It comes WITHOUT ANY WARRANTY WHATSOEVER. For details, see the file LICENSE
;; in the root directory or <http://www.gnu.org/licenses/gpl-3.0.html>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(texmacs-module (generic generic-widgets)
  (:use (generic generic-edit)
        (utils library cursor)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Basic search and replace buffers management
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(tm-define (search-buffer)
  (string->url "tmfs://aux/search"))

(tm-define (replace-buffer)
  (string->url "tmfs://aux/replace"))

(tm-define (master-buffer)
  (and (buffer-exists? (search-buffer))
       (buffer-get-master (search-buffer))))

(tm-define (inside-search-buffer?)
  (== (current-buffer) (search-buffer)))

(tm-define (inside-replace-buffer?)
  (== (current-buffer) (replace-buffer)))

(tm-define (inside-search-or-replace-buffer?)
  (in? (current-buffer) (list (search-buffer) (replace-buffer))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Highlighting the search results
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (perform-search)
  (let* ((what (buffer-get-body (search-buffer)))
         (ok? #t))
    (when (tm-func? what 'document 1)
      (set! what (tm-ref what 0)))
    (when (tm-func? what 'inactive 1)
      (set! what (tm-ref what 0)))
    (when (tm-func? what 'inactive* 1)
      (set! what (tm-ref what 0)))
    (with-buffer (master-buffer)
      (if (tree-empty? what)
          (begin
            (selection-cancel)
            (cancel-alt-selection "alternate")
            (go-to (get-search-reference #t)))
          (let* ((t (buffer-tree))
                 (sels (tree-search-tree t what (tree->path t))))
            (if (null? sels)
                (begin
                  (selection-cancel)
                  (cancel-alt-selection "alternate")
                  (go-to (get-search-reference #t))
                  (set! ok? #f))
                (begin
                  (set-alt-selection "alternate" sels)
                  (with after? (next-search-result #t #f)
                    (when (not after?)
                      (selection-cancel))))))))
    (with-buffer (search-buffer)
      (if ok?
          (init-default "bg-color")
          (init-env "bg-color" "#fff0f0")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Highlighting a particular next or previous search result
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (set-search-reference cur)
  (set-alt-selection "search-reference" (list cur cur)))

(define (get-search-reference forward?)
  (with sel (get-alt-selection "search-reference")
    (if (nnull? sel) (car sel)
        (if forward? (cursor-path) (cursor-path*)))))

(define (search-next sels cur strict?)
  (while (and (nnull? sels)
              (nnull? (cdr sels))
              (not (path-less-eq? cur (cadr sels))))
    (set! sels (cddr sels)))
  (if (and (>= (length sels) 4)
           (== (cadr sels) (caddr sels))
           (== (cadr sels) cur))
      (set! sels (cddr sels)))
  (if (and strict? (>= (length sels) 2))
      (set! sels (cddr sels)))
  (and (>= (length sels) 2)
       (list (car sels) (cadr sels))))

(define (search-previous sels cur strict?)
  (set! sels (reverse sels))
  (while (and (nnull? sels)
              (nnull? (cdr sels))
              (not (path-less-eq? (cadr sels) cur)))
    (set! sels (cddr sels)))
  (if (and strict? (>= (length sels) 2))
      (set! sels (cddr sels)))
  (and (>= (length sels) 2)
       (list (cadr sels) (car sels))))

(define (next-search-result forward? strict?)
  (let* ((sels (get-alt-selection "alternate"))
         (cur (get-search-reference forward?)))
    (and (nnull? sels)
         (and-with sel (if forward?
                           (search-next sels cur strict?)
                           (search-previous sels cur strict?))
           (selection-set-range-set sel)
           (go-to (car sel))
           (when strict? (set-search-reference (car sel)))
           #t))))

(define (extreme-search-result last?)
  (with sels (get-alt-selection "alternate")
    (and (nnull? sels)
         (and-with sel (if last?
                           (list (cAr (cDr sels)) (cAr sels))
                           (list (car sels) (cadr sels)))
           (selection-set-range-set sel)
           (go-to (car sel))
           (set-search-reference (car sel))))))

(tm-define (search-next-match forward?)
  (with-buffer (master-buffer)
    (next-search-result forward? #t)))

(tm-define (search-extreme-match last?)
  (with-buffer (master-buffer)
    (extreme-search-result last?)))

(tm-define ((search-cancel u) . args)
  (with-buffer u
    (cancel-alt-selection "alternate")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Replace occurrences
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (by-tree)
  (and (buffer-exists? (replace-buffer))
       (with by (buffer-get-body (replace-buffer))
         (when (tm-func? by 'document 1)
           (set! by (tm-ref by 0)))
         by)))

(define (replace-next by)
  (let* ((sels (get-alt-selection "alternate"))
         (cur (get-search-reference #t)))
    (and (nnull? sels)
         (and-with sel (search-next sels cur #f)
           (go-to (car sel))
           (selection-set-range-set sel)
           (clipboard-cut "dummy")
           (insert-go-to (tree-copy by) (path-end by '()))
           #t))))

(tm-define (replace-one)
  (and-with by (by-tree)
    (and (with-buffer (master-buffer)
           (replace-next by))
         (begin
           (perform-search)
           #t))))

(tm-define (replace-all)
  (while (replace-one)
    (noop)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Customized keyboard shortcuts in search and replace modes
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define search-kbd-intercepted? #f)

(tm-define (keyboard-press key time)
  (:require (inside-search-buffer?))
  (set! search-kbd-intercepted? #f)
  (former key time)
  (when (not search-kbd-intercepted?)
    (perform-search)))

(tm-define (kbd-enter t shift?)
  (:require (inside-search-buffer?))
  (if (or shift? (inside? 'inactive) (inside? 'inactive*))
      (former t shift?)
      (begin
        (set! search-kbd-intercepted? #t)
        (with ok? (search-next-match #t)
          (when (not ok?)
            (search-extreme-match #f))))))

(tm-define (kbd-enter t shift?)
  (:require (inside-replace-buffer?))
  (if (or shift? (inside? 'inactive) (inside? 'inactive*))
      (former t shift?)
      (replace-one)))

(tm-define (kbd-incremental t forwards?)
  (:require (inside-search-or-replace-buffer?))
  (set! search-kbd-intercepted? #t)
  (search-next-match forwards?))

(tm-define (traverse-incremental t forwards?)
  (:require (inside-search-or-replace-buffer?))
  (set! search-kbd-intercepted? #t)
  (search-next-match forwards?))

(tm-define (traverse-extremal t forwards?)
  (:require (inside-search-or-replace-buffer?))
  (set! search-kbd-intercepted? #t)
  (search-extreme-match forwards?))

(kbd-map
  (:require (inside-search-or-replace-buffer?))
  ("std ?" (make 'select-region))
  ("std 1" (insert '(wildcard "x")))
  ("std 2" (insert '(wildcard "y")))
  ("std 3" (insert '(wildcard "z"))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Search widget
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(tm-widget ((search-widget u style aux) quit)
  (padded
    (resize "600px" "60px"
      (texmacs-input `(document "") `(style (tuple ,@style)) aux))
    ======
    (explicit-buttons
      (hlist
        ("First" (search-extreme-match #f)) // //
        ("Previous" (search-next-match #f)) // //
        ("Next" (search-next-match #t)) // //
        ("Last" (search-extreme-match #t)) >>>
        ("Done" (quit))))))

(tm-define (open-search)
  (:interactive #t)
  (let* ((u (current-buffer))
         (st (list-remove-duplicates (rcons (get-style-list) "macro-editor")))
         (aux (search-buffer)))
    (buffer-set-master aux u)
    (set-search-reference (cursor-path))
    (dialogue-window (search-widget u st aux) (search-cancel u) "Search")))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Search and replace widget
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(tm-widget ((replace-widget u style saux raux) quit)
  (padded
    (resize "600px" "60px"
      (texmacs-input `(document "") `(style (tuple ,@style)) saux))
    ===
    (resize "600px" "60px"
      (texmacs-input `(document "") `(style (tuple ,@style)) raux))
    ======
    (explicit-buttons
      (hlist
        ("Previous" (search-next-match #f)) // //
        ("Next" (search-next-match #t)) // //
        ("Replace" (replace-one)) // //
        ("Replace all" (replace-all)) >>>
        ("Done" (quit))))))

(tm-define (open-replace)
  (:interactive #t)
  (let* ((u (current-buffer))
         (st (list-remove-duplicates (rcons (get-style-list) "macro-editor")))
         (saux (search-buffer))
         (raux (replace-buffer)))
    (buffer-set-master saux u)
    (buffer-set-master raux u)
    (set-search-reference (cursor-path))
    (dialogue-window (replace-widget u st saux raux)
                     (search-cancel u)
                     "Search and replace")))
