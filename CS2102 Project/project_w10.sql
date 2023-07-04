------------------------------------------------------------------------
------------------------------------------------------------------------
--
-- CS2102 - PROJECT
--
------------------------------------------------------------------------
------------------------------------------------------------------------
DROP TABLE IF EXISTS Joins, Sessions, Updates, Juniors, Seniors, Managers, Bookers, HealthDeclarations, Employees, MeetingRooms, Departments;

CREATE TABLE Departments (
  did INTEGER PRIMARY KEY,
  dname VARCHAR(255)
);

CREATE TABLE Employees (
  eid INTEGER PRIMARY KEY,
  ename VARCHAR(255),
  email VARCHAR(255) UNIQUE, 
  home_phone INTEGER,
  mobile_phone INTEGER,
  office_phone INTEGER,
  resigned_date DATE,
  did INTEGER NOT NULL,
  FOREIGN KEY (did) REFERENCES Departments (did)
);


CREATE TABLE HealthDeclarations (
  eid INTEGER,
  declare_date DATE,
  temp FLOAT,
  fever BOOLEAN,
  PRIMARY KEY (eid, declare_date),
  FOREIGN KEY (eid) REFERENCES Employees (eid) ON DELETE CASCADE ON UPDATE CASCADE,
  CHECK (temp BETWEEN 34 AND 43),
  CHECK (temp <= 37.5 OR fever = TRUE)
);

