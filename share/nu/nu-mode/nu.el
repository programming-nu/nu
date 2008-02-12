;;; nu.el --- Nu editing mode

;; This code is written by Victor M. Rodriguez R. and placed in the
;; Public Domain.  All warranties are disclaimed.

;;; Commentary:

;; The major mode for editing Nu code.  Based almost on its entirety
;; on Scheme mode.
;;
;; This mode is very simple, providing only syntax highlighting and
;; indentation.  Nonetheless, since it is derived from lisp-mode it
;; inherits all of Emacs' ability for editing Lisp code.
;;
;; To install, add this to you .emacs file after adding `nu.el' to
;; /some/path:
;;
;;     (add-to-list 'load-path "/some/path")
;;     (require 'nu)
;;     
;;
;; Please note that this code has been tested Aquamacs 1.0b and
;; GNU Emacs 22.1.1.
;;
;; Forward questions, comments, bug reports, patches, etc. to victorr
;; at gmail.com.

;;; History:

;; 2008-02-11 Aleksander Skobelev
;;    - Added modify-syntax-entry for ?\\ character to fix font
;;      locking in strings like "\"#{x}\"";
;;    - scheme-mode-hook replaced with nu-mode-hook;
;;    - added (autoload run-nush...);
;;            
;; 2007-10-06 Initial ALPHA release.

;;; Code:

(require 'lisp-mode)

(autoload 'run-nush "nush" "Run an inferior Nush process." t)

(defconst nu-version "2008-02-11"
  "Nu Mode version number.")


(defvar nu-mode-syntax-table
  (let ((st (make-syntax-table))
        (i 0))

    ;; Default is atom-constituent.
    (while (< i 256)
      (modify-syntax-entry i "_   " st)
      (setq i (1+ i)))

    ;; Word components.
    ;; 0-9
    (setq i ?0)
    (while (<= i ?9)
      (modify-syntax-entry i "w   " st)
      (setq i (1+ i)))
    ;; A-Z
    (setq i ?A)
    (while (<= i ?Z)
      (modify-syntax-entry i "w   " st)
      (setq i (1+ i)))
    ;; a-z
    (setq i ?a)
    (while (<= i ?z)
      (modify-syntax-entry i "w   " st)
      (setq i (1+ i)))

    ;; Whitespace
    (modify-syntax-entry ?\t "    " st)
    (modify-syntax-entry ?\n ">   " st)
    (modify-syntax-entry ?\f "    " st)
    (modify-syntax-entry ?\r "    " st)
    (modify-syntax-entry ?\s "    " st)

    ;; Strings
    (modify-syntax-entry ?\" "\"   " st)

    ;; Parenthesis
    (modify-syntax-entry ?\( "()  " st)
    (modify-syntax-entry ?\) ")(  " st)
    
    ;; Comments
    (modify-syntax-entry ?\; "<   " st)
    (modify-syntax-entry ?\# "<   " st)

    ;; Strings
    (modify-syntax-entry ?' "'   " st)

    ;; Symbols
    (modify-syntax-entry ?' "'   " st)
    (modify-syntax-entry ?\\ "\\   " st)
    
    st)
  "Syntax table for Nu mode.")

(defun nu-mode-variables ()
  (set-syntax-table nu-mode-syntax-table)

  (make-local-variable 'indent-line-function)
  (setq indent-line-function 'lisp-indent-line)

  (set (make-local-variable 'font-lock-defaults)
       '((nu-font-lock-keywords)
         nil t (("+-*/.<>=!?$%_&~^:" . "w"))))

  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t)

  (make-local-variable 'outline-regexp)
  (setq outline-regexp ";;; \\|(....")

  (make-local-variable 'comment-start)
  (setq comment-start ";")

  (set (make-local-variable 'comment-add) 1)

  (make-local-variable 'comment-column)
  (setq comment-column 40)

  (make-local-variable 'parse-sexp-ignore-comments)
  (setq parse-sexp-ignore-comments t))

(defvar nu-mode-map
  (let ((smap (make-sparse-keymap))
        (map  (make-sparse-keymap "Nu")))

    (set-keymap-parent smap lisp-mode-shared-map)
    (define-key smap [menu-bar nu] (cons "Nu" map))
    (define-key map [run-nush] '("Run Inferior Nush" . run-nush))
    (define-key map [uncomment-region]
      '("Uncomment Out Region" . (lambda (beg end)
                                   (interactive "r")
                                   (comment-region beg end '(4)))))
    (define-key map [comment-region] '("Comment Out Region" . comment-region))
    (define-key map [indent-region] '("Indent Region" . indent-region))
    (define-key map [indent-line] '("Indent Line" . lisp-indent-line))
    (put 'comment-region 'menu-enable 'mark-active)
    (put 'uncomment-region 'menu-enable 'mark-active)
    (put 'indent-region 'menu-enable 'mark-active)
    smap)
  "Keymap for Nu mode.")

;;;###autoload
(defun nu-mode ()
  "Major mode for editing Nu code.
Rest of the documentation goes here."
  (interactive)
  (kill-all-local-variables)
  (use-local-map nu-mode-map)
  (setq major-mode 'nu-mode)
  (setq mode-name "Nu")
  (nu-mode-variables)
  (run-mode-hooks 'nu-mode-hook))

(defgroup nu nil
  "Editing Nu code."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :group 'lisp)

(defcustom nu-mode-hook nil
  "Normal hook run when entering `nu-mode'.
