-- foreign_keys.sql
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.

-- ── absence_cases · md5 bee468396ebfe07605a0a2642ead1862
ALTER TABLE v2.absence_cases
    ADD CONSTRAINT absence_cases_ladder_id_fkey FOREIGN KEY (ladder_id) REFERENCES v2.absence_ladder(id);
ALTER TABLE v2.absence_cases
    ADD CONSTRAINT absence_cases_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.absence_cases
    ADD CONSTRAINT absence_cases_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.absence_cases
    ADD CONSTRAINT absence_cases_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── absence_excuse_claims · md5 3037edc24a4c8060ebdb699576478a7b
ALTER TABLE v2.absence_excuse_claims
    ADD CONSTRAINT absence_excuse_claims_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES v2.people(id);
ALTER TABLE v2.absence_excuse_claims
    ADD CONSTRAINT absence_excuse_claims_event_id_fkey FOREIGN KEY (event_id) REFERENCES v2.events(id);
ALTER TABLE v2.absence_excuse_claims
    ADD CONSTRAINT absence_excuse_claims_excuse_item_fkey FOREIGN KEY (excuse_item) REFERENCES v2.absence_excuses(item_no);
ALTER TABLE v2.absence_excuse_claims
    ADD CONSTRAINT absence_excuse_claims_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.absence_excuse_claims
    ADD CONSTRAINT absence_excuse_claims_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);

-- ── absence_ladder_items · md5 52230fb8e9582a47b16102efdab90d51
ALTER TABLE v2.absence_ladder_items
    ADD CONSTRAINT absence_ladder_items_evidence_kind_fkey FOREIGN KEY (evidence_kind) REFERENCES v2.evidence_kinds(key);
ALTER TABLE v2.absence_ladder_items
    ADD CONSTRAINT absence_ladder_items_ladder_id_fkey FOREIGN KEY (ladder_id) REFERENCES v2.absence_ladder(id) ON DELETE CASCADE;

-- ── absence_tasks · md5 054d14ed863617d95fc25d2e11be494a
ALTER TABLE v2.absence_tasks
    ADD CONSTRAINT absence_tasks_case_id_fkey FOREIGN KEY (case_id) REFERENCES v2.absence_cases(id) ON DELETE CASCADE;
ALTER TABLE v2.absence_tasks
    ADD CONSTRAINT absence_tasks_delegated_by_fkey FOREIGN KEY (delegated_by) REFERENCES v2.people(id);
ALTER TABLE v2.absence_tasks
    ADD CONSTRAINT absence_tasks_done_by_fkey FOREIGN KEY (done_by) REFERENCES v2.people(id);
ALTER TABLE v2.absence_tasks
    ADD CONSTRAINT absence_tasks_evidence_kind_fkey FOREIGN KEY (evidence_kind) REFERENCES v2.evidence_kinds(key);
ALTER TABLE v2.absence_tasks
    ADD CONSTRAINT absence_tasks_item_id_fkey FOREIGN KEY (item_id) REFERENCES v2.absence_ladder_items(id);
ALTER TABLE v2.absence_tasks
    ADD CONSTRAINT absence_tasks_owner_person_fkey FOREIGN KEY (owner_person) REFERENCES v2.people(id);

-- ── academic_years · md5 b8d11d5805ed2082dd542d2c0b4e6a39
ALTER TABLE v2.academic_years
    ADD CONSTRAINT academic_years_closed_by_fkey FOREIGN KEY (closed_by) REFERENCES v2.people(id);
ALTER TABLE v2.academic_years
    ADD CONSTRAINT academic_years_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── app_users · md5 9dc6f2b53699eeaa526cc54bd75f7f5f
ALTER TABLE v2.app_users
    ADD CONSTRAINT app_users_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.app_users
    ADD CONSTRAINT app_users_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.app_users
    ADD CONSTRAINT app_users_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES v2.tenants(id);

-- ── assignments · md5 c18acbe36cb4a6c4c844dbd4de30e7f0
ALTER TABLE v2.assignments
    ADD CONSTRAINT assignments_issued_by_fkey FOREIGN KEY (issued_by) REFERENCES v2.people(id);
ALTER TABLE v2.assignments
    ADD CONSTRAINT assignments_issuer_post_fkey FOREIGN KEY (issuer_post) REFERENCES v2.posts(key);
ALTER TABLE v2.assignments
    ADD CONSTRAINT assignments_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.assignments
    ADD CONSTRAINT assignments_post_key_fkey FOREIGN KEY (post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.assignments
    ADD CONSTRAINT assignments_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.assignments
    ADD CONSTRAINT assignments_seat_id_fkey FOREIGN KEY (seat_id) REFERENCES v2.school_seats(id);
ALTER TABLE v2.assignments
    ADD CONSTRAINT assignments_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── attachments · md5 fd91133c156ac42840e61cef3e49e8c9
ALTER TABLE v2.attachments
    ADD CONSTRAINT attachments_guardian_id_fkey FOREIGN KEY (guardian_id) REFERENCES v2.guardians(id);
ALTER TABLE v2.attachments
    ADD CONSTRAINT attachments_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.attachments
    ADD CONSTRAINT attachments_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);

-- ── attendance · md5 a13046721ffd36e671592108d7f04096
ALTER TABLE v2.attendance
    ADD CONSTRAINT att_permit_fk FOREIGN KEY (permit_id) REFERENCES v2.entry_permits(id);
ALTER TABLE v2.attendance
    ADD CONSTRAINT attendance_entered_by_fkey FOREIGN KEY (entered_by) REFERENCES v2.people(id);
ALTER TABLE v2.attendance
    ADD CONSTRAINT attendance_late_recorded_by_fkey FOREIGN KEY (late_recorded_by) REFERENCES v2.people(id);
ALTER TABLE v2.attendance
    ADD CONSTRAINT attendance_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES v2.people(id);
ALTER TABLE v2.attendance
    ADD CONSTRAINT attendance_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.attendance
    ADD CONSTRAINT attendance_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.attendance
    ADD CONSTRAINT attendance_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── attendance_ledger · md5 4b88d99e11050e1af90a995b4e31b8b3
ALTER TABLE v2.attendance_ledger
    ADD CONSTRAINT attendance_ledger_by_person_fkey FOREIGN KEY (by_person) REFERENCES v2.people(id);
ALTER TABLE v2.attendance_ledger
    ADD CONSTRAINT attendance_ledger_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.attendance_ledger
    ADD CONSTRAINT attendance_ledger_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.attendance_ledger
    ADD CONSTRAINT attendance_ledger_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── behavior_census · md5 2eb7914cd903484e99f8a58ec54b399a
ALTER TABLE v2.behavior_census
    ADD CONSTRAINT behavior_census_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES v2.people(id);
ALTER TABLE v2.behavior_census
    ADD CONSTRAINT behavior_census_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES v2.people(id);
ALTER TABLE v2.behavior_census
    ADD CONSTRAINT behavior_census_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id);
ALTER TABLE v2.behavior_census
    ADD CONSTRAINT behavior_census_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.behavior_census
    ADD CONSTRAINT behavior_census_task_id_fkey FOREIGN KEY (task_id) REFERENCES v2.behavior_tasks(id);

