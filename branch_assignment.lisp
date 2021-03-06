(defun b-to-s (b s)
  "Assign branches to subprojects"
  ;; b >= s
  (cond ((or (zerop b) (zerop s)) '())
	(t (nconc (list (list s b))
		  (b-to-s b (1- s))
		  (b-to-s (1- b) s)))))

(defun distinct-b-to-s (b s)
  (remove-duplicates (b-to-s b s)
		     :test #'equal))

(defun inclusive-range (a b)
  "An inclusive range on interval [a b]"
  (if (> a b) '()
      (cons a
	    (inclusive-range (1+ a) b))))

(defun duplicates? (lst &key (test #'eql))
  (and lst
       (or (member (car lst) (cdr lst) :test test)
	   (duplicates? (cdr lst) :test test))))

(defun assign-branches-to-subprojects (branches subprojs)
  "b >= s. Disjoint groups, assigned from branches to subgroups"
  (let* ((B (inclusive-range 1 branches))
	 (S (inclusive-range 1 subprojs))
	 (groups (remove-if #'duplicates?
			    (loop for x in S
			       nconc (loop for y in (permute-list-n B (floor branches subprojs))
					collect (cons x y)))))
	 (remainder (mod branches subprojs)))
    (cond ((and (evenp branches) (evenp subprojs))
	   groups)
	  (t (nconc groups
		    (loop for x from (- branches remainder) to subprojs
		       nconc (loop for y in groups
				collect (append y (list x)))))))))

(defun distinct-branch-assignments (branches subprojs)
  ;(remove-duplicates (assign-branches-to-subprojects branches subprojs)
  ;		     :test #'(lambda (x y) (equal (cdr x) (cdr y)))))
  (remove-if #'duplicates? (assign-branches-to-subprojects
			    branches subprojs)))

(defun permute-list-n (lst n)
  (remove-duplicates (mapcar #'(lambda (x)
				 (subseq x 0 n))
			     (permute-list lst))
		     :test #'equal))

(defun permute-list (lst)
  (if (= (length lst) 1) (list lst)
      (loop for iter in (permute-list (cdr lst))
	 nconc (loop for y below (length lst) 
		  collect (nconc (subseq iter 0 y)
				 (cons (car lst)
				       (subseq iter y)))))))

(defun min-dist-intersections-to-hq (hq intersections sent)
  (cond ((= sent hq) '())
	(t (cons (cons sent
		       (loop for (u v l) in intersections
			  when (and (or (eql sent u) (eql sent v))
				    (or (eql hq u) (eql hq v)))
			  minimizing l into d finally (return d)))
		 (min-dist-intersections-to-hq hq intersections (1+ sent))))))

(defun dist-to-hq (intersection min-dists)
  "Distance to headquarters from intersection. Uses value from MIN-DIST-INTERSECTIONS-TO-HQ."
  (cdr (assoc intersection
	      min-dists)))

(defun find-min-dist (intersections path from to)
  (cond ((null path) nil) ;; there's no way, shouldn't happen
	((eql (caar path) to)
	 (progn (format t "~A~%" path)
		(loop for (u v l) in (cdr path) summing l)))
	(t (let* ((addnl (loop for (p u v l) in intersections
			    when (and (eql u (cadr (car path)))
				      p
				      (not (member (list u v l)
						   path
						   :test #'equal)))
			    collect (list u v l)))
		  (min-addnl (loop for (u v l) in addnl
				minimize l
				finally (return (list (list u v l)))))
		  (new-intersections (mapcar #'(lambda (x)
						 (if (member (cdr x) min-addnl :test #'equal)
						     (cons nil (cdr x))
						     x))
					     intersections)))
	     (cond ((null addnl)
		    (find-min-dist new-intersections
				   (cdr path)
				   from to))
		   (t (find-min-dist new-intersections
				     (append min-addnl path)
				     from to)))))))

(defun find-min (lst &key (key #'identity))
  (reduce #'(lambda (x y)
	      (min x (funcall key y)))
	  lst))

(defun min-dist-hq-to-intersections (hq intersections)
  (let ((starting (find-min (loop for (u v l) in intersections
			       when (eql u hq)
			       collect (list u v l))
			    :key #'(lambda (x) (subseq x 2))))
	(intersections* (loop for x in intersections
			   collect (cons T x))))
    (loop for i from 1 below hq
       collect (find-min-dist intersections* (list starting) hq i))))

(defvar +insx+
  '((5 2 1)
    (2 5 1)
    (3 5 5)
    (4 5 0)
    (1 5 1)
    (2 3 1)
    (3 2 5)
    (2 4 5)
    (2 1 1)
    (3 4 2)))
