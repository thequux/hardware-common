;; -*- scheme -*-

(use-modules (ice-9 ftw))

(define (add-component-library-recursively path)
  (map (lambda (dirname)
	 (let ((full-dir-name (string-append path "/" dirname)))
	   (when (and (not (string-prefix? "." dirname))
		      (eq? (stat:type (stat full-dir-name)) 'directory))
	     (component-library full-dir-name))))
       (scandir path)))

