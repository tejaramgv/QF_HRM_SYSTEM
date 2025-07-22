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
    id_proof_num        NUMBER,
    highest_degree      VARCHAR2(30) NOT NULL,
    university          VARCHAR2(50) NOT NULL,
    cgpa                NUMBER NOT NULL,
    city_id             NUMBER REFERENCES master_data(masterdata_id),
    country_id          NUMBER REFERENCES master_data(masterdata_id),
    last_employer       VARCHAR2(50),
    last_salary         NUMBER,
    expected_salary     NUMBER,
    years_of_experience NUMBER DEFAULT 0,
    skills              VARCHAR2(80) NOT NULL,
    interview_status    VARCHAR2(30) CHECK (interview_status IN ('Rejected', 'In Progress', 'Hired')),
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
    department_id    NUMBER REFERENCES master_data(masterdata_id),
    date_of_joining  DATE,
    band_id          NUMBER REFERENCES master_data(masterdata_id),
    manager_id       NUMBER,
    employee_status  VARCHAR2(15) DEFAULT 'Active' CHECK (employee_status IN ('Active', 'Inactive')),
    exit_date        DATE,
    exit_reason_id   NUMBER REFERENCES master_data(masterdata_id),
    leaves_balance   NUMBER DEFAULT 0
);

-- Employee Leaves Table (Composite PK)
CREATE TABLE employee_leaves (
    employee_id   NUMBER REFERENCES employees(employee_id),
    leaves_type   VARCHAR2(15) CHECK (leaves_type IN ('Sick', 'Casual', 'Annual', 'Maternity', 'Paternity', 'Unpaid')),
    start_date    DATE,
    end_date      DATE,
    status        VARCHAR2(20) CHECK (status IN ('Pending', 'Approved', 'Rejected')),
    approved_by   NUMBER REFERENCES employees(employee_id),
    PRIMARY KEY (employee_id, start_date)
);

-- Employee Attendance Table
CREATE TABLE employee_attendance (
    attendance_id    NUMBER PRIMARY KEY,
    employee_id      NUMBER REFERENCES employees(employee_id),
    attendance_date  DATE DEFAULT SYSDATE NOT NULL,
    check_in_time    TIMESTAMP,
    check_out_time   TIMESTAMP,
    working_hours    NUMBER(4,2),
    UNIQUE (employee_id, attendance_date)
);

-- Baseline Salary Table (Composite PK)
CREATE TABLE baseline_salary (
    band         VARCHAR2(2),
    job_title    VARCHAR2(100) NOT NULL,
    skill        VARCHAR2(50),
    min_salary   NUMBER NOT NULL,
    max_salary   NUMBER NOT NULL,
    min_exp      NUMBER NOT NULL,
    max_exp      NUMBER NOT NULL,
    PRIMARY KEY (band, job_title, skill)
);

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

select * from locations;
select * from countries;
select * from employees;