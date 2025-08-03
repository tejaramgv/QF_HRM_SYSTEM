-- Master Data Table
CREATE TABLE master_data (
    masterdata_id     NUMBER PRIMARY KEY,
    parent_id         NUMBER,
    masterdata_type   VARCHAR2(50) NOT NULL,
    masterdata_value  VARCHAR2(100) NOT NULL
);

ALTER TABLE master_data
ADD CONSTRAINT uq_master_data_type_value_parent
UNIQUE (masterdata_type, masterdata_value, parent_id);

-- Candidates Table
CREATE TABLE candidates (
    candidate_id        NUMBER PRIMARY KEY,
    first_name          VARCHAR2(50) NOT NULL,
    last_name           VARCHAR2(50) NOT NULL,
    email               VARCHAR2(100) UNIQUE NOT NULL,
    phone               NUMBER(10) NOT NULL,
    dob                 DATE NOT NULL,
    id_proof_type       VARCHAR2(30) CHECK (id_proof_type IN ('Passport', 'Aadhar', 'DL')),
    id_proof_num        VARCHAR2(100),
    highest_degree      VARCHAR2(30) NOT NULL,
    university          VARCHAR2(50) NOT NULL,
    cgpa                NUMBER NOT NULL,
    city          VARCHAR2(30),
    country        VARCHAR2(30),
    last_employer       VARCHAR2(50),
    last_salary         NUMBER,
    expected_salary     NUMBER,
    years_of_experience NUMBER DEFAULT 0,
    skills              VARCHAR2(80) NOT NULL,
    interview_status    VARCHAR2(30) CHECK (interview_status IN ('Rejected', 'In Progress', 'Selected')),
    rejection_reason    VARCHAR2(200),
    status              VARCHAR2(15) DEFAULT 'Active' CHECK (status IN ('Active', 'Inactive'))
);

-- Employees Table
CREATE TABLE employee (
    employee_id      NUMBER PRIMARY KEY,
    candidate_id     NUMBER REFERENCES candidates(candidate_id) NOT NULL,
    first_name       VARCHAR2(30) NOT NULL,
    last_name        VARCHAR2(30) NOT NULL,
    salary           NUMBER NOT NULL,
    department_id    NUMBER REFERENCES department(department_id),
    date_of_joining  DATE,
    band_id          NUMBER,
    manager_id       NUMBER,
    employee_status  VARCHAR2(15) DEFAULT 'Active' CHECK (employee_status IN ('Active', 'Inactive')),
    exit_date        DATE,
    exit_reason_id   NUMBER REFERENCES master_data(masterdata_id),
    leaves_balance   NUMBER DEFAULT 24
);

SELECT constraint_name
FROM user_constraints
WHERE table_name = 'EMPLOYEE'
  AND constraint_type = 'R'
;

ALTER TABLE employee
ADD CONSTRAINT fk_emp_department
FOREIGN KEY (department_id)
REFERENCES department(department_id);

SELECT constraint_name, table_name
FROM user_constraints
WHERE constraint_name = 'SYS_C008541';

ALTER TABLE employee
DROP CONSTRAINT SYS_C008541;

ALTER TABLE employee
ADD role VARCHAR2(100) NOT NULL;


-- Employee Leaves Table (Composite PK)
CREATE TABLE employee_leaves (
    employee_id   NUMBER REFERENCES employee(employee_id),
    leaves_type   VARCHAR2(15) CHECK (LOWER(leaves_type) IN ('sick', 'casual', 'annual', 'maternity', 'paternity', 'unpaid')),
    start_date    DATE,
    end_date      DATE,
    status        VARCHAR2(20) CHECK (LOWER(status) IN ('pending', 'approved', 'rejected')),
    approved_by   NUMBER REFERENCES employee(employee_id),
    PRIMARY KEY (employee_id, start_date)
);


-- Employee Attendance Table
CREATE TABLE employee_attendance (
    attendance_id     NUMBER PRIMARY KEY,
    employee_id       NUMBER NOT NULL,
    attendance_date   DATE DEFAULT TRUNC(SYSDATE),
    in_time           TIMESTAMP,
    out_time          TIMESTAMP,
    status            VARCHAR2(10) CHECK (LOWER(status) IN ('present', 'absent', 'leave')) NOT NULL,
    
    CONSTRAINT fk_attendance_employee
        FOREIGN KEY (employee_id)
        REFERENCES employee(employee_id),
        
    CONSTRAINT uq_attendance_employee_date
        UNIQUE (employee_id, attendance_date)
);

drop table employee_attendance;
-- Baseline Salary Table (Composite PK)
CREATE TABLE baseline_salary (
    band_id      NUMBER PRIMARY KEY,
    band         VARCHAR2(2),
    job_title    VARCHAR2(100) NOT NULL,
    skill        VARCHAR2(50),
    min_salary   NUMBER NOT NULL,
    max_salary   NUMBER NOT NULL,
    min_exp      NUMBER NOT NULL,
    max_exp      NUMBER NOT NULL,
    UNIQUE (band, job_title, skill)
);
INSERT INTO baseline_salary VALUES (1001, 'Junior', 'Software Engineer', 400000, 600000, 0.0, 2.99);