CREATE TABLE Juniors (
  eid INTEGER PRIMARY KEY,
  FOREIGN KEY (eid) REFERENCES Employees (eid) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Bookers (
  eid INTEGER PRIMARY KEY,
  FOREIGN KEY (eid) REFERENCES Employees (eid) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Seniors (
  eid INTEGER PRIMARY KEY,
  FOREIGN KEY (eid) REFERENCES Bookers (eid) ON DELETE CASCADE ON UPDATE CASCADE
);

CREATE TABLE Managers (
  eid INTEGER PRIMARY KEY,
  FOREIGN KEY (eid) REFERENCES Bookers (eid) ON DELETE CASCADE ON UPDATE CASCADE
);


CREATE TABLE MeetingRooms (
  floor_num INTEGER,
  room_num INTEGER,
  rname VARCHAR(255),
  did INTEGER NOT NULL,
  PRIMARY KEY (floor_num, room_num),
  FOREIGN KEY (did) REFERENCES Departments (did)
);

CREATE TABLE Sessions (
  floor_num INTEGER,
  room_num INTEGER,
  booking_date DATE,
  booking_time INTEGER,
  booker_eid INTEGER NOT NULL,
  manager_eid INTEGER,
  PRIMARY KEY (floor_num, room_num, booking_date, booking_time),
  FOREIGN KEY (floor_num, room_num) REFERENCES MeetingRooms (floor_num, room_num),
  FOREIGN KEY (booker_eid) REFERENCES Bookers (eid),
  FOREIGN KEY (manager_eid) REFERENCES Managers (eid)
);

CREATE TABLE Joins (
  employee_eid INTEGER,
  floor_num INTEGER,
  room_num INTEGER,
  booking_date DATE,
  booking_time INTEGER,
  PRIMARY KEY (employee_eid, floor_num, room_num, booking_date, booking_time),
  FOREIGN KEY (employee_eid) REFERENCES Employees (eid),
  FOREIGN KEY (floor_num, room_num, booking_date, booking_time) REFERENCES Sessions (floor_num, room_num, booking_date, booking_time)
);

CREATE TABLE Updates (
  manager_eid INTEGER,
  floor_num INTEGER,
  room_num INTEGER,
  update_date DATE,
  new_capacity INTEGER,
  PRIMARY KEY (manager_eid, floor_num, room_num, update_date),
  FOREIGN KEY (manager_eid) REFERENCES Managers (eid),
  FOREIGN KEY (floor_num, room_num) REFERENCES MeetingRooms (floor_num, room_num)
);

CREATE OR REPLACE PROCEDURE add_department (IN dept_id INTEGER, IN dept_name VARCHAR(255))
AS $$
BEGIN
  IF dept_id IN (SELECT did FROM Departments) THEN 
    RAISE EXCEPTION 'Department ID [%] already exists', dept_id;
  ELSE
	IF dept_name IN (SELECT dname FROM Departments) THEN 
	  RAISE NOTICE 'Duplicate Department Name [%] exists', dept_name;
	END IF;
	
	INSERT INTO Departments
	VALUES (dept_id, dept_name);
  END IF;
END;
$$ LANGUAGE plpgsql;

CALL add_department(101, 'IT');
CALL add_department(102, 'MATH');
CALL add_department(103, 'HR');
CALL add_department(104, 'SECURITY');
CALL add_department(104, 'EXISTS');


SELECT * FROM Departments;

CREATE OR REPLACE PROCEDURE remove_department (IN dept_id INTEGER)
AS $$
BEGIN
  
  IF dept_id NOT IN (SELECT did FROM Departments) THEN
    RAISE NOTICE 'Department with ID [%] does not exist in Database', dept_id;
  ELSE
	DELETE FROM Departments
	WHERE did = dept_id;
  END IF;

END;
$$ LANGUAGE plpgsql;

CALL remove_department(101);

SELECT * FROM Departments;


CREATE OR REPLACE PROCEDURE add_employee (IN ename VARCHAR(255), IN phone_number INTEGER, IN employee_type VARCHAR(255), IN dept_id INTEGER)
AS $$
DECLARE
  new_eid INTEGER;
  new_email VARCHAR(255);
BEGIN
  SELECT MAX(eid) INTO new_eid FROM Employees;
  
  IF new_eid IS NULL THEN new_eid := 1001;
  ELSE new_eid := new_eid + 1;
  END IF;
  
  new_email := CONCAT(ename, '_', new_eid, '@company.com');
  
  IF employee_type IN ('junior', 'senior', 'manager') THEN
  
    INSERT INTO Employees
    VALUES (new_eid, ename, new_email, NULL, phone_number, NULL, NULL, dept_id);
  
    IF employee_type = 'junior' THEN
      INSERT INTO Juniors
	  VALUES (new_eid);
	
    ELSIF employee_type = 'senior' THEN
      INSERT INTO Bookers
	  VALUES (new_eid);
	
	  INSERT INTO Seniors
	  VALUES (new_eid);
	
    ELSIF employee_type = 'manager' THEN
      INSERT INTO Bookers
	  VALUES (new_eid);
	
	  INSERT INTO Managers
	  VALUES (new_eid);

    END IF;
  END IF;

END;
$$ LANGUAGE plpgsql;

CALL add_employee('Jianning', 90045299, 'manager', 102);
CALL add_employee('Zihan', 91234567, 'manager', 102);
CALL add_employee('Vikas', 92345678, 'manager', 102);
CALL add_employee('Yizhi', 93456789, 'manager', 102);
CALL add_employee('boy', 93456789, 'junior', 102);

SELECT * FROM Employees;
SELECT * FROM Managers;
SELECT * FROM Bookers;


CREATE OR REPLACE PROCEDURE remove_employee (IN employee_id INTEGER, IN last_date DATE)
AS $$

BEGIN

  IF last_date <= CURRENT_DATE THEN

    UPDATE Employees
    SET resigned_date = last_date
    WHERE eid = employee_id;
  
  END IF;
 
END;
  
$$ LANGUAGE plpgsql;

CALL remove_employee(1004, '2021-10-12');

SELECT * FROM Employees;


CREATE OR REPLACE PROCEDURE add_room (IN floor_number INTEGER, IN room_number INTEGER, IN room_name VARCHAR(255), IN room_capacity INTEGER, IN dept_id INTEGER, IN manager_id INTEGER, IN add_date DATE)
AS $$

  INSERT INTO MeetingRooms
  VALUES (floor_number, room_number, room_name, dept_id);
  
  INSERT INTO Updates
  VALUES (manager_id, floor_number, room_number, add_date, room_capacity);
  

$$ LANGUAGE sql;

CALL add_room(1, 1, 'jianning room', 50, 102, 1001, '2021-10-10');
CALL add_room(1, 2, 'zihan room', 60, 102, 1002, '2021-10-10');
CALL add_room(1, 3, 'vikas room', 70, 102, 1003, '2021-10-10');
CALL add_room(1, 4, 'yizhi room', 80, 102, 1004, '2021-10-10');

SELECT * FROM MeetingRooms;
SELECT * FROM Updates;

CREATE OR REPLACE PROCEDURE change_capacity (IN floor_number INTEGER, IN room_number INTEGER, IN room_capacity INTEGER, IN manager_id INTEGER, IN change_date DATE)
AS $$
BEGIN
  IF manager_id IN (SELECT eid FROM Managers) THEN
    Update Updates
	SET manager_eid = manager_id, update_date = change_date, new_capacity = room_capacity
    WHERE floor_num = floor_number AND room_num = room_number;
  ELSE
    RAISE NOTICE 'Only Managers can change capacity';
  END IF;
END;
$$ LANGUAGE plpgsql;

/* CREATE OR REPLACE PROCEDURE change_capacity (IN floor_number INTEGER, IN room_number INTEGER, IN room_capacity INTEGER, IN manager_id INTEGER, IN change_date DATE)
AS $$
  
  INSERT INTO Updates
  VALUES (manager_id, floor_number, room_number, change_date, room_capacity);
  

$$ LANGUAGE sql; */

CALL change_capacity(1, 1, 100, 1001, '2021-10-11');
CALL change_capacity(1, 1, 200, 1001, '2021-11-11');
CALL change_capacity(1, 2, 40, 1002, '2021-10-12');

SELECT * FROM Updates;

/* CREATE OR REPLACE FUNCTION current_capacity (IN search_date DATE)
RETURNS TABLE(floor_number INTEGER, room_number INTEGER, room_capacity INTEGER) AS $$

  SELECT u1.floor_num, u1.room_num, (SELECT u2.new_capacity FROM Updates u2 WHERE u2.update_date = MAX(u1.update_date) AND u2.floor_num = u1.floor_num AND u2.room_num = u1.room_num)
  FROM Updates u1
  WHERE u1.update_date <= search_date
  GROUP BY u1.floor_num, u1.room_num;

$$ LANGUAGE sql;


CREATE OR REPLACE FUNCTION search_room (IN search_capacity INTEGER, IN search_date DATE, IN start_hour INTEGER, IN end_hour INTEGER)
RETURNS TABLE(floor_number INTEGER, room_number INTEGER, dept_id INTEGER, room_capacity INTEGER) AS $$


  SELECT m.floor_num, m.room_num, m.did, c.room_capacity
  FROM MeetingRooms m, current_capacity(search_date) c
  WHERE m.room_num = c.room_number AND m.floor_num = c.floor_number AND c.room_capacity >= search_capacity
  AND NOT EXISTS (SELECT 1
				  FROM Sessions s
				  WHERE s.floor_num = m.floor_num AND s.room_num = m.room_num AND s.booking_date = search_date AND s.booking_time BETWEEN start_hour AND end_hour - 1)
  ORDER BY c.room_capacity ASC;


$$ LANGUAGE sql; */

CREATE OR REPLACE FUNCTION search_room (IN search_capacity INTEGER, IN search_date DATE, IN start_hour INTEGER, IN end_hour INTEGER)
RETURNS TABLE(floor_number INTEGER, room_number INTEGER, dept_id INTEGER, room_capacity INTEGER) AS $$


  SELECT m.floor_num, m.room_num, m.did, c.new_capacity
  FROM MeetingRooms m, Updates c
  WHERE m.room_num = c.room_num AND m.floor_num = c.floor_num AND c.new_capacity >= search_capacity
  AND NOT EXISTS (SELECT 1
				  FROM Sessions s
				  WHERE s.floor_num = m.floor_num AND s.room_num = m.room_num AND s.booking_date = search_date AND s.booking_time BETWEEN start_hour AND end_hour - 1)
  ORDER BY c.new_capacity ASC;


$$ LANGUAGE sql;


INSERT INTO Sessions
VALUES (1, 1, '2021-10-17', 1, 1001, 1001);

/* SELECT * FROM current_capacity('2021-10-10');
SELECT * FROM current_capacity('2021-10-17'); */

SELECT * FROM search_room(10, '2021-10-17', 2, 3);
SELECT * FROM search_room(50, '2021-10-17', 1, 3);

CREATE OR REPLACE PROCEDURE book_room (IN floor_number INTEGER, IN room_number INTEGER, IN book_date DATE, IN start_hour INTEGER, IN end_hour INTEGER, IN employee_id INTEGER)
AS $$
DECLARE
  current_hour INTEGER := start_hour;
BEGIN

  IF employee_id IN (SELECT eid FROM Bookers) AND employee_id NOT IN (SELECT h.eid FROM HealthDeclarations h WHERE book_date = h.declare_date AND h.fever = TRUE) THEN
    IF ROW(floor_number, room_number) IN (SELECT a.floor_number, a.room_number FROM search_room(0, book_date, start_hour, end_hour) a) THEN
	  WHILE current_hour < end_hour LOOP
	  
	    INSERT INTO Sessions
	    VALUES (floor_number, room_number, book_date, current_hour, employee_id, NULL);
		
		current_hour := current_hour + 1;
	  END LOOP;
	ELSE
	  RAISE NOTICE 'Meeting Room already booked during this period';
	END IF;
  ELSE
    RAISE NOTICE 'Employee does not meet criteria to book meeting room';
  END IF;
 
END;
  
$$ LANGUAGE plpgsql;

CALL book_room(1, 1, '2021-10-17', 3, 5, 1001);

SELECT * FROM Sessions;

CALL book_room(1, 1, '2021-10-17', 4, 6, 1001);
CALL book_room(1, 1, '2021-10-17', 8, 11, 1005);

SELECT * FROM Sessions;

CREATE OR REPLACE PROCEDURE unbook_room (IN floor_number INTEGER, IN room_number INTEGER, IN book_date DATE, IN start_hour INTEGER, IN end_hour INTEGER, IN employee_id INTEGER)
AS $$
DECLARE
  current_hour INTEGER := start_hour;
BEGIN
  WHILE current_hour < end_hour LOOP
	IF ROW(floor_number, room_number, book_date, current_hour, employee_id) IN (SELECT floor_num, room_num, booking_date, booking_time, booker_eid FROM Sessions) THEN
	  DELETE FROM Sessions
	  WHERE floor_num = floor_number AND room_num = room_number AND booking_date = book_date AND booking_time = current_hour;
		
	  DELETE FROM Joins
	  WHERE floor_num = floor_number AND room_num = room_number AND booking_date = book_date AND booking_time = current_hour;
	ELSE
	  RAISE NOTICE 'Unable to unbook slot at %', current_hour;
	END IF;
    current_hour := current_hour + 1;
  END LOOP;
 
END;
  
$$ LANGUAGE plpgsql;

CALL unbook_room(1, 1, '2021-10-17', 3, 6, 1002);

SELECT * FROM Sessions; 

CALL unbook_room(1, 1, '2021-10-17', 3, 4, 1001);

SELECT * FROM Sessions; 