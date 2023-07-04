--\i C:/Users/harla/Documents/NUS/Y2S1/CS2102/CS2102_Project/schema.sql
--\i C:/Users/harla/Documents/NUS/Y2S1/CS2102/CS2102_Project/proc.sql
--\i C:/Users/harla/Documents/NUS/Y2S1/CS2102/CS2102_Project/data.sql 

--\i C:/Users/harla/Documents/NUS/Y2S1/CS2102/CS2102_Project/schema_W12_Thutsday.sql
--\i C:/Users/harla/Documents/NUS/Y2S1/CS2102/CS2102_Project/proc_W12_Thursday.sql
--\i C:/Users/harla/Documents/NUS/Y2S1/CS2102/CS2102_Project/data_W12_Thursday.sql 

--Add Departments. Dept IDs are from 101 onwards.
CALL add_department(101, 'ACCOUNTING');
CALL add_department(102, 'BUSINESS');
CALL add_department(103, 'COMPUTER ENGINEERING');
CALL add_department(104, 'DENTISTRY');
CALL add_department(105, 'ECONOMICS');
CALL add_department(106, 'FINANCE');
CALL add_department(107, 'GEOGRAPHY');
CALL add_department(108, 'HISTORY');
CALL add_department(109, 'INDUSTRIAL ENGINEERING');
CALL add_department(110, 'JAPANESE STUDIES');
CALL add_department(111, 'LAW');
CALL add_department(112, 'MEDICINE');
CALL add_department(113, 'NURSING');
CALL add_department(114, 'OBSTETRICS');
CALL add_department(115, 'PHYSICS');

--Trying to add_department with existing DID
CALL add_department(103, 'COMPUTING');

--Trying to add_department with existing Name (Only Raise Notice)
CALL add_department(116, 'COMPUTER ENGINEERING');

SELECT * FROM Departments ORDER BY did;

--Valid remove_department
CALL remove_department(110);
CALL remove_department(114);

--Invalid remove_department
CALL remove_department(117);

SELECT * FROM Departments ORDER BY did;

--Add employees. Eid starts from 1001.
CALL add_employee('Jianning', 90045299, 'manager', 103);
CALL add_employee('Zihan', 91234567, 'manager', 104);
CALL add_employee('Vikas', 92345678, 'manager', 105);
CALL add_employee('Yizhi', 93456789, 'manager', 103);

CALL add_employee('Junior1', 93456789, 'junior', 101);
CALL add_employee('Junior2', 99658584, 'junior', 102);
CALL add_employee('Junior3', 95330329, 'junior', 103);
CALL add_employee('Junior4', 94893129, 'junior', 104);
CALL add_employee('Junior5', 95604963, 'junior', 105);

CALL add_employee('Senior1', 99204443, 'senior', 101);
CALL add_employee('Senior2', 98970000, 'senior', 102);
CALL add_employee('Senior3', 93357101, 'senior', 103);
CALL add_employee('Senior4', 95329728, 'senior', 104);
CALL add_employee('Senior5', 94673693, 'senior', 105);

CALL add_employee('Manager1', 98353105, 'manager', 101);
CALL add_employee('Manager2', 92717965, 'manager', 102);
CALL add_employee('Manager3', 98268773, 'manager', 103);
CALL add_employee('Manager4', 95246534, 'manager', 104);
CALL add_employee('Manager5', 92203887, 'manager', 105);

--Invalid add employee. Invalid type.
CALL add_employee('Dean1', 90161449, 'Dean', 101);

--Invalid add employee. Invalid dept_id.
CALL add_employee('Junior6', 96852396, 'junior', 120);

SELECT * FROM Employees ORDER BY eid;
SELECT eid AS junior_eid FROM Juniors ORDER BY eid;
SELECT eid AS senior_eid FROM Seniors ORDER BY eid;
SELECT eid AS manager_eid FROM Managers ORDER BY eid;
SELECT eid AS booker_eid FROM Bookers ORDER BY eid;

-- Manually insert to violate ISA conditions.
INSERT INTO Juniors
VALUES (1001);

