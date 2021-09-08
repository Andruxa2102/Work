
-- 1. Еженедельная конверсия - приглашенные - оформленные (работающие).  В разрезе городов - проектов - вакансий 
SELECT inv.project_id, inv.spec_id, inv.region_id, inv.cnt_invited, workd.cnt_working, (workd.cnt_working / inv.cnt_invited) AS convrersion FROM
(SELECT project_id, spec_id, region_id, COUNT(*) AS cnt_invited
FROM couriers 
WHERE created BETWEEN '2021,9,1' AND '2021,9,10'
GROUP BY project_id, spec_id) AS inv
JOIN 
(SELECT project_id, spec_id, region_id, COUNT(*) AS cnt_working
FROM couriers 
WHERE id IN 
(SELECT couriers.id FROM contracts 
JOIN couriers ON contracts.courier_id = couriers.id) 
AND created BETWEEN '2021,9,1' AND '2021,9,10'
GROUP BY project_id, spec_id, region_id) AS workd
ON inv.project_id = workd.project_id AND inv.spec_id = workd.spec_id AND
inv.region_id = workd.region_id;


-- 2. Конверсия по этапам стажировки (отслеживать где у нас процент отсеивания самый большой идет)
SELECT state_details, cnt, SUM(a.cnt) OVER() AS summa, cnt/(SUM(a.cnt) OVER()) AS conversion FROM 
(SELECT state_details, COUNT(state_details) AS cnt FROM couriers
WHERE state_details <> -1
GROUP BY state_details) AS a
ORDER BY state_details;

-- 3.1. Сколько обработал карточек (даже если с одной и той же работал, маркер - поставил коммент или поменял статус) во всех разделах.
SELECT hhd.creator_id, u.surname, u.name, hhd.any_actions FROM
(SELECT creator_id, COUNT(*) AS any_actions
FROM history_details AS hd
JOIN 
(SELECT * FROM histories
  WHERE object_type = 1 AND created >= '2021,9,1' AND created <= '2021,9,30' AND creator_id IN
   (SELECT id FROM users WHERE department_id = 6)) AS h
  ON h.id = hd.history_id
GROUP BY creator_id) AS hhd
JOIN users AS u ON u.id = hhd.creator_id;


-- 3.2. Сколько пригласил (если раздел Контакты)/восстановил (если раздел исполнители, маркер - перевод в статус Новый или Восстановлен)
SELECT h.creator_id, u.surname, u.name, COUNT(*) AS vosstan_priglasheno FROM history_details hd
JOIN histories h ON h.id = hd.history_id
JOIN users u ON h.creator_id = u.id
WHERE ((hd.field_name = 'StateId' AND hd.value_new = 37 AND h.object_type = 3) OR (hd.field_name = 'StateDetails' AND hd.value_new = 19 AND h.object_type = 1)) AND 
	h.created >= '2021,9,1' AND h.created <= '2021,9,30' AND h.creator_id IN
   (SELECT id FROM users WHERE department_id = 6)
   GROUP BY h.creator_id
	ORDER BY vosstan_priglasheno;
	
	
-- 3.2. + 3.3. Сколько из созданных или восстановленных в итоге оформлены 
SELECT creator_id, surname, 'name', SUM(work_cnt), COUNT(*) FROM (
SELECT h.object_id, h.creator_id, u.surname, u.name, IF (COUNT(c.id) > 0, 1, 0) work_cnt FROM history_details hd
JOIN histories h ON h.id = hd.history_id
JOIN users u ON h.creator_id = u.id
LEFT JOIN contracts c ON c.courier_id = h.object_id
WHERE hd.field_name = 'StateDetails' AND hd.value_new = 19 AND h.object_type = 1 AND 
	h.created >= '2021,9,1' AND h.created <= '2021,9,30' AND h.creator_id IN
   (SELECT id FROM users WHERE department_id = 6)
   GROUP BY h.object_id, h.creator_id, u.surname, u.name
UNION
SELECT h.object_id, h.creator_id, u.surname, u.name, COUNT(c.id) work_cnt FROM history_details hd
JOIN histories h ON h.id = hd.history_id
JOIN users u ON h.creator_id = u.id
LEFT JOIN contacts c ON c.doer_id = h.object_id
WHERE hd.field_name = 'StateId' AND hd.value_new = 37 AND h.object_type = 3 AND 
	h.created >= '2021,9,1' AND h.created <= '2021,9,30' AND h.creator_id IN
   (SELECT id FROM users WHERE department_id = 6)
GROUP BY h.object_id, h.creator_id, u.surname, u.name) AS unioned
GROUP BY creator_id, surname, 'name';