/*
DROP TRIGGER close_contacts_remove ON ContactTracingLog;
DROP TRIGGER only_junior ON Juniors;
DROP TRIGGER only_booker ON Bookers;
DROP TRIGGER only_senior ON Seniors;
DROP TRIGGER only_manager ON Managers;
DROP TRIGGER add_booker_as_participant ON Sessions;
DROP TRIGGER employee_resigned ON Employees;
DROP TRIGGER capacity_overflow_after_reduction ON Updates;
*/

--psql -U postgres -d project_db -f schema_W12_Thursday.sql
--psql -U postgres -d project_db -f proc_W12_Thursday.sql
--psql -U postgres -d project_db -f data_W12_Thursday.sql

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

CREATE OR REPLACE PROCEDURE remove_department (IN dept_id INTEGER)
AS $$
BEGIN
  IF dept_id IN (SELECT did FROM MeetingRooms) THEN
	RAISE EXCEPTION 'Department ID [%] is still tied to a meeting room', dept_id;
  END IF;
  IF dept_id NOT IN (SELECT did FROM Departments) THEN
    RAISE EXCEPTION 'Department with ID [%] does not exist in Database', dept_id;
  END IF;
  DELETE FROM Departments
  WHERE did = dept_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE add_room (IN floor_number INTEGER, IN room_number INTEGER, IN room_name VARCHAR(255), IN room_capacity INTEGER, IN dept_id INTEGER, IN manager_id INTEGER, IN add_date DATE)
AS $$
BEGIN
  IF dept_id NOT IN (SELECT did FROM Departments) THEN
	RAISE EXCEPTION 'Department with ID [%] does not exist in Database', dept_id;
  END IF;
  IF manager_id NOT IN (SELECT eid FROM Managers) THEN
	RAISE EXCEPTION 'Manager with ID [%] does not exist in Database', manager_id;
  END IF;
  IF (SELECT resigned_date FROM Employees WHERE eid = manager_id) IS NOT NULL THEN
	RAISE EXCEPTION 'Manager with ID [%] has already resigned', manager_id;
  END IF;
  IF add_date != CURRENT_DATE THEN
	RAISE EXCEPTION 'Meeting Room can only be added today';
  END IF;
  IF (dept_id IN (SELECT did FROM Employees WHERE eid = manager_id)) THEN
	INSERT INTO MeetingRooms
	VALUES (floor_number, room_number, room_name, dept_id);
  
	INSERT INTO Updates
	VALUES (manager_id, floor_number, room_number, add_date, room_capacity);
  ELSE
      RAISE EXCEPTION 'Only Managers from same department can add room';
  END IF;
END;

$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE change_capacity (IN floor_number INTEGER, IN room_number INTEGER, IN room_capacity INTEGER, IN manager_id INTEGER, IN change_date DATE)
AS $$
BEGIN
  IF change_date != CURRENT_DATE THEN
	RAISE EXCEPTION 'Meeting Room capacity can only be updated today';
  END IF;
  IF manager_id NOT IN (SELECT eid FROM Managers) THEN
	RAISE EXCEPTION 'Only Managers can change capacity';
  END IF;
  IF (SELECT resigned_date FROM Employees WHERE eid = manager_id) IS NOT NULL THEN
	RAISE EXCEPTION 'Manager with ID [%] has already resigned', manager_id;
  END IF;
  IF(SELECT did FROM Employees WHERE eid = manager_id) IS NOT DISTINCT FROM (SELECT did FROM MeetingRooms WHERE floor_num = floor_number AND room_num = room_number) THEN
    UPDATE Updates
	SET manager_eid = manager_id, update_date = change_date, new_capacity = room_capacity
    WHERE floor_num = floor_number AND room_num = room_number;
  ELSE
    RAISE EXCEPTION 'Only Managers from same department as meeting room can change capacity';
  END IF;
END;
$$ LANGUAGE plpgsql;


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
  
  new_email := CONCAT(ename, '_', new_eid, '@ceg.com');
  IF dept_id NOT IN (SELECT did FROM Departments) THEN
	RAISE EXCEPTION 'Invalid Dept_ID';
  END IF;
  IF employee_type IN ('junior', 'senior', 'manager') THEN
  
    INSERT INTO Employees
    VALUES (new_eid, ename, new_email, NULL, dept_id);
	
	INSERT INTO EmployeeContacts
	VALUES (new_eid, phone_number);
  
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
  ELSE
	RAISE EXCEPTION 'Invalid Employee Type [%]', employee_type;
  END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE remove_employee (IN employee_id INTEGER, IN last_date DATE)
AS $$

BEGIN
  -- Project Requirements allow for resigned date to be <= CURRENT_DATE but our data.sql will only have resigned_date = CURRENT_DATE for things related to future records to make sense
  IF last_date <= CURRENT_DATE THEN

    UPDATE Employees
    SET resigned_date = last_date
    WHERE eid = employee_id;
  ELSE
	RAISE EXCEPTION 'Resigned date is in the future';
  END IF;
 
END;
  
$$ LANGUAGE plpgsql;