INSERT INTO Seniors
VALUES (1005);

INSERT INTO Managers
VALUES (1005);

INSERT INTO Bookers
VALUES (1005);

SELECT eid AS junior_eid FROM Juniors ORDER BY eid;
SELECT eid AS senior_eid FROM Seniors ORDER BY eid;
SELECT eid AS manager_eid FROM Managers ORDER BY eid;
SELECT eid AS booker_eid FROM Bookers ORDER BY eid;

--Valid remove_employee. One from each type (juniors, seniors, managers). Project Requirements allow for resigned date to be <= CURRENT_DATE but our data.sql will only have resigned_date = CURRENT_DATE for things related to future records to make sense
CALL remove_employee(1009, CURRENT_DATE);
CALL remove_employee(1014, CURRENT_DATE);
CALL remove_employee(1019, CURRENT_DATE);

--Invalid remove employee. Resigned date is in the future.
CALL remove_employee(1001, '2022-01-01');

SELECT * FROM Employees ORDER BY eid;

--Valid add_room. Floor number starts from 11, Room number starts from 51. Add room can only be added with today's date.
CALL add_room(11, 51, 'Jianning Room1', 100, 103, 1001, CURRENT_DATE);
CALL add_room(11, 52, 'Jianning Room2', 200, 103, 1001, CURRENT_DATE);
CALL add_room(11, 53, 'Jianning Room3', 300, 103, 1001, CURRENT_DATE);
CALL add_room(11, 54, 'Jianning Room4', 400, 103, 1001, CURRENT_DATE);
CALL add_room(11, 55, 'Jianning Room5', 500, 103, 1001, CURRENT_DATE);
CALL add_room(12, 51, 'Zihan Room1', 100, 104, 1002, CURRENT_DATE);
CALL add_room(12, 52, 'Zihan Room2', 200, 104, 1002, CURRENT_DATE);
CALL add_room(12, 53, 'Zihan Room3', 300, 104, 1002, CURRENT_DATE);
CALL add_room(12, 54, 'Zihan Room4', 400, 104, 1002, CURRENT_DATE);
CALL add_room(12, 55, 'Zihan Room5', 500, 104, 1002, CURRENT_DATE);
CALL add_room(13, 51, 'Vikas Room1', 100, 105, 1003, CURRENT_DATE);
CALL add_room(13, 52, 'Vikas Room2', 200, 105, 1003, CURRENT_DATE);
CALL add_room(13, 53, 'Vikas Room3', 300, 105, 1003, CURRENT_DATE);
CALL add_room(13, 54, 'Vikas Room4', 400, 105, 1003, CURRENT_DATE);
CALL add_room(13, 55, 'Vikas Room5', 500, 105, 1003, CURRENT_DATE);

--Invalid add room due to invalid dept_id.
CALL add_room(11, 56, 'Jianning Room6', 100, 120, 1001, CURRENT_DATE);

--Invalid add room due to invalid manager_id.
CALL add_room(11, 56, 'Jianning Room6', 100, 103, 1100, CURRENT_DATE);

--Invalid add room due to employee resigned
CALL add_room(11, 56, 'Jianning Room6', 100, 103, 1019, CURRENT_DATE);

--Invalid add room due to date != CURRENT_DATE.
CALL add_room(13, 55, 'Vikas Room1', 500, 105, 1003, '2021-10-28');

SELECT * FROM MeetingRooms ORDER BY floor_num, room_num;
SELECT * FROM Updates ORDER BY floor_num, room_num;

--Valid change capacity. Date must be today.
CALL change_capacity(11, 51, 99, 1001, CURRENT_DATE);
CALL change_capacity(12, 51, 3, 1002, CURRENT_DATE);
CALL change_capacity(13, 51, 79, 1003, CURRENT_DATE);

--Invalid change capacity due to date != CURRENT_DATE.
CALL change_capacity(11, 51, 99, 1001, '2021-10-28');

-- Invalid change capacity due to eid != manager.
CALL change_capacity(12, 51, 3, 1008, CURRENT_DATE);

