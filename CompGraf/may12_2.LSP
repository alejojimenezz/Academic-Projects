(setq e (cdr (assoc 330 datos)))
(setq edata (entget e))

(mapcar 'print edata)