CREATE OR REPLACE FUNCTION search_room (IN search_capacity INTEGER, IN search_date DATE, IN start_hour INTEGER, IN end_hour INTEGER)
RETURNS TABLE(floor_number INTEGER, room_number INTEGER, dept_id INTEGER, room_capacity INTEGER) AS $$
DECLARE
  curs CURSOR FOR (SELECT m.floor_num, m.room_num, m.did, c.new_capacity
				   FROM MeetingRooms m, Updates c
				   WHERE m.room_num = c.room_num AND m.floor_num = c.floor_num AND c.new_capacity >= search_capacity
				   AND NOT EXISTS (SELECT 1
								   FROM Sessions s
								   WHERE s.floor_num = m.floor_num AND s.room_num = m.room_num AND s.booking_date = search_date AND s.booking_time BETWEEN start_hour AND end_hour - 1)
				   ORDER BY c.new_capacity ASC);
  r1 RECORD;
BEGIN
  IF ((start_hour NOT BETWEEN 0 AND 23) OR (end_hour NOT BETWEEN 1 AND 24)) THEN --End hour of 24 means booking until 1159hrs on the same DAY
	RAISE EXCEPTION 'start_hour or end_hour is invalid';
  END IF;
  IF (end_hour <= start_hour) THEN
	RAISE EXCEPTION 'end_hour must be after start_hour';
  END IF;  
  OPEN curs;
  LOOP
	FETCH curs INTO r1;
	EXIT WHEN NOT FOUND;
	floor_number:= r1.floor_num;
	room_number := r1.room_num;
	dept_id := r1.did;
	room_capacity := r1.new_capacity;
	RETURN NEXT;
  END LOOP;
  CLOSE curs;
END;
$$ LANGUAGE plpgsql;

-- Cannot allow booking if even one slot within range of start_hour, end_hour is taken

CREATE OR REPLACE PROCEDURE book_room (IN floor_number INTEGER, IN room_number INTEGER, IN book_date DATE, IN start_hour INTEGER, IN end_hour INTEGER, IN employee_id INTEGER)
AS $$
DECLARE
  current_hour INTEGER := start_hour;
BEGIN
  IF ((start_hour NOT BETWEEN 0 AND 23) OR (end_hour NOT BETWEEN 1 AND 24)) THEN --End hour of 24 means booking until 1159hrs on the same DAY
	RAISE EXCEPTION 'start_hour or end_hour is invalid';
  END IF;
  IF (end_hour <= start_hour) THEN
	RAISE EXCEPTION 'end_hour must be after start_hour';
  END IF;  
  IF employee_id NOT IN (SELECT eid FROM Bookers) THEN
	RAISE EXCEPTION 'Meeting Room can only be booked by Seniors or Managers';
  END IF;	
  IF (SELECT resigned_date FROM Employees WHERE eid = employee_id) IS NOT NULL THEN
	RAISE EXCEPTION 'Booker with ID [%] has already resigned', employee_id;
  END IF;
  IF book_date <= CURRENT_DATE THEN
	RAISE EXCEPTION 'Book Date is in the past';
  END IF;
  IF employee_id IN (SELECT h.eid FROM HealthDeclarations h WHERE h.declare_date = CURRENT_DATE AND h.fever = FALSE) THEN --Meaning Booker has declared and does not have fever today
    WHILE current_hour < end_hour LOOP
		IF ROW(floor_number, room_number) IN (SELECT a.floor_number, a.room_number FROM search_room(0, book_date, current_hour, current_hour + 1) a) THEN
			INSERT INTO Sessions
			VALUES (floor_number, room_number, book_date, current_hour, employee_id, NULL);
		ELSE
			RAISE NOTICE 'Meeting Room already booked at %', current_hour;
		END IF;
		current_hour := current_hour + 1;
	END LOOP;
  ELSE
    RAISE EXCEPTION 'Employee has not declared temperature or has a fever';
  END IF;
 
END;
  
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE unbook_room (IN floor_number INTEGER, IN room_number INTEGER, IN book_date DATE, IN start_hour INTEGER, IN end_hour INTEGER, IN employee_id INTEGER)
AS $$
DECLARE
  current_hour INTEGER := start_hour;
BEGIN
  IF ((start_hour NOT BETWEEN 0 AND 23) OR (end_hour NOT BETWEEN 1 AND 24)) THEN --End hour of 24 means booking until 1159hrs on the same DAY
	RAISE EXCEPTION 'start_hour or end_hour is invalid';
  END IF;
  IF (end_hour <= start_hour) THEN
	RAISE EXCEPTION 'end_hour must be after start_hour';
  END IF;  
  IF (SELECT resigned_date FROM Employees WHERE eid = employee_id) IS NOT NULL THEN
	RAISE EXCEPTION 'Employee with ID [%] has already resigned', employee_id;
  END IF;
  IF book_date <= CURRENT_DATE THEN
	RAISE EXCEPTION 'Book Date is in the past';
  END IF;
  WHILE current_hour < end_hour LOOP
    IF employee_id NOT IN(SELECT booker_eid FROM Sessions WHERE floor_num = floor_number AND room_num = room_number AND booking_date = book_date AND booking_time = current_hour) THEN
	  RAISE NOTICE 'Employee with ID [%] is not the one who booked the session', employee_id;
	END IF;  
	IF ROW(floor_number, room_number, book_date, current_hour, employee_id) IN (SELECT floor_num, room_num, booking_date, booking_time, booker_eid FROM Sessions) THEN
	  DELETE FROM Sessions
	  WHERE floor_num = floor_number AND room_num = room_number AND booking_date = book_date AND booking_time = current_hour;
	ELSE
	  RAISE NOTICE 'Unable to unbook slot at %', current_hour;
	END IF;
    current_hour := current_hour + 1;
  END LOOP;
 