-- ── behavior_ledger · md5 b000e4c7fad439816e4417f1fa2b86d8
ALTER TABLE v2.behavior_ledger
    ADD CONSTRAINT behavior_ledger_by_person_fkey FOREIGN KEY (by_person) REFERENCES v2.people(id);
ALTER TABLE v2.behavior_ledger
    ADD CONSTRAINT behavior_ledger_merit_id_fkey FOREIGN KEY (merit_id) REFERENCES v2.conduct_merits(id);
ALTER TABLE v2.behavior_ledger
    ADD CONSTRAINT behavior_ledger_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id);
ALTER TABLE v2.behavior_ledger
    ADD CONSTRAINT behavior_ledger_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.behavior_ledger
    ADD CONSTRAINT behavior_ledger_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.behavior_ledger
    ADD CONSTRAINT behavior_ledger_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── behavior_plan_counts · md5 8a2740b872db3102bce9dc1cb040fef5
ALTER TABLE v2.behavior_plan_counts
    ADD CONSTRAINT behavior_plan_counts_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES v2.behavior_plans(id) ON DELETE CASCADE;

-- ── behavior_plans · md5 a2a56270a1a80085e40475548384033b
ALTER TABLE v2.behavior_plans
    ADD CONSTRAINT behavior_plans_owner_person_fkey FOREIGN KEY (owner_person) REFERENCES v2.people(id);
ALTER TABLE v2.behavior_plans
    ADD CONSTRAINT behavior_plans_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id) ON DELETE CASCADE;
ALTER TABLE v2.behavior_plans
    ADD CONSTRAINT behavior_plans_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);

-- ── behavior_records · md5 5de67143ca0e980ae9c95431272e76f7
ALTER TABLE v2.behavior_records
    ADD CONSTRAINT behavior_records_action_id_fkey FOREIGN KEY (action_id) REFERENCES v2.conduct_actions(id);
ALTER TABLE v2.behavior_records
    ADD CONSTRAINT behavior_records_problem_id_fkey FOREIGN KEY (problem_id) REFERENCES v2.conduct_problems(id);
ALTER TABLE v2.behavior_records
    ADD CONSTRAINT behavior_records_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES v2.people(id);
ALTER TABLE v2.behavior_records
    ADD CONSTRAINT behavior_records_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.behavior_records
    ADD CONSTRAINT behavior_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.behavior_records
    ADD CONSTRAINT behavior_records_victim_student_id_fkey FOREIGN KEY (victim_student_id) REFERENCES v2.students(id);
ALTER TABLE v2.behavior_records
    ADD CONSTRAINT behavior_records_voided_by_fkey FOREIGN KEY (voided_by) REFERENCES v2.people(id);
ALTER TABLE v2.behavior_records
    ADD CONSTRAINT behavior_records_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── behavior_tasks · md5 41e39fb214f62507c428315d0da976aa
ALTER TABLE v2.behavior_tasks
    ADD CONSTRAINT behavior_tasks_delegated_by_fkey FOREIGN KEY (delegated_by) REFERENCES v2.people(id);
ALTER TABLE v2.behavior_tasks
    ADD CONSTRAINT behavior_tasks_done_by_fkey FOREIGN KEY (done_by) REFERENCES v2.people(id);
ALTER TABLE v2.behavior_tasks
    ADD CONSTRAINT behavior_tasks_evidence_kind_fkey FOREIGN KEY (evidence_kind) REFERENCES v2.evidence_kinds(key);
ALTER TABLE v2.behavior_tasks
    ADD CONSTRAINT behavior_tasks_item_id_fkey FOREIGN KEY (item_id) REFERENCES v2.conduct_action_items(id);
ALTER TABLE v2.behavior_tasks
    ADD CONSTRAINT behavior_tasks_owner_person_fkey FOREIGN KEY (owner_person) REFERENCES v2.people(id);
ALTER TABLE v2.behavior_tasks
    ADD CONSTRAINT behavior_tasks_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id) ON DELETE CASCADE;
ALTER TABLE v2.behavior_tasks
    ADD CONSTRAINT behavior_tasks_response_by_fkey FOREIGN KEY (response_by) REFERENCES v2.people(id);

-- ── branding · md5 be1cd60a859f66bc274369dd1f723ebd
ALTER TABLE v2.branding
    ADD CONSTRAINT branding_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── break_slots · md5 cf77cb970bc572e64dfe022dedbdf14f
ALTER TABLE v2.break_slots
    ADD CONSTRAINT break_slots_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── calendar_days · md5 70724c6cb2090becec2af00c2930e8ff
ALTER TABLE v2.calendar_days
    ADD CONSTRAINT calendar_days_holiday_id_fkey FOREIGN KEY (holiday_id) REFERENCES v2.calendar_holidays(id);
ALTER TABLE v2.calendar_days
    ADD CONSTRAINT calendar_days_week_id_fkey FOREIGN KEY (week_id) REFERENCES v2.calendar_weeks(id) ON DELETE CASCADE;
ALTER TABLE v2.calendar_days
    ADD CONSTRAINT calendar_days_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.calendar_years(id) ON DELETE CASCADE;

-- ── calendar_entries · md5 59c003ad29aa9c5e1a7c1c7e89e6f4a6
ALTER TABLE v2.calendar_entries
    ADD CONSTRAINT calendar_entries_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.calendar_entries
    ADD CONSTRAINT calendar_entries_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── calendar_holidays · md5 f8d82ac22561af79eeb803eba114aac2
ALTER TABLE v2.calendar_holidays
    ADD CONSTRAINT calendar_holidays_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.calendar_years(id) ON DELETE CASCADE;

-- ── calendar_milestones · md5 910b0841659504f22f230bf8ebdbe374
ALTER TABLE v2.calendar_milestones
    ADD CONSTRAINT calendar_milestones_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.calendar_years(id) ON DELETE CASCADE;

-- ── calendar_term_stats · md5 bab4775c280de45df64c63f0bc9bdcf0
ALTER TABLE v2.calendar_term_stats
    ADD CONSTRAINT calendar_term_stats_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.calendar_years(id) ON DELETE CASCADE;

-- ── calendar_weeks · md5 f2f7fd6c8be7191c1adbcc2af3e22560
ALTER TABLE v2.calendar_weeks
    ADD CONSTRAINT calendar_weeks_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.calendar_years(id) ON DELETE CASCADE;

-- ── calendar_years · md5 e1211318e4834d47aa8035e15e21e884
ALTER TABLE v2.calendar_years
    ADD CONSTRAINT calendar_years_scope_key_fkey FOREIGN KEY (scope_key) REFERENCES v2.calendar_scopes(key);

-- ── card_matrix · md5 9f12a783e385515ba6ae29339650f2bf
ALTER TABLE v2.card_matrix
    ADD CONSTRAINT card_matrix_card_code_step_no_fkey FOREIGN KEY (card_code, step_no) REFERENCES v2.card_steps(card_code, step_no);

-- ── card_steps · md5 25020ddec1d670011cef658bfbb238c5
ALTER TABLE v2.card_steps
    ADD CONSTRAINT card_steps_card_code_fkey FOREIGN KEY (card_code) REFERENCES v2.proc_cards(code);

-- ── card_values · md5 da264195f844e40df285e41846758446
ALTER TABLE v2.card_values
    ADD CONSTRAINT card_values_card_code_fkey FOREIGN KEY (card_code) REFERENCES v2.proc_cards(code);
