;;; persp-projectile.el --- Perspective integration with Projectile

;; Copyright (C) 2014-2016 Daniel Wu, Bozhidar Batsov

;; Author: Daniel Wu
;; Created: 2014-04-14
;; Keywords: project, convenience
;; Version: 0.2.0
;; Package-Requires: ((perspective "1.9") (projectile "0.11.0") (cl-lib "0.3"))

;; This file is NOT part of GNU Emacs.

;;; License:

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 3, or (at your option)
;; any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to the
;; Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:
;;
;; This library bridges perspective mode to the awesome library
;; Projectile.  The idea is to create a separate perspective when
;; switching project.  A perspective is an independant workspace for
;; Emacs, similar to multiple desktops in Gnome and MacOS.  I often
;; work on many projects at the same time, and using perspective and
;; projectile together allows me to easily know which project I'm
;; current in, and focus on files that only belong to current project
;; when switching buffer.

;; To use this library, put this file in your Emacs load path, and
;; call (require 'persp-projectile)

;; See perspective.el on github: https://github.com/nex3/perspective-el

;;; Code:
(require 'perspective)
(require 'projectile)

;; TODO this may be incompatible helm which let's you find stuff in new frame
(defmacro projectile-persp-bridge (func-name)
  "Create advice to create a perspective before invoking function FUNC-NAME.
The advice provides bridge between perspective and projectile
functions when switch between projects.  After switching to a new
project, this advice creates a new perspective for that project."
  `(defadvice ,func-name (before projectile-create-perspective-after-switching-projects activate)
     "Create a dedicated perspective for current project's window after switching projects."
     (let ((project-name (projectile-project-name)))
       (when (projectile-project-p)
         (persp-switch project-name)))))

(projectile-persp-bridge projectile-dired)
(projectile-persp-bridge projectile-find-file)

(defun projectile-persp-create-or-switch-to-persp (project &rest args)
  "Switch to a PROJECT with ARGS .
If the perspective of corresponding project does not exist, create it.

Otherwise, this function calls `persp-switch' to switch to an
existing perspective of the project unless we're already in that
perspective."
  (let* ((name (file-name-nondirectory (directory-file-name project)))
         (persp (gethash name perspectives-hash)))
    (cond
     ;; project-specific perspective already exists
     ((and persp (not (equal persp persp-curr)))
      (persp-switch name))
     ;; project-specific perspective doesn't exist
     ((not persp)
      (let ((frame (selected-frame)))
        (persp-switch name)
        (when (not (equal frame (selected-frame)))
          (with-selected-frame frame
            (persp-kill name))))
      ))))

(advice-add 'projectile-switch-project-by-name
            :around #'projectile-persp-create-or-switch-to-persp)

(defadvice persp-init-frame (after projectile-persp-init-frame activate)
  "Rename  perspective to `projectile-project-name' when a new frame is created in a known project."
  (with-selected-frame frame
    (when (projectile-project-p)
      (persp-rename (projectile-project-name)))))

(provide 'persp-projectile)
;;; persp-projectile.el ends here