END;
  
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE join_meeting (IN floor_number INTEGER, IN room_number INTEGER, IN meeting_date DATE, IN start_hour INTEGER, IN end_hour INTEGER, IN employee_id INTEGER)
AS $$
DECLARE
  current_hour INTEGER := start_hour;
  current_capacity INTEGER;
  max_capacity INTEGER;
BEGIN
  IF ((start_hour NOT BETWEEN 0 AND 23) OR (end_hour NOT BETWEEN 1 AND 24)) THEN --End hour of 24 means booking until 1159hrs on the same DAY
	RAISE EXCEPTION 'start_hour or end_hour is invalid';
  END IF;
  IF (end_hour <= start_hour) THEN
	RAISE EXCEPTION 'end_hour must be after start_hour';
  END IF;  
  IF meeting_date <= CURRENT_DATE THEN
	RAISE EXCEPTION 'Meeting is already over';
  END IF;
  IF (SELECT resigned_date FROM Employees WHERE eid = employee_id) IS NOT NULL THEN
	RAISE EXCEPTION 'Employee with ID [%] has already resigned', employee_id;
  END IF;
  IF employee_id NOT IN (SELECT h.eid FROM HealthDeclarations h WHERE h.declare_date = CURRENT_DATE AND h.fever = FALSE) THEN
	RAISE EXCEPTION 'Employee has not declared temperature or has a fever';
  END IF;
  SELECT new_capacity INTO max_capacity FROM Updates WHERE floor_num = floor_number AND room_num = room_number;
  WHILE current_hour < end_hour LOOP
	SELECT COUNT(*) INTO current_capacity FROM Joins WHERE floor_num = floor_number AND room_num = room_number AND booking_date = meeting_date AND booking_time = current_hour;
	IF (current_capacity >= max_capacity) THEN
		RAISE NOTICE 'Current session capacity reached';
	ELSIF ROW(floor_number, room_number, meeting_date, current_hour) IN (SELECT s.floor_num, s.room_num, s.booking_date, s.booking_time FROM Sessions s WHERE s.manager_eid IS NULL) THEN 	
		INSERT INTO Joins
	    VALUES (employee_id, floor_number, room_number, meeting_date, current_hour);
	ELSE
		RAISE NOTICE 'Current session at [%] is already approved or does not exist', current_hour;
	END IF;
	current_hour := current_hour + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE leave_meeting (IN floor_number INTEGER, IN room_number INTEGER, IN meeting_date DATE, IN start_hour INTEGER, IN end_hour INTEGER, IN employee_id INTEGER)
AS $$
DECLARE
  current_hour INTEGER := start_hour;
BEGIN
  IF ((start_hour NOT BETWEEN 0 AND 23) OR (end_hour NOT BETWEEN 1 AND 24)) THEN --End hour of 24 means booking until 1159hrs on the same DAY
	RAISE EXCEPTION 'start_hour or end_hour is invalid';
  END IF;
  IF (end_hour <= start_hour) THEN
	RAISE EXCEPTION 'end_hour must be after start_hour';
  END IF;  
  IF meeting_date <= CURRENT_DATE THEN
	RAISE EXCEPTION 'Meeting is already over';
  END IF;
  IF (SELECT resigned_date FROM Employees WHERE eid = employee_id) IS NOT NULL THEN
	RAISE EXCEPTION 'Employee with ID [%] has already resigned', employee_id;
  END IF;
  WHILE current_hour < end_hour LOOP
	IF ROW(floor_number, room_number, meeting_date, current_hour) IN (SELECT s.floor_num, s.room_num, s.booking_date, s.booking_time FROM Sessions s WHERE s.manager_eid IS NULL) THEN
		-- If booker of session is the participant leaving, the session is removed completely. If there is only one participant left, then it must be the booker.
		IF (employee_id IN (SELECT booker_eid FROM Sessions WHERE floor_num = floor_number AND room_num = room_number AND booking_date = meeting_date AND booking_time = current_hour)) THEN
			RAISE NOTICE 'Booker with ID [%] is leaving the session', employee_id;
			DELETE FROM Sessions
			WHERE (floor_num = floor_number AND room_num = room_number AND booking_date = meeting_date AND booking_time = current_hour);
		ELSE 
			DELETE FROM Joins j
			WHERE (j.employee_eid = employee_id) AND (j.floor_num = floor_number) AND (j.room_num = room_number) AND (j.booking_date = meeting_date) AND (j.booking_time = current_hour);
		END IF;
	ELSE 
		RAISE NOTICE 'Current session at [%] is already approved or does not exist', current_hour;
	END IF;
	current_hour := current_hour + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
	

