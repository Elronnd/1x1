(load "/home/elronnd/quicklisp/setup.lisp")
(ql:quickload :sqlite)


(defparameter *db* (sqlite:connect "db.sqlite3"))

(sqlite:execute-non-query *db* "create table files (hash text primary key)")
(sqlite:disconnect *db*)


(ensure-directories-exist "files/")