ALTER TABLE v2.card_values
    ADD CONSTRAINT card_values_door_key_fkey FOREIGN KEY (door_key) REFERENCES v2.card_doors(key);

-- ── case_docs · md5 f91c760d48beb3e19138e96d7042e382
ALTER TABLE v2.case_docs
    ADD CONSTRAINT case_docs_issued_by_fkey FOREIGN KEY (issued_by) REFERENCES v2.people(id);
ALTER TABLE v2.case_docs
    ADD CONSTRAINT case_docs_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id) ON DELETE CASCADE;
ALTER TABLE v2.case_docs
    ADD CONSTRAINT case_docs_task_id_fkey FOREIGN KEY (task_id) REFERENCES v2.behavior_tasks(id);

-- ── census_items · md5 6e197a2003671d3faf5edb8bc06183d8
ALTER TABLE v2.census_items
    ADD CONSTRAINT census_items_based_on_fkey FOREIGN KEY (based_on) REFERENCES v2.census_items(id);
ALTER TABLE v2.census_items
    ADD CONSTRAINT census_items_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── class_practices · md5 5773b2457e9b29cced30dc27665ffef1
ALTER TABLE v2.class_practices
    ADD CONSTRAINT class_practices_escalate_to_fkey FOREIGN KEY (escalate_to) REFERENCES v2.conduct_problems(id);
ALTER TABLE v2.class_practices
    ADD CONSTRAINT class_practices_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── class_sections · md5 f24bffd0f25514770da91d262aca2122
ALTER TABLE v2.class_sections
    ADD CONSTRAINT class_sections_homeroom_person_fkey FOREIGN KEY (homeroom_person) REFERENCES v2.people(id);
ALTER TABLE v2.class_sections
    ADD CONSTRAINT class_sections_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.class_sections
    ADD CONSTRAINT class_sections_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── committee_duties · md5 ed7c68c4657b2ed734ea96d5ce662fb1
ALTER TABLE v2.committee_duties
    ADD CONSTRAINT committee_duties_committee_key_fkey FOREIGN KEY (committee_key) REFERENCES v2.committees(key);
ALTER TABLE v2.committee_duties
    ADD CONSTRAINT committee_duties_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── committee_meetings · md5 6ea7be02b942b0058ea338cb07ee703e
ALTER TABLE v2.committee_meetings
    ADD CONSTRAINT committee_meetings_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES v2.people(id);
ALTER TABLE v2.committee_meetings
    ADD CONSTRAINT committee_meetings_called_by_fkey FOREIGN KEY (called_by) REFERENCES v2.people(id);
ALTER TABLE v2.committee_meetings
    ADD CONSTRAINT committee_meetings_committee_key_fkey FOREIGN KEY (committee_key) REFERENCES v2.committees(key);
ALTER TABLE v2.committee_meetings
    ADD CONSTRAINT committee_meetings_minutes_by_fkey FOREIGN KEY (minutes_by) REFERENCES v2.people(id);
ALTER TABLE v2.committee_meetings
    ADD CONSTRAINT committee_meetings_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── committee_members · md5 ea229e30cc6cf471e0b434d60b767c30
ALTER TABLE v2.committee_members
    ADD CONSTRAINT committee_members_committee_key_fkey FOREIGN KEY (committee_key) REFERENCES v2.committees(key);
ALTER TABLE v2.committee_members
    ADD CONSTRAINT committee_members_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.committee_members
    ADD CONSTRAINT committee_members_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.committee_members
    ADD CONSTRAINT committee_members_via_post_key_fkey FOREIGN KEY (via_post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.committee_members
    ADD CONSTRAINT committee_members_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── committee_school_rules · md5 77e39d32229f18c37c0f0914468219cc
ALTER TABLE v2.committee_school_rules
    ADD CONSTRAINT committee_school_rules_committee_key_fkey FOREIGN KEY (committee_key) REFERENCES v2.committees(key);
ALTER TABLE v2.committee_school_rules
    ADD CONSTRAINT committee_school_rules_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.committee_school_rules
    ADD CONSTRAINT committee_school_rules_set_by_fkey FOREIGN KEY (set_by) REFERENCES v2.people(id);

-- ── committee_seats · md5 0988c35189ca6524099b54a1fd9e9522
ALTER TABLE v2.committee_seats
    ADD CONSTRAINT committee_seats_committee_key_fkey FOREIGN KEY (committee_key) REFERENCES v2.committees(key);
ALTER TABLE v2.committee_seats
    ADD CONSTRAINT committee_seats_post_key_fkey FOREIGN KEY (post_key) REFERENCES v2.posts(key);

-- ── committees · md5 aaf58edf798a5f5d23837e1d5d710222
ALTER TABLE v2.committees
    ADD CONSTRAINT committees_created_by_fkey FOREIGN KEY (created_by) REFERENCES v2.people(id);
ALTER TABLE v2.committees
    ADD CONSTRAINT committees_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── conduct_action_items · md5 18860552c03b25be6670eff55126661b
ALTER TABLE v2.conduct_action_items
    ADD CONSTRAINT conduct_action_items_action_id_fkey FOREIGN KEY (action_id) REFERENCES v2.conduct_actions(id) ON DELETE CASCADE;
ALTER TABLE v2.conduct_action_items
    ADD CONSTRAINT conduct_action_items_evidence_kind_fkey FOREIGN KEY (evidence_kind) REFERENCES v2.evidence_kinds(key);

-- ── conduct_actions · md5 d6c0f4ff7529b3a723c331bc2b41022d
ALTER TABLE v2.conduct_actions
    ADD CONSTRAINT conduct_actions_degree_no_fkey FOREIGN KEY (degree_no) REFERENCES v2.conduct_degrees(degree_no);

-- ── conduct_advice · md5 6f9a57de5df003667b68f42017c5cc8a
ALTER TABLE v2.conduct_advice
    ADD CONSTRAINT conduct_advice_problem_id_fkey FOREIGN KEY (problem_id) REFERENCES v2.conduct_problems(id);
ALTER TABLE v2.conduct_advice
    ADD CONSTRAINT conduct_advice_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── conduct_problems · md5 fbdfa46ee1963e29a1b86c1a5c517c57
ALTER TABLE v2.conduct_problems
    ADD CONSTRAINT conduct_problems_degree_no_fkey FOREIGN KEY (degree_no) REFERENCES v2.conduct_degrees(degree_no);

-- ── conduct_universal · md5 3ac326ea3c34966e5607b100e1f325f9
ALTER TABLE v2.conduct_universal
    ADD CONSTRAINT conduct_universal_degree_no_fkey FOREIGN KEY (degree_no) REFERENCES v2.conduct_degrees(degree_no);

-- ── counsel_cases · md5 28be1e7d70da80265833249e762596d9
ALTER TABLE v2.counsel_cases
    ADD CONSTRAINT counsel_cases_opened_by_fkey FOREIGN KEY (opened_by) REFERENCES v2.people(id);
ALTER TABLE v2.counsel_cases
    ADD CONSTRAINT counsel_cases_problem_id_fkey FOREIGN KEY (problem_id) REFERENCES v2.conduct_problems(id);
ALTER TABLE v2.counsel_cases
    ADD CONSTRAINT counsel_cases_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id);