CREATE OR REPLACE PROCEDURE approve_meeting (IN floor_number INTEGER, IN room_number INTEGER, IN meeting_date DATE, IN start_hour INTEGER, IN end_hour INTEGER, IN manager_id INTEGER) 
AS $$
DECLARE
  current_hour INTEGER := start_hour;
  manager_did INTEGER;
  room_did INTEGER;
BEGIN
  IF ((start_hour NOT BETWEEN 0 AND 23) OR (end_hour NOT BETWEEN 1 AND 24)) THEN --End hour of 24 means booking until 1159hrs on the same DAY
	RAISE EXCEPTION 'start_hour or end_hour is invalid';
  END IF;
  IF (end_hour <= start_hour) THEN
	RAISE EXCEPTION 'end_hour must be after start_hour';
  END IF;  
  IF manager_id NOT IN (SELECT eid FROM Managers) THEN
	RAISE EXCEPTION 'Meeting can only be approved by Managers';
  END IF;
  IF meeting_date <= CURRENT_DATE THEN
	RAISE EXCEPTION 'Meeting is already over';
  END IF;
  IF (SELECT resigned_date FROM Employees WHERE eid = manager_id) IS NOT NULL THEN
	RAISE EXCEPTION 'Employee with ID [%] has already resigned', manager_id;
  END IF;
  IF manager_id NOT IN (SELECT h.eid FROM HealthDeclarations h WHERE h.declare_date = CURRENT_DATE AND h.fever = FALSE) THEN
	RAISE EXCEPTION 'Employee has not declared temperature or has a fever';
  END IF;
  SELECT did INTO manager_did FROM Employees WHERE eid = manager_id;
  SELECT did INTO room_did FROM MeetingRooms WHERE floor_num = floor_number AND room_num = room_number;
  IF (manager_did IS DISTINCT FROM room_did) THEN
	RAISE EXCEPTION 'Manager can only approve meeting for rooms of same department';
  END IF;
  WHILE current_hour < end_hour LOOP
	IF ROW(floor_number, room_number, meeting_date, current_hour) IN (SELECT s.floor_num, s.room_num, s.booking_date, s.booking_time FROM Sessions s WHERE s.manager_eid IS NULL) THEN
    	Update Sessions s
		SET manager_eid = manager_id
    	WHERE s.floor_num = floor_number AND s.room_num = room_number AND s.booking_date = meeting_date AND s.booking_time = current_hour;
	ELSE
		RAISE NOTICE 'Current session at [%] is already approved or does not exist', current_hour;
	END IF;
	current_hour := current_hour + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE reject_meeting (IN floor_number INTEGER, IN room_number INTEGER, IN meeting_date DATE, IN start_hour INTEGER, IN end_hour INTEGER, IN manager_id INTEGER) 
AS $$
DECLARE
  current_hour INTEGER := start_hour;
  manager_did INTEGER;
  room_did INTEGER;
BEGIN
  IF ((start_hour NOT BETWEEN 0 AND 23) OR (end_hour NOT BETWEEN 1 AND 24)) THEN --End hour of 24 means booking until 1159hrs on the same DAY
	RAISE EXCEPTION 'start_hour or end_hour is invalid';
  END IF;
  IF (end_hour <= start_hour) THEN
	RAISE EXCEPTION 'end_hour must be after start_hour';
  END IF;  
  IF manager_id NOT IN (SELECT eid FROM Managers) THEN
	RAISE EXCEPTION 'Meeting can only be rejected by Managers';
  END IF;
  IF meeting_date <= CURRENT_DATE THEN
	RAISE EXCEPTION 'Meeting is already over';
  END IF;
  IF (SELECT resigned_date FROM Employees WHERE eid = manager_id) IS NOT NULL THEN
	RAISE EXCEPTION 'Employee with ID [%] has already resigned', manager_id;
  END IF;
  SELECT did INTO manager_did FROM Employees WHERE eid = manager_id;
  SELECT did INTO room_did FROM MeetingRooms WHERE floor_num = floor_number AND room_num = room_number;
  IF (manager_did IS DISTINCT FROM room_did) THEN
	RAISE EXCEPTION 'Manager can only reject meeting for rooms of same department';
  END IF;
  WHILE current_hour < end_hour LOOP
	IF ROW(floor_number, room_number, meeting_date, current_hour) IN (SELECT s.floor_num, s.room_num, s.booking_date, s.booking_time FROM Sessions s WHERE s.manager_eid IS NULL) THEN
		DELETE FROM Sessions s
    	WHERE s.floor_num = floor_number AND s.room_num = room_number AND s.booking_date = meeting_date AND s.booking_time = current_hour;
	ELSE
		RAISE NOTICE 'Current session at [%] is already approved or does not exist', current_hour;
	END IF;
	current_hour := current_hour + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE PROCEDURE declare_health (IN employee_id INTEGER, IN decl_date DATE, IN temperature FLOAT)
AS $$
DECLARE
  fever BOOLEAN;
BEGIN
  IF temperature > 37.5 THEN fever := TRUE;
  ELSE fever := FALSE;
  END IF;
  
  IF TRUE THEN -- IF decl_date <= CURRENT_DATE THEN /* Checking the declaration does not happen in the future */
  
    INSERT INTO HealthDeclarations
    VALUES (employee_id, decl_date, temperature, fever);
	
  ELSE
    RAISE NOTICE 'Declaration cannot be in the future';

  END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION contact_tracing (IN employee_id INTEGER)
