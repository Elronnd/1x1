(load "/home/elronnd/quicklisp/setup.lisp")
(ql:quickload :clack)
(ql:quickload :ningle)
(ql:quickload :sqlite)
(ql:quickload :ironclad)


(defparameter *port* 8080)
(defparameter *app* (make-instance 'ningle:<app>))
(defparameter *help-text* "Welcome to 1x1!
This is a common lisp clone of 0x0.st, available at https://0x0.st/ or https://github.com/lachs0r/0x0.
All files are kept for 30 days.  This number may someday change.
The source code for this site is available at https://github.com/Elronnd/1x1.
No information will be logged, unless at upload time, \"log_ip\" is set to \"true\".  This is useful because if you would like to delete something, you can prove it comes from you.
Any file deletion requests should go to elronnd@slashem.me")
(defparameter *host* "http://localhost:8080/")

(defparameter *db* (sqlite:connect "db.sqlite3"))

(defun sha256 (str)
  (ironclad:byte-array-to-hex-string
    (ironclad:digest-sequence :sha256
                              (ironclad:ascii-string-to-byte-array str))))
(defun hash (str)
  (sha256 str))

(defun handle-file (file-text)
  (let ((hash (hash file-text)))
    (unless (sqlite:execute-single *db* "select * from files where hash = ?" hash)
      (with-open-file (file (concatenate 'string "files/" hash) :direction :OUTPUT)
        (format file file-text))

      (sqlite:execute-non-query *db* "insert into files (hash) values (?)" hash))

    (concatenate 'string *host* (write-to-string (sqlite:execute-single *db* "select rowid from files where hash = ?" hash)))))


(setf (ningle:route *app* "/")
      *help-text*)
(setf (ningle:route *app* "/" :method :POST)
      #'(lambda (params)
          (let ((filetext (assoc "file" params :test #'string=)))
            (if filetext
                (handle-file (cadr filetext))
                "No file supplied??"))))

(setf (ningle:route *app* "/*")
      #'(lambda (params)
          (let ((id (cadr (assoc :splat params))))
            (if (sqlite:execute-single *db* "select * from files where rowid = ?" id)
                (with-open-file (file (concatenate 'string "files/" (sqlite:execute-single *db* "select hash from files where rowid = ?" id)))
                  (let ((seq (make-string (file-length file))))
                    (read-sequence seq file)
                    seq))
                "No file with that id found"))))

;(defun quit ()
;  (clack:close *handler*))

(defparameter *handler*
  (clack:clackup *app* :port *port* :server :woo :silent nil :use-thread t))