See `run-hooks'."
  :type 'hook
  :group 'nu)

;; Soon, hopefully
;; (defcustom nush-program-name "nush"
;;   "*Program invoked by the `run-nush' command."
;;   :type 'string
;;   :group 'nu)

(defconst nu-font-lock-keywords-1
  (list
   (cons (concat
          ;; "("
          "\\<"
          (regexp-opt
           '( ;; Assignment Operators
             "set" "global" "let" "+" "-" "+"
             ;; Arithmetic and Logical Operators
             "+" "-" "*" "/"
             "&" "|"
             ">" "<" ">=" "<=" "==" "!=" "eq"
             "<<" ">>"
             "and" "or" "not"
             ;; List Processing Operators
             "list" "cons" "car" "head" "cdr" "tail" "nil"
             ;; Evaluation Operators
             "quote" "eval" "parse" "context"
	     
             ;; Conditional Operators
             "cond" "case" "if" "then" "else" "unless"

             ;; Looping Operators
             "while" "until" "for" "break" "continue"

             ;; Sequencing Operators
             "progn" "send"

             ;; Function and Macros
             "function" "do" "macro"

             ;; Classes and Methods
             "class" "imethod" "cmethod" "ivar" "ivar-accessors" "is"

             ;; Exception Handling Operators
             "try" "catch" "throw"

             ;; Thread Control Operators
             "synchronized"

             ;; System Operators
             "load" "system"
             ) t)
          "\\>")
         'font-lock-keyword-face)
   (cons (concat
          ;; "("
          "\\<"
          (regexp-opt
           '( ;; System Operators
             "help" "version" "beep"
             ) t)
          "\\>")
         'font-lock-warning-face)
   (cons (concat
          ;; "("
          "\\<"
          (regexp-opt
           '( ;; Types
             "void" "id" "int" "BOOL" "double" "float" "NSRect" "NSPoint" 
             "NSSize" "NSRange" "SEL" "Class"
             ) t)
          "\\>")
         'font-lock-type-face)
   )
  "Expressions to highlight in Nu mode.")

(defvar nu-font-lock-keywords nu-font-lock-keywords-1
  "Default expressions to highlight in Nu mode.")

(put 'function     'lisp-indent-function 'defun)
(put 'do           'lisp-indent-function 1)
(put 'if           'lisp-indent-function 0)
(put 'then         'lisp-indent-function 0)
(put 'else         'lisp-indent-function 0)
(put 'unless       'lisp-indent-function 1)
(put 'while        'lisp-indent-function 1)
(put 'until        'lisp-indent-function 1)
(put 'for          'lisp-indent-function 1)
(put 'macro        'lisp-indent-function 1)
(put 'synchronized 'lisp-indent-function 1)




(add-to-list 'auto-mode-alist '("\\.nu\\'" . nu-mode))

(provide 'nu)

;;; nu.el ends here
