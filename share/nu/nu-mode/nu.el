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
;; 2008-03-22 Aleksandr Skobelev
;;    - Updated 'heredoc' strings handling; added NU-FIND-TAG-DEFAULT function to
;;      correctly select method keywords in FIND-TAG command
;;
;; 2008-03-16 Aleksandr Skobelev
;;    - Added support for 'heredoc' strings (based on font-lock-syntactic-keywords);
;;      more font-lock keywords; keywords are indented by column now.
;;
;; 2008-03-11 Aleksandr Skobelev
;;    - Added functions nu-indent-sexp, nu-indent-line to provide better
;;      indentation for keywords (they are aligned by colon now) and bodies
;;      of class and method definitions
;; 
;; 2008-02-11 Aleksandr Skobelev
;;    - Added modify-syntax-entry for ?\\ character to fix font
;;      locking in strings like "\"#{x}\"";
;;    - scheme-mode-hook replaced with nu-mode-hook;
;;    - added (autoload run-nush...);
;;            
;; 2007-10-06 Initial ALPHA release.

;;; Code:

(require 'lisp-mode)

(autoload 'run-nush "nush" "Run an inferior Nush process." t)

(defconst nu-version "2008-03-21"
  "Nu Mode version number.")

(defgroup nu nil
  "Editing Nu code."
  :link '(custom-group-link :tag "Font Lock Faces group" font-lock-faces)
  :group 'lisp)

(defcustom nu-mode-hook nil
  "Normal hook run when entering `nu-mode'.
See `run-hooks'."
  :type 'hook
  :group 'nu)

(defcustom nu-body-indent 4
  "Like the LISP_BODY_INDENT variable this one sets number of columns to indent the second line of various form."
  :type 'number
  :group 'nu)

(defcustom nu-keys-indent 4
  "Number of columns to indent method keywords and arguments."
  :type 'number
  :group 'nu)

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


(defun set-local (var val) (set (make-local-variable var) val))

(defvar nu-heredoc-beg-re "<<[+-]\\(\\(?:\\w\\|\\s_\\)+\\)\\(\n\\)?")
;;                                 1                        2
(defvar nu-heredoc-re
  "<<[+-]\\(\\(?:\\w\\|\\s_\\)+?\\)\\(?:\\(?:\\(\n\\)\\(\n\\|\\([][{}\"#()?]\\)\\|.\\)+?\\)\\|\\(?:\n\\)\\)\\(\\1\\>\\)")
;;         1                                   2       3       4                                             5
                      

(defun nu-mode-variables ()

  (set-syntax-table nu-mode-syntax-table)

  (set-local 'parse-sexp-lookup-properties t)
  (set-local 'parse-sexp-ignore-comments t)
  (set-local 'forward-sexp-function 'nu-forward-sexp)
  (set-local 'lisp-indent-function 'nu-indent-line)
  (set-local 'indent-line-function 'lisp-indent-line)
  (set-local 'find-tag-default-function 'nu-find-tag-default)
  (set-local 'font-lock-multiline t)
  (set-local 'font-lock-defaults
             `((nu-font-lock-keywords)
               nil
               nil
               (("+-*/.<>=!?@$%_&~^:" . "w"))
               beginning-of-defun
               (font-lock-syntactic-keywords . ((,nu-heredoc-re (2 "|" t t)
                                                                (4 "." keep t)
                                                                (3 "|" t t))
                                                
                                                ;(,nu-heredoc-beg-re (2 "|" t t))
                                                ))
               ))
  
  (set-local 'outline-regexp ";;; \\|(....")

  (set-local 'comment-start  ";")
  (set-local 'comment-add    1)
  (set-local 'comment-column 40))


(defvar nu-mode-map

  (let ((smap (make-sparse-keymap))
        (map  (make-sparse-keymap "Nu")))

    (set-keymap-parent smap lisp-mode-shared-map)
    (define-key smap "\e\C-q" 'nu-indent-sexp)
    (define-key smap [menu-bar nu] (cons "Nu" map))
    (define-key map [run-nush] '("Run Inferior Nush" . run-nush))
    (define-key map [uncomment-region]
      '("Uncomment Out Region" . (lambda (beg end)
                                   (interactive "r")
                                   (comment-region beg end '(4)))))
    (define-key map [comment-region] '("Comment Out Region" . comment-region))
    (define-key map [indent-region] '("Indent Region" . indent-region))
    (define-key map [indent-line] '("Indent Line" . lisp-indent-line))

    (put 'comment-region   'menu-enable 'mark-active)
    (put 'uncomment-region 'menu-enable 'mark-active)
    (put 'indent-region    'menu-enable 'mark-active)
    
    smap)
  
  "Keymap for Nu mode.")


;;;###autoload
(defun nu-mode ()
  "Major mode for editing Nu code.
\\{nu-mode-map}."
  (interactive)
  (kill-all-local-variables)
  (use-local-map nu-mode-map)
  (setq major-mode 'nu-mode)
  (setq mode-name "Nu")
  (nu-mode-variables)
  (run-mode-hooks 'nu-mode-hook))



(defconst nu-font-lock-keywords-1
  (list
    
    (cons (concat
           ;; "("
           "\\<"
           (regexp-opt
            '( ;; Assignment Operators
              "set" "global" "let"
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
              "class" "imethod" "cmethod" "ivar" "ivars" "ivar-accessors" "is" "self" "super"

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

    ;; FUNCIONS
    '("^\\s *(\\s *\\(function\\|macro\\)\\s +\\([^( \t\n]+\\)"
      2 font-lock-function-name-face keep)
    '("(\\s *\\(set\\|global\\)[ \t\n]+\\(\\(\\w\\|\\s_\\)+\\)[ \t\n]\\([ \t\n]*\\([;#].*[\n]\\)*[ \t\n]*\\)(\\(NuBridgedFunction\\|do\\)\\>"
      2 font-lock-function-name-face keep)

    ;; CLASS DECLARATIONS
    `(,(concat
        "^\\s *(\\s *class[ \t]+\\(\\(?:\\w\\|\\s_\\)+\\)"
        "\\(?:"
        "[ \t\n]\\(?:[ \t\n]*\\(?:[;#].*[\n]\\)*[ \t\n]*\\)"
        "is"
        "[ \t\n]\\(?:[ \t\n]*\\(?:[;#].*[\n]\\)*[ \t\n]*\\)"
        "\\(\\(?:\\w\\|\\s_\\)+\\)"
        "\\)?")
      (1 font-lock-type-face keep)
      (2 font-lock-type-face keep t))

    ;; CONSTANTS
    '("\\(\\s +\\b\\|:\\s *\\)\\(NS\\w\\w\\w+\\)"
      2 font-lock-constant-face keep)
    '("\\(\\<\\|:\\)\\([A-Z]\\([A-Z]\\|[_0-9-]\\)+\\)\\>"
      2 font-lock-constant-face keep)

    ;;VARIABLE NAMES
    '("^(\\s *\\(set\\|global\\)\\s +\\(\\(\\w\\|\\s_\\)+\\)"
      2 font-lock-variable-name-face keep)
    '("\\(\\b\\|:\\)\\([@$]\\(\\w\\|\\s_\\)+\\)"
      2 font-lock-variable-name-face keep)
   
    ;; HEREDOC KEYWORDS
    `(,nu-heredoc-re
      (5 font-lock-constant-face prepend))
    `(,nu-heredoc-beg-re (1 font-lock-constant-face prepend))
    '("[\n \t:]\\(<<[+-]\\)" (1 font-lock-keyword-face t))
    )
  "Expressions to highlight in Nu mode.")

(defvar nu-font-lock-keywords nu-font-lock-keywords-1
  "Default expressions to highlight in Nu mode.")

;; NU-FIND-HEREDOC-BACKWARD ----------------------------------------------------
(defun nu-find-heredoc-backward (&optional start bound-min bound-max)
  (interactive)
  
  (unless start (setq start (point)))
  (unless bound-min (setq bound-min (point-min)))
  (unless bound-max (setq bound-max (point-max)))

  (save-excursion

    (goto-char start)
    (unless (eq (char-before) ?\n)
      (skip-chars-forward "^\n")
      (when (< (point) bound-max) (forward-char)))
    
    (and (search-backward-regexp nu-heredoc-beg-re bound-min t)
         (<= (match-beginning 0) start)
         (looking-at nu-heredoc-re))

    ;;     (when (and (search-backward-regexp nu-heredoc-beg-re bound-min t)
    ;;                (<= (match-beginning 0) start))
    ;;       (let ((start (match-beginning 0)))
    ;;         (when (search-forward-regexp (concat (match-string 1) "\\>") bound-max t)
    ;;           (goto-char start)
    ;;           (looking-at nu-heredoc-re)))

    ))

;; ;; NU-FIND-HEREDOC-FORWARD -----------------------------------------------------
;; (defun nu-find-heredoc-forward (&optional start bound)
;;   (interactive)
  
;;   (unless start (setq start (point)))
;;   (unless bound (setq bound (point-max)))
;;   (save-excursion
;;     (goto-char start)
;;     (search-forward-regexp nu-heredoc-re bound t)))


(defvar nu-forward-sexp-level 0)

;; NU-FORWARD-SEXP1 -----------------------------------------------------------
(defun nu-forward-sexp1 ()
  (interactive "p")

;;   (message (format "nu-forward-sexp1 point = %d" (point)))

  (skip-chars-forward "[ \t\n]")

  (let ((pos (point))
        (level nu-forward-sexp-level))
    
    (save-match-data
      (cond
       ((and (nu-find-heredoc-backward pos)
             (< pos (match-end 0)))
        
        (goto-char (match-end 0)))

       ((looking-at "\\w\\|\\s_")
        
        (while (and (not (eq (char-after) ?:))
                    (looking-at "\\w\\|\\s_"))
          (forward-char))
        (if (eq (char-after) ?:) (forward-char)))
       
       (t
        (progn
          (let ((state (syntax-ppss)))
            (cond
             ((and (looking-at "(") (not (nth 3 state)))
              (forward-char)
              (skip-chars-forward "[ \t\n]")
              (incf nu-forward-sexp-level)
              (while (< level nu-forward-sexp-level) (nu-forward-sexp1)))

             ((and (looking-at ")") (not (nth 3 state)))
              (forward-char)
              (decf nu-forward-sexp-level))
            
             (t (let ((forward-sexp-function nil))
                  (forward-sexp 1)))))))))

    ))

;; NU-BACKWARD-SEXP1 -----------------------------------------------------------
(defun nu-backward-sexp1 ()
  (interactive "p")

  ;; (message (format "nu-backward-sexp1 point = %d" (point)))

  (skip-chars-backward "[ \t\n]")
;;   (while (member (char-before) '(32 ?\t ?\n))
;;     (backward-char))

  (let ((pos (point)))
    
    (save-match-data
      (if (and (nu-find-heredoc-backward pos)
               (>  pos (match-beginning 0))
               (<= pos (match-end 0)))
          
          (goto-char (match-beginning 0))

          ;;else
          (if (member (char-syntax (char-before)) '(?w ?_))
              (progn
                (while
                    (progn
                      (backward-char)
                      (and (not (eq (char-before) ?:))
                           (member (char-syntax (char-before)) '(?w ?_)) ))))
              ;;else 
              (let ((forward-sexp-function nil))
                (backward-sexp 1)))))))


;; FORWARD-SEXP ----------------------------------------------------------------
(defun nu-forward-sexp (&optional arg)
  (interactive "p")

  (setq nu-forward-sexp-level 0)
  (unless arg (setq arg 1))

;;   (message (format "nu-forward-sexp point = %d arg = %d" (point) arg))
  (while (< arg 0)
    (incf arg)
    (nu-backward-sexp1))

  (while (> arg 0)
    (decf arg)
    (nu-forward-sexp1)))


;; (defadvice nu-indent-line (after print-indent)
;;   (save-excursion
;;     (back-to-indentation)
;;     (message (format "line: %d  indent: %d" (line-number-at-pos) (current-column)))))


;; NU-INDENT-FUNCTION ----------------------------------------------------------
(defun nu-indent-line (indent-point state)

  (if (save-excursion
        (goto-char indent-point)
        (and (nu-find-heredoc-backward (point))
             (> (point) (match-beginning 0))
             (< (point) (match-end 0))))
      (progn
        (goto-char indent-point)
        (back-to-indentation)
        (current-column))
  
      (let ((lisp-body-indent nu-body-indent))
        (let ((lisp-indent (lisp-indent-function indent-point state)))
          
          ;;       (message (format "lisp-indent: %s indent-point: %s state: %s"
          ;;                        lisp-indent indent-point state))
  
          (unless (or (elt state 3)     ;inside string
                      (elt state 4)     ;inside comment
                      (progn (goto-char indent-point)
                             (looking-at "[ \t]*\\($\\|)\\)")))
    
            (save-excursion
        
              (let* ((list-beg (elt state 1))
                     (list-beg-col (progn
                                     (goto-char list-beg)
                                     (current-column)))
               
                     (first-sexp-end (progn
                                       (goto-char (+ list-beg 1))
                                       (nu-forward-sexp)
                                       (point)))
               
                     (first-sexp-beg (progn
                                       (goto-char first-sexp-end)
                                       (backward-sexp)
                                       (point)))
               
                     (first-sexp-str (buffer-substring-no-properties first-sexp-beg
                                                                     first-sexp-end))
                     (prev-sexp-beg  (elt state 2))

                     (prev-sexp-end (progn
                                      (goto-char prev-sexp-beg)
                                      (nu-forward-sexp)
                                      (point)))

                     (prev-sexp-str (buffer-substring-no-properties prev-sexp-beg
                                                                    prev-sexp-end))
               
                     (prev-sexp-col (progn
                                      (goto-char prev-sexp-beg)
                                      (current-column)))
               
                     (prev-sexp-end-col (progn
                                          (goto-char prev-sexp-end)
                                          (current-column)))
               
                     (cur-sexp-beg (progn
                                     (goto-char indent-point)
                                     (back-to-indentation)
                                     (point)))

                     (cur-sexp-end (progn
                                     (goto-char indent-point)
                                     (nu-forward-sexp)
                                     (point)))
               
                     (cur-sexp-col (progn
                                     (goto-char cur-sexp-beg)
                                     (current-column)))
             
                     (cur-sexp-end-col (progn
                                         (goto-char cur-sexp-end)
                                         (current-column)))

                     (cur-sexp-str (buffer-substring-no-properties cur-sexp-beg
                                                                   cur-sexp-end))

                     (cur-sexp-keyword-p (eq ?: (char-before cur-sexp-end)))
                     (colon-col 0))

                ;; if lisp-indent is not nil, redefine it only, if the first item in
                ;; the list is a list
                (when (or (not lisp-indent)
                          (eq (char-after first-sexp-beg) 40 ))
        
                  (goto-char first-sexp-beg)

                  ;; find colon column
                  (while (< (point) prev-sexp-end)
                    (nu-forward-sexp)
                    (when (eq ?: (char-before))
                      (setq colon-col (current-column))
                      (goto-char prev-sexp-end)))

                  ;; calclate indent
                  (setq lisp-indent
                        (cond
                         ;;indent the first method keyword
                         ((and (zerop colon-col) cur-sexp-keyword-p)
                          (+ list-beg-col nu-keys-indent))

                         ;; indent the body of class and class method definitions
                         ((or (string= first-sexp-str "class")
                              (and (or (string= cur-sexp-str "is")
                                       (string= prev-sexp-str "is"))
                               
                                   (or (string= first-sexp-str "imethod")
                                       (string= first-sexp-str "cmethod")
                                       ;; in fact, + and - require more strict check as it can be
                                       ;; aritmetic operators
                                       ;; here I just hope nobody use IS as the name of variable
                                       (string= first-sexp-str "-")
                                       (string= first-sexp-str "+"))))
                  
                          (+ list-beg-col nu-body-indent))

                         ;; indent method keyword's arguments
                         ((and (< 0 colon-col) (not cur-sexp-keyword-p))
                          (if (= colon-col prev-sexp-end-col)
                              (+ prev-sexp-col nu-keys-indent)
                              prev-sexp-col))

                         ;; indent method keyword other than the first one 
                         ((and (< 0 colon-col) cur-sexp-keyword-p)
                          (- colon-col (- cur-sexp-end-col cur-sexp-col)))))
                  )))
    
            lisp-indent)))))


;; NU-INDENT-SEXP --------------------------------------------------------------
(defun nu-indent-sexp  ()
  "Indent each line of the list starting just after point."
  
  (interactive)
  (save-excursion
    (let* ((pos (point))
           (sexp-end  (progn
                        (forward-sexp)
                        (point)))
           (sexp-beg (progn
                       (backward-sexp)
                       (point))))
;      (message (format "indent: %S %S" sexp-beg sexp-end))
      (indent-region sexp-beg sexp-end)))
  )

;; NU-NEWLINE ------------------------------------------------------------------
(defun nu-newline (&optional arg)
  (let ((bol (save-excursion (beginning-of-line))))
    (newline arg)
    (let ((pos (point)))
      (save-match-data
        (when (save-excursion
                (search-backward-regexp nu-heredoc-beg-re bol t))
          (goto-char pos)
          (insert (match-string 1)) )))))


;; NU-FIND-TAG-DEFAULT ---------------------------------------------------------
(defun nu-find-tag-default ()
  "Determine default tag to search for, based on text at point.
If there is no plausible default, return nil."
  (save-excursion
    (when (looking-at "\\sw\\|\\s_")
      (forward-sexp 1))
    (if (or (re-search-backward "\\sw\\|\\s_"
                                (save-excursion (beginning-of-line) (point))
                                t)
            (re-search-forward "\\(\\sw\\|\\s_\\)+"
                               (save-excursion (end-of-line) (point))
                               t))
        (progn
          (goto-char (match-end 0))
          (condition-case nil
              (buffer-substring-no-properties
               (point)
               (progn (forward-sexp -1)
                      (while (looking-at "\\s'")
                        (forward-char 1))
                      (point)))
            (error nil)))
        nil)))


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
(put 'set          'lisp-indent-function 0)
(put 'list         'lisp-indent-function 0)
(put 'car          'lisp-indent-function 0)
(put 'cdr          'lisp-indent-function 0)

;; NU-SETUP-HEREDOC-FACES ------------------------------------------------------
;; force font locking (and so setting proper syntax) for 'heredoc' strings
(defun nu-setup-heredoc-faces ()
  (save-excursion
    (goto-char (point-min))
    
    (while (search-forward-regexp nu-heredoc-re (point-max) 'return-nil)

      (let ((beg (match-beginning 0))
            (end (match-end 0)))

        (goto-char (- beg (current-column)))
        (font-lock-fontify-region (point) end)
        (goto-char end)))))


(add-hook 'nu-mode-hook 'nu-setup-heredoc-faces)

(add-to-list 'auto-mode-alist '("\\.nu\\'" . nu-mode))
(add-to-list 'auto-mode-alist '("Nukefile\\'" . nu-mode))
(add-to-list 'interpreter-mode-alist '("nush". nu-mode))

(provide 'nu)
;;; nu.el ends here