RETURNS TABLE(eid INTEGER) AS $contact_tracing$
BEGIN

CREATE OR REPLACE FUNCTION close_contacts (IN employee_id INTEGER) -- Nested Function to update logs for primary
RETURNS TABLE(eid INTEGER, contact_date DATE) AS $close_contacts$
BEGIN


RETURN QUERY

WITH CloseContacts AS (SELECT s.employee_eid AS eid, f.booking_date AS contact_date
FROM (SELECT room_num, floor_num, booking_time, booking_date, d.eid
	FROM (Sessions s NATURAL JOIN Joins j) a JOIN HealthDeclarations d ON a.employee_eid = d.eid
	WHERE d.fever = TRUE
	AND a.booking_date = d.declare_date
	AND d.eid = employee_id) f, (Sessions NATURAL JOIN Joins) s
	WHERE (f.booking_date - s.booking_date) BETWEEN 0 AND 3 /* Sessions from the past 3 days */
	AND f.eid <> s.employee_eid
	AND s.manager_eid IS NOT NULL /* Approved Session */
	AND (f.room_num, f.floor_num) = (s.room_num, s.floor_num))

SELECT * FROM CloseContacts c;

END;
$close_contacts$ LANGUAGE plpgsql;

IF TRUE IN (SELECT fever FROM HealthDeclarations d WHERE d.eid = employee_id) THEN

  DROP TABLE IF EXISTS contact;
	CREATE TEMP TABLE contact AS
	SELECT * FROM close_contacts(employee_id);

  INSERT INTO ContactTracingLog (employee_eid, contact_date, contact_type, log_time)
  SELECT d.eid, d.declare_date, 'primary', NOW() FROM HealthDeclarations d WHERE d.eid = employee_id AND d.fever = TRUE;

	INSERT INTO ContactTracingLog (employee_eid, contact_date, contact_type, log_time)
	SELECT DISTINCT c.eid, c.contact_date, 'contact', NOW() FROM contact c;

	RETURN QUERY (SELECT DISTINCT c.eid FROM contact c);

END IF;
	
END;

$contact_tracing$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION non_compliance (IN start_date DATE, IN end_date DATE) -- to check number of days of no declaration
RETURNS TABLE(eid INTEGER, days INTEGER) AS $$

  SELECT e.eid AS eid, (end_date - start_date) - COUNT(d.declare_date) + 1 AS days
  FROM Employees e LEFT OUTER JOIN (SELECT * FROM HealthDeclarations WHERE declare_date BETWEEN start_date AND end_date)d ON e.eid = d.eid
  WHERE e.resigned_date IS NULL
  OR e.resigned_date > end_date -- Excluding resign if the resign date is within the range

  GROUP BY e.eid
  HAVING (end_date - start_date) - COUNT(d.declare_date) + 1 > 0
  ORDER BY days DESC;

$$ LANGUAGE sql;

CREATE OR REPLACE FUNCTION view_booking_report(start_date DATE,emp_id INTEGER) -- for booker to check if a room is approved
RETURNS TABLE(floor_num INT,room_num INT,booking_date DATE,booking_time iNT,is_approved BOOLEAN)
AS $$
BEGIN
RETURN QUERY SELECT s.floor_num, s.room_num,s.booking_date,s.booking_time, CASE
WHEN manager_eid IS NULL THEN FALSE ElSE TRUE END is_approved -- not giving approved
FROM Sessions s
WHERE booker_eid = emp_id AND s.booking_date >= start_date
GROUP BY s.booking_date, s.booking_time, s.floor_num,s.room_num, manager_eid
ORDER BY s.booking_date ASC, s.booking_time ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_future_meeting(start_date DATE, emp_id INT) -- employee to find all meetings approved, joining
RETURNS TABLE(floor_num INT, room_num INT, booking_date DATE, start_hour INT)
AS $$
BEGIN
RETURN QUERY SELECT s.floor_num, s.room_num, s.booking_date,s.booking_time
FROM Joins j LEFT JOIN Sessions s
ON (j.room_num = s.room_num AND j.floor_num = s.floor_num AND j.booking_date = s.booking_date AND
j.booking_time = s.booking_time)
WHERE j.booking_date >= start_date AND s.manager_eid IS NOT NULL AND j.employee_eid = emp_id
GROUP BY s.booking_date,s.booking_time,s.floor_num,s.room_num
ORDER BY s.booking_date ASC, s.booking_time ASC;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION view_manager_report(start_date DATE,emp_eid INTEGER) -- manager to find all meeting rooms in his department not approved
RETURNS TABLE(floor_num INT, room_num INT, booking_date DATE, start_hour INT, employee_empid INT)
AS $$
BEGIN
RETURN QUERY SELECT s.floor_num AS floor_num, s.room_num AS room_num, s.booking_date,
 s.booking_time AS start_hour, booker_eid AS employee_empid
