USE ev_charging_tae2;

SELECT
    st.Station_ID,

    st.Station_Name,

    st.City,

    COUNT(cs.Session_ID) AS Total_Sessions,

    ROUND(
        SUM(cs.Energy_kWh), 2
    ) AS Total_Energy_kWh,

    ROUND(
        SUM(cs.Amount_INR), 2
    ) AS Total_Revenue_INR,

    ROUND(
        AVG(cs.Amount_INR), 2
    ) AS Avg_Amount_INR

FROM CHARGING_STATION st

INNER JOIN CHARGING_SESSION cs
    ON st.Station_ID = cs.Station_ID

GROUP BY
    st.Station_ID,
    st.Station_Name,
    st.City

ORDER BY Total_Revenue_INR DESC

LIMIT 10;

SELECT
    st.Station_ID,

    st.Station_Name,

    st.City,

    st.Station_Status,

    COUNT(cs.Session_ID) AS Total_Sessions

FROM CHARGING_STATION st

LEFT JOIN CHARGING_SESSION cs
    ON st.Station_ID = cs.Station_ID

GROUP BY
    st.Station_ID,
    st.Station_Name,
    st.City,
    st.Station_Status

ORDER BY Total_Sessions DESC;

SELECT
    st.Station_ID,

    st.Station_Name,

    st.City,

    COUNT(cs.Session_ID) AS Total_Sessions,

    ROUND(
        SUM(cs.Energy_kWh), 2
    ) AS Total_Energy_kWh,

    ROUND(
        SUM(cs.Amount_INR), 2
    ) AS Total_Revenue_INR

FROM CHARGING_STATION st

INNER JOIN CHARGING_SESSION cs
    ON st.Station_ID = cs.Station_ID

GROUP BY
    st.Station_ID,
    st.Station_Name,
    st.City

HAVING COUNT(cs.Session_ID) > 20

ORDER BY Total_Sessions DESC;

SELECT
    cs.Session_ID,

    cs.Station_ID,

    cs.Vehicle_No,

    cs.Energy_kWh,

    cs.Amount_INR

FROM CHARGING_SESSION cs

WHERE cs.Energy_kWh >
(

    SELECT AVG(cs2.Energy_kWh)

    FROM CHARGING_SESSION cs2

    WHERE cs2.Station_ID = cs.Station_ID
)

ORDER BY cs.Energy_kWh DESC

LIMIT 10;

SELECT
    c.Customer_ID,

    c.Customer_Name,

    COUNT(cs.Session_ID) AS Total_Sessions,

    ROUND(
        SUM(cs.Energy_kWh), 2
    ) AS Total_Energy_kWh,

    ROUND(
        SUM(cs.Amount_INR), 2
    ) AS Total_Spending_INR

FROM CUSTOMER c

INNER JOIN VEHICLE v
    ON c.Customer_ID = v.Customer_ID

INNER JOIN CHARGING_SESSION cs
    ON v.Vehicle_No = cs.Vehicle_No

GROUP BY
    c.Customer_ID,
    c.Customer_Name

ORDER BY Total_Spending_INR DESC

LIMIT 10;

SELECT
    o.Operator_Name,

    COUNT(cs.Session_ID) AS Total_Sessions,

    ROUND(
        SUM(cs.Energy_kWh), 2
    ) AS Total_Energy_kWh,

    ROUND(
        SUM(cs.Amount_INR), 2
    ) AS Total_Revenue_INR

FROM OPERATOR o

INNER JOIN CHARGING_STATION st
    ON o.Operator_Name = st.Operator_Name

INNER JOIN CHARGING_SESSION cs
    ON st.Station_ID = cs.Station_ID

GROUP BY
    o.Operator_Name

ORDER BY Total_Revenue_INR DESC;

SELECT
    s1.Operator_Name,

    s1.Station_ID AS Station_1,

    s1.Station_Name AS Station_1_Name,

    s2.Station_ID AS Station_2,

    s2.Station_Name AS Station_2_Name

FROM CHARGING_STATION s1

INNER JOIN CHARGING_STATION s2

    ON s1.Operator_Name = s2.Operator_Name

    AND s1.Station_ID < s2.Station_ID

ORDER BY s1.Operator_Name

LIMIT 10;

DROP PROCEDURE IF EXISTS GetStationSessions;

DELIMITER $$

CREATE PROCEDURE GetStationSessions(
    IN p_Station_ID VARCHAR(20)
)
BEGIN

    SELECT
        cs.Session_ID,

        cs.Station_ID,

        st.Station_Name,

        st.City,

        cs.Vehicle_No,

        cs.Staff_ID,

        cs.Connector_Type,

        cs.Start_Date,

        cs.Start_Time,

        cs.End_Time,

        cs.Energy_kWh,

        cs.Amount_INR,

        cs.Issue_Type

    FROM CHARGING_SESSION cs

    INNER JOIN CHARGING_STATION st
        ON cs.Station_ID = st.Station_ID

    WHERE cs.Station_ID = p_Station_ID

    ORDER BY cs.Start_Date, cs.Start_Time;

END $$

DELIMITER ;

CALL GetStationSessions('ST1001');

