-- =====================================================
-- TECHCARE HMS - IPD MODULE (33 TABLES)
-- Master Table: pch.patient_profiling
-- =====================================================

CREATE SCHEMA IF NOT EXISTS pch;

-- 1. Departments Table
CREATE TABLE pch.ipd_departments (
    department_id SERIAL PRIMARY KEY,
    department_code VARCHAR(10) UNIQUE NOT NULL,
    department_name VARCHAR(50) NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT TRUE
);

-- 2. Rooms/Beds Table
CREATE TABLE pch.ipd_rooms (
    room_id SERIAL PRIMARY KEY,
    room_number VARCHAR(20) NOT NULL,
    bed_code VARCHAR(10) NOT NULL,
    department_id INTEGER REFERENCES pch.ipd_departments(department_id),
    room_type VARCHAR(20) NOT NULL CHECK (room_type IN ('Standard', 'Private', 'ICU', 'ER', 'Maternity')),
    is_occupied BOOLEAN DEFAULT FALSE,
    capacity INTEGER DEFAULT 1,
    is_active BOOLEAN DEFAULT TRUE,
    UNIQUE(room_number, bed_code)
);

-- 3. Patient Admissions (IPD)
-- LINKED TO: patient_profiling
CREATE TABLE pch.ipd_patient_admissions (
    admission_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES pch.patient_profiling(patient_id) NOT NULL,
    admission_date DATE NOT NULL,
    admission_time TIME NOT NULL,
    discharge_date DATE,
    discharge_time TIME,
    room_id INTEGER REFERENCES pch.ipd_rooms(room_id),
    department_id INTEGER REFERENCES pch.ipd_departments(department_id),
    attending_doctor_id INTEGER,
    admitting_diagnosis TEXT,
    discharge_diagnosis TEXT,
    chief_complaint TEXT,
    history_present_illness TEXT,
    past_medical_history TEXT,
    status VARCHAR(20) DEFAULT 'Active' CHECK (status IN ('Active', 'Discharged', 'Transferred', 'Deceased')),
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 4. Patient Documents
CREATE TABLE pch.ipd_patient_documents (
    document_id SERIAL PRIMARY KEY,
    admission_id INTEGER REFERENCES pch.ipd_patient_admissions(admission_id) NOT NULL,
    document_type VARCHAR(50) NOT NULL,
    document_date DATE DEFAULT CURRENT_DATE,
    created_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 5. Clinical History and Physical Exam
CREATE TABLE pch.ipd_clinical_history_exam (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    pin VARCHAR(20),
    chief_complaint TEXT,
    admitting_diagnosis TEXT,
    discharge_diagnosis TEXT,
    case_code_1 VARCHAR(20),
    case_code_2 VARCHAR(20),
    date_admitted DATE,
    time_admitted TIME,
    date_discharged DATE,
    time_discharged TIME,
    history_present_illness TEXT,
    past_medical_history TEXT,
    surgical_history TEXT,
    social_history TEXT,
    ob_g VARCHAR(10),
    ob_p VARCHAR(10),
    ob_details VARCHAR(50),
    ob_lmp DATE,
    ob_na BOOLEAN DEFAULT FALSE,
    referred_from_hci BOOLEAN,
    referred_reason TEXT,
    originating_hci VARCHAR(100),
    general_survey TEXT,
    general_survey_awake BOOLEAN,
    general_survey_altered BOOLEAN,
    bp VARCHAR(20),
    hr VARCHAR(20),
    rr VARCHAR(20),
    temperature VARCHAR(20),
    heent_normal BOOLEAN,
    heent_pupil_abnormal BOOLEAN,
    heent_lymphadenopathy BOOLEAN,
    heent_dry_mucous BOOLEAN,
    heent_icteric BOOLEAN,
    heent_pale_conjunctivae BOOLEAN,
    heent_sunken_eyes BOOLEAN,
    heent_sunken_fontanelle BOOLEAN,
    heent_others TEXT,
    skin_normal BOOLEAN,
    skin_pallor BOOLEAN,
    skin_jaundice BOOLEAN,
    skin_petechiae BOOLEAN,
    skin_cyanosis BOOLEAN,
    skin_edema BOOLEAN,
    skin_others TEXT,
    chest_normal BOOLEAN,
    chest_retractions BOOLEAN,
    chest_wheezes BOOLEAN,
    chest_crackles BOOLEAN,
    chest_others TEXT,
    heart_normal BOOLEAN,
    heart_murmurs BOOLEAN,
    heart_irregular BOOLEAN,
    heart_others TEXT,
    abdomen_normal BOOLEAN,
    abdomen_distended BOOLEAN,
    abdomen_tenderness BOOLEAN,
    abdomen_mass BOOLEAN,
    abdomen_others TEXT,
    extremities_normal BOOLEAN,
    extremities_edema BOOLEAN,
    extremities_deformity BOOLEAN,
    extremities_weak_pulse BOOLEAN,
    extremities_cyanosis BOOLEAN,
    extremities_others TEXT,
    neuro_normal BOOLEAN,
    neuro_meningeal BOOLEAN,
    neuro_focal_deficit BOOLEAN,
    neuro_others TEXT,
    plan_of_care TEXT,
    attending_physician_id INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 6. Physical Exam Continued
CREATE TABLE pch.ipd_physical_exam_continued (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    continuing_exam TEXT,
    new_findings TEXT,
    updated_diagnosis TEXT,
    treatment_response TEXT,
    recommendations TEXT,
    physician_id INTEGER,
    exam_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 7. TPR Sheet
CREATE TABLE pch.ipd_tpr_sheet (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    sheet_date DATE NOT NULL,
    shift VARCHAR(10) CHECK (shift IN ('Morning', 'Afternoon', 'Night')),
    created_by INTEGER
);

-- 8. TPR Readings
CREATE TABLE pch.ipd_tpr_readings (
    reading_id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES pch.ipd_tpr_sheet(document_id),
    reading_time TIME NOT NULL,
    temperature DECIMAL(4,1),
    pulse INTEGER,
    respiration INTEGER,
    blood_pressure VARCHAR(10),
    spo2 DECIMAL(5,2),
    remarks TEXT,
    taken_by INTEGER
);

-- 9. Vital Signs Monitoring
CREATE TABLE pch.ipd_vital_signs (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    monitoring_date DATE NOT NULL,
    monitoring_time TIME NOT NULL,
    temperature DECIMAL(4,1),
    blood_pressure VARCHAR(10),
    heart_rate INTEGER,
    respiratory_rate INTEGER,
    spo2 DECIMAL(5,2),
    pain_score INTEGER CHECK (pain_score >= 0 AND pain_score <= 10),
    weight DECIMAL(5,2),
    height DECIMAL(5,2),
    bmi DECIMAL(4,2),
    gcs_eye INTEGER,
    gcs_verbal INTEGER,
    gcs_motor INTEGER,
    gcs_total INTEGER,
    consciousness_level VARCHAR(20),
    notes TEXT,
    taken_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 10. Intake & Output Monitoring
CREATE TABLE pch.ipd_io_monitoring (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    monitoring_date DATE NOT NULL,
    shift VARCHAR(10),
    total_intake DECIMAL(8,2),
    total_output DECIMAL(8,2),
    balance DECIMAL(8,2),
    notes TEXT,
    created_by INTEGER
);

-- 11. Intake Details
CREATE TABLE pch.ipd_io_monitoring_intake (
    intake_id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES pch.ipd_io_monitoring(document_id),
    time_recorded TIME,
    oral DECIMAL(6,2) DEFAULT 0,
    ivf DECIMAL(6,2) DEFAULT 0,
    tube_feeding DECIMAL(6,2) DEFAULT 0,
    other_fluids DECIMAL(6,2) DEFAULT 0,
    subtotal DECIMAL(6,2) DEFAULT 0,
    notes TEXT
);

-- 12. Output Details
CREATE TABLE pch.ipd_io_monitoring_output (
    output_id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES pch.ipd_io_monitoring(document_id),
    time_recorded TIME,
    urine DECIMAL(6,2) DEFAULT 0,
    stool VARCHAR(50),
    emesis DECIMAL(6,2) DEFAULT 0,
    drainage DECIMAL(6,2) DEFAULT 0,
    blood_loss DECIMAL(6,2) DEFAULT 0,
    other_output DECIMAL(6,2) DEFAULT 0,
    subtotal DECIMAL(6,2) DEFAULT 0,
    notes TEXT
);

-- 13. IVF Sheet
CREATE TABLE pch.ipd_ivf_sheet (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    date_started DATE,
    bottle_no VARCHAR(20),
    ivf_solution VARCHAR(100),
    volume_ml INTEGER,
    flow_rate VARCHAR(20),
    time_started TIME,
    time_finished TIME,
    bottle_sequence INTEGER,
    intake_ml DECIMAL(6,2),
    total_infused DECIMAL(6,2),
    reaction VARCHAR(50),
    notes TEXT,
    started_by INTEGER,
    monitored_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 14. Medication Regular
CREATE TABLE pch.ipd_medication_regular (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    sheet_date DATE,
    medication_name VARCHAR(100),
    dosage VARCHAR(50),
    route VARCHAR(20),
    frequency VARCHAR(50),
    time_0600 BOOLEAN,
    time_1200 BOOLEAN,
    time_1800 BOOLEAN,
    time_2400 BOOLEAN,
    given_by_0600 INTEGER,
    given_by_1200 INTEGER,
    given_by_1800 INTEGER,
    given_by_2400 INTEGER,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 15. Medication Stat/PRN
CREATE TABLE pch.ipd_medication_stat_prn (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    order_type VARCHAR(10) NOT NULL CHECK (order_type IN ('STAT', 'PRN')),
    date_ordered DATE,
    time_ordered TIME,
    medication_name VARCHAR(100),
    dosage VARCHAR(50),
    route VARCHAR(20),
    indication TEXT,
    date_given DATE,
    time_given TIME,
    given_by INTEGER,
    patient_response TEXT,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 16. Doctor's Orders
CREATE TABLE pch.ipd_doctor_orders (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    order_date DATE NOT NULL,
    order_time TIME NOT NULL,
    medicine_id INTEGER REFERENCES pch.pharmacy_medicines(medicine_id),
    csd_item_id BIGINT REFERENCES pch.medistock_items(item_id),
    requested_quantity NUMERIC(12,2),
    order_text TEXT NOT NULL,
    order_category VARCHAR(30) CHECK (order_category IN ('Medication', 'Laboratory', 'Imaging', 'Diet', 'Activity', 'Nursing Care', 'Consultation', 'Procedure', 'Other')),
    priority VARCHAR(10) DEFAULT 'Routine' CHECK (priority IN ('STAT', 'Urgent', 'Routine')),
    status VARCHAR(20) DEFAULT 'Pending' CHECK (status IN ('Pending', 'In Progress', 'Completed', 'Discontinued')),
    ordered_by INTEGER,
    acknowledged_by INTEGER,
    carried_out_by INTEGER,
    carried_out_date DATE,
    carried_out_time TIME,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_ipd_doctor_orders_item_source CHECK (
        (medicine_id IS NOT NULL AND csd_item_id IS NULL)
        OR (medicine_id IS NULL AND csd_item_id IS NOT NULL)
        OR (medicine_id IS NULL AND csd_item_id IS NULL)
    )
);

-- 17. Nurses Notes
CREATE TABLE pch.ipd_nurses_notes (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    note_date DATE NOT NULL,
    note_time TIME NOT NULL,
    focus TEXT,
    data TEXT,
    action TEXT,
    response TEXT,
    notes TEXT,
    treatments_given TEXT,
    medications_administered TEXT,
    vital_signs TEXT,
    i_o_balance TEXT,
    written_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 18. Clinical Abstract
CREATE TABLE pch.ipd_clinical_abstract (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    admission_summary TEXT,
    significant_findings TEXT,
    course_in_hospital TEXT,
    final_diagnosis TEXT,
    discharge_condition VARCHAR(50),
    discharge_recommendations TEXT,
    follow_up_schedule TEXT,
    medications_on_discharge TEXT,
    procedures_done TEXT,
    complications TEXT,
    attending_physician_id INTEGER,
    abstract_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 19. Discharge Notice & Clearance
CREATE TABLE pch.ipd_discharge_notice_clearance (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    discharge_date DATE,
    discharge_time TIME,
    discharge_type VARCHAR(30) CHECK (discharge_type IN ('Home', 'Transfer', 'AMA', 'Absconded', 'Expired')),
    discharge_diagnosis TEXT,
    final_diagnosis TEXT,
    nursing_cleared BOOLEAN,
    nursing_cleared_date TIMESTAMP,
    nursing_remarks TEXT,
    pharmacy_cleared BOOLEAN,
    pharmacy_cleared_date TIMESTAMP,
    pharmacy_remarks TEXT,
    billing_cleared BOOLEAN,
    billing_cleared_date TIMESTAMP,
    billing_remarks TEXT,
    laboratory_cleared BOOLEAN,
    laboratory_cleared_date TIMESTAMP,
    laboratory_remarks TEXT,
    radiology_cleared BOOLEAN,
    radiology_cleared_date TIMESTAMP,
    radiology_remarks TEXT,
    medical_records_cleared BOOLEAN,
    medical_records_cleared_date TIMESTAMP,
    medical_records_remarks TEXT,
    final_cleared BOOLEAN,
    final_cleared_date TIMESTAMP,
    discharged_by INTEGER,
    cleared_by INTEGER,
    physician_signature TEXT,
    nurse_signature TEXT,
    patient_signature TEXT,
    follow_up_instructions TEXT,
    medications TEXT,
    restrictions TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 20. Discharge Plan
CREATE TABLE pch.ipd_discharge_plan (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    planned_discharge_date DATE,
    discharge_disposition VARCHAR(50),
    discharge_to VARCHAR(50),
    rehabilitation_needs BOOLEAN,
    home_care_needs BOOLEAN,
    equipment_needed TEXT,
    medication_instructions TEXT,
    diet_instructions TEXT,
    activity_instructions TEXT,
    wound_care_instructions TEXT,
    follow_up_appointments TEXT,
    warning_signs TEXT,
    emergency_contact TEXT,
    prepared_by INTEGER,
    approved_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 21. Services / Dispensing (Nurse Request)
CREATE TABLE pch.ipd_services_dispensing (
    dispensing_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES pch.patient_profiling(patient_id) NOT NULL,
    admission_id INTEGER REFERENCES pch.ipd_patient_admissions(admission_id),
    document_id INTEGER REFERENCES pch.ipd_patient_documents(document_id),
    request_date DATE DEFAULT CURRENT_DATE,
    request_time TIME DEFAULT CURRENT_TIME,
    charge_slip_no VARCHAR(20),
    total_amount DECIMAL(10,2),
    prepared_by INTEGER,
    noted_by INTEGER,
    requested_by INTEGER,
    requested_by_name VARCHAR(100),
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'APPROVED', 'DISPENSED', 'REJECTED')),
    dispensed_by INTEGER, -- Added missing column
    dispensed_by_name VARCHAR(100), -- Added missing column
    dispensed_date TIMESTAMP, -- Added missing column
    trail TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP -- Added missing column
);

-- 22. Services / Dispensing Items
CREATE TABLE pch.ipd_services_dispensing_items (
    dispensing_item_id SERIAL PRIMARY KEY, -- UPDATED Primary Key
    dispensing_id INTEGER REFERENCES pch.ipd_services_dispensing(dispensing_id) ON DELETE CASCADE,
    medicine_id INTEGER REFERENCES pch.pharmacy_medicines(medicine_id),
    csd_item_id BIGINT REFERENCES pch.medistock_items(item_id),
    item_type VARCHAR(20) CHECK (item_type IN ('Medication', 'Supply', 'Equipment', 'Service')),
    date_requested DATE, -- Ensure this matches the model
    dosage VARCHAR(100),
    quantity INTEGER NOT NULL,
    unit VARCHAR(20),
    unit_cost DECIMAL(10,2),
    total_cost DECIMAL(10,2),
    pharmacist_name VARCHAR(100),
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP, -- Added missing column
    CONSTRAINT chk_ipd_services_dispensing_items_source CHECK (
        (medicine_id IS NOT NULL AND csd_item_id IS NULL)
        OR (medicine_id IS NULL AND csd_item_id IS NOT NULL)
        OR (medicine_id IS NULL AND csd_item_id IS NULL)
    )
);

-- 23. Clearance Slip
CREATE TABLE pch.ipd_clearance_slip (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    clearance_date DATE,
    clearance_time TIME,
    nursing_cleared BOOLEAN,
    nursing_cleared_by INTEGER,
    nursing_clearance_date TIMESTAMP,
    pharmacy_cleared BOOLEAN,
    pharmacy_cleared_by INTEGER,
    pharmacy_clearance_date TIMESTAMP,
    billing_cleared BOOLEAN,
    billing_cleared_by INTEGER,
    billing_clearance_date TIMESTAMP,
    laboratory_cleared BOOLEAN,
    laboratory_cleared_by INTEGER,
    laboratory_clearance_date TIMESTAMP,
    radiology_cleared BOOLEAN,
    radiology_cleared_by INTEGER,
    radiology_clearance_date TIMESTAMP,
    medical_records_cleared BOOLEAN,
    medical_records_cleared_by INTEGER,
    medical_records_clearance_date TIMESTAMP,
    final_cleared BOOLEAN,
    final_cleared_by INTEGER,
    final_clearance_date TIMESTAMP,
    remarks TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 24. Diet List
CREATE TABLE pch.ipd_diet_lists (
    list_id SERIAL PRIMARY KEY,
    admission_id INTEGER REFERENCES pch.ipd_patient_admissions(admission_id),
    list_date DATE NOT NULL,
    meal_type VARCHAR(20) CHECK (meal_type IN ('Breakfast', 'Lunch', 'Supper', 'Snacks')),
    prepared_by INTEGER,
    kitchen_notified BOOLEAN DEFAULT FALSE,
    kitchen_notified_at TIMESTAMP,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 25. Diet List Items
CREATE TABLE pch.ipd_diet_list_items (
    item_id SERIAL PRIMARY KEY,
    list_id INTEGER REFERENCES pch.ipd_diet_lists(list_id),
    patient_id INTEGER REFERENCES pch.patient_profiling(patient_id),
    ward_room VARCHAR(20),
    age INTEGER,
    sex CHAR(1),
    diet_type VARCHAR(50),
    texture VARCHAR(30),
    restrictions TEXT,
    instructions TEXT,
    served BOOLEAN DEFAULT FALSE,
    served_at TIMESTAMP
);

-- 26. Maternity Care Package
CREATE TABLE pch.ipd_maternity_care_package (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    prenatal_visits INTEGER,
    tt_immunization BOOLEAN,
    iron_supplementation BOOLEAN,
    delivery_date DATE,
    delivery_time TIME,
    mode_of_delivery VARCHAR(30),
    attendant VARCHAR(50),
    delivery_outcome VARCHAR(20),
    postnatal_visits INTEGER,
    mother_condition VARCHAR(50),
    breastfeeding_established BOOLEAN,
    family_planning_counseling BOOLEAN,
    newborn_weight DECIMAL(5,2),
    newborn_apgar INTEGER,
    newborn_breastfeeding BOOLEAN,
    newborn_bcg_given BOOLEAN,
    newborn_hepb_given BOOLEAN,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 27. Obstetrical History
CREATE TABLE pch.ipd_maternity_obstetrical_history (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    menarche_age INTEGER,
    lmp DATE,
    menstrual_cycle VARCHAR(30),
    menstrual_duration INTEGER,
    gravida INTEGER,
    para INTEGER,
    abortus INTEGER,
    living_children INTEGER,
    pregnancy_history JSONB,
    edc DATE,
    aog_weeks INTEGER,
    aog_days INTEGER,
    fundal_height INTEGER,
    fetal_heart_rate INTEGER,
    fetal_presentation VARCHAR(30),
    hgb_result VARCHAR(20),
    hiv_test VARCHAR(20),
    hbsag_test VARCHAR(20),
    syphilis_test VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 28. Partograph
CREATE TABLE pch.ipd_maternity_partograph (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    labor_onset_date DATE,
    labor_onset_time TIME,
    membrane_status VARCHAR(20),
    membrane_ruptured_at TIMESTAMP,
    fetal_heart_rate INTEGER,
    fetal_movement VARCHAR(20),
    cervical_dilation INTEGER,
    descent_of_head INTEGER,
    uterine_contractions INTEGER,
    contraction_duration INTEGER,
    contraction_frequency INTEGER,
    maternal_pulse INTEGER,
    maternal_bp VARCHAR(10),
    maternal_temp DECIMAL(4,1),
    urine_protein VARCHAR(10),
    urine_acetone VARCHAR(10),
    urine_volume INTEGER,
    oxytocin_drip BOOLEAN,
    drugs_given TEXT,
    delivery_time TIMESTAMP,
    placenta_delivery_time TIMESTAMP,
    blood_loss_ml INTEGER,
    baby_sex CHAR(1),
    baby_weight_g INTEGER,
    baby_apgar_1min INTEGER,
    baby_apgar_5min INTEGER,
    plotted_by INTEGER,
    reviewed_by INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 29. LPDO
CREATE TABLE pch.ipd_maternity_lpdo (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    age_risk BOOLEAN,
    parity_risk BOOLEAN,
    height_risk BOOLEAN,
    history_risk BOOLEAN,
    pregnancy_induced_htn BOOLEAN,
    anemia BOOLEAN,
    abnormal_presentation BOOLEAN,
    multiple_pregnancy BOOLEAN,
    risk_classification VARCHAR(20),
    referred_to_higher_facility BOOLEAN,
    referral_reason TEXT,
    pregnancy_outcome VARCHAR(20),
    delivery_date DATE,
    delivery_place VARCHAR(50),
    delivery_attendant VARCHAR(50),
    newborn_status VARCHAR(20),
    mother_status VARCHAR(20),
    complications TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 30. CF3 (Maternity Care Form)
CREATE TABLE pch.ipd_maternity_cf3 (
    document_id INTEGER PRIMARY KEY REFERENCES pch.ipd_patient_documents(document_id),
    philhealth_id VARCHAR(20),
    nhts_number VARCHAR(20),
    gravida INTEGER,
    para INTEGER,
    expected_delivery DATE,
    medical_conditions JSONB,
    allergies TEXT,
    initial_visit_date DATE,
    aog_at_initial_visit INTEGER,
    actual_delivery_date DATE,
    delivery_mode VARCHAR(30),
    delivery_outcome VARCHAR(20),
    maternal_outcome VARCHAR(20),
    newborn_outcome VARCHAR(20),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 31. CF3 Prenatal Visits
CREATE TABLE pch.ipd_maternity_cf3_prenatal (
    visit_id SERIAL PRIMARY KEY,
    document_id INTEGER REFERENCES pch.ipd_maternity_cf3(document_id),
    visit_date DATE,
    trimester INTEGER,
    aog INTEGER,
    weight DECIMAL(5,2),
    bp VARCHAR(10),
    fundal_height INTEGER,
    fetal_heart_rate INTEGER,
    fetal_presentation VARCHAR(30),
    hgb VARCHAR(20),
    urine_protein VARCHAR(10),
    urine_sugar VARCHAR(10),
    iron_given BOOLEAN,
    iron_quantity INTEGER,
    counseling_given TEXT,
    danger_signs TEXT,
    referred BOOLEAN,
    next_visit_date DATE,
    attended_by INTEGER
);

-- 32. Cart Forms (Pharmacy CLOSED / Night Request)
-- Purpose: Records medicines taken from the Floor Stock/Cart when Pharmacy is closed.
-- NOTE: Defined BEFORE pharmacy receipts because receipts reference cart forms
CREATE TABLE pch.ipd_cart_forms (
    cart_form_id SERIAL PRIMARY KEY,
    patient_id INTEGER REFERENCES pch.patient_profiling(patient_id) NOT NULL,
    admission_id INTEGER REFERENCES pch.ipd_patient_admissions(admission_id),
    request_date DATE DEFAULT CURRENT_DATE,
    requested_by INTEGER,
    requested_by_name VARCHAR(100),
    from_location_id INTEGER DEFAULT 2, -- DEFAULT: Cart/Floor Stock Location
    status VARCHAR(20) DEFAULT 'PENDING' CHECK (status IN ('PENDING', 'VERIFIED', 'REPLENISHED')),
    trail TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 33. Cart Form Items
CREATE TABLE pch.ipd_cart_form_items (
    cart_item_id SERIAL PRIMARY KEY, -- Renamed for consistency
    cart_form_id INTEGER REFERENCES pch.ipd_cart_forms(cart_form_id) ON DELETE CASCADE,
    medicine_id INTEGER REFERENCES pch.pharmacy_medicines(medicine_id), -- LINKED for inventory deduction
    date_taken DATE NOT NULL,
    drug_name VARCHAR(255) NOT NULL,
    quantity INTEGER NOT NULL,
    administered_by VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 34. Pharmacy Dispense Receipts (PHARMACY BILLING)
-- Purpose: The FINAL record of medicines used for BILLING and inventory.
-- LINKS BACK to either a Nurse Request (Table 21) OR a Cart Form (Table 32)
CREATE TABLE pch.pharmacy_dispense_receipts (
    receipt_id SERIAL PRIMARY KEY,
    receipt_no VARCHAR(30) UNIQUE NOT NULL,
    ipd_dispensing_id INTEGER REFERENCES pch.ipd_services_dispensing(dispensing_id), -- LINK TO REQUEST
    ipd_cart_form_id INTEGER REFERENCES pch.ipd_cart_forms(cart_form_id), -- NEW LINK TO CART FORM
    admission_id INTEGER REFERENCES pch.ipd_patient_admissions(admission_id) NOT NULL,
    patient_id INTEGER REFERENCES pch.patient_profiling(patient_id) NOT NULL,
    from_location_id INTEGER DEFAULT 1, -- DEFAULT: Main Pharmacy Location
    dispensing_date DATE DEFAULT CURRENT_DATE,
    charge_slip_no VARCHAR(20),
    total_amount DECIMAL(12,2) DEFAULT 0,
    received_status VARCHAR(20) DEFAULT 'RECEIVED' CHECK (received_status IN ('PENDING', 'RECEIVED', 'CANCELLED')),
    dispensed_by INTEGER,
    remarks TEXT,
    trail TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_receipt_source CHECK (
        (ipd_dispensing_id IS NOT NULL AND ipd_cart_form_id IS NULL)
        OR (ipd_dispensing_id IS NULL AND ipd_cart_form_id IS NOT NULL)
        OR (ipd_dispensing_id IS NULL AND ipd_cart_form_id IS NULL) -- For direct pharmacy sales if needed
    )
);

-- 35. Pharmacy Dispense Receipt Items
CREATE TABLE pch.pharmacy_dispense_receipt_items (
    receipt_item_id SERIAL PRIMARY KEY,
    receipt_id INTEGER REFERENCES pch.pharmacy_dispense_receipts(receipt_id) ON DELETE CASCADE,
    medicine_id INTEGER REFERENCES pch.pharmacy_medicines(medicine_id),
    item_code VARCHAR(30),
    item_description VARCHAR(255),
    quantity DECIMAL(12,2) NOT NULL,
    unit VARCHAR(20),
    unit_cost DECIMAL(12,2) NOT NULL,
    total_cost DECIMAL(12,2) NOT NULL,
    batch_id INTEGER,
    from_location_id INTEGER,
    line_status VARCHAR(15) DEFAULT 'DISPENSED',
    remarks TEXT
);

-- =====================================================
-- INDEXES
-- =====================================================
CREATE INDEX idx_admissions_patient ON pch.ipd_patient_admissions(patient_id);
CREATE INDEX idx_admissions_status ON pch.ipd_patient_admissions(status);
CREATE INDEX idx_documents_admission ON pch.ipd_patient_documents(admission_id);
CREATE INDEX idx_dispensing_sheet_status ON pch.ipd_services_dispensing(status);
CREATE INDEX idx_pharmacy_receipt_request ON pch.pharmacy_dispense_receipts(ipd_dispensing_id);
CREATE INDEX idx_cart_form_status ON pch.ipd_cart_forms(status);


ALTER TABLE pch.pharmacy_dispense_receipts 
ALTER COLUMN admission_id DROP NOT NULL;
