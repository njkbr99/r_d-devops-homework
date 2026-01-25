-- Ensure DB exists.
CREATE DATABASE IF NOT EXISTS SchoolDB
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE SchoolDB;

-- Institutions
CREATE TABLE IF NOT EXISTS Institutions (
    institution_id INT AUTO_INCREMENT PRIMARY KEY,
    institution_name VARCHAR(255) NOT NULL,
    institution_type ENUM('School','Kindergarten') NOT NULL,
    address VARCHAR(255) NOT NULL,
    UNIQUE KEY uq_institution_name (institution_name)
) ENGINE=InnoDB;

-- Classes
CREATE TABLE IF NOT EXISTS Classes (
    class_id INT AUTO_INCREMENT PRIMARY KEY,
    class_name VARCHAR(100) NOT NULL,
    institution_id INT NOT NULL,
    direction ENUM('Mathematics','Biology and Chemistry','Language Studies') NOT NULL,
    UNIQUE KEY uq_class_inst_name (institution_id, class_name),
    CONSTRAINT fk_classes_institution
        FOREIGN KEY (institution_id) REFERENCES Institutions(institution_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Children
CREATE TABLE IF NOT EXISTS Children (
    child_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    birth_date DATE NOT NULL,
    year_of_entry YEAR NOT NULL,
    age INT NOT NULL,
    institution_id INT NOT NULL,
    class_id INT NOT NULL,
    UNIQUE KEY uq_child_identity (first_name, last_name, birth_date),
    CONSTRAINT fk_children_institution
        FOREIGN KEY (institution_id) REFERENCES Institutions(institution_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE,
    CONSTRAINT fk_children_class
        FOREIGN KEY (class_id) REFERENCES Classes(class_id)
        ON DELETE RESTRICT
        ON UPDATE CASCADE
) ENGINE=InnoDB;

-- Parents
CREATE TABLE IF NOT EXISTS Parents (
    parent_id INT AUTO_INCREMENT PRIMARY KEY,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL
) ENGINE=InnoDB;

-- Link table: parent <-> child, plus tuition_fee (per child)
CREATE TABLE IF NOT EXISTS Parent_Children (
    parent_id INT NOT NULL,
    child_id INT NOT NULL,
    tuition_fee DECIMAL(10,2) NOT NULL,
    PRIMARY KEY (parent_id, child_id),
    CONSTRAINT fk_pc_parent
        FOREIGN KEY (parent_id) REFERENCES Parents(parent_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_pc_child
        FOREIGN KEY (child_id) REFERENCES Children(child_id)
        ON DELETE CASCADE
        ON UPDATE CASCADE
) ENGINE=InnoDB;