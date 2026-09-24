-- ================================================================
-- EV CHARGING NETWORK MANAGEMENT SYSTEM
-- TAE-2 : DATABASE SCHEMA
-- RDBMS: MySQL
-- ================================================================

-- ------------------------------------------------
-- 1. CREATE DATABASE
-- ------------------------------------------------

DROP DATABASE IF EXISTS ev_charging_tae2;

CREATE DATABASE ev_charging_tae2;

USE ev_charging_tae2;


-- ================================================================
-- 2. OPERATOR TABLE
-- ================================================================
-- Stores information about EV charging network operators.
--
-- Primary Key:
--     Operator_Name
--
-- Operator_Name is used as the primary key because
-- the approved TAE-1 relational schema uses Operator_Name
-- as the identifier.
-- ================================================================

CREATE TABLE OPERATOR
(
    Operator_Name VARCHAR(100) NOT NULL,

    PRIMARY KEY (Operator_Name)
);


-- ================================================================
-- 3. CUSTOMER TABLE
-- ================================================================
-- Stores EV customer information.
--
-- Primary Key:
--     Customer_ID
-- ================================================================

CREATE TABLE CUSTOMER
(
    Customer_ID VARCHAR(20) NOT NULL,

    Customer_Name VARCHAR(100) NOT NULL,

    Phone VARCHAR(15) NOT NULL,

    Email VARCHAR(150),

    PRIMARY KEY (Customer_ID)
);


-- ================================================================
-- 4. STAFF TABLE
-- ================================================================
-- Stores staff members responsible for charging sessions.
--
-- Primary Key:
--     Staff_ID
-- ================================================================

CREATE TABLE STAFF
(
    Staff_ID VARCHAR(20) NOT NULL,

    Staff_Name VARCHAR(100) NOT NULL,

    PRIMARY KEY (Staff_ID)
);


-- ================================================================
-- 5. CHARGING_STATION TABLE
-- ================================================================
-- Stores information about EV charging stations.
--
-- Relationship:
--
-- OPERATOR
--     1
--     |
--     | M
--     ↓
-- CHARGING_STATION
--
-- Foreign Key:
--     Operator_Name
-- ================================================================

CREATE TABLE CHARGING_STATION
(
    Station_ID VARCHAR(20) NOT NULL,

    Station_Name VARCHAR(150) NOT NULL,

    Operator_Name VARCHAR(100) NOT NULL,

    State VARCHAR(50) NOT NULL,

    City VARCHAR(50) NOT NULL,

    Address VARCHAR(255) NOT NULL,

    Station_Status VARCHAR(30) NOT NULL
        DEFAULT 'Active',

    PRIMARY KEY (Station_ID),

    -- Connect station with its operator
    FOREIGN KEY (Operator_Name)
        REFERENCES OPERATOR(Operator_Name)

        -- If an operator is deleted,
        -- its associated stations are also deleted.
        ON DELETE CASCADE

        -- If the operator name is updated,
        -- the related station records are updated.
        ON UPDATE CASCADE,

    -- Allow only valid station statuses
    CHECK (
        Station_Status IN
        (
            'Active',
            'Inactive',
            'Under Maintenance'
        )
    )
);


-- ================================================================
-- 6. VEHICLE TABLE
-- ================================================================
-- Stores vehicles owned by customers.
--
-- Relationship:
--
-- CUSTOMER
--     1
--     |
--     | M
--     ↓
-- VEHICLE
--
-- Foreign Key:
--     Customer_ID
-- ================================================================

CREATE TABLE VEHICLE
(
    Vehicle_No VARCHAR(20) NOT NULL,

    Vehicle_Model VARCHAR(100) NOT NULL,

    Customer_ID VARCHAR(20) NOT NULL,

    PRIMARY KEY (Vehicle_No),

    -- Connect vehicle with its owner
    FOREIGN KEY (Customer_ID)
        REFERENCES CUSTOMER(Customer_ID)

        ON DELETE CASCADE
        ON UPDATE CASCADE
);


