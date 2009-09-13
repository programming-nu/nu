;;; nush.el --- Nush process in a buffer. Based on cmuscheme.el

;; This code is written by Aleksandr Skobelev and placed in the
;; Public Domain.  All warranties are disclaimed.

;;; Commentary:
   
;; This code allows running a nush process from Nu file and interact with it.

;; HERE IS ORIGINAL CMUSCHEME.EL COPYRIGHT AND COMMENTARY

;; Copyright (C) 1988, 1994, 1997, 2001, 2002, 2003, 2004,
;;   2005, 2006, 2007 Free Software Foundation, Inc.

;;; Commentary:

;;    This is a customization of comint-mode (see comint.el)
;;
;; Written by Olin Shivers (olin.shivers@cs.cmu.edu). With bits and pieces
;; lifted from scheme.el, shell.el, clisp.el, newclisp.el, cobol.el, et al..
;; 8/88

;; History:
;; 2009-09-13 Aleksandr Skobelev
;;    - added (c-subword-mode t)

;; 2008-03-22 Aleksandr Skobelev
;;    - set COMINT-PROCESS-ECHOES to T
;;    - changed NUSH-SEND-REGION to not send additional "\n"

;; 2008-02-11 Aleksandr Skobelev
;;    Initial version released

;;; Code:

