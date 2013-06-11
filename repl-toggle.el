;;; repl-toggle.el --- Switch to/from repl buffer for current major-mode

;; Copyright (C) 2013 Tom Regner

;; Author: Tom Regner <tom@goochesa.de>
;; Maintainer: Tom Regner <tom@goochesa.de>
;; Version: 0.0.1
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
;;     (rtog/add-repl 'php-mode 'php-boris ) 
;;     (rtog/add-repl 'emacs-lisp-mode 'ielm ) 
;;     (global-set-key (kbd "C-c C-z") 'rtog/toggle-repl)
;; 
;; 
;; Code:

(defvar rtog/mode-repl-map (make-hash-table)
  "major-mode => repl-command")

(defvar rtog/--last-buffer nil
  "store the jump source in repl buffer")
(make-variable-buffer-local 'rtog/--last-buffer) 

;; internal functions
(defun rtog/--switch-to-buffer ()
  "If `rtog/--last-buffer` is non nil, switch to the buffer
identified by it."
  (if rtog/--last-buffer
	  (let ((--buffer rtog/--last-buffer))
		(setq rtog/--last-buffer nil)
		(switch-to-buffer --buffer))))


(defun rtog/--switch-to-repl ()
  "If `rtog/mode-repl-map` contains an entry for the `major-mode`
of the current buffer, call the value as function.

This assumes that the command executed will start a new repl, or
switch to an already running process."
  (let ((--buffer (current-buffer))
		(--mode-cmd (gethash major-mode rtog/mode-repl-map nil)))
	(progn
	  (funcall --mode-cmd)
	  (setq rtog/--last-buffer --buffer))))

;; interactive functions

;;;###autoload
(defun rtog/add-repl (mode repl-cmd)
  "If in a buffer with major-mode MODE, execute REPL-CMD when
  rtog/roggle-rep is called."
  (interactive "Mmajor mode? \narepl function? ")
  (puthash mode repl-cmd rtog/mode-repl-map))

;;;###autoload
(defun rtog/toggle-repl ()
  "Switch to the repl asscociated with the major mode of the
current buffer. If in a repl already switch back to the buffer we
came from."
  (interactive)
  (if rtog/--last-buffer
	  (rtog/--switch-to-buffer)
	(rtog/--switch-to-repl)))


(provide 'repl-toggle)

;;; repl-toggle.el ends here