FROM Sessions s LEFT JOIN MeetingRooms m 
ON (s.room_num = m.room_num AND s.floor_num = m.floor_num)
WHERE s.manager_eid IS NULL AND s.booking_date >= start_date
AND EXISTS (SELECT 1 FROM Managers WHERE eid = emp_eid) AND m.did = (SELECT did from employees where eid = emp_eid)
GROUP BY s.booking_date,s.booking_time,s.floor_num,s.room_num,booker_eid
ORDER BY s.booking_date, s.booking_time;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_close_contacts()
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.contact_type = 'primary') THEN
		DELETE FROM Joins j WHERE j.employee_eid = NEW.employee_eid AND (j.booking_date - NEW.contact_date) >= 0; 
		DELETE FROM Sessions s WHERE s.booker_eid = NEW.employee_eid AND (s.booking_date - NEW.contact_date) >= 0; 
	ELSIF (NEW.contact_type = 'contact') THEN
		DELETE FROM Joins j WHERE j.employee_eid = NEW.employee_eid AND (j.booking_date - NEW.contact_date) BETWEEN 0 AND 7;
	END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER close_contacts_remove
AFTER INSERT ON ContactTracingLog
FOR EACH ROW EXECUTE FUNCTION remove_close_contacts();

CREATE OR REPLACE FUNCTION check_only_junior()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.eid NOT IN (SELECT eid FROM Managers) AND NEW.eid NOT IN (SELECT eid FROM Seniors) AND NEW.eid NOT IN (SELECT eid FROM Bookers)) THEN
    RETURN NEW;
  ELSE
  RAISE NOTICE 'Employee with eid % is already of another type', NEW.eid; 
    RETURN NULL;
  END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_only_booker()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.eid NOT IN (SELECT eid FROM Juniors)) THEN
    RETURN NEW;
  ELSE
  RAISE NOTICE 'Employee with eid % is a Junior', NEW.eid; 
    RETURN NULL;
  END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION check_only_senior()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.eid NOT IN (SELECT eid FROM Managers) AND NEW.eid NOT IN (SELECT eid FROM Juniors)) THEN
    RETURN NEW;
  ELSE
  RAISE NOTICE 'Employee with eid % is already of another type', NEW.eid; 
    RETURN NULL;
  END IF;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION check_only_manager()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.eid NOT IN (SELECT eid FROM Seniors) AND NEW.eid NOT IN (SELECT eid FROM Juniors)) THEN
    RETURN NEW;
  ELSE
  RAISE NOTICE 'Employee with eid % is already of another type', NEW.eid; 
    RETURN NULL;
  END IF;

END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION add_booker_to_session()
RETURNS TRIGGER AS $$
BEGIN
  RAISE NOTICE 'Booker with eid [%] will be automatically added as participant.(from trigger)', NEW.booker_eid;
  INSERT INTO Joins
  VALUES (NEW.booker_eid, NEW.floor_num, NEW.room_num, NEW.booking_date, NEW.booking_time);
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_future_records()
RETURNS TRIGGER AS $$
BEGIN

	RAISE NOTICE 'Employee with eid [%] has resigned. Cleaning up future records (from trigger)', NEW.eid;
	-- Delete entire session if employee is booker and all who joined the session (ON DELETE CASCADE handles this) from future meetings (booking_date > resigned_date (which is today))
	DELETE FROM Sessions
	WHERE (booker_eid = NEW.eid AND booking_date > NEW.resigned_date);
	
	-- Delete employee as participant from sessions after resigned date (which is today) even if the meeting is approved
	DELETE FROM Joins
	WHERE (employee_eid = NEW.eid AND booking_date > NEW.resigned_date);
	
	-- Change sessions status from approved to not yet approved where employee is the approver 
	UPDATE Sessions
	SET manager_eid = NULL
    WHERE manager_eid = NEW.eid AND booking_date > NEW.resigned_date;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_overflow_sessions()
RETURNS TRIGGER AS $$
DECLARE
	curs CURSOR FOR (SELECT booking_date, booking_time, COUNT(*) AS count_participants FROM Joins WHERE floor_num = NEW.floor_num AND room_num = NEW.room_num AND booking_date > NEW.update_date GROUP BY (booking_date, booking_time));
	r1 RECORD;
BEGIN
	OPEN curs;
	LOOP
		FETCH curs INTO r1;
		EXIT WHEN NOT FOUND;
		IF r1.count_participants > NEW.new_capacity THEN
			RAISE NOTICE 'Session at [%] has exceeded new capacity. Session and participants will be deleted', r1.booking_time;
			DELETE FROM Sessions
			WHERE floor_num = NEW.floor_num AND room_num = NEW.room_num AND booking_date = r1.booking_date AND booking_time = r1.booking_time;
		END IF;
	END LOOP;
	CLOSE curs;
	RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_book_when_fever()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.booker_eid NOT IN (SELECT h.eid FROM HealthDeclarations h WHERE CURRENT_DATE = h.declare_date AND h.fever = FALSE) THEN 
		RAISE EXCEPTION 'Employee has not declared temperature or has a fever (from trigger)';
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_approve_when_fever()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.manager_eid NOT IN (SELECT h.eid FROM HealthDeclarations h WHERE CURRENT_DATE = h.declare_date AND h.fever = FALSE) THEN 
		RAISE EXCEPTION 'Employee has not declared temperature or has a fever (from trigger)';
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_join_when_fever()
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.employee_eid NOT IN (SELECT h.eid FROM HealthDeclarations h WHERE CURRENT_DATE = h.declare_date AND h.fever = FALSE) THEN 
		RAISE EXCEPTION 'Employee has not declared temperature or has a fever (from trigger)';
		RETURN NULL;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_update_when_approved()