ALTER TABLE v2.counsel_cases
    ADD CONSTRAINT counsel_cases_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.counsel_cases
    ADD CONSTRAINT counsel_cases_written_by_fkey FOREIGN KEY (written_by) REFERENCES v2.people(id);

-- ── counsel_reports · md5 93952b30c06b744a8e49b1ef4fd6350a
ALTER TABLE v2.counsel_reports
    ADD CONSTRAINT counsel_reports_case_id_fkey FOREIGN KEY (case_id) REFERENCES v2.counsel_cases(id) ON DELETE CASCADE;
ALTER TABLE v2.counsel_reports
    ADD CONSTRAINT counsel_reports_issued_by_fkey FOREIGN KEY (issued_by) REFERENCES v2.people(id);

-- ── counsel_sessions · md5 2a9791b09a011290e06cd1452c450512
ALTER TABLE v2.counsel_sessions
    ADD CONSTRAINT counsel_sessions_by_person_fkey FOREIGN KEY (by_person) REFERENCES v2.people(id);
ALTER TABLE v2.counsel_sessions
    ADD CONSTRAINT counsel_sessions_case_id_fkey FOREIGN KEY (case_id) REFERENCES v2.counsel_cases(id) ON DELETE CASCADE;

-- ── day_closures · md5 f9d5bc1ca8a639de29875da2a34b1a5f
ALTER TABLE v2.day_closures
    ADD CONSTRAINT day_closures_closed_by_fkey FOREIGN KEY (closed_by) REFERENCES v2.people(id);
ALTER TABLE v2.day_closures
    ADD CONSTRAINT day_closures_reopened_by_fkey FOREIGN KEY (reopened_by) REFERENCES v2.people(id);
ALTER TABLE v2.day_closures
    ADD CONSTRAINT day_closures_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── day_reversals · md5 5b820cbddfd0b5301a34587173d8f90c
ALTER TABLE v2.day_reversals
    ADD CONSTRAINT day_reversals_by_person_fkey FOREIGN KEY (by_person) REFERENCES v2.people(id);
ALTER TABLE v2.day_reversals
    ADD CONSTRAINT day_reversals_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── day_settings · md5 ed517103cbae9fdd4c02f1b2a750f864
ALTER TABLE v2.day_settings
    ADD CONSTRAINT day_settings_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id) ON DELETE CASCADE;

-- ── delegations · md5 3348bd03a6517a1a9c20aa4e1ce9656e
ALTER TABLE v2.delegations
    ADD CONSTRAINT delegations_from_person_fkey FOREIGN KEY (from_person) REFERENCES v2.people(id);
ALTER TABLE v2.delegations
    ADD CONSTRAINT delegations_issued_by_fkey FOREIGN KEY (issued_by) REFERENCES v2.people(id);
ALTER TABLE v2.delegations
    ADD CONSTRAINT delegations_post_key_fkey FOREIGN KEY (post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.delegations
    ADD CONSTRAINT delegations_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.delegations
    ADD CONSTRAINT delegations_to_person_fkey FOREIGN KEY (to_person) REFERENCES v2.people(id);

-- ── dismissal_records · md5 3798ad2afaada41247c84b436b3c71fc
ALTER TABLE v2.dismissal_records
    ADD CONSTRAINT dismissal_records_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES v2.people(id);
ALTER TABLE v2.dismissal_records
    ADD CONSTRAINT dismissal_records_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.dismissal_records
    ADD CONSTRAINT dismissal_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.dismissal_records
    ADD CONSTRAINT dismissal_records_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── dismissal_settings · md5 e16bfe92eb2a6efed886da82e80afe75
ALTER TABLE v2.dismissal_settings
    ADD CONSTRAINT dismissal_settings_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id) ON DELETE CASCADE;

-- ── doc_deliveries · md5 9fc385089ca1bde9429fbdcc944aaf24
ALTER TABLE v2.doc_deliveries
    ADD CONSTRAINT doc_deliveries_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES v2.case_docs(id) ON DELETE CASCADE;
ALTER TABLE v2.doc_deliveries
    ADD CONSTRAINT doc_deliveries_handed_by_fkey FOREIGN KEY (handed_by) REFERENCES v2.people(id);
ALTER TABLE v2.doc_deliveries
    ADD CONSTRAINT doc_deliveries_printed_by_fkey FOREIGN KEY (printed_by) REFERENCES v2.people(id);
ALTER TABLE v2.doc_deliveries
    ADD CONSTRAINT doc_deliveries_returned_by_fkey FOREIGN KEY (returned_by) REFERENCES v2.people(id);

-- ── doc_signatures · md5 04bfbadac5a3cd9be34112b1e7307c77
ALTER TABLE v2.doc_signatures
    ADD CONSTRAINT doc_signatures_doc_id_fkey FOREIGN KEY (doc_id) REFERENCES v2.case_docs(id) ON DELETE CASCADE;
ALTER TABLE v2.doc_signatures
    ADD CONSTRAINT doc_signatures_signer_person_fkey FOREIGN KEY (signer_person) REFERENCES v2.people(id);
ALTER TABLE v2.doc_signatures
    ADD CONSTRAINT doc_signatures_signer_student_fkey FOREIGN KEY (signer_student) REFERENCES v2.students(id);
ALTER TABLE v2.doc_signatures
    ADD CONSTRAINT doc_signatures_witnessed_by_fkey FOREIGN KEY (witnessed_by) REFERENCES v2.people(id);

-- ── duty_log · md5 14e18a49439757310dee3db35c7e464f
ALTER TABLE v2.duty_log
    ADD CONSTRAINT duty_log_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.duty_log
    ADD CONSTRAINT duty_log_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.duty_log
    ADD CONSTRAINT duty_log_substitute_fkey FOREIGN KEY (substitute) REFERENCES v2.people(id);
ALTER TABLE v2.duty_log
    ADD CONSTRAINT duty_log_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES v2.duty_zones(id);

-- ── duty_roster · md5 e9302644d371734960bbf7b0febd4c2f
ALTER TABLE v2.duty_roster
    ADD CONSTRAINT duty_roster_break_id_fkey FOREIGN KEY (break_id) REFERENCES v2.break_slots(id);
ALTER TABLE v2.duty_roster
    ADD CONSTRAINT duty_roster_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.duty_roster
    ADD CONSTRAINT duty_roster_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.duty_roster
    ADD CONSTRAINT duty_roster_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);
ALTER TABLE v2.duty_roster
    ADD CONSTRAINT duty_roster_zone_id_fkey FOREIGN KEY (zone_id) REFERENCES v2.duty_zones(id) ON DELETE CASCADE;

-- ── duty_zones · md5 366bb1fe785a7174ed9ccd23e2f48248
ALTER TABLE v2.duty_zones
    ADD CONSTRAINT duty_zones_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── enrolments · md5 8afa3d0bce3903483703a8a5f1c56d87
ALTER TABLE v2.enrolments
    ADD CONSTRAINT enrolments_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.enrolments
    ADD CONSTRAINT enrolments_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id) ON DELETE CASCADE;
ALTER TABLE v2.enrolments
    ADD CONSTRAINT enrolments_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── entry_permits · md5 188fdcdc66329842a6485ddc9ff22623