-- Invalid change capacity due to manager resigned.
CALL change_capacity(13, 51, 89, 1019, CURRENT_DATE);

--Invalid change capacity due to manager did != room did.
CALL change_capacity(12, 51, 89, 1003, CURRENT_DATE);

-- update_capacity_same_did_as_manager TRIGGER
UPDATE Updates SET new_capacity = 5, manager_eid = 1003 WHERE floor_num = 11 AND room_num = 52;

SELECT * FROM Updates ORDER BY floor_num, room_num;

--Valid health declaration. No fever.
CALL declare_health (1001, CURRENT_DATE, 37.0);
CALL declare_health (1001, CURRENT_DATE - 1, 37.0);
CALL declare_health (1004, CURRENT_DATE, 37.0);
CALL declare_health (1005, CURRENT_DATE, 37.0);
CALL declare_health (1006, CURRENT_DATE, 37.0);
CALL declare_health (1007, CURRENT_DATE, 37.0);
CALL declare_health (1008, CURRENT_DATE, 37.0);
CALL declare_health (1011, CURRENT_DATE, 37.0);
CALL declare_health (1012, CURRENT_DATE, 37.0);
CALL declare_health (1013, CURRENT_DATE, 37.0);
CALL declare_health (1015, CURRENT_DATE, 37.0);
CALL declare_health (1016, CURRENT_DATE, 37.0);
CALL declare_health (1017, CURRENT_DATE, 37.0);
CALL declare_health (1018, CURRENT_DATE, 37.0);

--Valid health declaration. Fever.
CALL declare_health (1003, CURRENT_DATE, 37.6);

--Valid book room.
CALL book_room (11, 51, '2021-11-11', 1, 4, 1001);
CALL book_room (11, 53, '2021-11-11', 7, 8, 1001);
CALL book_room (11, 52, '2021-11-12', 3, 6, 1001);
CALL book_room (11, 54, '2021-11-13', 5, 11, 1001);
CALL book_room (12, 51, '2021-11-14', 5, 8, 1011);
CALL book_room (11, 51, '2021-11-15', 5, 6, 1011);
CALL book_room (12, 52, '2021-11-11', 1, 3, 1011);
CALL book_room (12, 52, '2021-11-11', 2, 4, 1011); --Raise Notice for 2, Books for 3-4
CALL book_room (13, 51, '2021-11-11', 1, 3, 1018);


--Invalid book room due to eid not booker.
CALL book_room (11, 51, '2021-11-11', 7, 8, 1006);

--Invalid book room due to booker resigned.
CALL book_room (11, 51, '2021-11-11', 7, 8, 1019);

--Invalid book room due to book date in the past.
CALL book_room (11, 51, '2021-10-11', 1, 3, 1001);

--Invalid book room due to fever/haven't declare.
CALL book_room (12, 51, '2021-11-11', 1, 3, 1003);
CALL book_room (12, 51, '2021-11-11', 1, 3, 1002);

--Invalid book room due to invalid end hour.
CALL book_room (11, 51, '2021-11-11', 23, 0, 1001);

-- book_room_with_fever TRIGGER
INSERT INTO Sessions VALUES (13, 51, '2021-12-12', 1, 1003, NULL);

-- book_date_in_future TRIGGER
INSERT INTO Sessions VALUES (11, 51, CURRENT_DATE, 1, 1001, NULL);

-- booker_cannot_be_junior TRIGGER
INSERT INTO Sessions VALUES(11, 51, '2021-11-11', 15, 1006, NULL);

SELECT * FROM Sessions ORDER BY floor_num, room_num, booking_date, booking_time;

--Check that the add_booker_as_participant trigger is functioning.
SELECT * FROM Joins ORDER BY employee_eid, floor_num, room_num, booking_date, booking_time;

