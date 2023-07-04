CALL add_department(101, 'IT');
CALL add_department(102, 'MATH');
CALL add_department(103, 'HR');
CALL add_department(104, 'SECURITY');
CALL add_department(104, 'EXISTS');

CALL remove_department(101);

CALL add_employee('Jianning', 90045299, 'manager', 102);
CALL add_employee('Zihan', 91234567, 'manager', 102);
CALL add_employee('Vikas', 92345678, 'manager', 102);
CALL add_employee('Yizhi', 93456789, 'manager', 102);
CALL add_employee('boy', 93456789, 'junior', 102);

CALL remove_employee(1004, '2021-10-12');

CALL add_room(1, 1, 'jianning room', 50, 102, 1001, '2021-10-10');
CALL add_room(1, 2, 'zihan room', 60, 102, 1002, '2021-10-10');
CALL add_room(1, 3, 'vikas room', 70, 102, 1003, '2021-10-10');
CALL add_room(1, 4, 'yizhi room', 80, 102, 1004, '2021-10-10');

CALL change_capacity(1, 1, 100, 1001, '2021-10-11');
CALL change_capacity(1, 1, 200, 1001, '2021-11-11');
CALL change_capacity(1, 2, 40, 1002, '2021-10-12');

INSERT INTO Sessions
VALUES (1, 1, '2021-10-17', 1, 1001, 1001);

BEGIN TRANSACTION;
CALL book_room(1, 1, '2021-10-17', 3, 5, 1001);
CALL book_room(1, 1, '2021-10-17', 4, 6, 1001);
COMMIT;
CALL book_room(1, 1, '2021-10-17', 8, 11, 1005);

CALL unbook_room(1, 1, '2021-10-17', 3, 6, 1002);
CALL unbook_room(1, 1, '2021-10-17', 3, 4, 1001);

-- employees

INSERT into employees
values (9999,
  'ajunior','ajunior_9999@company.com', 1,null,null,null,102);
  
INSERT into employees
values (9998,
  'asenior','asenior_9998@company.com', 1,null,null,null,102);

INSERT into employees
values (9997,
  'amanager','amanager_9997@company.com', 1,null,null,null,102);
 
 INSERT into employees
values (9996,
  'bmanager','bmanager_9996@company.com', 1,null,null,null,103);
  
   INSERT into employees
values (9995,
  'bsenior','bsenior_9995@company.com', 1,null,null,null,103);
  
     INSERT into employees
values (9994,
  'bjunior','bjunior_9994@company.com', 1,null,null,null,103);
  
-- bookers
INSERT into bookers values (9998);
INSERT into bookers values (9997);
INSERT into bookers values (9996);
INSERT into bookers values (9995);

-- juniors
INSERT into juniors values (9999);
INSERT into juniors values (9994);

-- seniors
INSERT into seniors values (9998);
INSERT into seniors values (9995);
-- managers
INSERT into managers values (9997);
INSERT into managers values (9996);


-- meetingroom
INSERT INTO MeetingRooms(room_num, floor_num,rname,did)
VALUES (11,11,'Canteen',102);
INSERT INTO MeetingRooms(room_num, floor_num,rname,did)
VALUES (11,12,'Kitchen',102);
INSERT INTO MeetingRooms(room_num, floor_num,rname,did)
VALUES (12,12,'hr office',103);


-- sessions

INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (11,11,11,'2021-12-24',9998,9997); -- date future, booked by asenior approved by amanager
INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (11,11,10,'2021-9-24',9998,9997); -- date past, booked by asenior approved
INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (11,11,12,'2021-12-24',9998,NULL); -- date future, booked by asenior not approved
INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (11,11,12,'2021-9-24',9998,9997); -- date past, booked by asenior approved
INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (12,12,11,'2021-12-24',9995,9996); -- date future, booked by bsenior approved by bmanager
INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (12,12,12,'2021-12-24',9995,NULL); -- date future, booked by bsenior not approved
INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (11,11,13,'2021-12-24',9997,9997); -- date future, booked by amanager
INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (12,12,13,'2021-12-24',9996,9996); -- date future, booked by bmanager
INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (11,11,13,'2021-9-24',9997,9997); -- date past, booked by amanager
INSERT INTO SESSIONS (room_num,floor_num,booking_time,booking_date,booker_eid,manager_eid)
VALUES (12,12,13,'2021-9-24',9996,9996); -- date past, booked by bmanager

-- joins join 3 types of room , room approved room not approved room past

INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
VALUES (9999,11,11,11,'2021-12-24'); -- ajunior joining meeting room, future , approved
INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
VALUES (9999,11,11,12,'2021-12-24'); -- ajunior joining meeting room, future , not approved 
INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
VALUES (9999,11,11,13,'2021-12-24'); -- ajunior joining meeting room, future , approved
INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
VALUES (9999,11,11,13,'2021-9-24'); -- ajunior joining meeting room, past


INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
VALUES (9998,11,11,11,'2021-12-24'); -- asenior joining meeting room, future , approved
INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
VALUES (9998,11,11,12,'2021-12-24'); -- asenior joining meeting room, future , not approved
INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
VALUES (9998,11,11,13,'2021-12-24'); -- asenior joining meeting room, future , approved
INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
VALUES (9998,11,11,13,'2021-9-24'); -- asenior joining meeting room, past
INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
VALUES (9998,12,12,11,'2021-12-24'); -- asenior joining meeting room, future, another department appproved
--INSERT INTO JOINS (employee_eid, room_num, floor_num, booking_time, booking_date)
--VALUES (9998,11,11,12,'2021-12-24'); -- asenior joining meeting room, future, another department not approved

CALL declare_health(1001, '2021-10-9', 36.6);
CALL declare_health(1001, '2021-10-10', 36.7);
CALL declare_health(1002, '2020-10-10', 37.6);
CALL declare_health(1002, '2021-10-10', 36.6);

INSERT INTO Sessions
VALUES (1, 2, '2020-10-10', 1,  1002, 1001);

INSERT INTO Joins
VALUES (1002, 1, 2, '2020-10-10', 1); -- The source

INSERT INTO Sessions
VALUES (1, 2, '2020-10-09', 1, 1001, 1001);

INSERT INTO Joins
VALUES (1001, 1, 2, '2020-10-09', 1); -- Will kenna close contact OMG

INSERT INTO Sessions
VALUES (1, 2, '2020-10-11', 1, 1002, 1001); -- Should get deleted

INSERT INTO Joins
VALUES (1002, 1, 2, '2020-10-11', 1); -- Should get Deleted