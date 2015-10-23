;; AUCTeX configuration
(setenv "PATH" (concat "/usr/texbin:/usr/local/bin:" (getenv "PATH")))
(setq exec-path (append '("/usr/texbin" "/usr/local/bin") exec-path))
(load "auctex.el" nil t t)
(load "preview.el" nil t t)

(setq TeX-auto-save t)
(setq TeX-parse-self t)
;; (setq TeX-save-query nil)
(setq-default TeX-master nil)

;; use pdflatex
(setq TeX-PDF-mode t)

;; NOTE: Use `LaTex-mode-hook' for aucTeX latex, not `latex-mode-hook'
;; (add-hook 'LaTeX-mode-hook 'visual-line-mode)
;; (add-hook 'LaTeX-mode-hook 'flyspell-mode)
;; (add-hook 'LaTeX-mode-hook 'LaTeX-math-mode) ; conflict with cdlatex

;; reftex setup
(autoload 'reftex-mode "reftex" "RefTeX Minor Mode" t)
(autoload 'turn-on-reftex "reftex" "RefTeX Minor Mode" nil)
(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
;; Integrate reftex with aucteX
(setq reftex-plug-into-AUCTeX t)

;; use evince for dvi and pdf viewer
;; evince-dvi backend should be installed
(setq TeX-view-program-selection
      '((output-dvi "DVI Viewer")
        (output-pdf "PDF Viewer")
        (output-html "Safari")))
(setq TeX-view-program-list
      '(("DVI Viewer" "open %o")
        ("PDF Viewer" "open %o")
        ("Safari" "open %o")))


;; Enables Emacs to check the syntax of TeX file on-the-fly
(require 'flymake)

(defun flymake-get-tex-args (file-name)
  (list "pdflatex"
        (list "-file-line-error" "-draftmode" "-interaction=nonstopmode" file-name)))

(add-hook 'LaTeX-mode-hook 'flymake-mode)


;; spell-checking
;; (setq ispell-program-name "aspell") ; could be ispell as well, depending on your preferences
(setq ispell-dictionary "english") ; this can obviously be set to any language your spell-checking program supports

(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(add-hook 'LaTeX-mode-hook 'flyspell-buffer)


;; turn on word-wrap
(add-hook 'LaTeX-mode-hook 'visual-line-mode)

;; folding Macros and Environments
(add-hook 'Latex-mode-hook (lambda () (Tex-fold-mode 1)))


;; Define abbreviations that work in auctex modes only, without interfering with the standard text-mode.
;; (define-abbrev-table 'TeX-mode-abbrev-table (make-abbrev-table))
;; (add-hook 'TeX-mode-hook (lambda ()
;;    (setq abbrev-mode t)
;;    (setq local-abbrev-table TeX-mode-abbrev-table)))


;; Automagic detection of master file
(add-hook 'Latex-mode-hook (lambda ()
                             (setq TeX-master (guess-TeX-master (buffer-file-name)))))
(defun guess-TeX-master (filename)
  "Guess the master file for FILENAME from currently open .tex files."
  (let ((candidate nil)
        (filename (file-name-nondirectory filename)))
    (save-excursion
      (dolist (buffer (buffer-list))
        (with-current-buffer buffer
          (let ((name (buffer-name))
                (file buffer-file-name))
            (if (and file (string-match "\\.tex$" file))
                (progn
                  (goto-char (point-min))
                  (if (re-search-forward (concat "\\\\input{" filename "}") nil t)
                      (setq candidate file))
                  (if (re-search-forward (concat "\\\\include{" (file-name-sans-extension filename) "}") nil t)
                      (setq candidate file))))))))
    (if candidate
        (message "TeX master document: %s" (file-name-nondirectory candidate)))
    candidate))


;; extra commands and keys for LaTeX-mode
(require-package 'latex-extra)
(add-hook 'LaTeX-mode-hook #'latex-extra-mode)
;; Start view-command at end of `latex/compile-commands-until-done'
(setq latex/view-after-compile nil)
;; ask for confirmation on the "VIEW" command
;; (setq latex/view-skip-confirmation nil)
;; turn off auto-fill-mode, one can turn on it manually
(add-hook 'latex-extra-mode-hook (lambda () (auto-fill-mode -1)) t)

;; Completion for for math unicode symbols and latex tags using company-mode
(require-package 'company-math)
(after-load 'company-mode
  ;; global activation of the unicode symbol completion
  (add-to-list 'company-backends 'company-math-symbols-unicode)
  ;; allin symbols to the right
  (setq company-tooltip-align-annotations t))

;; preview inline latex in any mode
(require-package 'px)

;; magic-latex-buffer
;; (require 'magic-latex-buffer)


;;;;;; (Try?) Uncomment the following to use xelatex as the default engine for latex-mode
;; (defun auc ()
;;   (add-to-list 'TeX-command-list '("XeLaTeX" "%`xelatex%(mode)%' %t"
;;                                    TeX-run-TeX nil t))
;;   ;; (auto-complete-mode 1)
;;   (setq TeX-command-default "XeLaTeX")
;;   (setq TeX-save-query  nil )
;;   (setq TeX-show-compilation nil )
;;   (setq-default Tex-engine "xetex") ;; Use Xetex Engine
;;   (TeX-PDF-mode t)
;;   )
;; (add-hook 'LaTeX-mode-hook 'auc)



(provide 'init-auctex)