--Valid Search Room
SELECT * FROM search_room(0, CURRENT_DATE, 1, 2); --Expected all rooms. (15 rooms)
SELECT * FROM search_room(0, '2021-11-11', 1, 2); --Expected all rooms except #11-51, #12-52 and #13-51. (12 rooms)
SELECT * FROM search_room(500, '2021-11-11', 1, 2); --Expected rooms #11-55, #12-55, #13-55. (3 rooms)
SELECT * FROM search_room(0, '2021-11-12', 5, 7); --Expected all rooms except #11-52. (14 rooms)
SELECT * FROM search_room(0, '2021-12-12', 23, 24); --Expected all rooms, 11pm to midnight slot. (15 rooms)

--Invalid Search Rooms
SELECT * FROM search_room(0, CURRENT_DATE, 1, 25); --End hour not in range
SELECT * FROM search_room(0, CURRENT_DATE, -1, 23); --Start hour not in valid range
SELECT * FROM search_room(0, CURRENT_DATE, 5, 4); --Start hour after end hour

--Valid Join meetings
CALL join_meeting(11, 51, '2021-11-11', 1, 4, 1004);
CALL join_meeting(11, 51, '2021-11-11', 2, 3, 1018);
CALL join_meeting(11, 53, '2021-11-11', 7, 8, 1008);
CALL join_meeting(11, 53, '2021-11-11', 7, 8, 1004);
CALL join_meeting(12, 51, '2021-11-14', 5, 8, 1004);
CALL join_meeting(12, 51, '2021-11-14', 5, 8, 1005);
CALL join_meeting(12, 52, '2021-11-11', 2, 3, 1018);

--Invalid Join due to max capacity reached.
CALL join_meeting(12, 51, '2021-11-14', 5, 8, 1006);

--Invalid Join due to employee resigned.
CALL join_meeting(11, 51, '2021-11-11', 1, 3, 1019);

--Invalid Join due to meeting in the past.
CALL join_meeting(11, 51, '2020-11-11', 1, 3, 1018);

--Invalid Join due to fever.
CALL join_meeting(11, 51, '2021-11-11', 1, 3, 1003);

--Invalid Join due to doesn't exist 
CALL join_meeting(11, 51, '2021-11-11', 20, 21, 1008);

-- join_meeting_with_fever TRIGGER
INSERT INTO Joins VALUES (1003, 11, 51, '2021-11-11', 3);

-- join_date_in_future TRIGGER
INSERT INTO Joins VALUES (1001, 11, 51, CURRENT_DATE, 1);

-- join_meeting_overbooked TRIGGER
INSERT INTO Joins VALUES(1001, 12, 51, '2021-11-14', 5);

SELECT * FROM Joins ORDER BY floor_num, room_num, booking_date, booking_time;

--Valid unbook rooms, only booker join
CALL unbook_room (11, 54, '2021-11-13', 5, 6, 1001);
CALL unbook_room (12, 52, '2021-11-11', 1, 2, 1011);

--Valid unbook room with participants removed
CALL unbook_room (12, 51, '2021-11-14', 7, 8, 1011);

SELECT * FROM Sessions ORDER BY floor_num, room_num, booking_date, booking_time;

SELECT * FROM Joins ORDER BY floor_num, room_num, booking_date, booking_time;

--Invalid unbook room, employee resigned
CALL unbook_room (12, 51, '2021-11-14', 7, 8, 1019);

--Invalid unbook room due to invalid end hour
CALL unbook_room (12, 51, '2021-11-14', 7, 5, 1018);

--Invalid unbook room due to date in the past
CALL unbook_room (12, 51, '2020-11-14', 7, 8, 1018);

--Invalid unbook room due to employee is not the one who booked
CALL unbook_room (11, 51, '2021-11-11', 1, 2, 1011);

--Valid approve meeting
CALL approve_meeting (11, 51, '2021-11-11', 1, 3, 1001);
CALL approve_meeting (12, 51, '2021-11-14', 5, 6, 1018);

--Invalid approve meeting due to EID not manager
CALL approve_meeting (12, 51, '2021-11-14', 5, 6, 1006);

--Invalid approve meeting due to meeting in the past
CALL approve_meeting (12, 51, '2020-11-14', 5, 6, 1018);

