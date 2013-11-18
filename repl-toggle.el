;;; repl-toggle.el --- Switch to/from repl buffer for current major-mode

;; Copyright (C) 2013 Tom Regner

;; Author: Tom Regner <tom@goochesa.de>
;; Maintainer: Tom Regner <tom@goochesa.de>
;; Version: 0.0.8
;; Keywords: repl, buffers, toggle

;;  This file is NOT part of GNU Emacs

;;  This program is free software: you can redistribute it and/or modify
;;  it under the terms of the GNU General Public License as published by
;;  the Free Software Foundation, either version 3 of the License, or
;;  (at your option) any later version.

;;  This program is distributed in the hope that it will be useful,
;;  but WITHOUT ANY WARRANTY; without even the implied warranty of
;;  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;  GNU General Public License for more details.

;;  You should have received a copy of the GNU General Public License
;;  along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This is a generalization of an idea by Mickey Petersen of
;; masteringemacs fame: Use one keystroke to jump from a code buffer
;; to the corresponding repl buffer and back again. This works even if
;; you do other stuff in between, as the last buffer used to jump to a
;; repl is stored in a buffer local variable in the repl buffer.
;;
;; Currently this assumes that the stored command to start the repl
;; will switch to an already open repl buffer if it exists.
;;
;; There are no repl/mode combinations preconfigured, put something
;; like the following in your emacs setup for php and elisp repl:
;;
;;     (require 'repl-toggle)
;;     (setq rtog/mode-repl-alist '((php-mode . php-boris) (emacs-lisp-mode . ielm)))
;; 
;; This defines a global minor mode, indicated at with 'rt' in the modeline, that
;; grabs "C-c C-z" as repl toggling keybinding.
;;
;; I don't know with wich repl modes this actualy works. If you use
;; this mode, please tell me your rtog/mode-repl-alist, so that I can
;; update the documentation.
;;
;; Code:

;; customization

(defcustom rtog/mode-repl-alist ()
  "List of cons `(major-mode . repl-command)`, associating major
modes with a repl command."
  :type '(alist :key-type symbol :value-type function)
  :group 'repl-toggle)

;; minor mode
(defvar repl-toggle-mode-map
  (let ((m (make-sparse-keymap)))
    (define-key m (kbd "C-c C-z") 'rtog/toggle-repl)
   m)
  "Keymap for `repl-toggle-mode'.")

;;;###autoload
(define-minor-mode repl-toggle-mode
  "A minor mode to allow uniform repl buffer switching."
  nil
  :lighter " rt"
  :keymap repl-toggle-mode-map
  :global t)

;; variables
(defvar rtog/--last-buffer nil
  "store the jump source in repl buffer")
(make-variable-buffer-local 'rtog/--last-buffer) 

;; internal functions

(defun rtog/pass-code (passAlong?)
  "Depending on PASSALONG? return the current line or region,
function or definition or the whole current buffer." 
  (case passAlong?
	(4 (if (use-region-p)
		   (buffer-substring-no-properties
			(region-beginning)
			(region-end))
		 (thing-at-point 'line)))
	(16 (thing-at-point 'defun))
	(64 (buffer-substring-no-properties (point-min) (point-max)))))

(defun rtog/--switch-to-buffer ()
  "If `rtog/--last-buffer` is non nil, switch to the buffer
identified by it."
  (if (and rtog/--last-buffer
		   (buffer-live-p rtog/--last-buffer))
	  (switch-to-buffer rtog/--last-buffer)
	(setq rtog/--last-buffer nil)))


(defun rtog/--switch-to-repl (&optional code &rest ignored)
  "If `rtog/mode-repl-map` contains an entry for the `major-mode`
of the current buffer, call the value as function.

This assumes that the command executed will start a new repl, or
switch to an already running process.
 
Any text passed as CODE will be pasted in the repl buffer.
"
  (let ((--buffer (current-buffer))
		(--mode-cmd  (cdr (assoc major-mode rtog/mode-repl-alist ))))
	(if (and --mode-cmd (functionp --mode-cmd))
		(progn 
		  (funcall --mode-cmd)
		  (setq rtog/--last-buffer --buffer)
		  (if code
			  (progn 
				(goto-char (point-max))
				(insert code)))))))

;; interactive functions

;;;###autoload
(defun rtog/add-repl (mode repl-cmd)
  "If in a buffer with major-mode MODE, execute REPL-CMD when
  `rtog/toggle-repl is called´."
  (interactive "Mmajor mode? \narepl function? ")
  (add-to-list rtog/mode-repl-alist '(mode . repl-cmd) ))

;;;###autoload
(defun rtog/toggle-repl (&optional passAlong? &rest ignored)
  "Switch to the repl asscociated with the major mode of the
current buffer. If in a repl already switch back to the buffer we
came from.

If you provide a prefix with C-u, the current line or region is
passed to the repl buffer, using C-u C-u the current function or
definition is passed, and finaly using C-u C-u C-u you can pass
the whole current buffer.
"
  (interactive "p")
  (if rtog/--last-buffer
	  (rtog/--switch-to-buffer)
	(rtog/--switch-to-repl (rtog/pass-code passAlong?))))

;; hook into comint modes no matter what
(defun rtog/activate ()
  "Activate the repl-toggle minor mode."
  (repl-toggle-mode 1))

(add-hook 'comint-mode-hook 'rtog/activate)
(provide 'repl-toggle)

;;; repl-toggle.el ends here
