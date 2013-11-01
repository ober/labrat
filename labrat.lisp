(ql:quickload :drakma)

(defun writeFile (name content)
    (with-open-file (stream name
        :direction :output
        :if-exists :overwrite
        :if-does-not-exist :create)
      (format stream content)))

(defun fetch-each-server ()
  (let ((count 0))
    (with-open-file
        (stream "/tmp/servers.txt")
      (do
       ((line
         (read-line stream nil)
         (read-line stream nil)))
       ((null line))
        (setq count (+ count 1))
       (sb-thread:make-thread
       (lambda ()
         (writeFile (format nil "/tmp/servers/~A" line) (format nil "~A" (drakma:http-request (format nil "http://~A:44444/pinky/disk" line)  :connection-timeout 1 ) ))))))))

;;(fetch-each-server)
(sb-ext:save-lisp-and-die "labrat" :executable t :toplevel 'fetch-each-server)