RETURNS TRIGGER AS $$
DECLARE
BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF ROW(NEW.floor_num, NEW.room_num, NEW.booking_date, NEW.booking_time) IN (SELECT s.floor_num, s.room_num, s.booking_date, s.booking_time FROM Sessions s WHERE s.manager_eid IS NOT NULL) THEN
			RAISE EXCEPTION 'Session is already approved (from trigger)';
			RETURN NULL;
		ELSE 
			RETURN NEW;
		END IF;
	ELSIF (TG_OP = 'DELETE') THEN
		IF (OLD.employee_eid IN (SELECT eid FROM Employees WHERE resigned_date IS NOT NULL)) THEN
			RAISE NOTICE 'Employee [%] has resigned, allowed to be removed from approved meetings', OLD.employee_eid;
			RETURN OLD;
		ELSIF (OLD.employee_eid IN (SELECT employee_eid FROM ContactTracingLog WHERE contact_type = 'primary' AND (OLD.booking_date - contact_date >= 0))) THEN
			RAISE NOTICE 'Employee [%] is a primary, allowed to be removed from approved meetings', OLD.employee_eid;
			RETURN OLD;
		ELSIF (OLD.employee_eid IN (SELECT employee_eid FROM ContactTracingLog WHERE contact_type = 'contact' AND (OLD.booking_date - contact_date BETWEEN 0 AND 7))) THEN
			RAISE NOTICE 'Employee [%] is a close contact, allowed to be removed from approved meetings', OLD.employee_eid;
			RETURN OLD;
		ELSIF ROW(OLD.floor_num, OLD.room_num, OLD.booking_date, OLD.booking_time) IN (SELECT s.floor_num, s.room_num, s.booking_date, s.booking_time FROM Sessions s WHERE s.manager_eid IS NOT NULL) THEN
			RAISE EXCEPTION 'Session is already approved (from trigger)';
			RETURN NULL;
		ELSE
			RETURN OLD;
		END IF;			
	END IF;
END;
$$ LANGUAGE plpgsql; 

CREATE OR REPLACE FUNCTION disallow_update_capacity_for_diff_did()
RETURNS TRIGGER AS $$
BEGIN
	IF(SELECT did FROM Employees WHERE eid = NEW.manager_eid) IS DISTINCT FROM (SELECT did FROM MeetingRooms WHERE floor_num = NEW.floor_num AND room_num = NEW.room_num) THEN
		RAISE EXCEPTION 'Only Managers from same department as meeting room can change capacity (from trigger)';
		RETURN NULL;
	ELSE
		RETURN NEW;
	END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_book_date_in_past()
RETURNS TRIGGER AS $$
BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF NEW.booking_date <= CURRENT_DATE THEN
			RAISE EXCEPTION 'Book Date is in the past (from trigger)';
			RETURN NULL;
		ELSE 
			RETURN NEW;
		END IF;
	ELSIF (TG_OP = 'UPDATE') THEN
		IF NEW.booking_date <= CURRENT_DATE THEN
			RAISE EXCEPTION 'Book Date is in the past (from trigger)';
			RETURN NULL;
		ELSE 
			RETURN NEW;
		END IF;		
	ELSIF (TG_OP = 'DELETE') THEN
		IF OLD.booking_date <= CURRENT_DATE THEN
			RAISE EXCEPTION 'Book Date is in the past (from trigger)';
			RETURN NULL;
		ELSE 
			RETURN OLD;
		END IF;			
	END IF; 
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_join_date_in_past()
RETURNS TRIGGER AS $$
BEGIN
	IF (TG_OP = 'INSERT') THEN
		IF NEW.booking_date <= CURRENT_DATE THEN
			RAISE EXCEPTION 'Book Date is in the past (from trigger)';
			RETURN NULL;
		ELSE 
			RETURN NEW;
		END IF;
	ELSIF (TG_OP = 'DELETE') THEN
		IF OLD.booking_date <= CURRENT_DATE THEN
			RAISE EXCEPTION 'Book Date is in the past (from trigger)';
			RETURN NULL;
		ELSE 
			RETURN OLD;
		END IF;			
	END IF; 
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_join_overbooked()
RETURNS TRIGGER AS $$
DECLARE 
  current_capacity INTEGER;
  max_capacity INTEGER;