ALTER TABLE v2.entry_permits
    ADD CONSTRAINT entry_permits_issued_by_fkey FOREIGN KEY (issued_by) REFERENCES v2.people(id);
ALTER TABLE v2.entry_permits
    ADD CONSTRAINT entry_permits_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.entry_permits
    ADD CONSTRAINT entry_permits_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);

-- ── event_deliveries · md5 b6bcf8ccc5b6bfd7d687eee2bf1ee21c
ALTER TABLE v2.event_deliveries
    ADD CONSTRAINT event_deliveries_event_id_fkey FOREIGN KEY (event_id) REFERENCES v2.events(id) ON DELETE CASCADE;
ALTER TABLE v2.event_deliveries
    ADD CONSTRAINT event_deliveries_to_guardian_fkey FOREIGN KEY (to_guardian) REFERENCES v2.guardians(id);
ALTER TABLE v2.event_deliveries
    ADD CONSTRAINT event_deliveries_to_person_fkey FOREIGN KEY (to_person) REFERENCES v2.people(id);

-- ── events · md5 4e65b56d7f29f9f340b6945ee58bd34a
ALTER TABLE v2.events
    ADD CONSTRAINT events_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.events
    ADD CONSTRAINT events_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);

-- ── exceptions · md5 53d80ca85867dd6adb836bdea96b0f40
ALTER TABLE v2.exceptions
    ADD CONSTRAINT exceptions_decided_by_fkey FOREIGN KEY (decided_by) REFERENCES v2.people(id);
ALTER TABLE v2.exceptions
    ADD CONSTRAINT exceptions_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.exceptions
    ADD CONSTRAINT exceptions_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── form_entries · md5 f7fad25be84098be01655499b366bb28
ALTER TABLE v2.form_entries
    ADD CONSTRAINT form_entries_case_id_fkey FOREIGN KEY (case_id) REFERENCES v2.absence_cases(id);
ALTER TABLE v2.form_entries
    ADD CONSTRAINT form_entries_filled_by_fkey FOREIGN KEY (filled_by) REFERENCES v2.people(id);
ALTER TABLE v2.form_entries
    ADD CONSTRAINT form_entries_form_no_fkey FOREIGN KEY (form_no) REFERENCES v2.official_forms(form_no);
ALTER TABLE v2.form_entries
    ADD CONSTRAINT form_entries_mail_id_fkey FOREIGN KEY (mail_id) REFERENCES v2.incoming_mail(id);
ALTER TABLE v2.form_entries
    ADD CONSTRAINT form_entries_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id);
ALTER TABLE v2.form_entries
    ADD CONSTRAINT form_entries_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.form_entries
    ADD CONSTRAINT form_entries_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);

-- ── form_inbox · md5 e9b14679609eb3fa35506d2a4c99b40b
ALTER TABLE v2.form_inbox
    ADD CONSTRAINT form_inbox_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES v2.form_entries(id) ON DELETE CASCADE;
ALTER TABLE v2.form_inbox
    ADD CONSTRAINT form_inbox_guardian_id_fkey FOREIGN KEY (guardian_id) REFERENCES v2.guardians(id);
ALTER TABLE v2.form_inbox
    ADD CONSTRAINT form_inbox_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.form_inbox
    ADD CONSTRAINT form_inbox_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);

-- ── form_row_schema · md5 ae1ed8d8ea39603c3d69f8654b9ce1b3
ALTER TABLE v2.form_row_schema
    ADD CONSTRAINT form_row_schema_form_no_fkey FOREIGN KEY (form_no) REFERENCES v2.official_forms(form_no);

-- ── form_schema · md5 ae80c5f7584466b382de9c2d1f8d908b
ALTER TABLE v2.form_schema
    ADD CONSTRAINT form_schema_form_no_fkey FOREIGN KEY (form_no) REFERENCES v2.official_forms(form_no);

-- ── form_signatures · md5 b6eeddd1def66eaf5eb73e16e521085a
ALTER TABLE v2.form_signatures
    ADD CONSTRAINT form_signatures_entry_id_fkey FOREIGN KEY (entry_id) REFERENCES v2.form_entries(id) ON DELETE CASCADE;
ALTER TABLE v2.form_signatures
    ADD CONSTRAINT form_signatures_guardian_id_fkey FOREIGN KEY (guardian_id) REFERENCES v2.guardians(id);
ALTER TABLE v2.form_signatures
    ADD CONSTRAINT form_signatures_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.form_signatures
    ADD CONSTRAINT form_signatures_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);

-- ── gaps · md5 61baae2ffe9f4453bdd0137ed04be910
ALTER TABLE v2.gaps
    ADD CONSTRAINT gaps_card_code_fkey FOREIGN KEY (card_code) REFERENCES v2.proc_cards(code);

-- ── grading_subjects · md5 243e1c216935f7af0b2dc35cae663edf
ALTER TABLE v2.grading_subjects
    ADD CONSTRAINT grading_subjects_model_no_fkey FOREIGN KEY (model_no) REFERENCES v2.grading_models(model_no) ON DELETE CASCADE;

-- ── guardian_contacts · md5 254dce3e932939509ca053435f8b0217
ALTER TABLE v2.guardian_contacts
    ADD CONSTRAINT guardian_contacts_by_person_fkey FOREIGN KEY (by_person) REFERENCES v2.people(id);
ALTER TABLE v2.guardian_contacts
    ADD CONSTRAINT guardian_contacts_guardian_id_fkey FOREIGN KEY (guardian_id) REFERENCES v2.guardians(id);
ALTER TABLE v2.guardian_contacts
    ADD CONSTRAINT guardian_contacts_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id);
ALTER TABLE v2.guardian_contacts
    ADD CONSTRAINT guardian_contacts_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.guardian_contacts
    ADD CONSTRAINT guardian_contacts_task_id_fkey FOREIGN KEY (task_id) REFERENCES v2.behavior_tasks(id);

-- ── guardians · md5 ef20b126081f157f191932129a942ad8
ALTER TABLE v2.guardians
    ADD CONSTRAINT guardians_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id) ON DELETE CASCADE;

-- ── incident_seizures · md5 17ccbd6a599d2d0eb953822aabe8e7f1
ALTER TABLE v2.incident_seizures
    ADD CONSTRAINT incident_seizures_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id) ON DELETE CASCADE;

-- ── incident_witnesses · md5 e882b09f6e3e8606a16d538a6a46b541
ALTER TABLE v2.incident_witnesses
    ADD CONSTRAINT incident_witnesses_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id) ON DELETE CASCADE;

-- ── incoming_mail · md5 caa65e3733cc315b374d223d8fda48b2
ALTER TABLE v2.incoming_mail
    ADD CONSTRAINT incoming_mail_directed_by_fkey FOREIGN KEY (directed_by) REFERENCES v2.people(id);
ALTER TABLE v2.incoming_mail
    ADD CONSTRAINT incoming_mail_received_by_fkey FOREIGN KEY (received_by) REFERENCES v2.people(id);
ALTER TABLE v2.incoming_mail
    ADD CONSTRAINT incoming_mail_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.incoming_mail
    ADD CONSTRAINT incoming_mail_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── inheritance_rules · md5 f947da8c0cff1d4f164f977544ca86db