CREATE TABLE IF NOT EXISTS PAYMENT_AUDIT
(
    Audit_ID INT AUTO_INCREMENT PRIMARY KEY,

    Session_ID VARCHAR(20) NOT NULL,

    Old_Status VARCHAR(20),

    New_Status VARCHAR(20),

    Changed_At TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DROP TRIGGER IF EXISTS trg_payment_status_audit;

DELIMITER $$

CREATE TRIGGER trg_payment_status_audit

AFTER UPDATE ON PAYMENT

FOR EACH ROW

BEGIN

    IF OLD.Payment_Status <> NEW.Payment_Status THEN

        INSERT INTO PAYMENT_AUDIT
        (
            Session_ID,
            Old_Status,
            New_Status
        )

        VALUES
        (
            NEW.Session_ID,

            OLD.Payment_Status,

            NEW.Payment_Status
        );

    END IF;

END $$

DELIMITER ;

UPDATE PAYMENT

SET Payment_Status = 'Pending'

WHERE Session_ID = 'SES5000';

SELECT *
FROM PAYMENT_AUDIT

ORDER BY Audit_ID DESC

LIMIT 5;

CREATE OR REPLACE VIEW Station_Performance AS

SELECT
    st.Station_ID,

    st.Station_Name,

    st.Operator_Name,

    st.State,

    st.City,

    st.Station_Status,

    COUNT(cs.Session_ID) AS Total_Sessions,

    ROUND(
        COALESCE(SUM(cs.Energy_kWh), 0), 2
    ) AS Total_Energy_kWh,

    ROUND(
        COALESCE(SUM(cs.Amount_INR), 0), 2
    ) AS Total_Revenue_INR,

    ROUND(
        COALESCE(AVG(cs.Amount_INR), 0), 2
    ) AS Average_Revenue_Per_Session

FROM CHARGING_STATION st

LEFT JOIN CHARGING_SESSION cs
    ON st.Station_ID = cs.Station_ID

GROUP BY
    st.Station_ID,
    st.Station_Name,
    st.Operator_Name,
    st.State,
    st.City,
    st.Station_Status;

SELECT *
FROM Station_Performance

ORDER BY Total_Revenue_INR DESC

LIMIT 10;

CREATE OR REPLACE VIEW Customer_Charging_Summary AS

SELECT
    c.Customer_ID,

    c.Customer_Name,

    c.Phone,

    c.Email,

    COUNT(cs.Session_ID) AS Total_Sessions,

    ROUND(
        COALESCE(SUM(cs.Energy_kWh), 0), 2
    ) AS Total_Energy_kWh,

    ROUND(
        COALESCE(SUM(cs.Amount_INR), 0), 2
    ) AS Total_Amount_INR,

    ROUND(
        COALESCE(AVG(cs.Amount_INR), 0), 2
    ) AS Average_Amount_INR

FROM CUSTOMER c

LEFT JOIN VEHICLE v
    ON c.Customer_ID = v.Customer_ID

LEFT JOIN CHARGING_SESSION cs
    ON v.Vehicle_No = cs.Vehicle_No

GROUP BY
    c.Customer_ID,
    c.Customer_Name,
    c.Phone,
    c.Email;

SELECT *
FROM Customer_Charging_Summary

ORDER BY Total_Amount_INR DESC

LIMIT 10;

EXPLAIN
SELECT
    cs.Session_ID,
    cs.Station_ID,
    cs.Start_Date,
    cs.Energy_kWh,
    cs.Amount_INR
FROM CHARGING_SESSION cs
WHERE cs.Station_ID = 'ST1001'
  AND cs.Start_Date >= '2026-07-20'
ORDER BY cs.Start_Date;

CREATE INDEX idx_session_station_date
ON CHARGING_SESSION
(
    Station_ID,
    Start_Date
);

EXPLAIN
SELECT
    cs.Session_ID,
    cs.Station_ID,
    cs.Start_Date,
    cs.Energy_kWh,
    cs.Amount_INR
FROM CHARGING_SESSION cs
WHERE cs.Station_ID = 'ST1001'
  AND cs.Start_Date >= '2026-07-20'
ORDER BY cs.Start_Date;

EXPLAIN
SELECT
    cs.Vehicle_No,
    COUNT(*) AS Total_Sessions,
    SUM(cs.Energy_kWh) AS Total_Energy,
    SUM(cs.Amount_INR) AS Total_Amount
FROM CHARGING_SESSION cs
WHERE cs.Vehicle_No = 'DL031434'
GROUP BY cs.Vehicle_No;

CREATE INDEX idx_session_vehicle
ON CHARGING_SESSION
(
    Vehicle_No
);

EXPLAIN
SELECT
    cs.Vehicle_No,
    COUNT(*) AS Total_Sessions,
    SUM(cs.Energy_kWh) AS Total_Energy,
    SUM(cs.Amount_INR) AS Total_Amount
FROM CHARGING_SESSION cs
WHERE cs.Vehicle_No = 'DL031434'
GROUP BY cs.Vehicle_No;

SHOW INDEX FROM CHARGING_SESSION;

SHOW PROCEDURE STATUS
WHERE Db = 'ev_charging_tae2';

SHOW TRIGGERS;

SHOW FULL TABLES
WHERE Table_type = 'VIEW';
