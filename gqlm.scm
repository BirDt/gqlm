;; gqlm is licensed under the terms of the GNU Affero General Public License, v3.0

;;; Helper macro definitions
(define-macro (->string expr)
  `(js-invoke ,expr "toString")) ; Shortcut for JS .toString()

(define-macro (assert expr msg)
  `(when (not ,expr)
     (print ,msg)
     (exit)))

(define-macro (get-cli-arg arg param)
  `(let ((subset-args (member ,arg args)))
     (when subset-args
       (,param (cadr subset-args)))))

;;; Parser combinators
;; Match a given character
(define (char match-char)
  (assert (char? match-char) "Error: Character parser must take a character as input")
  (lambda (input)
    (if (and (< 0 (string-length input)) (equal? (string-ref input 0) match-char))
	(cons match-char (substring input 1 (string-length input)))
	#f)))

;; Match any character
(define (any)
  (lambda (input)
    (if (< 0 (string-length input))
	(cons (string-ref input 0) (substring input 1 (string-length input)))
	#f)))

;; Match any character except for the one given
(define (any-but parser)
  (lambda (input)
    (if (and (< 0 (string-length input)) (not (parser input)))
	(cons (string-ref input 0) (substring input 1 (string-length input)))
	#f)))

;; Match a sequence of parsers
(define (seq . parsers)
  (define (match-next p result rest)
    (let ((parser (list-ref parsers p)))
      (if (js-undefined? parser) (cons result rest)
	  (let ((parse-result (parser rest)))
	    (if parse-result
		(match-next (+ 1 p)
			    (append result (list (car parse-result)))
			    (cdr parse-result))
		#f)))))
  (lambda (input)
    (match-next 0 '() input)))

;; Match a parser * times
(define (many parser)
  (define (match-next result rest)
    (let ((parse-result (parser rest)))
      (if parse-result
	  (match-next (append result (list (car parse-result)))
		      (cdr parse-result))
	  (cons result rest))))
  (lambda (input)
    (match-next '() input)))

;; Match a word
(define (word match-word)
  (apply seq (map (lambda (x) (char x)) (string->list match-word))))

;; Match the first of any parsers
(define (either . parsers)
  (define (test-parser p input)
    (if (null? p) #f
	(let ((parser (car p)))
	  (let ((parse-result (parser input)))
	    (if parse-result
		parse-result
		(test-parser (cdr  p)
			     input))))))
  (lambda (input)
    (test-parser parsers input)))

;; Discard parser result
(define (discard parser)
  (lambda (input)
    (let ((result (parser input)))
      (if result
	  (cons '() (cdr result))
	  #f))))

;;; Import filesystem
(define fs (node-require "fs"))

;; Get commandline args
;; We remove the head args, which are always node, biwas, and gqlm.scm
(define args (list-tail (vector->list (js-eval "process.argv")) 3))

;; Print help if called with no args
(define (print-help)
  (print "-f <schema file> -o <output file>"))

(when (= 0 (length args))
  (print-help)
  (exit))

;; Get schema file path, cli -f arg
(define schema-file (make-parameter "schema.graphql"))
(get-cli-arg "-f" schema-file)

;; Exit if the given schema file doesn't exist
(assert (file-exists? (schema-file)) "Error: Schema file does not exist")

;; Get output file path, cli -o arg
(define output-file (make-parameter (schema-file)))
(get-cli-arg "-o" output-file)

;; Get the text of the schema file
(define schema-text (->string (js-invoke fs "readFileSync" (schema-file))))

;; Get interface definitions and their bodies
(define interface-header (seq (word "interface")
			   (many (char #\space))
			   (many (any-but (char #\space)))
			   (many (char #\space))
			   (char #\{)))
(define (match-interface-header input)
  (let ((parse-result (interface-header input)))
    (if parse-result
	(cons (list->string (list-ref (car parse-result) 2)) (cdr parse-result))
	#f)))

(define type-body (many (any-but (char #\}))))
(define (match-type-body input)
  (let ((parse-result (type-body input)))
    (if parse-result
	(cons (list->string (car parse-result)) (cdr parse-result))
	#f)))

(define match-interface (seq match-interface-header match-type-body))
(define match-interfaces (many (either match-interface (discard (any)))))
;; This is an alist of every interface definition
(define interfaces (filter (lambda (x) (not (null? x))) (car (match-interfaces schema-text))))

;; Replace expansions
(map (lambda (obj)
       (let ((body-segment (js-invoke ;; This is a bit crap, it doesn't handle indentation correctly
			    (car (cdr obj))
			    "trim")))
	 (set! schema-text
	   (regexp-replace-all
	    (string->regexp (format "[\ \t]...~a" (car obj)))
	    schema-text
	    body-segment))))
     interfaces)

;; Write to a file
(js-invoke fs "writeFileSync" (output-file) schema-text)

