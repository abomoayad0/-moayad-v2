-- v2.v_students
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.
-- md5 d53b029c0c11559f013814438f83cf7e

CREATE VIEW v2.v_students AS
 SELECT id,
    tenant_id,
    school_id,
    student_no,
    national_id,
    full_name,
    nationality,
    birth_date,
    health_notes,
    status,
    created_at,
    birth_date_hijri,
    joined_hijri,
    reg_status,
    doc_type,
    doc_issuer,
    doc_issued_hijri,
    passport_no,
    full_name_en,
    source_ref,
    v2.fn_display_name(full_name) AS display_name,
    v2.fn_norm_ar(full_name) AS search_name,
    v2.fn_norm_ar(v2.fn_display_name(full_name)) AS search_display
   FROM v2.students s;
