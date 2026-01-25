SELECT
    c.child_id,
    c.first_name,
    c.last_name,
    i.institution_name,
    i.institution_type,
    cl.class_name,
    cl.direction
FROM Children c
         JOIN Institutions i ON c.institution_id = i.institution_id
         JOIN Classes cl ON c.class_id = cl.class_id
ORDER BY i.institution_name, cl.class_name, c.last_name;