--drop table baseline_salary;
-- Performance Reviews Table (Composite Unique)
CREATE TABLE performance_reviews (
    review_id   NUMBER PRIMARY KEY,
    emp_id      NUMBER REFERENCES employees(employee_id) NOT NULL,
    quarter     VARCHAR2(2) NOT NULL,
    year        NUMBER NOT NULL,
    rating      NUMBER CHECK (rating BETWEEN 1 AND 5),  
    status      VARCHAR2(10) CHECK (status IN ('Provisional', 'Final')) NOT NULL,
    created_at  DATE DEFAULT SYSDATE,
    UNIQUE (emp_id, quarter, year)
);

-- Salary History Table
CREATE TABLE salary_history (
    hist_id     NUMBER PRIMARY KEY,
    emp_id      NUMBER REFERENCES employees(employee_id) NOT NULL,
    old_salary  NUMBER NOT NULL,
    new_salary  NUMBER NOT NULL,
    changed_on  DATE DEFAULT SYSDATE,
    reason      VARCHAR2(100)
);

-- Promotion Eligibility Table
CREATE TABLE promotion_eligibility (
    emp_id            NUMBER PRIMARY KEY REFERENCES employees(employee_id),
    eligibility_reason VARCHAR2(100) NOT NULL,
    marked_on         DATE DEFAULT SYSDATE
);

-- Employee Exit Table
CREATE TABLE employee_exit (
    exit_id     NUMBER PRIMARY KEY,
    emp_id      NUMBER REFERENCES employees(employee_id) NOT NULL,
    exit_reason VARCHAR2(100) NOT NULL,
    exit_date   DATE NOT NULL
);


--Departments Table
CREATE TABLE department (
    department_id   NUMBER PRIMARY KEY,
    department_name VARCHAR2(100) NOT NULL,
    manager_id      NUMBER,
    city_id         NUMBER REFERENCES master_data(masterdata_id)
);

ALTER TABLE department
ADD CONSTRAINT fk_employee_department
FOREIGN KEY (manager_id)
REFERENCES employee(employee_id);


--SELECT a.table_name, a.constraint_name
--FROM user_constraints a
--JOIN user_constraints b
--  ON a.r_constraint_name = b.constraint_name
--WHERE b.table_name = 'EMPLOYEE';


--drop table department;
--drop table employee;
--drop table employee_leaves;
drop table candidates;
ALTER TABLE candidates ADD gender CHAR(1) CHECK (gender IN ('M','F'));
ALTER TABLE employee ADD gender CHAR(1) CHECK (gender IN ('M','F'));
ALTER TABLE employee MODIFY gender CHAR(1) NOT NULL;

ALTER TABLE candidates MODIFY gender CHAR(1) NOT NULL;
ALTER TABLE candidates MODIFY country NOT NULL;
ALTER TABLE employee MODIFY gender NOT NULL;

SELECT constraint_name
FROM user_constraints
WHERE table_name = 'CANDIDATES'
  AND constraint_type = 'R';
  
ALTER TABLE candidates
DROP CONSTRAINT SYS_C008290;

ALTER TABLE candidates
RENAME COLUMN city_id TO city;

ALTER TABLE candidates
MODIFY city VARCHAR2(30) NOT NULL;

ALTER TABLE candidates
RENAME COLUMN country_id TO country;

ALTER TABLE candidates
MODIFY country VARCHAR2(30) NOT NULL;

ALTER TABLE candidates
ADD role VARCHAR2(100) NOT NULL;

ALTER TABLE candidates ADD CONSTRAINT uniq_id_proof UNIQUE (id_proof_num);

ALTER TABLE candidates ADD CONSTRAINT unique_phone UNIQUE (phone);

ALTER TABLE candidates MODIFY id_proof_num VARCHAR2(20) NOT NULL;

ALTER TABLE candidates MODIFY id_proof_type VARCHAR2(20) NOT NULL;

ALTER TABLE candidates MODIFY Interview_Status VARCHAR2(20) DEFAULT 'In Progress';

--new alters--
ALTER TABLE department
ADD CONSTRAINT uniq_dept_city UNIQUE (department_name, city_id);

ALTER TABLE department
MODIFY city_id NOT NULL;


SELECT constraint_name, column_name
FROM user_cons_columns
WHERE table_name = 'CANDIDATES'
  AND column_name IN ('PHONE', 'EMAIL', 'ID_PROOF_NUM');


ALTER TABLE candidates DROP CONSTRAINT SYS_C008277 ;
ALTER TABLE candidates DROP CONSTRAINT SYS_C008278;
ALTER TABLE candidates DROP CONSTRAINT SYS_C008288;
ALTER TABLE candidates DROP CONSTRAINT UNIQ_ID_PROOF;
ALTER TABLE candidates DROP CONSTRAINT UNIQUE_PHONE;