--Invalid approve meeting due to resigned
CALL approve_meeting (12, 51, '2021-11-14', 5, 6, 1019);

--Invalid approve due to fever 
CALL approve_meeting (12, 51, '2021-11-14', 5, 6, 1003);
--CALL approve_meeting (13, 51, '2021-11-11', 1, 2, 1003); #For trigger

--Invalid approve due to different department
CALL approve_meeting (12, 51, '2021-11-14', 5, 6, 1001);

--Invalid approve due to already approved
CALL approve_meeting (12, 51, '2021-11-14', 5, 6, 1018);

-- approve_room_with_fever TRIGGER
UPDATE Sessions  SET manager_eid = 1003  WHERE floor_num = 13 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 1 AND booker_eid = 1018;

-- approve_meeting_same_did_as_manager trigger
UPDATE Sessions  SET manager_eid = 1005  WHERE floor_num = 11 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 3 AND booker_eid = 1001;

-- meeting_approved_only_once TRIGGER
UPDATE Sessions SET manager_eid = 1004 WHERE floor_num = 11 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 2;

SELECT * FROM Sessions ORDER BY floor_num, room_num, booking_date, booking_time;
SELECT * FROM Joins ORDER BY floor_num, room_num, booking_date, booking_time;

--Valid leave meeting, non-booker
CALL leave_meeting(11, 51, '2021-11-11', 3, 4, 1004);

--Valid leave meeting, booker causing delete session and all participants to leave
CALL leave_meeting(11, 53, '2021-11-11', 7, 8, 1001);

--Invalid leave meeting due to meeting date in the past
CALL leave_meeting(11, 53, '2020-11-11', 7, 8, 1001);

--Invalid leave meeting due to meeting already approved  
CALL leave_meeting(11, 51, '2021-11-11', 1, 2, 1001);

--Invalid leave meeting due to session does not exist 
CALL leave_meeting(11, 53, '2021-11-11', 22, 23, 1001);

SELECT * FROM Sessions ORDER BY floor_num, room_num, booking_date, booking_time;
SELECT * FROM Joins ORDER BY floor_num, room_num, booking_date, booking_time;

--Valid reject meeting, no other participants
CALL reject_meeting(11, 54, '2021-11-13', 10, 11, 1001);

--Valid reject meeting, with other participants
CALL reject_meeting(12, 52, '2021-11-11', 2, 3, 1018);

--Invalid reject meeting due to not manager
CALL reject_meeting(11, 54, '2021-11-13', 9, 10, 1007);

--Invalid reject meeting due to meeting in the past
CALL reject_meeting(11, 54, '2020-11-13', 9, 10, 1001);

--Invalid reject meeting due to resigned employee
CALL reject_meeting(11, 54, '2021-11-13', 9, 10, 1019);

--Invalid reject meeeting due to different department
CALL reject_meeting(11, 54, '2021-11-13', 9, 10, 1018);

--Invalid reject meeting due to already approved
CALL reject_meeting(11, 51, '2021-11-11', 1, 2, 1001);

SELECT * FROM Sessions ORDER BY floor_num, room_num, booking_date, booking_time;
SELECT * FROM Joins ORDER BY floor_num, room_num, booking_date, booking_time;

--Valid remove employee causing employee_resigned trigger
--CALL remove_employee(1018, CURRENT_DATE); --#12-51 5-6 will become unapproved. #13-51 1-3 will be removed. #11-51 2-3 1018 removed as participant. 
--UPDATE Employees SET resigned_date = CURRENT_DATE WHERE eid = 1018; --

--SELECT * FROM Sessions ORDER BY floor_num, room_num, booking_date, booking_time;
--SELECT * FROM Joins ORDER BY floor_num, room_num, booking_date, booking_time;

--Valid change_capacity causing capacity_overflow_after_reduction trigger
--CALL change_capacity(12, 51, 2, 1018, CURRENT_DATE); --#12-51 5-6 will be removed. #12-51 6-7 will be removed. 
--UPDATE Updates SET new_capacity = 2 WHERE floor_num = 12 AND room_num = 51;

