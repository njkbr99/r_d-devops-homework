SELECT
    p.parent_id,
    p.first_name  AS parent_first_name,
    p.last_name   AS parent_last_name,
    c.child_id,
    c.first_name  AS child_first_name,
    c.last_name   AS child_last_name,
    pc.tuition_fee
FROM Parents p
         JOIN Parent_Children pc ON pc.parent_id = p.parent_id
         JOIN Children c ON c.child_id = pc.child_id
ORDER BY p.last_name, p.first_name, c.last_name, c.first_name;