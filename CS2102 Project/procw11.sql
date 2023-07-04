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
  
  IF dept_id NOT IN (SELECT did FROM Departments) THEN
    RAISE NOTICE 'Department with ID [%] does not exist in Database', dept_id;
  ELSE
	DELETE FROM Departments
	WHERE did = dept_id;
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

CREATE OR REPLACE PROCEDURE add_room (IN floor_number INTEGER, IN room_number INTEGER, IN room_name VARCHAR(255), IN room_capacity INTEGER, IN dept_id INTEGER, IN manager_id INTEGER, IN add_date DATE)
AS $$

  INSERT INTO MeetingRooms
  VALUES (floor_number, room_number, room_name, dept_id);
  
  INSERT INTO Updates
  VALUES (manager_id, floor_number, room_number, add_date, room_capacity);
  

$$ LANGUAGE sql;

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
		
	    CALL join_meeting(floor_number, room_number, book_date, current_hour, current_hour + 1, employee_id);
		
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

CREATE OR REPLACE PROCEDURE declare_health (IN employee_id INTEGER, IN decl_date DATE, IN temperature FLOAT)
AS $$
DECLARE
  fever BOOLEAN;
BEGIN
  IF temperature > 37.5 THEN fever := TRUE;
  ELSE fever := FALSE;
  END IF;
  
  IF decl_date <= CURRENT_DATE THEN /* Checking the declaration does not happen in the future */
  
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

INSERT INTO ContactTracingLog (employee_eid, contact_date, contact_type)
SELECT d.eid, d.declare_date, 'primary' FROM HealthDeclarations d WHERE d.eid = employee_id AND d.fever = TRUE;

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

	INSERT INTO ContactTracingLog (employee_eid, contact_date, contact_type)
	SELECT DISTINCT c.eid, c.contact_date, 'contact' FROM contact c;

	RETURN QUERY (SELECT DISTINCT c.eid FROM contact c);

END IF;
	
END;

$contact_tracing$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION non_compliance (IN start_date DATE, IN end_date DATE)
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

CREATE OR REPLACE PROCEDURE join_meeting (IN floor_num INTEGER, IN room_num INTEGER, IN date DATE, IN start_hour INTEGER, 
IN end_hour INTEGER, IN employee_id INTEGER)
AS $$
DECLARE
  current_hour INTEGER := start_hour;
BEGIN
  WHILE current_hour < end_hour LOOP
	IF ROW(floor_num, room_num, date, current_hour) IN (SELECT s.floor_num, s.room_num, s.booking_date, s.booking_time FROM Sessions s WHERE s.manager_eid IS NULL) AND ROW(floor_num, room_num, date, current_hour, employee_id) NOT IN (SELECT j.floor_num, j.room_num, j.booking_date, j.booking_time, j.employee_eid FROM Joins j) AND employee_id NOT IN (SELECT h.eid FROM HealthDeclarations h WHERE date = h.declare_date AND h.fever = TRUE) THEN
		INSERT INTO Joins
	    	VALUES (employee_id, floor_num, room_num, date, current_hour);
	END IF;
	
	current_hour := current_hour + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE PROCEDURE leave_meeting (IN floor_number INTEGER, IN room_number INTEGER, IN date DATE, IN start_hour INTEGER, 
IN end_hour INTEGER, IN employee_id INTEGER)
AS $$
DECLARE
  current_hour INTEGER := start_hour;
BEGIN
  WHILE current_hour < end_hour LOOP
	IF ROW(floor_number, room_number, date, current_hour) IN (SELECT s.floor_num, s.room_num, s.booking_date, s.booking_time FROM Sessions s WHERE s.manager_eid IS NULL) THEN
		DELETE FROM Joins j
	  	WHERE (j.employee_eid = employee_id) AND (j.floor_num = floor_number) AND (j.room_num = room_number) AND (j.booking_date = date) AND (j.booking_time = current_hour);
	END IF;

	current_hour := current_hour + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;
	

CREATE OR REPLACE PROCEDURE approve_meeting (IN floor_number INTEGER, IN room_number INTEGER, IN date DATE, IN start_hour INTEGER, 
IN end_hour INTEGER, IN manager_id INTEGER) 
AS $$
DECLARE
  current_hour INTEGER := start_hour;
BEGIN

  WHILE current_hour < end_hour LOOP
	IF ROW(floor_number, room_number, date, current_hour) IN (SELECT s.floor_num, s.room_num, s.booking_date, s.booking_time FROM Sessions s WHERE s.manager_eid IS NULL) AND manager_id IN (SELECT eid FROM Managers) THEN
    		Update Sessions s
		SET manager_eid = manager_id
    		WHERE s.floor_num = floor_number AND s.room_num = room_number AND s.booking_date = date AND s.booking_time = current_hour;
	END IF;

	current_hour := current_hour + 1;
  END LOOP;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION remove_close_contacts()
RETURNS TRIGGER AS $$
BEGIN
	IF (NEW.contact_type = 'primary') THEN
		DELETE FROM Joins j WHERE j.employee_eid = NEW.employee_eid AND (j.booking_date - NEW.contact_date) >= 0; 
		DELETE FROM Sessions s WHERE s.booker_eid = NEW.employee_eid AND (s.booking_date - NEW.contact_date) >= 0; -- Logic is there but need to use unbook_room/ON DELETE CASCADE of Joins for Sessions
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
  IF (NEW.eid NOT IN (SELECT eid FROM Managers) AND NEW.eid NOT IN (SELECT eid FROM Seniors)) THEN
    RETURN NEW;
  ELSE
	RAISE NOTICE 'Employee with eid % is already of another type', NEW.eid; 
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

CREATE TRIGGER only_junior
BEFORE INSERT OR UPDATE ON Juniors
FOR EACH ROW EXECUTE FUNCTION check_only_junior();

CREATE TRIGGER only_senior
BEFORE INSERT OR UPDATE ON Seniors
FOR EACH ROW EXECUTE FUNCTION check_only_senior();

CREATE TRIGGER only_manager
BEFORE INSERT OR UPDATE ON Managers
FOR EACH ROW EXECUTE FUNCTION check_only_manager();