--SELECT * FROM Sessions ORDER BY floor_num, room_num, booking_date, booking_time;
--SELECT * FROM Joins ORDER BY floor_num, room_num, booking_date, booking_time;

--Automatically add booker as participant through TRIGGER
--INSERT INTO Sessions VALUES (11, 55, '2021-11-20', 1, 1001, NULL);
--SELECT * FROM Sessions ORDER BY floor_num, room_num, booking_date, booking_time;
--SELECT * FROM Joins ORDER BY floor_num, room_num, booking_date, booking_time;

-- leave_meeting_booker TRIGGER
-- DELETE FROM Joins WHERE employee_eid = 1001 AND floor_num = 11 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 1;

-- capacity_overflow_after_reduction TRIGGER
-- CALL change_capacity(12, 51, 2, 1018, CURRENT_DATE); --#12-51 5-6 will be removed. #12-51 6-7 will be removed. 

/* Contact Tracing */

-- Valid health declaration. Resigned
CALL declare_health (1009, CURRENT_DATE - 1, 36.0);

-- Does not include 1009 (Resigned)
SELECT * FROM non_compliance(CURRENT_DATE - 3, CURRENT_DATE);

-- Includes 1009 (Time period before resignation)
SELECT * FROM non_compliance(CURRENT_DATE - 3, CURRENT_DATE - 1);

-- Booking after fever day (1005 Not Traced)
CALL book_room (11, 51, '2022-10-11', 1, 4, 1001);
CALL join_meeting(11, 51, '2022-10-11', 1, 4, 1005);
CALL approve_meeting (11, 51, '2022-10-11', 1, 4, 1001);

-- Booking on fever day with the fever (1002, 1004 Traced)
CALL book_room (11, 51, '2022-10-10', 1, 4, 1001);
CALL join_meeting (11, 51, '2022-10-10', 1, 4, 1015);
CALL join_meeting(11, 51, '2022-10-10', 1, 4, 1004);
CALL approve_meeting (11, 51, '2022-10-10', 1, 4, 1001);

-- Booking on fever day without the fever (1006 Traced)
CALL book_room (11, 51, '2022-10-10', 8, 9, 1001);
CALL join_meeting(11, 51, '2022-10-10', 8, 9, 1006);
CALL approve_meeting (11, 51, '2022-10-10', 8, 9, 1001);

-- Booking on fever day in another room (1007 Not Traced)
CALL book_room (11, 52, '2022-10-10', 1, 4, 1001);
CALL join_meeting(11, 52, '2022-10-10', 1, 4, 1007);
CALL approve_meeting (11, 52, '2022-10-10', 1, 4, 1001);

-- Booking on fever day not approved (1008 Not Traced)
CALL book_room (11, 51, '2022-10-10', 6, 7, 1001);
CALL join_meeting(11, 51, '2022-10-10', 6, 7, 1008);

-- Booking on fever day - 3 (1011 Traced)
CALL book_room (11, 51, '2022-10-07', 1, 4, 1001);
CALL join_meeting(11, 51, '2022-10-07', 1, 4, 1011);
CALL approve_meeting (11, 51, '2022-10-07', 1, 4, 1001);

-- Booking on fever day + 7 (Deleted - 1004 close contact)
CALL book_room (11, 51, '2022-10-17', 1, 4, 1004);

CALL approve_meeting (11, 51, '2022-10-17', 1, 4, 1004);

-- Booking on fever day + 7 (Not Deleted - 1005 Not close contact)
CALL book_room (11, 51, '2022-10-17', 5, 6, 1001);
CALL join_meeting (11, 51, '2022-10-17', 5, 6, 1005);
CALL approve_meeting (11, 51, '2022-10-17', 5, 6, 1001);

-- Booking on fever day + 8 (Not Deleted - After D + 7)
CALL book_room (11, 51, '2022-10-18', 1, 4, 1004);

CALL approve_meeting (11, 51, '2022-10-18', 1, 4, 1004);

-- Booking on fever day + 15 by primary (Deleted - 1002 primary contact)
CALL book_room (11, 51, '2022-10-25', 1, 4, 1015);

