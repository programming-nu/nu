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
;; 2009-09-13 Aleksandr Skobelev
;;    - added (c-subword-mode t)
;;
;; 2008-09-16 Aleksandr Skobelev
;;    - added (required 'cl)
;;
;; 2008-07-13 Aleksandr Skobelev
;;    - added import keyword
;;    - updated nu-indent-line to better handle lists with regexp as the first element
;;
;; 2008-04-04 Aleksandr Skobelev
;;    - fixed bug in NU-FORWARD-SEXP1 and NU-BACKWARD-SEXP1 with skipping closing parens
;;      and made them more PAREDIT compatible (signal an error on list bounds);
;;      fixed positioning of the cursur on empty line;
;;      changed NU-DEFUN-RE for SET form;
;;
;; 2008-04-03 Aleksandr Skobelev
;;    - added support for character syntax; rewrote and optimized indentation and
;;      navigation functionality
;; 
;; 2008-03-31 Aleksandr Skobelev
;;    - added functions NU-BEGINNING-OF-DEFUN, NU-END-OF-DEFUN, rewrote
;;      NU-FORWARD-SEXP1, NU-BACKWARD-SEXP1; added support for regexps 
;;
;; 2008-03-27 Aleksandr Skobelev
;;    - optimized NU-FIND-HEREDOCS-RANGES, NU-FIND-HEREDOCS-RANGES-IN-RANGE,
;;      NU-CUT-HEREDOCS-RANGES
;;
;; 2008-03-25 Aleksandr Skobelev
;;    - Changed NU-FIND-HEREDOCS-RANGES; added NU-HEREDOCS-RANGES variable,
;;      NU-KNOWN-HEREDOC-RANGE-STARTING-BEFORE, NU-FIND-HEREDOCS-RANGES,
;;      NU-CUT-HEREDOCS-RANGES, NU-HEREDOCS-RANGES-SPLIT functions
;;
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

(require 'cl)
(require 'lisp-mode)

(autoload 'run-nush "nush" "Run an inferior Nush process." t)
(autoload 'switch-to-nush "nush" "Switch to an inferior Nush process." t)

(defconst nu-version "2009-09-11"
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

(defcustom nu-align-by-first-colon t
  "If not NIL, then method keywords will be right-aligned to the first keyword colon, otherwise – to the previous one."
  :type 'boolen
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
  "<<[+-]\\(\\(?:\\w\\|\\s_\\)+?\\)\\(?:\\(?:\\(\n\\)\\(\n\\|\\([][{}\"#()?]\\)\\|\\(/\\)\\|.\\)+?\\)\\|\\(?:\n\\)\\)\\(\\1\\>\\)")
;;         1                                   2       3       4                    5                                  6
                      
(defvar nu-regexp-root-re "\\(/\\)\\(?:[^ \t\n\\]\\|\\(?:[^ \t\n].*?[^\\]\\)\\)?\\(/\\)")
(defvar nu-regexp-sfx-re "\\([isxlm]\\{0,5\\}\\(\\W\\)\\)")
(defvar nu-regexp-re (concat nu-regexp-root-re nu-regexp-sfx-re))

(defvar nu-char-re "\\('\\)\\(?:\\\\\\(?:['\\\\]\\|[0-7]\\{3\\}\\|x[0-9a-fA-F]\\{2\\}\\|u[0-9a-fA-F]\\{4\\}\\)\\|\\\\?[^'\\\\xu]\\)\\('\\)")

(defvar nu-defun-re "\\(^(set\\s +[$]\\w\\)\\|\\(^\\s *(\\(global\\|class\\|macro\\|function\\)\\>\\)")


;(defun nu-regex-syntax )

(defun nu-mode-variables ()

  (set-syntax-table nu-mode-syntax-table)

  (make-local-variable 'after-change-functions)
  (push 'nu-after-change after-change-functions)

  (set-local 'max-lisp-eval-depth 600)
  (set-local 'nu-heredocs-ranges nil)
  (set-local 'parse-sexp-lookup-properties t)
  (set-local 'parse-sexp-ignore-comments t)
  (set-local 'forward-sexp-function 'nu-forward-sexp)
  (set-local 'lisp-indent-function 'nu-indent-line)
  (set-local 'indent-region-function 'nu-indent-region)
  (set-local 'indent-line-function 'nu-lisp-indent-line)

  (set-local 'beginning-of-defun-function 'nu-beginning-of-defun)
  (set-local 'end-of-defun-function 'nu-end-of-defun)

  (set-local 'find-tag-default-function 'nu-find-tag-default)
  (set-local 'font-lock-multiline t)
  (set-local 'font-lock-defaults
             `((nu-font-lock-keywords)
               nil
               nil
               (("+-*/.<>=!?@$%_&~^:" . "w"))
               nu-beginning-of-syntax
               (font-lock-syntactic-keywords . ((,nu-heredoc-re (2 "|" t t) (3 "|" t t) (4 "_" t t) (5 "w" t t) )
                                                (,nu-regexp-re (1 "\"" keep t) (2 "\"" keep t))
                                                (,nu-char-re (1 "\"" keep t) (2 "\"" keep t))))
               ))
  
  (set-local 'outline-regexp ";;; \\|(....")

  (set-local 'comment-start  ";")
  (set-local 'comment-add    1)
  (set-local 'comment-column 40))


(defvar nu-mode-map

  (let ((smap (make-sparse-keymap))
        (map  (make-sparse-keymap "Nu")))

    (set-keymap-parent smap lisp-mode-shared-map)
    (define-key smap "\C-c\C-z" 'switch-to-nush)
    (define-key smap "\e\C-q" 'nu-indent-sexp)
    (define-key smap "\t" 'nu-lisp-indent-line)
    (define-key smap [menu-bar nu] (cons "Nu" map))
    (define-key map [switch-to-nush] '("Switch to Nush" . switch-to-nush))
    (define-key map [run-nush] '("Run Inferior Nush" . run-nush))
    (define-key map [uncomment-region]
      '("Uncomment Out Region" . (lambda (beg end)
                                   (interactive "r")
                                   (comment-region beg end '(4)))))
    (define-key map [comment-region] '("Comment Out Region" . comment-region))
    (define-key map [indent-region] '("Indent Region" . indent-region))
     (define-key map [indent-line] '("Indent Line" . nu-lisp-indent-line))

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
  (c-subword-mode t)
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
              "load" "system" "import"
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

    '("(\\s *\\(set\\|global\\)[ \t\n]+\\(\\(\\w\\|\\s_\\)+\\)[ \t\n]\\([ \t\n]*\\([;#].*[\n]\\)*[ \t\n]*\\)(NuBridgedConstant\\>"
      2 font-lock-constant-face keep)
    
    ;;VARIABLE NAMES
    '("^(\\s *\\(set\\|global\\)\\s +\\(\\(\\w\\|\\s_\\)+\\)"
      2 font-lock-variable-name-face keep)
    '("\\(\\b\\|:\\)\\([@$]\\(\\w\\|\\s_\\)+\\)"
      2 font-lock-variable-name-face keep)
   
    ;; HEREDOC KEYWORDS
    `(,nu-heredoc-re
      (6 font-lock-constant-face ))
    `(,nu-heredoc-beg-re (1 font-lock-constant-face ))
    '("[\n \t:]\\(<<[+-]\\)" (1 font-lock-keyword-face ))

    ;; REGEXP KEYWORDS
    `(,nu-regexp-re
      (3 font-lock-constant-face t))
    )
  "Expressions to highlight in Nu mode.")

(defvar nu-font-lock-keywords nu-font-lock-keywords-1
  "Default expressions to highlight in Nu mode.")

(defvar nu-heredocs-ranges (list '(0 . 0))
  "List of cached ranges for heredoc strings. Every range is in (BEGIN . END) form.")

;; (defsubst nu-syntax-ppss (&optional pos)
;;   (let ((beginning-of-defun-function nil)) (synax-ppss pos)))

;; NU-CUT-POINT ----------------------------------------------------------------
(defsubst nu-cut-point () (or (cdar (last nu-heredocs-ranges)) (point-min)))

;; NU-EMPTY-RANGE --------------------------------------------------------------
(defsubst nu-empty-range-p (range) (or (null range) (= (car range) (cdr range))))

;; NU-IN-RANGE -----------------------------------------------------------------
(defsubst nu-in-range-p (point range)
  (and range (>= point (car range)) (< point (cdr range))))

;; NU-LAST-RANGE ---------------------------------------------------------------
(defsubst nu-last-range () (car (last nu-heredocs-ranges)))

;; NU-CUT-HEREDOCS-RANGES ----------------------------------------------------
(defun nu-cut-heredocs-ranges (point)
  (let (ranges)
    (do* ((rest nu-heredocs-ranges (cdr rest))
          (range (car nu-heredocs-ranges) (car rest)))
        
        ;; Exit if list is empty or range below point
        ((or (null rest)
             (< point (cdr range)))
         
         ;; if the point is in non-empty range than set point to the point
         ;; before the range
         (cond ((null rest) (setq point nil))
               ((>= point (car range)) (setq point (1- (car range))))))
      
      (push range ranges))
    
;;     ;; remove marker range if exists
;;     (when (nu-empty-range-p (first ranges)) (pop ranges))
    
    (when point (push (cons point point) ranges))
    (setq nu-heredocs-ranges (reverse ranges)))
  nu-heredocs-ranges)


;; NU-FIND-HEREDOCS-RANGES ----------------------------------------------------
(defun nu-find-heredocs-ranges-in-range (beg end)
  (save-excursion
    (save-match-data

      ;; remove marker range at the end of NU-HEREDOCS-RANGES
      (when (and nu-heredocs-ranges (nu-empty-range-p (nu-last-range)))
        (setq nu-heredocs-ranges (butlast nu-heredocs-ranges)))
          
      (let (ranges
            range
            (after-end (progn (goto-char end)
                              (beginning-of-line 2)
                              (point))))
        (goto-char beg)

        ;; if end point is in heredoc range add this range
        ;; also reset cut-point
        (while (and (< (point) after-end)
                    (search-forward-regexp nu-heredoc-beg-re after-end  t)
                    (<= (match-beginning 0) end))
          
;;           (message (format "find hdoc beg in (%d %d)--> \"%s\"" beg end (match-string 0)))
          (let ((point (match-end 0)))
            (when (progn (goto-char (match-beginning 0))
                         (looking-at nu-heredoc-re))
              ;; (setq cut-point nil)
;;               (message (format "find full hdoc in (%d %d)--> \"%s\"" beg end (match-string 0)))
              (setq range (cons (match-beginning 0) (match-end 0)))
              (push range ranges)
              (setq point (match-end 0)))
            
            (goto-char point)))
        
;;         ;; if end point is in heredoc range add this range
;;         ;; also reset cut-point
;;         (when (and (search-forward-regexp nu-heredoc-beg-re after-end  t)
;;                    (<= (match-beginning 0) end)
;;                    (progn (goto-char (match-beginning 0))
;;                           (looking-at nu-heredoc-re)))
          
;;           (setq cut-point nil)
;;           (push (cons (match-beginning 0) (match-end 0)) ranges))
        (when (or (not range) (< (cdr range) end)) 
          (push (cons end end) ranges))
        
        (setq nu-heredocs-ranges
              (append nu-heredocs-ranges (reverse ranges))) )))
  nu-heredocs-ranges)

;; NU-FIND-HEREDOCS-RANGES ----------------------------------------------------
(defun nu-find-heredocs-ranges (&optional end-point no-cut)

  (unless end-point (setq end-point (point-max)))
  (unless no-cut (setq nu-heredocs-ranges (list '(0 . 0))))

  (let ((cut-point (nu-cut-point)))
     (when (<= cut-point end-point)
      (nu-find-heredocs-ranges-in-range cut-point end-point)))
  nu-heredocs-ranges)



;; NU-KNOWN-HEREDOC-RANGE-STARTING-BEFORE --------------------------------------
(defun nu-known-heredoc-range-starting-before (point)

  (do* ((rest nu-heredocs-ranges (cdr rest))
        (range (car nu-heredocs-ranges) (car rest))
        prev-range)
      
      ;; Exit if list is empty or point below the range end 
      ((or (nu-empty-range-p range) (< point (cdr range)))
       (if (nu-in-range-p point range)
           range
           prev-range))
    
    (setq prev-range range)))


;; NU-FIND-HEREDOC-BACKWARD ----------------------------------------------------
(defun nu-find-heredoc-backward (&optional point bound-min bound-max)
  
  (unless point (setq point (point)))
  (unless bound-min (setq bound-min (point-min)))
  (unless bound-max (setq bound-max (point-max)))

  ;; (message (format "find backward at %d min: %d max: %d" point bound-min bound-max))
  
  (save-excursion
    (nu-find-heredocs-ranges point 'keep)

    (let ((point (car (nu-known-heredoc-range-starting-before point))))
      (when point
        (goto-char point)
        (looking-at nu-heredoc-re)))))

(defvar nu-forward-sexp-level 0)

;; NU-SKIPS-SPACE-FORWARD ---------------------------------------------------
(defun nu-skip-space-forward (&optional in-clear-state)
  (skip-chars-forward " \t\n")
  
  (let ((state (unless in-clear-state (syntax-ppss))))
    (when (and (not (nth 3 state))
               (or (nth 4 state)
                   (and (char-after)
                        (= (char-syntax (char-after)) ?<))))

      (while (and (progn (beginning-of-line 2)
                         (skip-chars-forward " \t\n")
                         (< (point) (point-max)))
                  (= (char-syntax (char-after)) ?<)))    
      )))


;; NU-SKIP-STRING-FORWARD ------------------------------------------------------
(defun nu-skip-string-forward (dlm)
  (while (progn
           (while (and (< (point) (point-max))
                       (/= (char-after) dlm))
             (forward-char))
           
           (and (> (point) (point-min))
                (= (char-before) ?\\)
                (oddp (- (point)
                         (save-excursion
                           (while (and (> (point) (point-min))
                                       (progn (backward-char) (= (char-before) ?\\))))
                           (point))))))
    (forward-char))
  (forward-char))


;; NU-FORWARD-SEXP1 -----------------------------------------------------------
(defun nu-forward-sexp1 (&optional in-clear-state)
;;   (message (format "NU-FORWARD-SEXP1 -- NU-FORWARD-SEXP-LEVEL = %d" nu-forward-sexp-level))
  ;;(message (format "nu-forward-sexp1: entered at %d and state is %sclear" (point) (if in-clear-state "" "not ")))

  ;; (message (format "nu-forward-sexp1 point = %d" (point)))   
  (nu-skip-space-forward in-clear-state)
  ;; (message (format "nu-forward-sexp1: skipped space to %d" (point)))

  (when (< (point) (point-max))
    (let ((pos (point))
          (level nu-forward-sexp-level))

      (save-match-data
        (if (and (nu-find-heredoc-backward pos)
                 (< pos (match-end 0)))
            
            (goto-char (match-end 0))

            
            (let ((state (unless in-clear-state (syntax-ppss))))
              (if (nth 3 state)
                  (progn
                    (nu-skip-string-forward (nth 3 state))
                    ;;(message (format "nu-forward-sexp1: skipped string to %d" (point)))
                    )

                  (let ((ch (char-after)))
                    (cond               ; not in string
                     
                     ((= ch ?\()
                      (while (progn
                               (incf nu-forward-sexp-level)
                               (forward-char)
                               (and (< (point) (point-max))
                                    (looking-at "[ \t]*(")))
                        (skip-chars-forward " \t"))
                      
;;                       (incf nu-forward-sexp-level)
                      (while (and (< (point) (point-max))
                                  (< level nu-forward-sexp-level)) (nu-forward-sexp1 'in-clear-state)))
                     
                     ((= ch ?\))
                      (cond ((< 0 nu-forward-sexp-level)
                             (decf nu-forward-sexp-level)
                             (forward-char))
                            ;; else signal a proper 'scan-error to satisfy paredit 
                            (t (let ((forward-sexp-function nil)) (forward-sexp)))))
                     
                     ((when (or (= ch ?\")
                                (and (= ch ?') (looking-at nu-char-re))
                                (and (= ch ?/) (looking-at nu-regexp-re)))
                        (forward-char)
                        (nu-skip-string-forward (char-before))
                        ;;(message (format "nu-forward-sexp1: skipped string from the beginning to %d" (point)))
                        t))
               
                     ((= ch ?\') (forward-char)
                      ;;(message (format "down in list at %d" (point)))
                      )

                     ((member (char-syntax ch) '(?w ?_))
                      (while (and (/= ch ?:)
                                  (member (char-syntax ch) '(?w ?_)))
                        (forward-char)
                        (setq ch (char-after)))
                
                      (if (= ch ?:) (forward-char)))
               

                     (t
                      ;;(message (format "Unknown state to go forward at point %s : %s" (point) state))
                      (when (< (point) (point-max))
                        (forward-char)
                        (nu-forward-sexp1)) ))))))))))


;; NU-SKIP-SPACE-BACKWARD ---------------------------------------------------
(defun nu-skip-space-backward ()

  (while (and (> (point) (point-min))
              (skip-chars-backward " \t\n")
              (let ((state (syntax-ppss))) (and (not (nth 3 state))
                                                (nth 4 state))))
    (skip-chars-backward "^;#")
    (skip-chars-backward ";#")))



;;------------------------------------------------------------------------------
(defun nu-skip-string-backward (dlm)
  (while (progn
           (while (and (> (point) (point-min))
                       (/= (char-before) dlm))
             (backward-char))
           (backward-char)
           (and (> (point) (point-min))
                (= (char-before) ?\\)
                (oddp (- (point)
                         (save-excursion
                           (while (and (> (point) (point-min))
                                       (progn (backward-char)
                                              (= (char-before) ?\\))))
                           (point))))))
   ))

;; NU-BACKWARD-SEXP1 -----------------------------------------------------------
(defun nu-backward-sexp1 ()
;;   (message (format "NU-BACKWARD-SEXP1 -- NU-FORWARD-SEXP-LEVEL = %d MAX-LISP-EVAL-DEPTH = %d"
;;                    nu-forward-sexp-level
;;                    max-lisp-eval-depth))

  ;; (message (format "nu-backward-sexp1 point = %d" (point)))
  (nu-skip-space-backward)

  (when (> (point) (point-min))
    (let ((pos (point))
          (level nu-forward-sexp-level))

      (save-match-data
        (if (and (nu-find-heredoc-backward pos)
                 (> pos (match-beginning 0))
                 (<= pos (match-end 0)))

            (goto-char (match-beginning 0))
          
            (let* ((state (syntax-ppss))
                   (cb (char-before)))
              
              (if (nth 3 state)
                  
                  (nu-skip-string-backward (nth 3 state))

                  (cond
                   ((= cb ?\) )
                    
                    (while (progn
                             (incf nu-forward-sexp-level)
                             (backward-char)
                             (and (> (point) (point-min))
                                  (looking-back ")[ \t]*")))
                      (skip-chars-backward " \t"))
                   
                    ;; (incf nu-forward-sexp-level)
                    (while (< level nu-forward-sexp-level) (nu-backward-sexp1)))
               
               
                   ((= cb ?\( )
                    (cond ((< 0 nu-forward-sexp-level)
                           (decf nu-forward-sexp-level)
                           (backward-char))
                          ;; else signal a proper 'scan-error to satisfy paredit 
                          (t (let ((forward-sexp-function nil)) (backward-sexp)))))

                   ;; (decf nu-forward-sexp-level))
                
                   ((when (or (= cb ?\")
                              (and (= cb ?') (looking-back nu-char-re))
                              (and (= cb ?/) (looking-back nu-regexp-root-re) (looking-at nu-regexp-sfx-re)
                                   ;; (save-excursion (nth 3 (syntax-ppss (1- (point)))))
                                   ))
                      (backward-char)
                      (nu-skip-string-backward cb)
                      t))
               
                   ((member (char-syntax cb) '(?w ?_))
                    (while (progn (backward-char)
                                  (let ((ch (char-before)))
                                    (and (not (member ch '(?: ?/)))
                                         (member (char-syntax ch) '(?w ?_)))))))
                
                   (t
                    ;;(message "Unknown state to go backward")
                    (when (< (point-min) (point))
                      (backward-char)
                      (nu-backward-sexp1)) )))))))))


;; FORWARD-SEXP ----------------------------------------------------------------
(defun nu-forward-sexp (&optional arg)

  (setq nu-forward-sexp-level 0)
  (unless arg (setq arg 1))

;;   (message (format "nu-forward-sexp point = %d arg = %d" (point) arg))
  (while (< arg 0)
    (incf arg)
    (nu-backward-sexp1))

  (while (> arg 0)
    (decf arg)
    (nu-forward-sexp1)))


;; NU-INDENT-FUNCTION ----------------------------------------------------------
(defun nu-indent-line (indent-point state)

  (if (save-excursion
        (goto-char indent-point)
        
        (and (nu-find-heredoc-backward (point))
             (> (point) (match-end 1))
             (< (point) (match-end 0))))
      
      (progn
        (goto-char indent-point)
        (back-to-indentation)
        (current-column))
  
      (let ((lisp-body-indent nu-body-indent))
        (let ((lisp-indent (lisp-indent-function indent-point state)))
          
          (unless (or (nth 3 state)     ;inside string
                      (nth 4 state)     ;inside comment
                      (progn (goto-char indent-point)
                             (skip-chars-forward " \t")
                             (member (char-after) '(?\n ?\) ))))
    
            (save-excursion
        
              (let* ((list-beg (nth 1 state))
                     (list-beg-col (progn
                                     (goto-char list-beg)
                                     (current-column)))
               
                     (first-sexp-beg (progn
                                       (goto-char (+ list-beg 1))
                                       (nu-skip-space-forward 'in-clear-state)
                                       (point)))
               
                     (first-sexp-end (progn
                                       ;; (goto-char first-sexp-beg)
                                       (nu-forward-sexp1 'in-clear-state)
                                       (point)))
               
                     (first-sexp-str (buffer-substring-no-properties first-sexp-beg
                                                                     first-sexp-end))
                     (prev-sexp-beg  (nth 2 state))
                     
                     (prev-sexp-col (progn
                                      (goto-char prev-sexp-beg)
                                      (current-column)))
               
                     (prev-sexp-end (progn
                                      (nu-forward-sexp1 'in-clear-state)
                                      (point)))

                     (prev-sexp-end-col (current-column))
               
                     (prev-sexp-str (buffer-substring-no-properties prev-sexp-beg
                                                                    prev-sexp-end))
               
                     (cur-sexp-beg (progn
                                     (goto-char indent-point)
                                     (skip-chars-forward " \t")
                                     (point)))

                     (cur-sexp-col (current-column))
             
                     (cur-sexp-end (progn
                                     (nu-forward-sexp1 'in-clear-state)
                                     (point)))
               
                     (cur-sexp-end-col (current-column))

                     (cur-sexp-str (buffer-substring-no-properties cur-sexp-beg
                                                                   cur-sexp-end))

                     (cur-sexp-keyword-p (eq ?: (char-before cur-sexp-end)))
                     colon-col
                     is-has-found)

                ;; if lisp-indent is not nil, redefine it only, if the first item in
                ;; the list is a list or regexp
                (when (or (not lisp-indent)
                          (= (char-after first-sexp-beg) ?\( ) ;; list check
                          (and (= (char-after first-sexp-beg) ?/ ) ;; regexp check
                               (< 1 (- first-sexp-end first-sexp-beg))))
        
                  (goto-char first-sexp-end)
                  
                  ;; find colon column
                  (while (<= (point) prev-sexp-end)

                    (when (and (or (not nu-align-by-first-colon) (null colon-col))
                               (eq ?: (char-before)))
                      (setq colon-col (current-column)))

                    (nu-skip-space-forward 'in-clear-state)
                    (when (looking-at "is[ \t\n;#]") (setq is-has-found t))
                    (nu-forward-sexp1 'in-clear-state))

                  
                  ;; calclate indent
                  (setq lisp-indent
                        (cond
                         ;;indent the first method keyword
                         ((and (null colon-col) cur-sexp-keyword-p)
                          (+ list-beg-col nu-keys-indent))
                         
                         ;; indent the body of class and class method definitions
                         ((or (string= first-sexp-str "class")
                              (and is-has-found
                                   (string-match "^[ci]method\\|[+-]$" first-sexp-str)))
                          
                          (+ list-beg-col nu-body-indent))
                         
                         ;; indent method keyword's arguments
                         ((and colon-col (not cur-sexp-keyword-p))
                          (if (and (>= colon-col prev-sexp-col)
                                   (<= colon-col prev-sexp-end-col))
                              
                              (+ prev-sexp-col nu-keys-indent)
                              prev-sexp-col))
                         
                         ;; indent method keyword other than the first one 
                         ((and colon-col cur-sexp-keyword-p)
                          (- colon-col (- cur-sexp-end-col cur-sexp-col)))))
                  ))))
          
          lisp-indent))))

;; NU-LISP-INDENT-LINE ---------------------------------------------------------
(defun nu-lisp-indent-line (&optional whole-exp)
  "Indent current line as Lisp code.
With argument, indent any additional lines of the same expression
rigidly along with this one."
  (interactive "P")
  (unless (save-excursion
            (beginning-of-line)
            (and (= (point) (point-min))
                 (looking-at "#!")))
    (lisp-indent-line whole-exp)
    ))

;; NU-INDENT-SEXP --------------------------------------------------------------
(defun nu-indent-sexp  (&optional endpos)
  "Indent each line of the list starting just after point."
  
  (interactive)
  (save-excursion
    (save-match-data
      (let* ((pos (point))
             (state (syntax-ppss))
             (in-clear-state (not (or (nth 3 state) (nth 4 state))))
             sexp-beg
             sexp-end)
        
        (when (and in-clear-state
                   (skip-chars-forward " \t")
                   (= (char-after) ?\( ))
          (setq sexp-beg (point)))
        
        (setq sexp-end (progn (nu-forward-sexp1 in-clear-state)
                              (point)))
        
        (unless sexp-beg (setq sexp-beg (progn (backward-sexp) (point))))

        (if (progn (goto-char sexp-beg)
                   (beginning-of-line)
                   (skip-chars-forward " \t")
                   (= (point) sexp-beg))
            
            (beginning-of-line 2)
            (setq sexp-beg (point)))
        
;;         (message (format "indent: %S %S" sexp-beg sexp-end))
        (when (< sexp-beg sexp-end) (nu-indent-region sexp-beg sexp-end))))))


;; INDENT-SEXP ADVICE ----------------------------------------------------------
(defadvice indent-sexp (around nu-replace-indent-sexp)
  (interactive)
  ;; (message "IN INDENT-SEXP ADVICE ------------------------")
  (if (eq major-mode 'nu-mode)
      (nu-indent-sexp)
      ad-do-it))

(ad-activate 'indent-sexp)

;; NU-INDENT-SEXP --------------------------------------------------------------
(defun nu-indent-region  (start end)
  "Indent each line of the list starting just after point."
  
  (interactive)
  (save-excursion
    (save-match-data
      (let* ((pos (point))
             sexp-beg
             sexp-end)

        (goto-char start)
        (beginning-of-line)

        (dotimes  (n (count-lines start end))
          (nu-lisp-indent-line)
          (beginning-of-line 2))))))


;; NU-LOOKING-AT-DEFUN ---------------------------------------------------------
(defsubst nu-looking-at-defun () (looking-at nu-defun-re))


;; NU-BEGINNING-OF-SYNTAX ------------------------------------------------------
(defun nu-beginning-of-syntax ()
;;   (beginning-of-line)
  
;;   (while (and (> (point) (point-min))
;;               (not (nu-looking-at-defun))
;;               (not (nth 3 (syntax-ppss))))
    
;;     (beginning-of-line 0))
  
  (goto-char (point-min))) 

;; NU-BEGINNING-OF-DEFUN -------------------------------------------------------
(defun nu-beginning-of-defun ()

  (save-match-data
    (beginning-of-line)
    (while (not (or (= (point) (point-min))
                    (and (nu-looking-at-defun)
                         (not (nth 3 (syntax-ppss))))))
      (beginning-of-line 0)))

  (point)) 

;; NU-END-OF-DEFUN -------------------------------------------------------
(defun nu-end-of-defun ()

  (nu-skip-space-forward)
  
  (when (or (and (nu-looking-at-defun) (not (nth 3 (syntax-ppss))))
            (nu-beginning-of-defun))
    
      (nu-forward-sexp1)))


;; NU-AFTER-CHANGE -------------------------------------------------------------
(defun nu-after-change (beg end old-length)

  (when (string= (buffer-substring-no-properties beg end) "\n")
    (nu-after-newline beg end))

  (condition-case err
      ;;(message (format "cat heredocs ranges for point %s" beg))
    (nu-cut-heredocs-ranges beg)

    (error (message (error-message-string err))))
  ;; (message (format "changed from: %s to: %s old length: %s" beg end old-length))
  )

;; NU-AFTER-NEWLINE ------------------------------------------------------------
(defun nu-after-newline (beg end)
  (save-match-data
    (let ((bol (save-excursion (beginning-of-line 0) (point))))
      (when (looking-back nu-heredoc-beg-re bol)
        (save-excursion
          (goto-char (match-beginning 0))
          (let ((emark (match-string 1)))
            (goto-char end)
            (insert emark)))))))


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
;;     (nu-find-heredocs-ranges)
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

;; (setq elp-function-list
;;       '(nu-indent-line
;;         nu-skip-space-forward
;;         nu-skip-space-backward
;;         nu-forward-sexp1
;;         nu-backward-sexp1
;;         nu-find-heredoc-backward
;;         nu-beginning-of-defun
;;         nu-end-of-defun
;;         syntax-ppss
;;         ))

;; (elp-instrument-list)
;; (setq elp-set-master nil)

(provide 'nu)
;;; nu.el ends here