BEGIN
  SELECT new_capacity INTO max_capacity FROM Updates WHERE floor_num = NEW.floor_num AND room_num = NEW.room_num;
  SELECT COUNT(*) INTO current_capacity FROM Joins WHERE floor_num = NEW.floor_num AND room_num = NEW.room_num AND booking_date = NEW.booking_date AND booking_time = NEW.booking_time;
  IF max_capacity <= current_capacity THEN
	RAISE EXCEPTION 'Current session capacity reached(from trigger)';
	RETURN NULL;
  ELSE 
	RETURN NEW;
  END IF;	
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION delete_session_also()
RETURNS TRIGGER AS $$
BEGIN
  IF (OLD.employee_eid IN (SELECT booker_eid FROM Sessions WHERE floor_num = OLD.floor_num AND room_num = OLD.room_num AND booking_date = OLD.booking_date AND booking_time = OLD.booking_time)) THEN
	RAISE NOTICE 'Booker with ID [%] is leaving the session (from trigger)', OLD.employee_eid;
	DELETE FROM Sessions
	WHERE (floor_num = OLD.floor_num AND room_num = OLD.room_num AND booking_date = OLD.booking_date AND booking_time = OLD.booking_time);
	RETURN NULL;
  ELSE
	RETURN OLD;
  END IF;	
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_book_junior()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.booker_eid NOT IN (SELECT eid FROM Bookers) THEN
	RAISE EXCEPTION 'Meeting Room can only be booked by Seniors or Managers (from trigger)';
	RETURN NULL;
  ELSE
	RETURN NEW;
  END IF;	
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_approve_for_diff_did()
RETURNS TRIGGER AS $$
DECLARE 
  manager_did INTEGER;
  room_did INTEGER;
BEGIN
  SELECT did INTO manager_did FROM Employees WHERE eid = NEW.manager_eid;
  SELECT did INTO room_did FROM MeetingRooms WHERE floor_num = NEW.floor_num AND room_num = NEW.room_num;
  IF (manager_did IS DISTINCT FROM room_did) THEN
	RAISE EXCEPTION 'Manager can only approve meeting for rooms of same department (from trigger)';
	RETURN NULL;
  ELSE
	RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION disallow_multiple_approve()
RETURNS TRIGGER AS $$
BEGIN
  IF (OLD.manager_eid IS NOT NULL) THEN
	RAISE EXCEPTION 'Meeting is already approved (from trigger)';
	RETURN NULL;
  ELSE 
	RETURN NEW;
  END IF;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER only_junior
BEFORE INSERT OR UPDATE ON Juniors
FOR EACH ROW EXECUTE FUNCTION check_only_junior();

CREATE TRIGGER only_booker
BEFORE INSERT OR UPDATE ON Bookers
FOR EACH ROW EXECUTE FUNCTION check_only_booker();

CREATE TRIGGER only_senior
BEFORE INSERT OR UPDATE ON Seniors
FOR EACH ROW EXECUTE FUNCTION check_only_senior();

CREATE TRIGGER only_manager
BEFORE INSERT OR UPDATE ON Managers
FOR EACH ROW EXECUTE FUNCTION check_only_manager();

CREATE TRIGGER add_booker_as_participant
AFTER INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION add_booker_to_session();

CREATE TRIGGER employee_resigned
AFTER UPDATE ON Employees
FOR EACH ROW WHEN (NEW.resigned_date IS NOT NULL)
EXECUTE FUNCTION remove_future_records();

CREATE TRIGGER capacity_overflow_after_reduction
AFTER UPDATE ON Updates
FOR EACH ROW WHEN (NEW.new_capacity < OLD.new_capacity)
EXECUTE FUNCTION remove_overflow_sessions();

CREATE TRIGGER book_room_with_fever
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION disallow_book_when_fever();

CREATE TRIGGER approve_room_with_fever
BEFORE UPDATE ON Sessions
FOR EACH ROW WHEN (NEW.manager_eid IS NOT NULL)
EXECUTE FUNCTION disallow_approve_when_fever();

CREATE TRIGGER join_meeting_with_fever
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION disallow_join_when_fever();

CREATE TRIGGER update_participants_after_approval
BEFORE INSERT OR DELETE ON Joins
FOR EACH ROW EXECUTE FUNCTION disallow_update_when_approved();

CREATE TRIGGER update_capacity_same_did_as_manager
BEFORE INSERT OR UPDATE ON Updates
FOR EACH ROW EXECUTE FUNCTION disallow_update_capacity_for_diff_did();

CREATE TRIGGER book_date_in_future
BEFORE INSERT OR UPDATE OR DELETE ON Sessions
FOR EACH ROW EXECUTE FUNCTION disallow_book_date_in_past();

CREATE TRIGGER join_date_in_future
BEFORE INSERT OR DELETE ON Joins
FOR EACH ROW EXECUTE FUNCTION disallow_join_date_in_past();

CREATE TRIGGER join_meeting_overbooked
BEFORE INSERT ON Joins
FOR EACH ROW EXECUTE FUNCTION disallow_join_overbooked();

CREATE TRIGGER leave_meeting_booker
BEFORE DELETE ON Joins 
FOR EACH ROW EXECUTE FUNCTION delete_session_also();

CREATE TRIGGER booker_cannot_be_junior
BEFORE INSERT ON Sessions
FOR EACH ROW EXECUTE FUNCTION disallow_book_junior();

CREATE TRIGGER approve_meeting_same_did_as_manager
BEFORE UPDATE ON Sessions
FOR EACH ROW WHEN (NEW.manager_eid IS NOT NULL)
EXECUTE FUNCTION disallow_approve_for_diff_did();

CREATE TRIGGER meeting_approved_only_once
BEFORE UPDATE ON Sessions
FOR EACH ROW WHEN (NEW.manager_eid IS NOT NULL)
EXECUTE FUNCTION disallow_multiple_approve();