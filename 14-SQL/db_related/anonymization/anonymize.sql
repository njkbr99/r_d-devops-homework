USE SchoolDB_Restore;

SET NAMES utf8mb4;

UPDATE Children
SET first_name = 'Child',
    last_name  = 'Anonymous';

UPDATE Parents
SET first_name = CONCAT('Parent', parent_id),
    last_name  = 'Anon';

UPDATE Institutions
SET institution_name = CONCAT('Institution', institution_id),
    address = CONCAT('UA, Address ', institution_id);

UPDATE Parent_Children
SET tuition_fee = 2000 + (MOD(parent_id * 37 + child_id * 13, 21) * 100);
