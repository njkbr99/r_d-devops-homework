SELECT
    i.institution_id,
    i.institution_name,
    i.institution_type,
    i.address,
    COUNT(c.child_id) AS children_count
FROM Institutions i
         LEFT JOIN Children c ON c.institution_id = i.institution_id
GROUP BY i.institution_id, i.institution_name, i.institution_type, i.address
ORDER BY children_count DESC, i.institution_name;