-- The primary fever contact for contact tracing
CALL declare_health (1015, '2022-10-10', 37.6);

SELECT * FROM Contact_tracing(1015);
SELECT * FROM ContactTracingLog;

-- View booking report
SELECT * FROM view_booking_report('2021-11-11',1001);
SELECT * FROM view_booking_report('2021-11-11',1005);
SELECT * FROM view_booking_report('2021-11-11',1011);

-- View future meeting
SELECT * FROM view_future_meeting('2021-11-11',1001);
SELECT * FROM view_future_meeting('2021-11-11',1005);
SELECT * FROM view_future_meeting('2021-11-11',1011);

-- View manager report
SELECT * FROM view_manager_report('2021-11-11',1001);
SELECT * FROM view_manager_report('2021-11-11',1005);
SELECT * FROM view_manager_report('2021-11-11',1011);

--SELECT * FROM Sessions ORDER BY floor_num, room_num, booking_date, booking_time;
--SELECT * FROM Joins ORDER BY floor_num, room_num, booking_date, booking_time;

--only junior TRIGGER
--INSERT INTO Juniors VALUES(1001);

--only booker TRIGGER
--INSERT INTO Bookers VALUES(1005);

--only senior TRIGGER
-- INSERT INTO Seniors VALUES(1005);

--only manager TRIGGER
-- INSERT INTO Managers VALUES(1011);

-- add_booker_as_participant TRIGGER
-- Triggers every book_room 

-- employee_resigned TRIGGER 
-- Triggers everytime employee resigns 

-- update_capacity_same_did_as_manager TRIGGER
-- UPDATE Updates SET new_capacity = 5, manager_eid = 1003 WHERE floor_num = 11 AND room_num = 52;

-- capacity_overflow_after_reduction TRIGGER
--CALL change_capacity(12, 51, 2, 1018, CURRENT_DATE); --#12-51 5-6 will be removed. #12-51 6-7 will be removed. 

-- book_room_with_fever TRIGGER
-- INSERT INTO Sessions VALUES (13, 51, '2021-12-12', 1, 1003, NULL);

-- approve_room_with_fever TRIGGER
-- UPDATE Sessions  SET manager_eid = 1003  WHERE floor_num = 13 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 1 AND booker_eid = 1018;

-- join_meeting_with_fever TRIGGER
-- INSERT INTO Joins VALUES (1003, 11, 51, '2021-11-11', 3);

-- update_participants_after_approval TRIGGER
--DELETE FROM Joins WHERE employee_eid = 1004 AND floor_num = 11 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 1;

-- update_capacity_same_did_as_manager TRIGGER
-- UPDATE Updates SET new_capacity = 5, manager_eid = 1003 WHERE floor_num = 11 AND room_num = 52;

-- book_date_in_future TRIGGER
-- INSERT INTO Sessions VALUES (11, 51, CURRENT_DATE, 1, 1001, NULL);

-- join_date_in_future TRIGGER
-- INSERT INTO Joins VALUES (1001, 11, 51, CURRENT_DATE, 1);

-- join_meeting_overbooked TRIGGER
-- INSERT INTO Joins VALUES(1001, 12, 51, '2021-11-14', 5);

-- leave_meeting_booker TRIGGER
-- DELETE FROM Joins WHERE employee_eid = 1001 AND floor_num = 11 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 1;

-- booker_cannot_be_junior TRIGGER
-- INSERT INTO Sessions VALUES(11, 51, '2021-11-11', 15, 1006, NULL);

-- approve_meeting_same_did_as_manager trigger
--UPDATE Sessions SET manager_eid = 1016 WHERE floor_num = 11 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 5;
--UPDATE Sessions  SET manager_eid = 1005  WHERE floor_num = 11 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 3 AND booker_eid = 1001;

-- meeting_approved_only_once TRIGGER
-- UPDATE Sessions SET manager_eid = 1004 WHERE floor_num = 11 AND room_num = 51 AND booking_date = '2021-11-11' AND booking_time = 2;