-- ================================================================
-- 7. CHARGING_SESSION TABLE
-- ================================================================
-- Stores individual EV charging sessions.
--
-- Relationships:
--
-- CHARGING_STATION
--        1
--        |
--        | M
--        ↓
-- CHARGING_SESSION
--
-- VEHICLE
--    1
--    |
--    | M
--    ↓
-- CHARGING_SESSION
--
-- STAFF
--    1
--    |
--    | M
--    ↓
-- CHARGING_SESSION
--
-- Primary Key:
--     Session_ID
--
-- Foreign Keys:
--     Station_ID
--     Vehicle_No
--     Staff_ID
-- ================================================================

CREATE TABLE CHARGING_SESSION
(
    Session_ID VARCHAR(20) NOT NULL,

    Station_ID VARCHAR(20) NOT NULL,

    Vehicle_No VARCHAR(20) NOT NULL,

    Staff_ID VARCHAR(20) NOT NULL,

    Connector_Type VARCHAR(50) NOT NULL,

    Start_Date DATE NOT NULL,

    Start_Time TIME NOT NULL,

    End_Time TIME NOT NULL,

    Energy_kWh DECIMAL(10,2) NOT NULL,

    Amount_INR DECIMAL(10,2) NOT NULL,

    Issue_Type VARCHAR(100)
        DEFAULT 'No Issue',

    PRIMARY KEY (Session_ID),


    -- Connect session with charging station
    FOREIGN KEY (Station_ID)
        REFERENCES CHARGING_STATION(Station_ID)

        ON DELETE CASCADE
        ON UPDATE CASCADE,


    -- Connect session with vehicle
    FOREIGN KEY (Vehicle_No)
        REFERENCES VEHICLE(Vehicle_No)

        ON DELETE CASCADE
        ON UPDATE CASCADE,


    -- Connect session with staff member
    FOREIGN KEY (Staff_ID)
        REFERENCES STAFF(Staff_ID)

        ON DELETE CASCADE
        ON UPDATE CASCADE,


    -- Energy consumed cannot be negative
    CHECK (Energy_kWh >= 0),


    -- Charging amount cannot be negative
    CHECK (Amount_INR >= 0)
);


-- ================================================================
-- 8. PAYMENT TABLE
-- ================================================================
-- Stores payment information associated with a charging session.
--
-- Relationship:
--
-- CHARGING_SESSION
--       1
--       |
--       | 1
--       ↓
-- PAYMENT
--
-- Session_ID acts as:
--     Primary Key
--     Foreign Key
--
-- This represents the approved TAE-1 1:1 relationship
-- between CHARGING_SESSION and PAYMENT.
-- ================================================================

CREATE TABLE PAYMENT
(
    Session_ID VARCHAR(20) NOT NULL,

    Payment_Mode VARCHAR(20) NOT NULL
        DEFAULT 'UPI',

    Payment_Status VARCHAR(20) NOT NULL
        DEFAULT 'Pending',

    PRIMARY KEY (Session_ID),

    -- Connect payment with charging session
    FOREIGN KEY (Session_ID)
        REFERENCES CHARGING_SESSION(Session_ID)

        ON DELETE CASCADE
        ON UPDATE CASCADE,


    -- Allow only valid payment modes
    CHECK (
        Payment_Mode IN
        (
            'UPI',
            'Card',
            'Cash'
        )
    ),


    -- Allow only valid payment statuses
    CHECK (
        Payment_Status IN
        (
            'Completed',
            'Pending',
            'Failed'
        )
    )
);


-- ================================================================
-- 9. VERIFY TABLES
-- ================================================================
-- Display all tables created in the database.
-- ================================================================

SHOW TABLES;


-- ================================================================
-- 10. VERIFY TABLE STRUCTURES
-- ================================================================
-- These commands allow us to verify the columns,
-- data types, keys and constraints.
-- ================================================================

DESCRIBE OPERATOR;

DESCRIBE CUSTOMER;

DESCRIBE STAFF;

DESCRIBE CHARGING_STATION;

DESCRIBE VEHICLE;

DESCRIBE CHARGING_SESSION;

DESCRIBE PAYMENT;
