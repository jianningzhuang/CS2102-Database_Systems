DROP TABLE IF EXISTS Joins, Sessions, Updates, Juniors, Seniors, Managers, Bookers, HealthDeclarations, Employees, EmployeeContacts, MeetingRooms, Departments, ContactTracingLog;

CREATE TABLE Departments (
  did INTEGER PRIMARY KEY,
  dname VARCHAR(255)
);

CREATE TABLE Employees (
  eid INTEGER PRIMARY KEY,
  ename VARCHAR(255),
  email VARCHAR(255) UNIQUE, 
  resigned_date DATE,
  did INTEGER NOT NULL,
  FOREIGN KEY (did) REFERENCES Departments (did),
  CHECK (resigned_date <= CURRENT_DATE) --Assuming time only moves forward, resigned_date once inserted will never violate
);

CREATE TABLE EmployeeContacts (
  eid INTEGER,
  contact_number INTEGER,
  PRIMARY KEY (eid, contact_number),
  FOREIGN KEY (eid) REFERENCES Employees (eid)
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
  FOREIGN KEY (floor_num, room_num) REFERENCES MeetingRooms (floor_num, room_num) ON DELETE CASCADE,
  FOREIGN KEY (booker_eid) REFERENCES Bookers (eid),
  FOREIGN KEY (manager_eid) REFERENCES Managers (eid),
  CHECK (booking_time BETWEEN 0 AND 23)
);

CREATE TABLE Joins (
  employee_eid INTEGER,
  floor_num INTEGER,
  room_num INTEGER,
  booking_date DATE,
  booking_time INTEGER,
  PRIMARY KEY (employee_eid, floor_num, room_num, booking_date, booking_time),
  FOREIGN KEY (employee_eid) REFERENCES Employees (eid),
  FOREIGN KEY (floor_num, room_num, booking_date, booking_time) REFERENCES Sessions (floor_num, room_num, booking_date, booking_time) ON DELETE CASCADE,
  CHECK (booking_time BETWEEN 0 AND 23)
);

CREATE TABLE Updates (
  manager_eid INTEGER,
  floor_num INTEGER,
  room_num INTEGER,
  update_date DATE,
  new_capacity INTEGER,
  PRIMARY KEY (manager_eid, floor_num, room_num, update_date),
  FOREIGN KEY (manager_eid) REFERENCES Managers (eid),
  FOREIGN KEY (floor_num, room_num) REFERENCES MeetingRooms (floor_num, room_num),
  CONSTRAINT non_negative_capacity CHECK (new_capacity > 0)
);

CREATE TABLE ContactTracingLog (
  employee_eid INTEGER,
  contact_date DATE,
  contact_type VARCHAR(255),
  log_time TIMESTAMP,
  PRIMARY KEY (employee_eid, contact_date, contact_type, log_time),
  FOREIGN KEY (employee_eid) REFERENCES Employees (eid)
);