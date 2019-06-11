;;; indent.el --- test indentation function from execline.el  -*- lexical-binding: t; -*-

;; Copyright (C) 2019  Dmitry Bogatov

;; Author: Dmitry Bogatov <KAction@debian.org>
;; Keywords: test

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:
;;
;; This module is not indented to be loaded by regular users of `execline.el'.
;; It contains only tests and test utilities.  This is why for brievity, "%"
;; is used as prefix.
;;
;; Some prefix is needed to make sure that no collisions with Emacs internals
;; could happen, but it does not matter if some other third-party package uses
;; it too.

;; 

;;; Code:
(require 'ert)
(require 's)
(require 'execline)

;; Structure to keep properties of buffer that are checked by tests.
(cl-defstruct %buffer content point)

(defun %set-buffer-state (state)
  "Set properties of current buffer according to slots of STATE."
  (erase-buffer)
  (insert (%buffer-content state))
  (goto-char (%buffer-point state)))

(defun %get-buffer-state ()
  "Return `%buffer' structure, containing point and content of current buffer."
  (make-%buffer :content (buffer-string) :point (point)))

(cl-defun %parse-buffer-state (string &optional (point-marker "|"))
  "Parse struct %buffer from STRING with point at POINT-MARKER substring.

Position of point is marked by substring POINT-MARKER, which is not part
of actual buffer content."
  (with-temp-buffer
    (insert string)
    (search-backward point-marker)
    (delete-char (length point-marker))
    (%get-buffer-state)))

(ert-deftest %test:parse-buffer-state ()
  (should (equal (%parse-buffer-state "foo|bar")
                 #s(%buffer "foobar" 4))))

(defun %test-buffer-edit (before after function)
  "Call FUNCTION in temporary buffer with state BEFORE and check new state.

If new state differs from AFTER, abort current test.  FUNCTION is
called without arguments, and both BEFORE and AFTER arguments are
`%buffer' structs."
  (let ((actual
         (with-temp-buffer
           (%set-buffer-state before)
           (funcall function)
           (%get-buffer-state))))
    ; `equal' works on structs, but output of ert would be less readable.
    (should (equal (%buffer-content actual) (%buffer-content after)))
    (should (equal (%buffer-point actual) (%buffer-point after)))))

(cl-defun %execline-indentation (before after &optional (point-marker "|"))
  "Check that `execline-indent-line-function' changes buffer in expected way.

Parse structs `%buffer' from strings BEFORE and AFTER with POINT-MARKER,
and check with `%test-buffer-edit', that `execline-indent-line-function'
actually changes buffer state as specified by BEFORE and AFTER arguments,
aborting current test otherwise."
  (let ((tab-width 8)
        (indent-tabs-mode t))
    (%test-buffer-edit
     (%parse-buffer-state before point-marker)
     (%parse-buffer-state after point-marker)
     #'execline-indent-line-function)))

(defun %get-file-content (file)
  "Get content of FILE as string."
  (with-temp-buffer
    (insert-file-contents file)
    (buffer-string)))

(ert-deftest test-indentation-examples ()
  "Test examples in t/data/indent/*/{before,after}."
  (cd "t/data/indent")
  (dolist (dir (directory-files "."))
    (unless (or (equal dir ".") (equal dir ".."))
      (let ((before (%get-file-content (format "%s/before" dir)))
            (after    (%get-file-content (format "%s/after"  dir))))
        (%execline-indentation before after)))))

;;; execline-test.el ends here