ALTER TABLE v2.inheritance_rules
    ADD CONSTRAINT inheritance_rules_heir_post_key_fkey FOREIGN KEY (heir_post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.inheritance_rules
    ADD CONSTRAINT inheritance_rules_vacant_post_key_fkey FOREIGN KEY (vacant_post_key) REFERENCES v2.posts(key);

-- ── mail_acknowledgements · md5 131f866dd3ee036ae9cce2660e86ae55
ALTER TABLE v2.mail_acknowledgements
    ADD CONSTRAINT mail_acknowledgements_guardian_id_fkey FOREIGN KEY (guardian_id) REFERENCES v2.guardians(id);
ALTER TABLE v2.mail_acknowledgements
    ADD CONSTRAINT mail_acknowledgements_item_id_fkey FOREIGN KEY (item_id) REFERENCES v2.mail_items(id) ON DELETE CASCADE;
ALTER TABLE v2.mail_acknowledgements
    ADD CONSTRAINT mail_acknowledgements_mail_id_fkey FOREIGN KEY (mail_id) REFERENCES v2.incoming_mail(id) ON DELETE CASCADE;
ALTER TABLE v2.mail_acknowledgements
    ADD CONSTRAINT mail_acknowledgements_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.mail_acknowledgements
    ADD CONSTRAINT mail_acknowledgements_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);

-- ── mail_attachments · md5 a5e3145bfe8e9e8558c797901df03bb1
ALTER TABLE v2.mail_attachments
    ADD CONSTRAINT mail_attachments_mail_id_fkey FOREIGN KEY (mail_id) REFERENCES v2.incoming_mail(id) ON DELETE CASCADE;

-- ── mail_followups · md5 23748b5215aebfa394ef222ba92b3478
ALTER TABLE v2.mail_followups
    ADD CONSTRAINT mail_followups_done_by_fkey FOREIGN KEY (done_by) REFERENCES v2.people(id);
ALTER TABLE v2.mail_followups
    ADD CONSTRAINT mail_followups_item_id_fkey FOREIGN KEY (item_id) REFERENCES v2.mail_items(id) ON DELETE CASCADE;
ALTER TABLE v2.mail_followups
    ADD CONSTRAINT mail_followups_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);

-- ── mail_items · md5 1e01525d66421eaacda63159e03e2556
ALTER TABLE v2.mail_items
    ADD CONSTRAINT mail_items_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES v2.people(id);
ALTER TABLE v2.mail_items
    ADD CONSTRAINT mail_items_mail_id_fkey FOREIGN KEY (mail_id) REFERENCES v2.incoming_mail(id) ON DELETE CASCADE;

-- ── mail_targets · md5 1618059050d5fb6a8530894216d64903
ALTER TABLE v2.mail_targets
    ADD CONSTRAINT mail_targets_item_id_fkey FOREIGN KEY (item_id) REFERENCES v2.mail_items(id) ON DELETE CASCADE;
ALTER TABLE v2.mail_targets
    ADD CONSTRAINT mail_targets_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);

-- ── meeting_attendance · md5 e4c9916cdd3c055063b23123a59b864b
ALTER TABLE v2.meeting_attendance
    ADD CONSTRAINT meeting_attendance_meeting_id_fkey FOREIGN KEY (meeting_id) REFERENCES v2.committee_meetings(id) ON DELETE CASCADE;
ALTER TABLE v2.meeting_attendance
    ADD CONSTRAINT meeting_attendance_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);

-- ── meeting_items · md5 36b1af8d3449638279277fffdbbf5d4f
ALTER TABLE v2.meeting_items
    ADD CONSTRAINT meeting_items_carried_from_fkey FOREIGN KEY (carried_from) REFERENCES v2.meeting_items(id);
ALTER TABLE v2.meeting_items
    ADD CONSTRAINT meeting_items_done_by_fkey FOREIGN KEY (done_by) REFERENCES v2.people(id);
ALTER TABLE v2.meeting_items
    ADD CONSTRAINT meeting_items_duty_id_fkey FOREIGN KEY (duty_id) REFERENCES v2.committee_duties(id);
ALTER TABLE v2.meeting_items
    ADD CONSTRAINT meeting_items_meeting_id_fkey FOREIGN KEY (meeting_id) REFERENCES v2.committee_meetings(id) ON DELETE CASCADE;
ALTER TABLE v2.meeting_items
    ADD CONSTRAINT meeting_items_owner_person_fkey FOREIGN KEY (owner_person) REFERENCES v2.people(id);

-- ── meeting_votes · md5 0a6bb0f0af8fb1757acbe9235c1ae6be
ALTER TABLE v2.meeting_votes
    ADD CONSTRAINT meeting_votes_item_id_fkey FOREIGN KEY (item_id) REFERENCES v2.meeting_items(id) ON DELETE CASCADE;
ALTER TABLE v2.meeting_votes
    ADD CONSTRAINT meeting_votes_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);

-- ── merit_entries · md5 036463bb2174dfcc678cd1eb5ce82200
ALTER TABLE v2.merit_entries
    ADD CONSTRAINT merit_entries_delegated_to_fkey FOREIGN KEY (delegated_to) REFERENCES v2.people(id);
ALTER TABLE v2.merit_entries
    ADD CONSTRAINT merit_entries_filed_by_fkey FOREIGN KEY (filed_by) REFERENCES v2.people(id);
ALTER TABLE v2.merit_entries
    ADD CONSTRAINT merit_entries_graded_by_fkey FOREIGN KEY (graded_by) REFERENCES v2.people(id);
ALTER TABLE v2.merit_entries
    ADD CONSTRAINT merit_entries_joined_by_fkey FOREIGN KEY (joined_by) REFERENCES v2.people(id);
ALTER TABLE v2.merit_entries
    ADD CONSTRAINT merit_entries_lifted_by_fkey FOREIGN KEY (lifted_by) REFERENCES v2.people(id);
ALTER TABLE v2.merit_entries
    ADD CONSTRAINT merit_entries_opp_id_fkey FOREIGN KEY (opp_id) REFERENCES v2.merit_opportunities(id) ON DELETE CASCADE;
ALTER TABLE v2.merit_entries
    ADD CONSTRAINT merit_entries_verdict_by_fkey FOREIGN KEY (verdict_by) REFERENCES v2.people(id);

-- ── merit_opportunities · md5 fbf30adf7e1524f22720ea3b328d587a
ALTER TABLE v2.merit_opportunities
    ADD CONSTRAINT merit_opportunities_held_by_fkey FOREIGN KEY (held_by) REFERENCES v2.people(id);
ALTER TABLE v2.merit_opportunities
    ADD CONSTRAINT merit_opportunities_merit_id_fkey FOREIGN KEY (merit_id) REFERENCES v2.conduct_merits(id);
ALTER TABLE v2.merit_opportunities
    ADD CONSTRAINT merit_opportunities_opened_by_fkey FOREIGN KEY (opened_by) REFERENCES v2.people(id);
ALTER TABLE v2.merit_opportunities
    ADD CONSTRAINT merit_opportunities_planned_by_fkey FOREIGN KEY (planned_by) REFERENCES v2.people(id);
ALTER TABLE v2.merit_opportunities
    ADD CONSTRAINT merit_opportunities_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── message_templates · md5 558cbc23d8128f5931a8a86c0b18d4fe
