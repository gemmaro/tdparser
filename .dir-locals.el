;;; Directory Local Variables            -*- no-byte-compile: t -*-
;;; For more information see (info "(emacs) Directory Variables")

((nil
  . ((eval
      . (progn
          (require 'grep)
          (add-to-list 'grep-find-ignored-directories "html")
          (add-to-list 'grep-find-ignored-directories "coverage"))))))
