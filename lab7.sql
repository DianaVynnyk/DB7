SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='ONLY_FULL_GROUP_BY,STRICT_TRANS_TABLES,NO_ZERO_IN_DATE,NO_ZERO_DATE,ERROR_FOR_DIVISION_BY_ZERO,NO_ENGINE_SUBSTITUTION';
 SET GLOBAL log_bin_trust_function_creators = 1;
-- -----------------------------------------------------
-- Schema pharmacy
-- -----------------------------------------------------
DROP SCHEMA IF EXISTS pharmacy ;

-- -----------------------------------------------------
-- Schema pharmacy
-- -----------------------------------------------------
CREATE SCHEMA IF NOT EXISTS pharmacy ;
USE pharmacy ;

-- -----------------------------------------------------
-- Table pharmacy.position
-- -----------------------------------------------------
DROP TABLE IF EXISTS pharmacy.position ;

CREATE TABLE IF NOT EXISTS pharmacy.position (
  name VARCHAR(50) NOT NULL,
  PRIMARY KEY (name))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table pharmacy.street_name
-- -----------------------------------------------------
DROP TABLE IF EXISTS pharmacy.street_name ;

CREATE TABLE IF NOT EXISTS pharmacy.street_name (
  name VARCHAR(50) NOT NULL,
  PRIMARY KEY (name))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table pharmacy.pharmacy_institution
-- -----------------------------------------------------
DROP TABLE IF EXISTS pharmacy.pharmacy_institution ;

