
CREATE OR REPLACE FUNCTION check_only_engineer()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.eid NOT IN (SELECT eid FROM Managers)) THEN
    RETURN NEW;
  ELSE
	RAISE NOTICE 'Employee with eid % is already a Manager', NEW.eid; 
    RETURN NULL;
  END IF;

END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION check_only_manager()
RETURNS TRIGGER AS $$
BEGIN
  IF (NEW.eid NOT IN (SELECT eid FROM Engineers)) THEN
    RETURN NEW;
  ELSE
	RAISE NOTICE 'Employee with eid % is already an Engineer', NEW.eid; 
    RETURN NULL;
  END IF;

END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER only_engineer
BEFORE INSERT OR UPDATE ON Engineers
FOR EACH ROW EXECUTE FUNCTION check_only_engineer();

CREATE TRIGGER only_manager
BEFORE INSERT OR UPDATE ON Managers
FOR EACH ROW EXECUTE FUNCTION check_only_manager();

INSERT INTO Offices
VALUES (10001, 'Bishan');

INSERT INTO Departments
VALUES (101, 1000, 10001, 1001);

INSERT INTO Employees
VALUES (1001, 101), (1002, 101), (1003, 101);

INSERT INTO Managers
VALUES (1001), (1002);

INSERT INTO Engineers
VALUES (1001), (1003);

INSERT INTO Managers
VALUES (1003), (1004);

CREATE OR REPLACE FUNCTION check_budget_exceed()
RETURNS TRIGGER AS $$
DECLARE
	total_hours INTEGER;
	budget INTEGER;
	remaining INTEGER;
BEGIN
	SELECT SUM(hours) INTO total_hours FROM Works WHERE pid = NEW.pid AND eid <> NEW.pid;
	
	SELECT pbudget INTO budget FROM Projects WHERE pid = NEW.pid;
	
	remaining := (budget - total_hours*100)/100;
	
	IF NEW.hours > remaining THEN
		RETURN (NEW.pid, NEW.eid, NEW.wid, remaining);
	ELSE	
		RETURN NEW;
	END IF;
	
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_budget
BEFORE INSERT OR UPDATE ON Works
FOR EACH ROW EXECUTE FUNCTION check_budget_exceed();

CREATE OR REPLACE FUNCTION check_hours_exceed()
RETURNS TRIGGER AS $$
DECLARE
	total_hours INTEGER;
	max_hour INTEGER;
	remaining INTEGER;
BEGIN
	SELECT SUM(hours) INTO total_hours FROM Works WHERE wid = NEW.wid AND eid <> NEW.pid;
	
	SELECT max_hours INTO max_hour FROM WorkType WHERE wid = NEW.wid;
	
	remaining := (max_hour - total_hours);
	
	IF NEW.hours > remaining THEN
		RETURN (NEW.pid, NEW.eid, NEW.wid, remaining);
	ELSE	
		RETURN NEW;
	END IF;
	
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_hours
BEFORE INSERT OR UPDATE ON Works
FOR EACH ROW EXECUTE FUNCTION check_hours_exceed();

CREATE OR REPLACE FUNCTION raise_worktype_notice()
RETURNS TRIGGER AS $$
BEGIN
	RAISE NOTICE 'default wid should not be deleted or modified';
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_worktype
BEFORE DELETE OR UPDATE ON WorkType
FOR EACH ROW WHEN (OLD.wid = 0)
EXECUTE FUNCTION raise_worktype_notice();

INSERT INTO Worktype
VALUES (0, 100), (1, 200);