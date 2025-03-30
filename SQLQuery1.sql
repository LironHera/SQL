/*
The project addresses the topic of a gym that opened in 2014 in Tel Aviv.
It is structured from 7 different tables that focus on the gym's employees, instructors, and members.
I chose this topic because it is one of my main areas of interest, and I wanted to research it.
There are certain topics related to the gym that are not included in the project because they are not relevant to my database.
In the "Member Registration" table, the dates refer to the current year and do not include previous years, as they are not relevant.
I will elaborate on each table and its data further below.
*/


USE MASTER
GO
CREATE DATABASE Project_num1
GO
USE Project_num1


/*
The first table is the "Membership Types" table. Since it is a master table with no relationships (foreign keys), it is listed first.
This table details the different types of memberships available at the gym, categorized by duration and type of membership.
It was created so that each gym member can register for the relevant facilities based on the period during which they wish to train.
*/

CREATE TABLE [Membership Types]
(	MemTypeID INT IDENTITY (1,1),
	[Period] VARCHAR (15) NOT NULL,
	[Membership Type] VARCHAR (30) NOT NULL,
	[Monthly Cost] MONEY CONSTRAINT mem_price_df DEFAULT 0.00,
	CONSTRAINT mem_id_pk PRIMARY KEY (MemTypeID))



/*
The second table is the "Departments" table. 
Since it is also a master table with no relationships (foreign keys), it is listed second.
This table details the various employee departments at the gym.
The table was created to understand the different departments and why some employees are not directly connected to clients.	
*/

CREATE TABLE Departments
(	DepartmentID INT IDENTITY (100,100),
	[Department Name] VARCHAR (20),
	CONSTRAINT dep_depid_pk PRIMARY KEY (DepartmentID),
	CONSTRAINT dep_depname_uk UNIQUE ([Department Name]))



/*
The third table is the "Employees" table.
This table provides the details of the gym's employees across the various departments.
It includes all employees who have worked at the gym since its opening in 2014, up to the current date.
This table is related to the "Departments" table with a one-to-many relationship: one department has many employees, 
but each employee works in only one department.
*/

