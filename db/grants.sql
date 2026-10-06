-- grants.sql
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.

-- ── grants · md5 a7a2a8e64ad23b647a21f3895b94406f
GRANT USAGE ON SCHEMA v2 TO authenticated;



GRANT EXECUTE ON FUNCTION v2.acting_school() TO authenticated;
GRANT EXECUTE ON FUNCTION v2.assert_my_child(p_student uuid, p_what text) TO authenticated;
REVOKE ALL ON FUNCTION v2.assert_my_school(p_school uuid, p_what text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.assert_my_school(p_school uuid, p_what text) TO authenticated;
REVOKE ALL ON FUNCTION v2.assert_my_student(p_student uuid, p_what text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.assert_my_student(p_student uuid, p_what text) TO authenticated;
REVOKE ALL ON FUNCTION v2.assert_role(p_allowed text[], p_what text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION v2.attachment_allows(p_path text) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.attachment_guardian_ok(p_path text) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.caller_kind(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.can_do(p_allowed text[]) TO authenticated;
REVOKE ALL ON FUNCTION v2.current_person() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.current_person() TO authenticated;
REVOKE ALL ON FUNCTION v2.current_tenant() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.current_tenant() TO authenticated;
GRANT EXECUTE ON FUNCTION v2.evidence_exists(p_path text) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.evidence_ok(p_entry uuid, p_path text) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.evidence_path_for(p_entry uuid) TO authenticated;
REVOKE ALL ON FUNCTION v2.fn_absence_days(p_student uuid, p_year uuid, p_excused boolean) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_accept_excuse(p_claim uuid, p_by uuid, p_note text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_acknowledge_mail(p_ack uuid, p_signed boolean, p_kind text, p_refused boolean, p_reason text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_action_items_expanded(p_action integer) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_add_working_days(p_school uuid, p_from date, p_days integer) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_apply_absence(p_student uuid, p_date date, p_term smallint, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_approve_mail_item(p_item uuid, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_attendance_balance(p_student uuid, p_year uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_attendance_state(p_student uuid, p_year uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_audit() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_behavior_balance(p_student uuid, p_year uuid, p_term smallint) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION v2.fn_clear_test(p_school uuid) TO authenticated;
REVOKE ALL ON FUNCTION v2.fn_close(p_school text, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_close_day(p_school uuid, p_date date, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_close_day_inner(p_school uuid, p_date date, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_day_kind(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_day_list(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_day_log(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_day_summary(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_decide_excuse(p_claim uuid, p_accept boolean, p_by uuid, p_note text, p_principal_ext boolean) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_digits(p text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_display_name(p_name text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_entitlement(p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_excuse_window(p_school uuid, p_absence date, p_submitted date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_find_student(p_q text, p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_is_excused(p_student uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_load_balance(p_school uuid, p_year uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_log_incoming(p_school uuid, p_from text, p_subject text, p_received date, p_body text, p_ref text, p_secrecy text, p_doc_date date, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_mail_state(p_mail uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION v2.fn_my_roles() TO authenticated;
REVOKE ALL ON FUNCTION v2.fn_my_schools() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_norm_ar(p text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_person_silence() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_quick_day(p_school text, p_date date, p_absent text[], p_late text[], p_late_minutes smallint, p_missed_assembly text[], p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_arrival(p_student uuid, p_date date, p_arrived time without time zone, p_decision text, p_term smallint, p_by uuid, p_note text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_assembly(p_student uuid, p_date date, p_state text, p_term smallint, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_attendance(p_student uuid, p_date date, p_state text, p_term smallint, p_minutes_late smallint, p_note text, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_behavior(p_student uuid, p_problem integer, p_term smallint, p_period smallint, p_place text, p_note text, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_dismissal(p_student uuid, p_date date, p_left time without time zone, p_reason text, p_term smallint, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_period(p_student uuid, p_date date, p_period smallint, p_state text, p_subject text, p_teacher uuid, p_minutes_late smallint, p_term smallint, p_note text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_permission(p_student uuid, p_date date, p_out time without time zone, p_reason text, p_requested_by text, p_periods smallint[], p_term smallint, p_by uuid, p_back time without time zone) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_segment(p_student uuid, p_date date, p_segment text, p_state text, p_by uuid, p_term smallint, p_note text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_register_attendance(p_school uuid, p_year uuid, p_from date, p_to date, p_grade smallint, p_section text, p_student uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_register_rollup(p_level text, p_school uuid, p_year uuid, p_from date, p_to date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_reopen_day(p_school uuid, p_date date, p_reason text, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_school_days(p_school uuid, p_from date, p_to date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_send_prenotice(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_submit_excuse(p_student uuid, p_from date, p_to date, p_by text, p_channel text, p_excuse_item smallint, p_reason text, p_attachment text, p_attachment_name text, p_submitted date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_teaching_load(p_person uuid, p_year uuid, p_term smallint) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_term_of(p_school uuid, p_date date) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION v2.fn_test_mode(p_school text, p_on boolean) TO authenticated;
REVOKE ALL ON FUNCTION v2.fn_to_hijri(p date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_today(p_school text, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_year_open_guard() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION v2.grade_ar(g smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.merit_path_allows(p_path text, p_write boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.my_grant() TO authenticated;
GRANT EXECUTE ON FUNCTION v2.my_posts() TO authenticated;
REVOKE ALL ON FUNCTION v2.my_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.my_role() TO authenticated;
REVOKE ALL ON FUNCTION v2.my_school(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.my_school(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.quorum_of(p_school uuid, p_committee text) TO authenticated;
REVOKE ALL ON FUNCTION v2.role_ar(p text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.role_ar(p text) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.seat_cap(p_school uuid, p_committee text, p_seat_role text) TO authenticated;
GRANT EXECUTE ON FUNCTION v2.stage_ar(p text) TO authenticated;
REVOKE ALL ON FUNCTION v2.trg_attendance_calendar_guard() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.trg_day_closed_guard() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.trg_period_guard() FROM PUBLIC;

REVOKE ALL ON FUNCTION public.v2_absence_task_delegate(p_task uuid, p_person uuid, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_delegate(p_task uuid, p_person uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_delegate(p_task uuid, p_person uuid, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_absence_task_done(p_task uuid, p_ev jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_done(p_task uuid, p_ev jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_done(p_task uuid, p_ev jsonb) TO service_role;
REVOKE ALL ON FUNCTION public.v2_absence_task_skip(p_task uuid, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_skip(p_task uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_skip(p_task uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_act_as(p_role text, p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_act_as(p_role text, p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_act_as(p_role text, p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_age_ar(p_birth date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_age_ar(p_birth date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_age_ar(p_birth date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_attach(p_student uuid, p_kind text, p_file_name text, p_storage_path text, p_mime text, p_size_kb integer, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_attach(p_student uuid, p_kind text, p_file_name text, p_storage_path text, p_mime text, p_size_kb integer, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_attach(p_student uuid, p_kind text, p_file_name text, p_storage_path text, p_mime text, p_size_kb integer, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_attachments(p_student uuid, p_kind text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_attachments(p_student uuid, p_kind text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_attachments(p_student uuid, p_kind text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_branding(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_branding(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_branding(p_school uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_case_card(p_case uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_case_card(p_case uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_case_card(p_case uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_case_report(p_case uuid, p_opinion text, p_recommend text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_case_report(p_case uuid, p_opinion text, p_recommend text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_case_report(p_case uuid, p_opinion text, p_recommend text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_case_report_card(p_student uuid, p_problem integer) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_case_report_card(p_student uuid, p_problem integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_case_report_card(p_student uuid, p_problem integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_case_write(p_case uuid, p_student_view text, p_observed text, p_factors text, p_plan text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_case_write(p_case uuid, p_student_view text, p_observed text, p_factors text, p_plan text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_case_write(p_case uuid, p_student_view text, p_observed text, p_factors text, p_plan text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_close_day(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_close_day(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_close_day(p_school uuid, p_date date) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_committee_board(p_school uuid, p_committee text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_committee_board(p_school uuid, p_committee text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_board(p_school uuid, p_committee text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_committee_quorum(p_school uuid, p_committee text, p_min smallint, p_note text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_committee_quorum(p_school uuid, p_committee text, p_min smallint, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_quorum(p_school uuid, p_committee text, p_min smallint, p_note text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat(p_school uuid, p_committee text, p_seat_role text, p_person uuid, p_post_key text, p_nominated_by text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat(p_school uuid, p_committee text, p_seat_role text, p_person uuid, p_post_key text, p_nominated_by text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat(p_school uuid, p_committee text, p_seat_role text, p_person uuid, p_post_key text, p_nominated_by text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat_count(p_school uuid, p_committee text, p_seat_role text, p_count smallint, p_reason text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat_count(p_school uuid, p_committee text, p_seat_role text, p_count smallint, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat_count(p_school uuid, p_committee text, p_seat_role text, p_count smallint, p_reason text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_committee_unseat(p_school uuid, p_committee text, p_person uuid, p_reason text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_committee_unseat(p_school uuid, p_committee text, p_person uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_unseat(p_school uuid, p_committee text, p_person uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_conduct_list(p_student uuid, p_mode text, p_target text, p_stage text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_conduct_list(p_student uuid, p_mode text, p_target text, p_stage text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_conduct_list(p_student uuid, p_mode text, p_target text, p_stage text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_counsel_board(p_school uuid, p_state text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_counsel_board(p_school uuid, p_state text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_counsel_board(p_school uuid, p_state text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_day_classes(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_day_classes(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_day_classes(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_day_dismissals(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_day_dismissals(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_day_dismissals(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_day_list(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_day_list(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_day_list(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_day_log(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_day_log(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_day_log(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_day_summary(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_day_summary(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_day_summary(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_decide_excuse(p_claim uuid, p_accept boolean, p_note text, p_principal_ext boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_decide_excuse(p_claim uuid, p_accept boolean, p_note text, p_principal_ext boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_decide_excuse(p_claim uuid, p_accept boolean, p_note text, p_principal_ext boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_default_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_default_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_default_role() TO service_role;
REVOKE ALL ON FUNCTION public.v2_duty_autofill(p_school uuid, p_weekday smallint, p_zone text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_duty_autofill(p_school uuid, p_weekday smallint, p_zone text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_duty_autofill(p_school uuid, p_weekday smallint, p_zone text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_duty_eligible(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_duty_eligible(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_duty_eligible(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_duty_today(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_duty_today(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_duty_today(p_school uuid, p_date date) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_entries_pending(p_school uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_entries_pending(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_entries_pending(p_school uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_entry_delegate(p_entry uuid, p_person uuid, p_note text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_entry_delegate(p_entry uuid, p_person uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_entry_delegate(p_entry uuid, p_person uuid, p_note text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_entry_file(p_entry uuid, p_what text, p_evidence_path text, p_evidence_desc text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_entry_file(p_entry uuid, p_what text, p_evidence_path text, p_evidence_desc text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_entry_file(p_entry uuid, p_what text, p_evidence_path text, p_evidence_desc text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_entry_grade(p_entry uuid, p_points numeric, p_note text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_entry_grade(p_entry uuid, p_points numeric, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_entry_grade(p_entry uuid, p_points numeric, p_note text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_entry_verdict(p_entry uuid, p_verdict text, p_note text, p_file text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_entry_verdict(p_entry uuid, p_verdict text, p_note text, p_file text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_entry_verdict(p_entry uuid, p_verdict text, p_note text, p_file text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_error_fixed(p_id uuid, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_error_fixed(p_id uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_error_fixed(p_id uuid, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_errors(p_days integer, p_kind text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_errors(p_days integer, p_kind text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_errors(p_days integer, p_kind text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_evidence_kinds() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_evidence_kinds() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_evidence_kinds() TO service_role;
REVOKE ALL ON FUNCTION public.v2_form(p_form smallint, p_student uuid, p_ref uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_form(p_form smallint, p_student uuid, p_ref uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_form(p_form smallint, p_student uuid, p_ref uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_form_open(p_form smallint, p_student uuid, p_ref uuid, p_task uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_form_open(p_form smallint, p_student uuid, p_ref uuid, p_task uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_form_open(p_form smallint, p_student uuid, p_ref uuid, p_task uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_form_save(p_form smallint, p_data jsonb, p_rows jsonb, p_student uuid, p_ref uuid, p_task uuid, p_entry uuid, p_final boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_form_save(p_form smallint, p_data jsonb, p_rows jsonb, p_student uuid, p_ref uuid, p_task uuid, p_entry uuid, p_final boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_form_save(p_form smallint, p_data jsonb, p_rows jsonb, p_student uuid, p_ref uuid, p_task uuid, p_entry uuid, p_final boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_form_sign(p_entry uuid, p_signer text, p_signed boolean, p_refuse_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_form_sign(p_entry uuid, p_signer text, p_signed boolean, p_refuse_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_form_sign(p_entry uuid, p_signer text, p_signed boolean, p_refuse_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_form_void(p_entry uuid, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_form_void(p_entry uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_form_void(p_entry uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_child(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_child(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_child(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_form_note(p_inbox uuid, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_form_note(p_inbox uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_form_note(p_inbox uuid, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_form_read(p_inbox uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_form_read(p_inbox uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_form_read(p_inbox uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_form_reply(p_inbox uuid, p_reply text, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_form_reply(p_inbox uuid, p_reply text, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_form_reply(p_inbox uuid, p_reply text, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_forms() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_forms() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_forms() TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_me() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_me() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_me() TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_read(p_event uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_read(p_event uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_read(p_event uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_attachment_name text, p_excuse_item smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_attachment_name text, p_excuse_item smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_attachment_name text, p_excuse_item smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_log_error(p jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_log_error(p jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_log_error(p jsonb) TO service_role;
REVOKE ALL ON FUNCTION public.v2_mail_ack(p_mail uuid, p_signed boolean, p_refuse_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_mail_ack(p_mail uuid, p_signed boolean, p_refuse_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_mail_ack(p_mail uuid, p_signed boolean, p_refuse_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_mail_card(p_mail uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_mail_card(p_mail uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_mail_card(p_mail uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_mail_followup_done(p_followup uuid, p_note text, p_evidence text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_mail_followup_done(p_followup uuid, p_note text, p_evidence text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_mail_followup_done(p_followup uuid, p_note text, p_evidence text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_mail_inbox(p_school uuid, p_status text, p_days integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_mail_inbox(p_school uuid, p_status text, p_days integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_mail_inbox(p_school uuid, p_status text, p_days integer) TO service_role;
REVOKE ALL ON FUNCTION public.v2_mail_my_tasks(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_mail_my_tasks(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_mail_my_tasks(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_me() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_me() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_me() TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meeting_approve(p_meeting uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meeting_approve(p_meeting uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_approve(p_meeting uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meeting_call(p_school uuid, p_committee text, p_kind text, p_held_on date, p_started time without time zone, p_place text, p_agenda text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meeting_call(p_school uuid, p_committee text, p_kind text, p_held_on date, p_started time without time zone, p_place text, p_agenda text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_call(p_school uuid, p_committee text, p_kind text, p_held_on date, p_started time without time zone, p_place text, p_agenda text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meeting_card(p_meeting uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meeting_card(p_meeting uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_card(p_meeting uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meeting_invite(p_meeting uuid, p_kind text, p_person uuid, p_student uuid, p_guardian uuid, p_note text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meeting_invite(p_meeting uuid, p_kind text, p_person uuid, p_student uuid, p_guardian uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_invite(p_meeting uuid, p_kind text, p_person uuid, p_student uuid, p_guardian uuid, p_note text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meeting_item(p_meeting uuid, p_kind text, p_title text, p_student uuid, p_record uuid, p_opp uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meeting_item(p_meeting uuid, p_kind text, p_title text, p_student uuid, p_record uuid, p_opp uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_item(p_meeting uuid, p_kind text, p_title text, p_student uuid, p_record uuid, p_opp uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meeting_minute(p_meeting uuid, p_ended time without time zone) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meeting_minute(p_meeting uuid, p_ended time without time zone) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_minute(p_meeting uuid, p_ended time without time zone) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meeting_vote(p_item uuid, p_vote text, p_note text, p_change_note text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meeting_vote(p_item uuid, p_vote text, p_note text, p_change_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_vote(p_item uuid, p_vote text, p_note text, p_change_note text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_meetings_list(p_school uuid, p_committee text, p_status text, p_days integer) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_meetings_list(p_school uuid, p_committee text, p_status text, p_days integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meetings_list(p_school uuid, p_committee text, p_status text, p_days integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_merits() TO anon;
GRANT EXECUTE ON FUNCTION public.v2_merits() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_merits() TO service_role;
REVOKE ALL ON FUNCTION public.v2_my_duties(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_duties(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_duties(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_my_now(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_now(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_now(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_my_roles() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_roles() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_roles() TO service_role;
REVOKE ALL ON FUNCTION public.v2_my_schools() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_schools() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_schools() TO service_role;
REVOKE ALL ON FUNCTION public.v2_my_sections(p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_sections(p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_sections(p_date date) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_opp_card(p_opp uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_opp_card(p_opp uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_card(p_opp uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_opp_close(p_opp uuid, p_why text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_opp_close(p_opp uuid, p_why text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_close(p_opp uuid, p_why text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_opp_join(p_opp uuid, p_student uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_opp_join(p_opp uuid, p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_join(p_opp uuid, p_student uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_opp_open(p_school uuid, p_merit integer, p_kind text, p_title text, p_when text, p_capacity smallint, p_held_by uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_opp_open(p_school uuid, p_merit integer, p_kind text, p_title text, p_when text, p_capacity smallint, p_held_by uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_open(p_school uuid, p_merit integer, p_kind text, p_title text, p_when text, p_capacity smallint, p_held_by uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_opp_plan(p_opp uuid, p_note text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_opp_plan(p_opp uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_plan(p_opp uuid, p_note text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_opps_list(p_school uuid, p_state text, p_days integer) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_opps_list(p_school uuid, p_state text, p_days integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opps_list(p_school uuid, p_state text, p_days integer) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_opps_open_for(p_student uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_opps_open_for(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opps_open_for(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_outbox_pull(p_limit integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_outbox_pull(p_limit integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_outbox_pull(p_limit integer) TO service_role;
REVOKE ALL ON FUNCTION public.v2_outbox_result(p_id uuid, p_ok boolean, p_ref text, p_err text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_outbox_result(p_id uuid, p_ok boolean, p_ref text, p_err text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_outbox_result(p_id uuid, p_ok boolean, p_ref text, p_err text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_pending_excuses(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_pending_excuses(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_pending_excuses(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_period_list(p_section uuid, p_period smallint, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_period_list(p_section uuid, p_period smallint, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_period_list(p_section uuid, p_period smallint, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_period_summary(p_section uuid, p_period smallint, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_period_summary(p_section uuid, p_period smallint, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_period_summary(p_section uuid, p_period smallint, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_practices(p_scope text, p_polarity text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_practices(p_scope text, p_polarity text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_practices(p_scope text, p_polarity text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_queue_messages(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_queue_messages(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_queue_messages(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_record_arrival(p_student uuid, p_date date, p_arrived time without time zone, p_decision text, p_term smallint, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_record_arrival(p_student uuid, p_date date, p_arrived time without time zone, p_decision text, p_term smallint, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_record_arrival(p_student uuid, p_date date, p_arrived time without time zone, p_decision text, p_term smallint, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_record_assembly(p_student uuid, p_date date, p_state text, p_term smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_record_assembly(p_student uuid, p_date date, p_state text, p_term smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_record_assembly(p_student uuid, p_date date, p_state text, p_term smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_record_behavior(p_student uuid, p_problem integer, p_place text, p_note text, p_period smallint, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_record_behavior(p_student uuid, p_problem integer, p_place text, p_note text, p_period smallint, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_record_behavior(p_student uuid, p_problem integer, p_place text, p_note text, p_period smallint, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_record_dismissal(p_student uuid, p_date date, p_left time without time zone, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_record_dismissal(p_student uuid, p_date date, p_left time without time zone, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_record_dismissal(p_student uuid, p_date date, p_left time without time zone, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_record_period(p_student uuid, p_period smallint, p_state text, p_date date, p_minutes smallint, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_record_period(p_student uuid, p_period smallint, p_state text, p_date date, p_minutes smallint, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_record_period(p_student uuid, p_period smallint, p_state text, p_date date, p_minutes smallint, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_record_practice(p_student uuid, p_code text, p_period smallint, p_subject text, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_record_practice(p_student uuid, p_code text, p_period smallint, p_subject text, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_record_practice(p_student uuid, p_code text, p_period smallint, p_subject text, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_reopen_day(p_school uuid, p_date date, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_reopen_day(p_school uuid, p_date date, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_reopen_day(p_school uuid, p_date date, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_section_timetable(p_section uuid, p_term smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_section_timetable(p_section uuid, p_term smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_section_timetable(p_section uuid, p_term smallint) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_session_add(p_case uuid, p_on date, p_minutes smallint, p_discussed text, p_response text, p_next text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_session_add(p_case uuid, p_on date, p_minutes smallint, p_discussed text, p_response text, p_next text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_session_add(p_case uuid, p_on date, p_minutes smallint, p_discussed text, p_response text, p_next text) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_setting_rows(p_key text, p_school uuid) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_setting_rows(p_key text, p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_setting_rows(p_key text, p_school uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_setting_update(p_key text, p_id text, p_patch jsonb) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_setting_update(p_key text, p_id text, p_patch jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_setting_update(p_key text, p_id text, p_patch jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_settings_catalog() TO anon;
GRANT EXECUTE ON FUNCTION public.v2_settings_catalog() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_settings_catalog() TO service_role;
REVOKE ALL ON FUNCTION public.v2_staff_list(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_staff_list(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_staff_list(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_student_absence_tasks(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_student_absence_tasks(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_student_absence_tasks(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_student_card(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_student_card(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_student_card(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_student_tasks(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_student_tasks(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_student_tasks(p_student uuid) TO service_role;
GRANT EXECUTE ON FUNCTION public.v2_student_timeline(p_student uuid, p_as text) TO anon;
GRANT EXECUTE ON FUNCTION public.v2_student_timeline(p_student uuid, p_as text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_student_timeline(p_student uuid, p_as text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_by text, p_channel text, p_excuse_item smallint, p_attachment_name text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_by text, p_channel text, p_excuse_item smallint, p_attachment_name text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_by text, p_channel text, p_excuse_item smallint, p_attachment_name text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_task_delegate(p_task uuid, p_person uuid, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_task_delegate(p_task uuid, p_person uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_task_delegate(p_task uuid, p_person uuid, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_task_done(p_task uuid, p_ev jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_task_done(p_task uuid, p_ev jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_task_done(p_task uuid, p_ev jsonb) TO service_role;
REVOKE ALL ON FUNCTION public.v2_task_skip(p_task uuid, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_task_skip(p_task uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_task_skip(p_task uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_undo_practice(p_record uuid, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_undo_practice(p_record uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_undo_practice(p_record uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_weekday(p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_weekday(p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_weekday(p_date date) TO service_role;
-- دوالٌّ بلا ACL صريح (الافتراضيّ: EXECUTE لـ PUBLIC): 59