ALTER TABLE v2.message_templates
    ADD CONSTRAINT message_templates_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── outbox · md5 3bd889dcd7f0981cd09d1ba2004ca0ca
ALTER TABLE v2.outbox
    ADD CONSTRAINT outbox_delivery_id_fkey FOREIGN KEY (delivery_id) REFERENCES v2.event_deliveries(id) ON DELETE CASCADE;
ALTER TABLE v2.outbox
    ADD CONSTRAINT outbox_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── people · md5 30ab9b803e980a7255ebf4a3913dd04e
ALTER TABLE v2.people
    ADD CONSTRAINT people_post_key_fkey FOREIGN KEY (post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.people
    ADD CONSTRAINT people_rank_key_fkey FOREIGN KEY (rank_key) REFERENCES v2.teaching_ranks(key);
ALTER TABLE v2.people
    ADD CONSTRAINT people_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES v2.tenants(id);

-- ── period_attendance · md5 48e2de9a526ba7fb811f3ee40f1897f5
ALTER TABLE v2.period_attendance
    ADD CONSTRAINT period_attendance_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES v2.people(id);
ALTER TABLE v2.period_attendance
    ADD CONSTRAINT period_attendance_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.period_attendance
    ADD CONSTRAINT period_attendance_segment_fkey FOREIGN KEY (segment) REFERENCES v2.day_segments(key);
ALTER TABLE v2.period_attendance
    ADD CONSTRAINT period_attendance_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.period_attendance
    ADD CONSTRAINT period_attendance_teacher_id_fkey FOREIGN KEY (teacher_id) REFERENCES v2.people(id);
ALTER TABLE v2.period_attendance
    ADD CONSTRAINT period_attendance_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── period_slots · md5 50654d9de686fca358164f8a4a08a972
ALTER TABLE v2.period_slots
    ADD CONSTRAINT period_slots_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── phrase_bank · md5 5d6b0bb8706c0b74c065be6bba964739
ALTER TABLE v2.phrase_bank
    ADD CONSTRAINT phrase_bank_problem_id_fkey FOREIGN KEY (problem_id) REFERENCES v2.conduct_problems(id);
ALTER TABLE v2.phrase_bank
    ADD CONSTRAINT phrase_bank_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── practice_overrides · md5 477dc0c0d593447cb8115bb3b76de878
ALTER TABLE v2.practice_overrides
    ADD CONSTRAINT practice_overrides_code_fkey FOREIGN KEY (code) REFERENCES v2.class_practices(code);
ALTER TABLE v2.practice_overrides
    ADD CONSTRAINT practice_overrides_escalate_to_fkey FOREIGN KEY (escalate_to) REFERENCES v2.conduct_problems(id);
ALTER TABLE v2.practice_overrides
    ADD CONSTRAINT practice_overrides_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.practice_overrides
    ADD CONSTRAINT practice_overrides_set_by_fkey FOREIGN KEY (set_by) REFERENCES v2.people(id);

-- ── practice_points · md5 d71efaa877406fe8d1480c1454b6f3c0
ALTER TABLE v2.practice_points
    ADD CONSTRAINT practice_points_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.practice_records(id) ON DELETE CASCADE;
ALTER TABLE v2.practice_points
    ADD CONSTRAINT practice_points_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.practice_points
    ADD CONSTRAINT practice_points_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.practice_points
    ADD CONSTRAINT practice_points_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── practice_records · md5 cc835a0df55a41805ae4ef8327432eb7
ALTER TABLE v2.practice_records
    ADD CONSTRAINT practice_records_by_person_fkey FOREIGN KEY (by_person) REFERENCES v2.people(id);
ALTER TABLE v2.practice_records
    ADD CONSTRAINT practice_records_code_fkey FOREIGN KEY (code) REFERENCES v2.class_practices(code);
ALTER TABLE v2.practice_records
    ADD CONSTRAINT practice_records_escalated_record_fkey FOREIGN KEY (escalated_record) REFERENCES v2.behavior_records(id);
ALTER TABLE v2.practice_records
    ADD CONSTRAINT practice_records_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.practice_records
    ADD CONSTRAINT practice_records_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.practice_records
    ADD CONSTRAINT practice_records_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── practice_scopes · md5 3de2e79ccda3abfedd57b0a7304de9d1
ALTER TABLE v2.practice_scopes
    ADD CONSTRAINT practice_scopes_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── report_filers · md5 f8197dc364fc905bd1362f304591adeb
ALTER TABLE v2.report_filers
    ADD CONSTRAINT report_filers_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id) ON DELETE CASCADE;
ALTER TABLE v2.report_filers
    ADD CONSTRAINT report_filers_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── school_custody · md5 db753f3bb268978238d0d981ce84d06c
ALTER TABLE v2.school_custody
    ADD CONSTRAINT school_custody_received_by_fkey FOREIGN KEY (received_by) REFERENCES v2.people(id);
ALTER TABLE v2.school_custody
    ADD CONSTRAINT school_custody_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.school_custody
    ADD CONSTRAINT school_custody_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── school_seats · md5 45ee7a79614ddfad203aa1089eccc491