CREATE TABLE IF NOT EXISTS pharmacy.pharmacy_institution (
  id INT NOT NULL auto_increment,
  house_number INT NOT NULL,
  webpage VARCHAR(45) NULL,
  start_time TIME NOT NULL,
  end_time TIME NOT NULL,
  isOnSaturday TINYINT NOT NULL,
  isOnSunday TINYINT NOT NULL,
  street_name VARCHAR(50) NOT NULL,
  PRIMARY KEY (id, street_name),
  INDEX fk_pharmacy_institution_street_name1_idx (street_name ASC) VISIBLE,
  CONSTRAINT fk_pharmacy_institution_street_name1
    FOREIGN KEY (street_name)
    REFERENCES pharmacy.street_name (name)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table pharmacy.employees
-- -----------------------------------------------------
DROP TABLE IF EXISTS pharmacy.employees ;

CREATE TABLE IF NOT EXISTS pharmacy.employees (
  id INT NOT NULL auto_increment,
  first_name VARCHAR(45) NOT NULL,
  last_name VARCHAR(45) NOT NULL,
  identification_number INT NOT NULL,
  series_passport_number VARCHAR(45) NOT NULL,
  seniority INT NOT NULL,
  date_of_birth DATE NOT NULL,
  position_name VARCHAR(50) NOT NULL,
  pharmacy_institution_id INT NOT NULL,
  PRIMARY KEY (id, position_name, pharmacy_institution_id),
  INDEX fk_employees_position_idx (position_name ASC) VISIBLE,
  INDEX fk_employees_pharmacy_institution1_idx (pharmacy_institution_id ASC) VISIBLE,
  CONSTRAINT fk_employees_position
    FOREIGN KEY (position_name)
    REFERENCES pharmacy.position (name)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_employees_pharmacy_institution1
    FOREIGN KEY (pharmacy_institution_id)
    REFERENCES pharmacy.pharmacy_institution (id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table pharmacy.list_of_madicine
-- -----------------------------------------------------
DROP TABLE IF EXISTS pharmacy.list_of_medicine ;

CREATE TABLE IF NOT EXISTS pharmacy.list_of_medicine (
  id INT NOT NULL auto_increment,
  name VARCHAR(50) NOT NULL,
  ministry_code VARCHAR(4) NOT NULL,
  isPsyhotropic TINYINT NOT NULL,
  sDrug TINYINT NOT NULL,
  withRecept TINYINT NOT NULL,
  PRIMARY KEY (id))
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table pharmacy.influence
-- -----------------------------------------------------
DROP TABLE IF EXISTS pharmacy.influence ;
CREATE TABLE IF NOT EXISTS pharmacy.influence (
  organ VARCHAR(50) NOT NULL,
  PRIMARY KEY (organ),
  UNIQUE INDEX organ_UNIQUE (organ ASC) VISIBLE)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table pharmacy.has_influence
-- -----------------------------------------------------
DROP TABLE IF EXISTS pharmacy.has_influence ;

CREATE TABLE IF NOT EXISTS pharmacy.has_influence (
  list_of_madicine_id INT NOT NULL,
  influence_organ VARCHAR(50) NOT NULL,
  PRIMARY KEY (list_of_madicine_id, influence_organ),
  INDEX fk_list_of_madicine_has_influence_influence1_idx (influence_organ ASC) VISIBLE,
  INDEX fk_list_of_madicine_has_influence_list_of_madicine1_idx (list_of_madicine_id ASC) VISIBLE,
  CONSTRAINT fk_list_of_madicine_has_influence_list_of_madicine1
    FOREIGN KEY (list_of_madicine_id)
    REFERENCES pharmacy.list_of_madicine (id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT fk_list_of_madicine_has_influence_influence1
    FOREIGN KEY (influence_organ)
    REFERENCES pharmacy.influence (organ)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


-- -----------------------------------------------------
-- Table pharmacy.medicine_avaible
-- -----------------------------------------------------
DROP TABLE IF EXISTS pharmacy.medicine_avaible ;

CREATE TABLE IF NOT EXISTS pharmacy.medicine_avaible (
  pharmacy_institution_id INT NOT NULL,
  list_of_madicine_id INT NOT NULL,
  PRIMARY KEY (pharmacy_institution_id,list_of_madicine_id),

    FOREIGN KEY (pharmacy_institution_id )
    REFERENCES pharmacy.pharmacy_institution (id )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
 
    FOREIGN KEY (list_of_madicine_id)
    REFERENCES pharmacy.list_of_madicine (id)
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
 DELIMITER //
DELIMITER $$
 CREATE DEFINER=root`@`localhost FUNCTION getSeniorityAVG() RETURNS mediumtext CHARSET utf8mb4
BEGIN
  RETURN (SELECT AVG(seniority) FROM employees);
END
//
DELIMITER ;

SELECT pharmacy.getSeniorityAVG() as seniority_avg
SELECT * from employees where seniority > (SELECT pharmacy.getSeniorityAVG() as seniority_avg)

 DELIMITER //

 CREATE  FUNCTION findWorkTime(id INT) 
 
 RETURNS VARCHAR(50) 
BEGIN
  RETURN (SELECT  concat (p.start_time, "-", p.end_time) as work_time 
from employees as e, pharmacy_institution as p where  e.id = id);
END //
DELIMITER ;

SELECT first_name, last_name, findWorkTime(1) from employees, pharmacy_institution where pharmacy_institution_id = 1;


DELIMITER //
CREATE TRIGGER BeforeInsertPharmacyInstitutionCheckFK
BEFORE INSERT
ON pharmacy_institution FOR EACH ROW
BEGIN
  IF ((new.street_name NOT IN (SELECT name FROM street_name)))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Insert: foreign key failure";
  END IF;
END //
DELIMITER ;


DELIMITER //
CREATE TRIGGER BeforeInsertMedicineAvaibleCheckFK
BEFORE INSERT
ON medicine_avaible FOR EACH ROW
BEGIN
  IF ((new.pharmacy_institution_id NOT IN (SELECT id FROM pharmacy_institution) OR 
    (new.list_of_madicine_id NOT IN (SELECT id FROM list_of_medicine))))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Insert: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeInsertHasInfluenceCheckFK
BEFORE INSERT
ON has_influence FOR EACH ROW
BEGIN
  IF ((new.list_of_madicine_id NOT IN (SELECT id FROM list_of_medicine) OR 
    (new.influence_organ NOT IN (SELECT organ FROM influence))))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Insert: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeDeleteStreetNameCheckFK
BEFORE DELETE
ON street_name FOR EACH ROW
BEGIN
  IF (old.name IN (SELECT street_name FROM pharmacy_institution))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Delete: foreign key failure";
  END IF;
END //
DELIMITER ;
DELIMITER //
CREATE TRIGGER BeforeDeletePositionCheckFK
BEFORE DELETE
ON position FOR EACH ROW
BEGIN
  IF (old.name IN (SELECT name FROM position))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Delete: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeDeleteListOfMedicineCheckFK
BEFORE DELETE
ON list_of_medicine FOR EACH ROW
BEGIN
  IF ((old.id IN (SELECT list_of_medicine_id FROM has_influence) OR (SELECT list_of_medicine_id
    FROM medicine_avaible)))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Delete: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeDeletePharmacyInstitutionCheckFK
BEFORE DELETE
ON pharmacy_institution FOR EACH ROW
BEGIN
  IF (old.id IN (SELECT pharmacy_institution_id FROM employees))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Delete: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeDeleteInfluenceCheckFK
BEFORE DELETE
ON influence FOR EACH ROW
BEGIN
  IF (old.organ IN (SELECT influence_organ FROM has_influence))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Delete: foreign key failure";
  END IF;
END //
DELIMITER ;

UPGRADE:
DELIMITER //
CREATE TRIGGER BeforeUpdatePositionCheckFK
BEFORE UPDATE
ON position FOR EACH ROW
BEGIN
  IF (old.name != new.name 
        AND (
      old.name IN (SELECT position_name FROM employees)
    )
    )
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Update: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeUpdatePharmacyInstitutionCheckFK
BEFORE UPDATE
ON pharmacy_institution FOR EACH ROW
BEGIN
  IF (old.id != new.id 
        AND (
      old.id IN (SELECT pharmacy_institution_id FROM employees) 
      OR old.id IN (SELECT pharmacy_institution_id FROM medicine_avaible)
    )
    )
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Update: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeUpdateInfluenceCheckFK
BEFORE UPDATE
ON influence FOR EACH ROW
BEGIN
  IF (old.organ != new.organ 
        AND (
      old.organ IN (SELECT influence_organ FROM has_influence)
    )
    )
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Update: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeUpdateStreetNameCheckFK
BEFORE UPDATE
ON street_name FOR EACH ROW
BEGIN
  IF (old.name != new.name 
        AND (
      old.name IN (SELECT street_name FROM pharmacy_institution)
    )
    )
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Update: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeUpdateListOfMedicineCheckFK
BEFORE UPDATE
ON list_of_medicine FOR EACH ROW
BEGIN
  IF (old.id != new.id 
        AND (
      old.id IN (SELECT list_of_madicine_id FROM has_influence) 
      OR old.id IN (SELECT list_of_madicine_id FROM medicine_avaible)
    )
    )
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Update: foreign key failure";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeInsertEmployeesCheckFK
BEFORE INSERT
ON employees FOR EACH ROW
BEGIN
  IF ((new.position_name NOT IN (SELECT name FROM position)) OR (new.pharmacy_institution_id NOT IN
    (SELECT id from pharmacy_institution)))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Insert: foreign key failure";
  END IF;
END //
DELIMITER ;



DELIMITER //
CREATE TRIGGER BeforeInsertIdentificationNumber

BEFORE INSERT
ON employees FOR EACH ROW
FOLLOWS BeforeInsertEmployeesCheckFK

BEGIN
  
  IF (new.identification_number NOT RLIKE("[0-9]{1,10}"))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Employees: identification_number is not correct";
  END IF;
END //
DELIMITER ;
DELIMITER //
CREATE TRIGGER BeforeDeleteFromPharmacyInstitution
BEFORE delete
ON pharmacy_institution FOR EACH ROW
FOLLOWS BeforeDeletePharmacyInstitutionCheckFK
BEGIN
  
  IF ( (SELECT COUNT(*) FROM pharmacy_institution) < 4)
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for Pharmacy Institution: cardinality is < 4";
  END IF;
END //
DELIMITER ;

DELIMITER //
CREATE TRIGGER BeforeInsertListOfMedicine
BEFORE insert
ON list_of_medicine FOR EACH ROW

BEGIN
  IF (new.ministry_code NOT RLIKE CONCAT("^", SUBSTRING(new.name, 1, 1), "[0-9][0-9][0-9]"))
  THEN SIGNAL SQLSTATE "45000"
    SET MESSAGE_TEXT = "CHECK error for list of medicine: value does not match pattern";
  END IF;
END //


 
DELIMITER //
CREATE PROCEDURE insertIntoMedicineAvaible(IN pharmacy_id INT, 
IN medicine_id int)
BEGIN
  create table medicine_avaible_string(
    pharmacy_name VARCHAR(50),
        medicine_name VARCHAR(50)
    );
    insert into medicine_avaible_string () VALUES((
    SELECT street_name from pharmacy_institution where id = pharmacy_id), (SELECT name FROM
    list_of_medicine where id = medicine_id));
END //
  

DELIMITER //
CREATE PROCEDURE insertIntoPharmacyInstitution(IN house_number INT, 
IN webpage varchar(45), IN start_time time, IN end_time time, isOnSaturday BOOLEAN, IN isOnSunday BOOLEAN,
IN street_name VARCHAR (50))
BEGIN
    INSERT INTO pharmacy_institution(house_number, webpage, start_time, end_time,
    isOnSaturday, isOnSunday, street_name) 
    VALUES (house_number, webpage, start_time, end_time, isOnSaturday, isOnSunday, street_name);
END
 //
  

DELIMITER //


DROP procedure IF EXISTS CreateNewTables;


USE `pharmacy`$$
CREATE DEFINER=root`@`localhost PROCEDURE CreateNewTables()
BEGIN

DECLARE done int DEFAULT false;
DECLARE name_position VARCHAR(45);

DECLARE position_cursor CURSOR
FOR SELECT name FROM position;
DECLARE CONTINUE HANDLER
FOR NOT FOUND SET done = true;

OPEN position_cursor;
myLoop: LOOP

  FETCH position_cursor INTO name_position;

  IF done=true THEN LEAVE myLoop;
  END IF;
  SET @temp_query=CONCAT("CREATE TABLE IF NOT EXISTS `", name_position, 
  " (`name VARCHAR(45) NOT NULL, code VARCHAR(45) NOT NULL, PRIMARY KEY (name))");
  

  PREPARE myquery FROM @temp_query;
  EXECUTE myquery;
  DEALLOCATE PREPARE myquery;

END LOOP;



CLOSE position_cursor;

END$$

DELIMITER ;