(require 'cl)
(require 'nu)
(require 'comint)


(defgroup nush nil
  "Run a nush process in a buffer."
  :group 'nu)

(defcustom nush-program-name "nush"
  "*Program invoked by the `run-nush' command."
  :type 'string
  :group 'nush)

(defcustom nush-start-file-name "~/.nush-init"
  "*Program invoked by the `run-nush' command."
  :type 'string
  :group 'nush)

(defconst nush-version "2009-09-11"
  "Nush Mode version number.")




;;; INFERIOR NUSH MODE STUFF
;;;============================================================================

(defcustom inferior-nush-mode-hook nil
  "*Hook for customizing inferior-nush mode."
  :type 'hook
  :group 'nush)

(defvar inferior-nush-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m "\M-\C-x"  'nush-send-definition) ;gnu convention
    (define-key m "\C-x\C-e" 'nush-send-last-sexp)
    (define-key m "\C-c\C-l" 'nush-load-file)
    ;; (define-key m "\C-c\C-k" 'nu-compile-file)
    ;; (nu-mode-commands m)
    m))

;; Install the process communication commands in the nu-mode keymap.
(define-key nu-mode-map "\M-\C-x"  'nush-send-definition) ;gnu convention
(define-key nu-mode-map "\C-x\C-e" 'nush-send-last-sexp) ;gnu convention
(define-key nu-mode-map "\C-c\C-e" 'nush-send-definition)
(define-key nu-mode-map "\C-c\M-e" 'nush-send-definition-and-go)
(define-key nu-mode-map "\C-c\C-r" 'nush-send-region)
(define-key nu-mode-map "\C-c\M-r" 'nush-send-region-and-go)
;; (define-key nu-mode-map "\C-c\C-z" 'switch-to-nush)
(define-key nu-mode-map "\C-c\C-l" 'nush-load-file)

(let ((map (lookup-key nu-mode-map [menu-bar nu])))
  (define-key map [separator-eval] '("--"))
  (define-key map [load-file]
    '("Load Nu File" . nush-load-file))
;;   (define-key map [switch]
;;     '("Switch to Nush" . switch-to-nush))
  (define-key map [send-def-go]
    '("Evaluate Last Definition & Go" . nush-send-definition-and-go))
  (define-key map [send-def]
    '("Evaluate Last Definition" . nush-send-definition))
  (define-key map [send-region-go]
    '("Evaluate Region & Go" . nush-send-region-and-go))
  (define-key map [send-region]
    '("Evaluate Region" . nush-send-region))
  (define-key map [send-sexp]
    '("Evaluate Last S-expression" . nush-send-last-sexp))
  )

(defvar nush-buffer)

(define-derived-mode inferior-nush-mode comint-mode "Inferior Nush"
  "Major mode for interacting with an inferior Nu process.

The following commands are available:
\\{inferior-nush-mode-map}

A Nush process can be fired up with M-x run-nush.

Customization: Entry to this mode runs the hooks on comint-mode-hook and
inferior-nush-mode-hook (in that order).

You can send text to the inferior Nush process from other buffers containing
Nu source.
    switch-to-nush switches the current buffer to the Nush process buffer.
    nush-send-definition sends the current definition to the Nu process.
    nush-send-region sends the current region to the Nu process.
    
    nush-send-definition-and-go, nush-send-region-and-go
        switch to the Nush process buffer after sending their text.
For information on running multiple processes in multiple buffers, see
documentation for variable nush-buffer.

Commands:
Return after the end of the process' output sends the text from the
    end of process to point.
Return before the end of the process' output copies the sexp ending at point
    to the end of the process' output, and sends it.
Delete converts tabs to spaces as it moves back.
Tab indents for Nu; with argument, shifts rest
    of expression rigidly with the current line.
C-M-q does Tab on each line starting within following expression.
Paragraphs are separated only by blank lines.  Semicolons start comments.
If you accidentally suspend your process, use \\[comint-continue-subjob]
to continue it."
  ;; Customize in inferior-nush-mode-hook
  (setq comint-prompt-regexp "^\\([%-] \\)+")
  
  (nu-mode-variables)
  (c-subword-mode t)
  (set-local 'comint-process-echoes t)
  (setq mode-line-process '(":%s"))
  (setq comint-input-filter (function nush-input-filter))
  (setq comint-get-old-input (function nush-get-old-input)))

(defcustom inferior-nush-filter-regexp "\\`\\s *\\S ?\\S ?\\s *\\'"
  "*Input matching this regexp are not saved on the history list.
Defaults to a regexp ignoring all inputs of 0, 1, or 2 letters."
  :type 'regexp
  :group 'nush)

(defun nush-input-filter (str)
  "Don't save anything matching `inferior-nush-filter-regexp'."
  (not (string-match inferior-nush-filter-regexp str)))

(defun nush-get-old-input ()
  "Snarf the sexp ending at point."
  (save-excursion
    (let ((end (point)))
      (backward-sexp)
      (buffer-substring (point) end))))

(defun nush-args-to-list (string)
  (let ((where (string-match "[ \t]" string)))
    (cond ((null where) (list string))
          ((not (= where 0))
           (cons (substring string 0 where)
                 (nush-args-to-list (substring string (+ 1 where)
                                               (length string)))))
          (t (let ((pos (string-match "[^ \t]" string)))
               (if (null pos)
                   nil
                   (nush-args-to-list (substring string pos
                                                 (length string)))))))))

;;;###autoload
(defun run-nush (&optional cmd)
  "Run an inferior Nush process, input and output via buffer `*nush*'.
If there is a process already running in `*nush*', switch to that buffer.
With argument, allows you to edit the command line (default is value
of `nush-program-name').
If the file `~/.nush_init' exists, it is given as initial input.
Note that this may lose due to a timing error if the Nush processor
discards input when it starts up.
Runs the hook `inferior-nush-mode-hook' \(after the `comint-mode-hook'
is run).
\(Type \\[describe-mode] in the process buffer for a list of commands.)"

  (interactive
   (list (if current-prefix-arg
			 (read-string "Run Nush: " nush-program-name)
			 nush-program-name)))

  (if (null cmd) (setq cmd nush-program-name))
  
  (if (not (comint-check-proc "*nush*"))
      (let ((cmdlist (nush-args-to-list cmd)))
        (set-buffer (apply 'make-comint "nush" (car cmdlist)
                           (nush-start-file (car cmdlist)) (cdr cmdlist)))
        (inferior-nush-mode)))
  
  (setq nush-program-name cmd)
  (setq nush-buffer "*nush*")
  (pop-to-buffer "*nush*"))
;;;###autoload (add-hook 'same-window-buffer-names "*nush*")

(defun nush-start-file (prog)
  "Return the name of the start file corresponding to PROG.
Search in the directories \"~\" and \"~/.emacs.d\", in this
order.  Return nil if no start file found."
  (if (and nush-start-file-name (file-exists-p nush-start-file-name))
      nush-start-file-name))

(defun nush-send-region (start end)
  "Send the current region to the inferior Nush process."
  (interactive "r")
;;   (save-match-data
;;     (let ((lines (split-string (buffer-substring start end) "\n")))
;;       (dolist (line lines)
;;         (comint-send-string (nush-proc) (concat line "\n"))
;;         )))
  (comint-send-region (nush-proc) start end)
  (save-excursion
    (save-match-data
      (goto-char end)
      (unless (looking-back "^[ \t]*" end)
        (comint-send-string (nush-proc) "\n"))))
  )

(defun nush-send-definition ()
  "Send the current definition to the inferior Nush process."
  (interactive)
  (save-excursion
    (beginning-of-defun)
    (let ((beg (point)))
      (end-of-defun)
      (nush-send-region beg (point)))))

(defun nush-send-last-sexp ()
  "Send the previous sexp to the inferior Nush process."
  (interactive)
  (nush-send-region (save-excursion (backward-sexp) (point)) (point)))


(defun nush-form-at-point ()
  (let ((next-sexp (thing-at-point 'sexp)))
    (if (and next-sexp (string-equal (substring next-sexp 0 1) "("))
        next-sexp
        (save-excursion
          (backward-up-list)
          (nush-form-at-point)))))

(defun switch-to-nush (eob-p)
  "Switch to the nush process buffer.
With argument, position cursor at end of buffer."
  (interactive "P")
  (if (or (and nush-buffer
               (get-buffer nush-buffer)
               (get-buffer-process nush-buffer))
          (run-nush))
      (pop-to-buffer nush-buffer)
      (error "No current process buffer.  See variable `nush-buffer'"))
  (when eob-p
    (push-mark)
    (goto-char (point-max))))

(defun nush-send-region-and-go (start end)
  "Send the current region to the inferior Nush process.
Then switch to the process buffer."
  (interactive "r")
  (nush-send-region start end)
  (switch-to-nush t))

(defun nush-send-definition-and-go ()
  "Send the current definition to the inferior Nush.
Then switch to the process buffer."
  (interactive)
  (nush-send-definition)
  (switch-to-nush t))

(defcustom nu-source-modes '(nu-mode)
  "*Used to determine if a buffer contains Nu source code.
If it's loaded into a buffer that is in one of these major modes, it's
considered a nu source file by `nush-load-file'.
Used by these commands to determine defaults."
  :type '(repeat function)
  :group 'nush)

(defvar nush-prev-l/c-dir/file nil
  "Caches the last (directory . file) pair.
Caches the last pair used in the last `nush-load-file' command.
Used for determining the default in the next one.")

(defun nush-load-file (file-name)
  "Load a Nu file FILE-NAME into the inferior Nush process."
  (interactive (comint-get-source "Load Nu file: " nush-prev-l/c-dir/file
                                  nu-source-modes t)) ; t because `load'
                                        ; needs an exact name
  (comint-check-source file-name) ; Check to see if buffer needs saved.
  (setq nush-prev-l/c-dir/file (cons (file-name-directory    file-name)
                                     (file-name-nondirectory file-name)))
  (comint-send-string (nush-proc) (concat "(load \""
                                          file-name
                                          "\"\)\n")))



(defvar nush-buffer nil "*The current nush process buffer.

MULTIPLE PROCESS SUPPORT
===========================================================================
To run multiple Nush processes, you start the first up with
\\[run-nush].  It will be in a buffer named *nush*.  Rename this buffer
with \\[rename-buffer].  You may now start up a new process with another
\\[run-nush].  It will be in a new buffer, named *nush*.  You can
switch between the different process buffers with \\[switch-to-buffer].

Commands that send text from source buffers to Nush processes --
like `nush-send-definition' or `nush-compile-region' -- have to choose a
process to send to, when you have more than one Nush process around.  This
is determined by the global variable `nush-buffer'.  Suppose you
have three inferior Nushs running:
    Buffer	Process
    foo		nush
    bar		nush<2>
    *nush*    nush<3>
If you do a \\[nush-send-definition-and-go] command on some Nush source
code, what process do you send it to?

- If you're in a process buffer (foo, bar, or *nush*),
  you send it to that process.
- If you're in some other buffer (e.g., a source file), you
  send it to the process attached to buffer `nush-buffer'.
This process selection is performed by function `nush-proc'.

Whenever \\[run-nush] fires up a new process, it resets `nush-buffer'
to be the new process's buffer.  If you only run one process, this will
do the right thing.  If you run multiple processes, you can change
`nush-buffer' to another process buffer with \\[set-variable].

More sophisticated approaches are, of course, possible.  If you find yourself
needing to switch back and forth between multiple processes frequently,
you may wish to consider ilisp.el, a larger, more sophisticated package
for running inferior Lisp and Nush processes.  The approach taken here is
for a minimal, simple implementation.  Feel free to extend it.")

(defun nush-proc ()
  "Return the current Nush process, starting one if necessary.
See variable `nush-buffer'."
  (unless (and nush-buffer
               (get-buffer nush-buffer)
               (comint-check-proc nush-buffer))
;;     (nush-interactively-start-process)
    (run-nush))
  (or (nush-get-process)
      (error "No current process.  See variable `nush-buffer'")))

(defun nush-get-process ()
  "Return the current Nush process or nil if none is running."
  (get-buffer-process (if (eq major-mode 'inferior-nush-mode)
                          (current-buffer)
                          nush-buffer)))

(defun nush-interactively-start-process (&optional cmd)
  "Start an inferior Nush process.  Return the process started.
Since this command is run implicitly, always ask the user for the
command to run."
  (save-window-excursion
    (run-nush (read-string "Run Nush: " nush-program-name))))

;;; Do the user's customization...

(defcustom nush-load-hook nil
  "This hook is run when nush is loaded in.
This is a good place to put keybindings."
  :type 'hook
  :group 'nush)

(run-hooks 'nush-load-hook)

(provide 'nush)


;;; nush.el ends here
