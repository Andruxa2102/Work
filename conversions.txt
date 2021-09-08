-- workers conversion
SELECT inv.project_id, inv.spec_id, inv.region_id, inv.cnt_invited, workd.cnt_working, (workd.cnt_working / inv.cnt_invited) AS convrersion 
FROM (SELECT project_id, spec_id, region_id, COUNT(*) AS cnt_invited
FROM couriers 
WHERE created BETWEEN '2021,9,1' AND '2021,9,10'
GROUP BY project_id, spec_id) AS inv
JOIN (SELECT project_id, spec_id, region_id, COUNT(*) AS cnt_working
FROM couriers 
WHERE id IN 
(SELECT couriers.id FROM contracts 
JOIN couriers ON contracts.courier_id = couriers.id) 
AND created BETWEEN '2021,9,1' AND '2021,9,10'
GROUP BY project_id, spec_id, region_id) AS workd
ON inv.project_id = workd.project_id AND inv.spec_id = workd.spec_id AND
inv.region_id = workd.region_id;

-- training conversion
SELECT state_details, cnt, SUM(a.cnt) OVER() AS summa, cnt/(SUM(a.cnt) OVER()) AS conversion FROM 
(SELECT state_details, COUNT(state_details) AS cnt FROM couriers
WHERE state_details <> -1
GROUP BY state_details) AS a
ORDER BY state_details;