CREATE TABLE Employees
(	EmployeeID INT IDENTITY (1,1),
	[First Name] VARCHAR (10) NOT NULL,
	[Last Name] VARCHAR (30) NOT NULL,
	Adress VARCHAR (50),
	Phone VARCHAR (15) NOT NULL,
	[Date Of Birth] DATE,
	[Hire Date] DATE NOT NULL DEFAULT CAST(GETDATE() AS DATE), 
	[Work End Date] DATE, 
	DepartmentID INT,
	CONSTRAINT emp_empid_pk PRIMARY KEY(EmployeeID),  
	CONSTRAINT emp_phone_uk UNIQUE (Phone),
	CONSTRAINT emp_phone_ck CHECK (Phone LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	CONSTRAINT emp_depid_fk FOREIGN KEY (DepartmentID) REFERENCES Departments (DepartmentID))



/*
The fourth table is the "Training Schedule" table.
This table provides details of the gym's classes, including the class name, day, time, and instructor.
Each day features four classes between 18:00 and 21:00, and only members who have subscribed to classes can register for them.
This table is related to the "Employees" table with a one-to-many relationship: one employee can lead several classes, 
but each class is associated with a single instructor.
*/

CREATE TABLE [Traininig Schedule]
(	TrainingID INT IDENTITY,
	[Training Name] VARCHAR (20) NOT NULL,
	[Day] VARCHAR (10) NOT NULL,
	[Hour] TIME NOT NULL,
	[Max Partitcipants] INT  DEFAULT 10,
	EmployeeID INT ,
	CONSTRAINT ttype_trainid_pk PRIMARY KEY(TrainingID), 
	CONSTRAINT ttype_empid_fk FOREIGN KEY (EmployeeID) REFERENCES Employees (EmployeeID))



/*
The fifth table is the "Memberships" table.
This table includes all the relevant details about the gym's members.
It also includes members whose membership have ended in the current year and have not been renewed.
The table includes all personal details of the members, but it does not include subscription details.
All subscription information is stored in the tables linked to this one and will be detailed further below.
This is a master table, and it has no relationships (foreign keys) with the other tables.
*/

CREATE TABLE Memberships
(	MembershipID INT IDENTITY,
	[First Name] VARCHAR (10) NOT NULL,
	[Last Name] VARCHAR (30) NOT NULL,
	Adress VARCHAR (30),
	Phone VARCHAR (15) NOT NULL,
	Email VARCHAR (50),
	[Date Of Birth] DATE,
	Sex VARCHAR (1), 
	CONSTRAINT mem_empid_pk PRIMARY KEY(MembershipID), 
	CONSTRAINT mem_phone_uk UNIQUE (Phone),
	CONSTRAINT mem_phone_ck CHECK (Phone LIKE '[0-9][0-9][0-9]-[0-9][0-9][0-9][0-9][0-9][0-9][0-9]'),
	CONSTRAINT mem_email_uk UNIQUE(Email),
	CONSTRAINT mem_email_ck CHECK(Email LIKE '%@%.%'))



/*
The sixth table is the "Trainee Registration" table.
This table details the registration information for each member, including dates and subscription status.
This table was created to record the dates and type of membership separately from the "Memberships" table,
In order to avoid creating an overload of rows and repeating irrelevant details.
It is related to the "Membership Types" table with a one-to-many relationship: one membership type can have multiple registrations.
It is also related to the "Memberships" table with a one-to-many relationship: a single member can register multiple times for the gym within the current year (depending on the type of subscription).
*/
	
CREATE TABLE [Trainee Registration]
(	RegistrationID INT IDENTITY (1,1),
	MembershipID INT,
	MemTypeID INT,
	[Registration Date] DATE NOT NULL,
	[End Date] DATE,  
	[Status] VARCHAR (10) CONSTRAINT reg_status_df DEFAULT 'active'
	CONSTRAINT regid_reg_pk PRIMARY KEY(RegistrationID), 
	CONSTRAINT memid_reg_fk FOREIGN KEY (MembershipID) REFERENCES Memberships (MembershipID),
	CONSTRAINT trainid_reg_fk FOREIGN KEY (MemTypeID) REFERENCES [Membership Types] (MemTypeID))
	


/*
The seventh table is the "Registration For Classes" table.
This table details which members have registered for which classes.
Only members whose membership type includes access to classes can register for them.
This table was created to maintain organized class registrations,
And to monitor that the number of members registered for a specific class does not exceed the maximum allowed capacity (which is specified in the "Training Schedule" table).
It is related to the "Membership" table with a one-to-many relationship: one member can register for several classes.
It is also related to the "Training Schedule" table with a one-to-many relationship: each specific training time can have multiple member registrations.
*/

CREATE TABLE [Registration For Classes]
(	RegClassesID INT IDENTITY (1,1),
	MembershipID INT,
	TrainingID INT,
	CONSTRAINT rgcl_mem_fk FOREIGN KEY (MembershipID) REFERENCES Memberships (MembershipID),
	CONSTRAINT rgcl_trn_fk FOREIGN KEY (TrainingID) REFERENCES [Traininig Schedule] (TrainingID))



-----------------------------------------------------------------------------------------------------------------	



GO

INSERT INTO [Membership Types] ([Period], [Membership Type], [Monthly Cost])
	VALUES  ('Monthly','Gym',300),
			('Semi-Annual','Gym',250),
			('Annual','Gym',200),
			('Monthly','Gym & Classes',450),
			('Semi-Annual','Gym & Classes',400),
			('Annual','Gym & Classes',350)


INSERT INTO Departments ([Department Name])
	VALUES ('Administration'),
			('Maintenance'),
			('Training')


		
INSERT INTO Employees ([First Name], [Last Name], Adress, Phone, [Date Of Birth], [Hire Date], [Work End Date], DepartmentID)
	VALUES ('Adar','Popel','Hashalom 13','050-4440224','1997-09-04','2014-01-10',NULL,100),
			('Gefen','Hackmon','Yarkon 57','052-6234980','1998-07-23','2016-03-15','2020-05-20',300),
			('David','Kaplan','Ben Gurion 8','050-1652896','1965-10-17','2021-04-20',NULL,200),
			('Anat','Solomon','Hashomer Hatzair 23','054-7345966','2000-03-08','2014-01-12','2020-06-30',100),
			('Dalit','Azulay','Jabotinsky 51','050-5678151','1977-08-04','2022-06-15','2021-04-01',200),
			('Yossi','Tzukrel','Yigael Allon 25','050-8913172','1996-12-27','2016-07-17','2021-09-01',300),
			('Lilach','Ashkenazi','Eli Cohen 11','054-9463466','2000-01-13','2018-03-23','2020-11-05',300),
			('Ronit','Farkash','Yarmuch 17','052-3091256','2000-03-13','2000-05-01',NULL,300),
			('Amit','Peretz','Moshe Dayan 4','052-6725670','1999-01-12','2014-01-10','2021-01-01',200),
			('Sharon','Zohar','Givati ??7','050-3330357','2002-08-08','2019-12-06','2023-12-10',300),
			('Aviv','Ben-Shimon','Hirshfeld 41','052-8778127','2000-07-25','2015-06-07',NULL,300),
			('Or','Chazan','Rimon 1','052-3801794','2002-07-03','2023-04-19',NULL,300),
			('Gali','Yeger','Rabbi Uziel 12','053-4355940','2001-08-06','2023-11-11','2024-12-09',300),
			('Ana','Baruch','Merhavim 29','054-3509895','2001-02-26','2015-02-18',NULL,300),
			('Misha','Zach','HaHermon 14','052-3412101','2001-02-18','2014-01-10',NULL,300),
			('Ran','Danino','Zabotinsky 65','054-3113680','2000-12-22','2018-08-19','2023-10-15',300),
			('Avi','Lapid','Karl Netter 6','050-4656724','2000-09-03','2017-04-26',NULL,300),
			('Yuri','Kaplinsky','Ada 6','050-4677468','2000-08-17','2014-01-13','2024-04-30',300),
			('Sima','Cohen','Wolfson 30','054-9264590','2000-08-22','2020-09-06',NULL,300),
			('Natali','Shahar','HaShikma 3','050-8444111','2001-11-07','2020-11-19',NULL,300),
			('Ben','Baruch','Hechaluts 4','050-3652356','2001-06-01','2014-01-12','2016-12-16',300),
			('Netta ','Kaplan','Allenby 231','053-2863987','1967-06-04','2023-07-28',NULL,200),
			('Meir ','Alon','Rothschild Boulevard 215','054-9968580','2005-03-03','2014-05-14','2021-04-01',100),
			('Ilana ','Peled','Dizengoff 168','053-6100347','2010-08-17','2021-03-30','2022-02-01',100),
			('Yair ','Davidovich','King George 210','052-6267569','1975-02-12','2020-10-26','2021-10-28',200),
			('Yael',' Cohen-Arazi','Jaffa 65','054-9961093','2018-07-25','2023-12-02','2024-06-24',300),
			('Tzvika ','Shalom','Ben Yehuda 96','052-2471289','2020-09-08','2021-09-07','2022-02-01',100),
			('Yigal ','Barkai','Herzl 8','054-9798670','2004-05-02','2018-11-13','2022-03-15',300),
			('Limor ','Avrahami','Hayarkon 96','054-7631680','1958-11-29','2022-08-29','2003-01-01',200),
			('Reut ','Shteinberg','Shalom Aleichem 47','053-2801166','2008-04-18','2020-07-21','2024-01-20',300),
			('Aharon ','Klein','Ibn Gabirol 187','050-2652222','2019-10-04','2016-03-16','2022-01-01',100),
			('Or ','Naor','Bialik 35','054-6601469','2016-11-16','2019-04-09','2021-06-30',300),
			('Shaked ','Abramovich','Haifa 51','053-7125555','2018-07-29','2022-02-20',NULL,100),
			('Shimon ','Golan','Hamered 19','058-6662690','2020-12-23','2015-06-15','2020-09-30',300),
			('Tami ','Lavon','Yehuda Halevi 147','054-8757890','2022-02-15','2021-08-06','2021-10-10',200),
			('Yaara ','Kedmi','Emek Refaim 7','050-4814341','2017-01-03','2017-09-11','2018-08-25',300),
			('Hanan ','Grossman','Begin Boulevard 225','058-6251146','1979-04-27','2014-10-04','2022-05-30',200),
			('Aviv ','Doron','Shimon Peres 8','054-8153999','2023-06-10','2020-05-23','2022-07-10',300),
			('Inbal ','Paz','Levontin 26','052-6267094','2021-10-28','2021-12-03','2022-07-04',300),
			('Nimrod ','Ben-Ami','Tchernichovsky 34','054-9965157','2014-02-07','2020-10-17',NULL,300),
			('Noga ','Stern','Sderot Rothschild 134','052-2469666','2023-08-19','2024-04-27',NULL,300)

	

INSERT INTO [Traininig Schedule] ([Training Name] ,[Day] ,[Hour] ,[Max Partitcipants] ,EmployeeID )
	VALUES ('Strength','Sunday','18:00',10,8),
			('Weights','Monday','18:00',10,11),
			('HIT','Tuesday','18:00',5,12),
			('Functional','Wednesday','18:00',6,41),
			('Aerobic','Thursday','18:00',10,14),
			('Endurance','Sunday','19:00',6,8),
			('Crossfit','Monday','19:00',6,11),
			('Kickboxing','Tuesday','19:00',6,12),
			('TRX','Wednesday','19:00',10,41),
			('Spinning','Thursday','19:00',6,14),
			('Spinning','Sunday','20:00',6,15),
			('TRX','Monday','20:00',10,40),
			('Kickboxing','Tuesday','20:00',6,17),
			('Crossfit','Wednesday','20:00',10,19),
			('Endurance','Thursday','20:00',6,20),
			('Aerobic','Sunday','21:00',10,15),
			('Functional','Monday','21:00',6,40),
			('HIT','Tuesday','21:00',5,17),
			('Weights','Wednesday','21:00',10,19),
			('Crossfit','Thursday','21:00',6,20)




INSERT INTO  Memberships ([First Name],[Last Name],Adress,Phone, Email,[Date Of Birth],Sex)
	VALUES  ('Alon','Cohen',' King George 45','055-8849196','alon.cohen@gmail.com','1994-02-01','M'),
			('Daniel','Levi','HaBarzel 10','052-2586813','daniel-levi@gmail.com','2022-05-08','M'),
			('Shira','Mizrahi','Rothschild Boulevard 7','052-6159154','shira-mizrahi@gmail.com','1997-02-17','F'),
			('Dana','Ben-David','Ben Yehuda 22','054-4922647','dana_ben_david@gmail.com','2000-05-15','F'),
			('Inbal','Shapiro','HaYarkon 55','050-2411186','inbal_hayarkon_shapiro@gmail.com','2001-03-30','F'),
			('Amir','Kaplan','Shalom Aleichem 12','052-3415562','amir.kaplan@gmail.com','1998-09-14','M'),
			('Liron','Peretz','Haneviim 32','050-7416820','liron_peretz@gmail.com','1991-01-01','F'),
			('Hila','Ashkenazi','Derech Menachem Begin 54','052-2362369','hila.ashkenazi@@gmail.com','1999-09-07','F'),
			('Rami','Barkai','Sderot Yerushalayim 18','052-6368243','rami-barkai@gmail.com','2004-04-08','M'),
			('Shahar','Segal','Hagalil 4','054-4931692','shahar-segal@gmail.com','2002-11-25','M'),
			('Tal','Stein','Shderot Haatzmaut 10','050-8442770','tal_stein@gfail.cof','2000-08-18','F'),
			('Keren','Weiss','HaNassi 24','054-4777332','keren-weiss@gfail.cof','1998-06-17','F'),
			('Noa','Azulay','Revivim 8','050-3300639','noa.azulay@gfail.cof','1990-01-26','F'),
			('Roei','Roth','Derech Eretz 12','050-7551575','roei-roth@gmail.com','1989-05-31','M'),
			('Gal','Avrahami','Kineret 18','054-4722913','gal_avrahami@gmail.com','1995-03-29','M'),
			('Nadav','Nahum','Yehuda Halevi 36','050-9006450','nadav_nahum@gmail.com','1987-03-23','M'),
			('Osher','Tzukrel','HaShomer 2','054-5896796','osher-tzukrel@gmail.com','2000-06-18','M'),
			('Lior','Erez','HaTikva 13','050-8661043','lior.erez@gmail.cof','2005-03-17','F'),
			('Ben','Shoham','Ben Gurion Boulevard 24','052-4772077','ben_shoam@gmail.com','2004-09-01','M'),
			('Adi','Ben-Ami','Emil zola 16','050-2344448','adi-ben-ami@gmail.cof','1999-10-21','F'),
			('David ','Cohen','Menahem Begin Road','050-9741078','cohen.david@email.com','2006-07-23','M'),
			('Sarah ',' Levi','Sderot HaNassi 25','050-6732336','levi.sarah@gmail.com','2013-10-15','F'),
			('Yaakov ','Katz','HaShlosha 18','050-7624092','katz-yaakov@gmail.com','2015-09-18','M'),
			('Miriam ','Shamir','Tzahal 31','050-5477707','shamir_miriam@gmail.com','2021-11-04','F'),
			('Daniel ','Ben-David','Givat Shmuel 14','050-9519367','ben.david.daniel@gmail.com','2018-03-09','F'),
			('Rachel ','Azulay','Hadasa 38','054-6960152','azulay-rachel@gmail.com','2022-01-26','F'),
			('Moshe ','Friedman','David Ben Gurion 124','054-6333817','friedman.moshe@gmail.com','2008-05-11','M'),
			('Talia ','Rosenberg','Neve Tzedek 5','052-7047881','rosenberg.talia@gmail.com','2009-02-13','F'),
			('Eliav ','Stein','Beer Sheva 27','052-7808722','stein_eliav@gmail.com','2016-04-21','M'),
			('Chaim ','Goldstein','Kibbutz Galuyot 145','054-6000752','goldstein.chaim@gmail.com','2007-06-30','M'),
			('Batya ','Shapira','Bograshov 96','050-3983262','shapira.batya@gmail.com','2014-08-16','F'),
			('Shlomo ','Cohen','Derech HaShalom 127','052-3033396','cohen_shlomo@gmail.com','2019-12-24','M'),
			('Ruth ','Weiss','Shdema 18','054-7851267','weiss.ruth@gmail.com','2017-09-22','F'),
			('Yossi ','Barak','Nachal Oz 3','058-5095509','barak.yossi@gmail.com','2003-04-05','M'),
			('Dalia ','Amir','Shoshanat HaAaretz 11','052-2784347','amir.dalia@gmail.com','2000-11-19','F'),
			('Reuven ','Gross','Herzl 27','050-2300134','gross-reuven@gmail.com','2020-01-11','M'),
			('Yaara ','Halevi','Tzvi Ginzburg 14','054-2409236','halevi-yaara@gmail.com','2009-10-25','F'),
			('Avraham ','Mizrahi','HaDarom 62','050-2112930','mizrahi_avraham@gmail.com','2012-06-02','M'),
			('Noa ','Peretz','Galgalei Haplada 29','050-2641997','peretz.noa@gmail.com','2011-07-27','F'),
			('Itamar ','Schwartz','Sderot HaMeginim 42','054-6997369','schwartz.itamar@gmail.com','2019-05-14','M'),
			('Avigail ','Oren','HaPalmach 64','052-4146564','oren.avigail@gmail.com','2005-12-06','F'),
			('Erez ','Tzukrel','Kikar Hamedina 34','054-9907576','tzukrel_erez@gmail.com','2022-07-03','M'),
			('Tamar ','Even','Derech Menachem Begin 129','052-4297171','even.tamar@gmail.com','2023-09-09','F'),
			('Niv ','Kfir','Nachalat Binyamin 146','053-2362060','kfir_niv@gmail.com','2004-12-17','F'),
			('Matan ','Elbaz','Yigal Alon 94','052-6267066','elbaz.matan@gmail.com','2017-08-01','F'),
			('Yonatan ','Levi','Yona HaNavi 2','054-9961595','levi.yonatan@gmail.com','2006-01-28','M'),
			('Liora ','Orbach','Chaim Weizmann 35','052-2479305','orbach-liora@gmail.com','2008-10-09','F'),
			('Oren ','Ben-Ari','Arlozorov 66','052-3219266','ben.ari.oren@gmail.com','2015-04-20','M'),
			('Shani ','Biton','Ben Gurion Boulevard 89','050-9615501','biton.shani@gmail.com','2013-03-01','F'),
			('Gidi ','Harel','Mount Herzl 22','054-5640217','harel.gidi@gmail.com','2004-07-07','M')



INSERT INTO [Trainee Registration] (MembershipID ,MemTypeID,[Registration Date],[End Date],[Status])
	VALUES (1,4,'2024-10-02','2024-11-01','Inactive'),
			(1,6,'2024-12-02',NULL,'Active'),
			(2,2,'2024-05-04','2024-11-03','Inactive'),
			(2,6,'2024-11-04',NULL,'Active'),
			(3,6,'2024-05-05',NULL,'Active'),
			(4,6,'2024-02-03',NULL,'Active'),
			(5,1,'2024-02-15','2024-03-14','Inactive'),
			(6,2,'2024-03-03','2024-09-02','Inactive'),
			(6,3,'2024-09-03',NULL,'Active'),
			(7,6,'2024-01-17',NULL,'Active'),
			(8,3,'2024-05-20',NULL,'Active'),
			(9,1,'2024-03-06','2024-04-05','Inactive'),
			(9,4,'2024-04-06','2024-05-05','Inactive'),
			(9,5,'2024-05-10','2024-11-09','Inactive'),
			(9,5,'2024-11-10',NULL,'Active'),
			(10,2,'2024-07-06',NULL,'Active'),
			(11,6,'2024-05-13',NULL,'Active'),
			(12,3,'2024-11-09',NULL,'Active'),
			(13,6,'2024-06-01',NULL,'Active'),
			(14,6,'2024-02-13',NULL,'Active'),
			(15,6,'2024-09-20',NULL,'Active'),
			(16,3,'2024-06-06',NULL,'Active'),
			(17,3,'2024-07-18',NULL,'Active'),
			(18,6,'2024-01-03',NULL,'Active'),
			(19,6,'2024-08-10',NULL,'Active'),
			(20,1,'2024-06-15','2024-07-14','Inactive'),
			(20,3,'2024-07-15',NULL,'Active'),
			(21,3,'2024-02-20',NULL,'Active'),
			(22,6,'2024-08-15',NULL,'Active'),
			(23,3,'2024-08-17',NULL,'Active'),
			(24,6,'2024-03-03',NULL,'Active'),
			(25,6,'2024-05-14',NULL,'Active'),
			(26,5,'2024-06-29',NULL,'Active'),
			(27,5,'2024-07-05',NULL,'Active'),
			(28,3,'2024-09-06',NULL,'Active'),
			(29,3,'2024-02-19',NULL,'Active'),
			(30,2,'2024-02-06','2024-08-05','Inactive'),
			(31,6,'2024-04-05',NULL,'Active'),
			(32,6,'2024-02-03',NULL,'Active'),
			(33,1,'2024-06-05','2024-06-04','Inactive'),
			(33,3,'2024-06-05',NULL,'Active'),
			(34,5,'2024-07-10',NULL,'Active'),
			(35,2,'2024-05-03','2024-11-02','Inactive'),
			(36,6,'2024-08-19',NULL,'Active'),
			(37,6,'2024-02-13',NULL,'Active'),
			(38,6,'2024-08-06',NULL,'Active'),
			(39,3,'2024-05-14',NULL,'Active'),
			(40,5,'2024-09-20',NULL,'Active'),
			(41,6,'2024-05-15',NULL,'Active'),
			(42,1,'2024-06-04','2024-07-03','Inactive'),
			(42,4,'2024-07-10','2024-08-09','Inactive'),
			(43,2,'2024-08-15',NULL,'Active'),
			(44,3,'2024-07-17',NULL,'Active'),
			(45,4,'2024-02-03','2024-08-02','Inactive'),
			(45,1,'2024-08-07','2024-07-07','Inactive'),
			(45,3,'2024-07-08',NULL,'Active'),
			(46,4,'2024-03-05','2024-04-04','Inactive'),
			(47,5,'2024-09-09',NULL,'Active'),
			(48,6,'2024-08-14',NULL,'Active'),
			(49,6,'2024-11-13',NULL,'Active'),
			(50,6,'2024-12-10',NULL,'Active')



INSERT INTO [Registration For Classes] (MembershipID,TrainingID)
	VALUES (1,1),
			(1,15),
			(1,18),
			(1,20),
			(2,2),
			(2,4),
			(2,8),
			(2,10),
			(2,14),
			(3,3),
			(3,12),
			(3,16),
			(4,5),
			(4,6),
			(4,7),
			(4,17),
			(7,9),
			(7,13),
			(7,19),
			(9,2),
			(9,4),
			(9,18),
			(9,20),
			(11,3),
			(11,10),
			(11,14),
			(11,16),
			(13,9),
			(13,11),
			(13,12),
			(13,13),
			(14,1),
			(14,15),
			(15,2),
			(15,4),
			(15,8),
			(15,18),
			(15,20),
			(18,6),
			(18,12),
			(18,16),
			(18,17),
			(19,5),
			(19,7),
			(19,9),
			(19,11),
			(19,13),
			(22,2),
			(22,4),
			(22,8),
			(22,20),
			(24,3),
			(24,10),
			(24,14),
			(24,16),
			(24,19),
			(25,5),
			(25,6),
			(25,17),
			(26,7),
			(26,9),
			(26,11),
			(26,12),
			(26,13),
			(27,1),
			(27,2),
			(27,15),
			(27,18),
			(27,20),
			(31,3),
			(31,10),
			(31,14),
			(32,5),
			(32,6),
			(32,16),
			(32,17),
			(32,19),
			(34,7),
			(34,9),
			(34,11),
			(34,13),
			(36,1),
			(36,12),
			(36,15),
			(37,18),
			(37,20),
			(38,2),
			(38,4),
			(38,8),
			(38,10),
			(38,14),
			(40,6),
			(40,17),
			(40,19),
			(41,5),
			(41,7),
			(42,1),
			(42,9),
			(42,11),
			(42,13),
			(42,19),
			(47,2),
			(47,4),
			(47,8),
			(47,10),
			(47,14),
			(48,3),
			(48,16),
			(49,5),
			(49,6),
			(49,12),
			(49,17),
			(50,7),
			(50,9),
			(50,11)


-------------------------------------------------------------------------------------------------------------
		
SELECT * FROM [Membership Types]
SELECT * FROM Departments
SELECT * FROM Employees
SELECT * FROM [Traininig Schedule]
SELECT * FROM Memberships
SELECT * FROM [Trainee Registration]
SELECT * FROM [Registration For Classes]