ALTER TABLE v2.school_seats
    ADD CONSTRAINT school_seats_carries_post_key_fkey FOREIGN KEY (carries_post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.school_seats
    ADD CONSTRAINT school_seats_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.school_seats
    ADD CONSTRAINT school_seats_post_key_fkey FOREIGN KEY (post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.school_seats
    ADD CONSTRAINT school_seats_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.school_seats
    ADD CONSTRAINT school_seats_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── schools · md5 c936dd803d6c5adff7508c24c5f523c4
ALTER TABLE v2.schools
    ADD CONSTRAINT schools_calendar_scope_fkey FOREIGN KEY (calendar_scope) REFERENCES v2.calendar_scopes(key);
ALTER TABLE v2.schools
    ADD CONSTRAINT schools_structure_code_fkey FOREIGN KEY (structure_code) REFERENCES v2.structures(code);
ALTER TABLE v2.schools
    ADD CONSTRAINT schools_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES v2.tenants(id);

-- ── session_role · md5 8ef77af954f71703d5059babbe73e49f
ALTER TABLE v2.session_role
    ADD CONSTRAINT session_role_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── signatures · md5 3cd9f31f7bf88dce987fc2cc934dfdcd
ALTER TABLE v2.signatures
    ADD CONSTRAINT signatures_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);

-- ── signed_forms_file · md5 fa8b693cbb8cf5c94bdcec797faa18ff
ALTER TABLE v2.signed_forms_file
    ADD CONSTRAINT signed_forms_file_form_no_fkey FOREIGN KEY (form_no) REFERENCES v2.official_forms(form_no);
ALTER TABLE v2.signed_forms_file
    ADD CONSTRAINT signed_forms_file_kept_by_fkey FOREIGN KEY (kept_by) REFERENCES v2.people(id);
ALTER TABLE v2.signed_forms_file
    ADD CONSTRAINT signed_forms_file_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.signed_forms_file
    ADD CONSTRAINT signed_forms_file_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.signed_forms_file
    ADD CONSTRAINT signed_forms_file_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── signoffs · md5 a8d2c19b0bbab02b37643509583a34b9
ALTER TABLE v2.signoffs
    ADD CONSTRAINT signoffs_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.signoffs
    ADD CONSTRAINT signoffs_post_key_fkey FOREIGN KEY (post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.signoffs
    ADD CONSTRAINT signoffs_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.signoffs
    ADD CONSTRAINT signoffs_signature_id_fkey FOREIGN KEY (signature_id) REFERENCES v2.signatures(id);
ALTER TABLE v2.signoffs
    ADD CONSTRAINT signoffs_stamp_id_fkey FOREIGN KEY (stamp_id) REFERENCES v2.stamps(id);
ALTER TABLE v2.signoffs
    ADD CONSTRAINT signoffs_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── staffing_rules · md5 ba8586dc1bceed427d2a876cd594d818
ALTER TABLE v2.staffing_rules
    ADD CONSTRAINT staffing_rules_post_key_fkey FOREIGN KEY (post_key) REFERENCES v2.posts(key);

-- ── stamps · md5 e591c60a0bbbfe177906cc598fe46d90
ALTER TABLE v2.stamps
    ADD CONSTRAINT stamps_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── structure_posts · md5 8c76445503efaa17e9a81be247d689f3
ALTER TABLE v2.structure_posts
    ADD CONSTRAINT structure_posts_parent_post_key_fkey FOREIGN KEY (parent_post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.structure_posts
    ADD CONSTRAINT structure_posts_post_key_fkey FOREIGN KEY (post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.structure_posts
    ADD CONSTRAINT structure_posts_structure_code_fkey FOREIGN KEY (structure_code) REFERENCES v2.structures(code);

-- ── student_permissions · md5 62925e622f1082eb5b973db4acd223df
ALTER TABLE v2.student_permissions
    ADD CONSTRAINT student_permissions_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES v2.people(id);
ALTER TABLE v2.student_permissions
    ADD CONSTRAINT student_permissions_guardian_id_fkey FOREIGN KEY (guardian_id) REFERENCES v2.guardians(id);
ALTER TABLE v2.student_permissions
    ADD CONSTRAINT student_permissions_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.student_permissions
    ADD CONSTRAINT student_permissions_student_id_fkey FOREIGN KEY (student_id) REFERENCES v2.students(id);
ALTER TABLE v2.student_permissions
    ADD CONSTRAINT student_permissions_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── students · md5 13876506e64ea9f355ba5e38ed575e6f
ALTER TABLE v2.students
    ADD CONSTRAINT students_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.students
    ADD CONSTRAINT students_tenant_id_fkey FOREIGN KEY (tenant_id) REFERENCES v2.tenants(id);

-- ── subject_plan · md5 5aad647ddc38aa4a6e8cd14e89770970
ALTER TABLE v2.subject_plan
    ADD CONSTRAINT subject_plan_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── teacher_subjects · md5 0c4db25fd62525499b4a61e5be22326b
ALTER TABLE v2.teacher_subjects
    ADD CONSTRAINT teacher_subjects_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.teacher_subjects
    ADD CONSTRAINT teacher_subjects_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── teaching_assignments · md5 5c3fd7cc115b54e8d9c055657f8760a3
ALTER TABLE v2.teaching_assignments
    ADD CONSTRAINT teaching_assignments_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id) ON DELETE CASCADE;
ALTER TABLE v2.teaching_assignments
    ADD CONSTRAINT teaching_assignments_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.teaching_assignments
    ADD CONSTRAINT teaching_assignments_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── teaching_quota · md5 aadd220a960893c1b3564c1543f4d281
ALTER TABLE v2.teaching_quota
    ADD CONSTRAINT teaching_quota_post_key_fkey FOREIGN KEY (post_key) REFERENCES v2.posts(key);
ALTER TABLE v2.teaching_quota
    ADD CONSTRAINT teaching_quota_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.teaching_quota
    ADD CONSTRAINT teaching_quota_set_by_fkey FOREIGN KEY (set_by) REFERENCES v2.people(id);

-- ── terms · md5 4712f1be1f0a0b096d39db36086bc5cb
ALTER TABLE v2.terms
    ADD CONSTRAINT terms_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── timetable · md5 f29884691adfe5d7599a7378f2160d7f
ALTER TABLE v2.timetable
    ADD CONSTRAINT timetable_person_id_fkey FOREIGN KEY (person_id) REFERENCES v2.people(id);
ALTER TABLE v2.timetable
    ADD CONSTRAINT timetable_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.timetable
    ADD CONSTRAINT timetable_section_id_fkey FOREIGN KEY (section_id) REFERENCES v2.class_sections(id) ON DELETE CASCADE;
ALTER TABLE v2.timetable
    ADD CONSTRAINT timetable_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── timetable_draft_slots · md5 77203875aaf875d39621b3ae426e8af0
ALTER TABLE v2.timetable_draft_slots
    ADD CONSTRAINT timetable_draft_slots_draft_id_fkey FOREIGN KEY (draft_id) REFERENCES v2.timetable_drafts(id) ON DELETE CASCADE;

-- ── timetable_drafts · md5 52aaaa730f2495a200aa0805f838ce4c
ALTER TABLE v2.timetable_drafts
    ADD CONSTRAINT timetable_drafts_applied_by_fkey FOREIGN KEY (applied_by) REFERENCES v2.people(id);
ALTER TABLE v2.timetable_drafts
    ADD CONSTRAINT timetable_drafts_made_by_fkey FOREIGN KEY (made_by) REFERENCES v2.people(id);
ALTER TABLE v2.timetable_drafts
    ADD CONSTRAINT timetable_drafts_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);

-- ── violence_cases · md5 46d8d1cbb5c9024e3385ec1ebaa468ce
ALTER TABLE v2.violence_cases
    ADD CONSTRAINT violence_cases_kept_by_fkey FOREIGN KEY (kept_by) REFERENCES v2.people(id);
ALTER TABLE v2.violence_cases
    ADD CONSTRAINT violence_cases_offender_student_fkey FOREIGN KEY (offender_student) REFERENCES v2.students(id);
ALTER TABLE v2.violence_cases
    ADD CONSTRAINT violence_cases_record_id_fkey FOREIGN KEY (record_id) REFERENCES v2.behavior_records(id);
ALTER TABLE v2.violence_cases
    ADD CONSTRAINT violence_cases_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.violence_cases
    ADD CONSTRAINT violence_cases_type_key_fkey FOREIGN KEY (type_key) REFERENCES v2.violence_types(key);
ALTER TABLE v2.violence_cases
    ADD CONSTRAINT violence_cases_victim_id_fkey FOREIGN KEY (victim_id) REFERENCES v2.students(id);
ALTER TABLE v2.violence_cases
    ADD CONSTRAINT violence_cases_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

-- ── violence_census · md5 1723450b3083f126bbe09c005c1667ef
ALTER TABLE v2.violence_census
    ADD CONSTRAINT violence_census_school_id_fkey FOREIGN KEY (school_id) REFERENCES v2.schools(id);
ALTER TABLE v2.violence_census
    ADD CONSTRAINT violence_census_type_key_fkey FOREIGN KEY (type_key) REFERENCES v2.violence_types(key);
ALTER TABLE v2.violence_census
    ADD CONSTRAINT violence_census_year_id_fkey FOREIGN KEY (year_id) REFERENCES v2.academic_years(id);

