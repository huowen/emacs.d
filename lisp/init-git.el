;; disable all vc backends
;; @see http://stackoverflow.com/questions/5748814/how-does-one-disable-vc-git-in-emacs
(setq vc-handled-backends ())

;; TODO: link commits from vc-log to magit-show-commit
;; TODO: smerge-mode
(require-package 'magit)
(require-package 'git-blame)
(require-package 'git-commit-mode)
(require-package 'git-rebase-mode)
(require-package 'gitignore-mode)
(require-package 'gitconfig-mode)
(require-package 'git-messenger) ;; Though see also vc-annotate's "n" & "p" bindings
(require-package 'git-timemachine)

(setq-default
 magit-save-some-buffers nil
 magit-process-popup-time 10
 magit-diff-refine-hunk t
 magit-completing-read-function 'magit-ido-completing-read)

(defun magit-status-somedir ()
  (interactive)
  (let ((current-prefix-arg t))
    (magit-status default-directory)))

;; Sometimes I want check other developer's commit
;; show file of specific version
(autoload 'magit-show "magit" "" t nil)
;; show the commit
(autoload 'magit-show-commit "magit" "" t nil)

;; Hint: customize `magit-repo-dirs' so that you can use C-u M-F12 to
;; quickly open magit on any one of your projects.
(global-set-key [(meta f12)] 'magit-status)
(global-set-key [(shift meta f12)] 'magit-status-somedir)

(eval-after-load 'magit
  '(progn
     ;; Don't let magit-status mess up window configurations
     ;; http://whattheemacsd.com/setup-magit.el-01.html
     (defadvice magit-status (around magit-fullscreen activate)
       (window-configuration-to-register :magit-fullscreen)
       ad-do-it
       (delete-other-windows))

     (defun magit-quit-session ()
       "Restores the previous window configuration and kills the magit buffer"
       (interactive)
       (kill-buffer)
       (when (get-register :magit-fullscreen)
         (jump-to-register :magit-fullscreen)))

     (define-key magit-status-mode-map (kbd "q") 'magit-quit-session)))

(after-load 'magit
  (define-key magit-status-mode-map (kbd "C-M-<up>") 'magit-goto-parent-section)
  (add-hook 'magit-mode-hook (lambda () (toggle-truncate-lines -1)) t))

;; (require-package 'fullframe)
;; (after-load 'magit
;;   (fullframe magit-status magit-mode-quit-window))

(add-hook 'git-commit-mode-hook 'goto-address-mode)
(after-load 'session
  (add-to-list 'session-mode-disable-list 'git-commit-mode))


;;; When we start working on git-backed files, use git-wip if available

(after-load 'magit
  (global-magit-wip-save-mode)
  (diminish 'magit-wip-save-mode))

;; (after-load 'magit
;;   (diminish 'magit-auto-revert-mode))


(when *is-a-mac*
  (after-load 'magit
    (add-hook 'magit-mode-hook (lambda () (local-unset-key [(meta h)])))))



;; Convenient binding for vc-git-grep
(global-set-key (kbd "C-x v f") 'vc-git-grep)



;;; git-svn support

(require-package 'magit-svn)
(autoload 'magit-svn-enabled "magit-svn")
(defun sanityinc/maybe-enable-magit-svn-mode ()
  (when (magit-svn-enabled)
    (magit-svn-mode)))
(add-hook 'magit-status-mode-hook #'sanityinc/maybe-enable-magit-svn-mode)

(after-load 'compile
  (dolist (defn (list '(git-svn-updated "^\t[A-Z]\t\\(.*\\)$" 1 nil nil 0 1)
                      '(git-svn-needs-update "^\\(.*\\): needs update$" 1 nil nil 2 1)))
    (add-to-list 'compilation-error-regexp-alist-alist defn)
    (add-to-list 'compilation-error-regexp-alist (car defn))))

(defvar git-svn--available-commands nil "Cached list of git svn subcommands")

(defun git-svn (dir)
  "Run a git svn subcommand in DIR."
  (interactive "DSelect directory: ")
  (unless git-svn--available-commands
    (setq git-svn--available-commands
          (sanityinc/string-all-matches
           "^  \\([a-z\\-]+\\) +"
           (shell-command-to-string "git svn help") 1)))
  (let* ((default-directory (vc-git-root dir))
         (compilation-buffer-name-function (lambda (major-mode-name) "*git-svn*")))
    (compile (concat "git svn "
                     (ido-completing-read "git-svn command: " git-svn--available-commands nil t)))))


(require-package 'git-messenger)
(global-set-key (kbd "C-x v p") #'git-messenger:popup-message)


(eval-after-load 'magit
  '(progn
     (require 'magit-key-mode)
     ))

;; {{ git-gutter
(when *emacs24*
  (require 'git-gutter)

  ; If you enable global minor mode
  (global-git-gutter-mode t)

  (git-gutter:linum-setup)

  (global-set-key (kbd "C-x C-g") 'git-gutter:toggle)
  (global-set-key (kbd "C-x v =") 'git-gutter:popup-hunk)

  ;; Jump to next/previous hunk
  (global-set-key (kbd "C-x p") 'git-gutter:previous-hunk)
  (global-set-key (kbd "C-x n") 'git-gutter:next-hunk)

  ;; Stage current hunk
  (global-set-key (kbd "C-x v s") 'git-gutter:stage-hunk)

  ;; Revert current hunk
  (global-set-key (kbd "C-x v r") 'git-gutter:revert-hunk)
  )
;; }}


(defun git-reset-current-file ()
  "git reset file of current buffer"
  (interactive)
  (let ((filename))
    (when buffer-file-name
      (setq filename (file-truename buffer-file-name))
      (shell-command (concat "git reset " filename))
      (message "DONE! git reset %s" filename)
      )))

(defun git-add-current-file ()
  "git add file of current buffer"
  (interactive)
  (let ((filename))
    (when buffer-file-name
      (setq filename (file-truename buffer-file-name))
      (shell-command (concat "git add " filename))
      (message "DONE! git add %s" filename)
      )))

(defun git-push-remote-origin ()
  "run `git push'"
  (interactive)
  (when buffer-file-name
    (message "(pwd)=%s" default-directory)
    (shell-command (concat "cd " (pwd) ";git push"))
    (message "DONE! git push at %s" default-directory)
    ))

(defun git-add-option-update ()
  "git add only tracked files of default directory"
  (interactive)
  (when buffer-file-name
    (shell-command "git add -u")
    (message "DONE! git add -u %s" default-directory)
    ))


;; {{ goto next/previous hunk/section
(defun my-goto-next-section (arg)
  "wrap magit and other diff plugins next/previous command"
  (interactive "p")
  (cond
   ((string= major-mode "magit-commit-mode")
    (setq arg (abs arg))
    (while (> arg 0)
      (condition-case nil
          ;; buggy when start from first line
          (magit-goto-next-sibling-section)
        (error
         (magit-goto-next-section)))
      (setq arg (1- arg))))
   (t (git-gutter:next-hunk arg))
   ))

(defun my-goto-previous-section (arg)
  "wrap magit and other diff plugins next/previous command"
  (interactive "p")
  (cond
   ((string= major-mode "magit-commit-mode")
    (setq arg (abs arg))
    (while (> arg 0)
      (condition-case nil
          ;; buggy when start from first line
          (magit-goto-previous-sibling-section)
        (error
         (magit-goto-previous-section)))
      (setq arg (1- arg))))
   (t (git-gutter:previous-hunk arg))
   ))

(defun my-goto-next-hunk (arg)
  "wrap magit and other diff plugins next/previous command"
  (interactive "p")
  (cond
   ((string= major-mode "magit-commit-mode")
    (diff-hunk-next arg))
   (t (git-gutter:next-hunk arg))
   ))

(defun my-goto-previous-hunk (arg)
  "wrap magit and other diff plugins next/previous command"
  (interactive "p")
  (cond
   ((string= major-mode "magit-commit-mode")
    (diff-hunk-prev arg))
   (t (git-gutter:previous-hunk arg))
   ))

;; turn off the overlay, I do NOT want to lose original syntax highlight!
(setq magit-highlight-overlay t)
;; }}
(provide 'init-git)

