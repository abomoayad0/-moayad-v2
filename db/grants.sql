-- grants.sql
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.

-- ── grants · md5 75292c4276d691d7c85496d7aa0df9a3
GRANT USAGE ON SCHEMA v2 TO authenticated;



REVOKE ALL ON FUNCTION v2.acting_posts(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.acting_posts(p_school uuid) TO authenticated;
REVOKE ALL ON FUNCTION v2.acting_school() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.acting_school() TO authenticated;
REVOKE ALL ON FUNCTION v2.ar_num(n numeric) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.ar_num(n numeric) TO authenticated;
REVOKE ALL ON FUNCTION v2.arrival_state(p_school uuid, p_at time without time zone) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.arrival_state(p_school uuid, p_at time without time zone) TO authenticated;
REVOKE ALL ON FUNCTION v2.assert_grant(p_allowed text[], p_what text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.assert_grant(p_allowed text[], p_what text) TO authenticated;
REVOKE ALL ON FUNCTION v2.assert_my_child(p_student uuid, p_what text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.assert_my_child(p_student uuid, p_what text) TO authenticated;
REVOKE ALL ON FUNCTION v2.assert_my_school(p_school uuid, p_what text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.assert_my_school(p_school uuid, p_what text) TO authenticated;
REVOKE ALL ON FUNCTION v2.assert_my_student(p_student uuid, p_what text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.assert_my_student(p_student uuid, p_what text) TO authenticated;
REVOKE ALL ON FUNCTION v2.assert_role(p_allowed text[], p_what text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.assert_student_or_kin(p_student uuid, p_what text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.assert_student_or_kin(p_student uuid, p_what text) TO authenticated;
REVOKE ALL ON FUNCTION v2.attachment_allows(p_path text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.attachment_allows(p_path text) TO authenticated;
REVOKE ALL ON FUNCTION v2.attachment_guardian_ok(p_path text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.attachment_guardian_ok(p_path text) TO authenticated;
REVOKE ALL ON FUNCTION v2.behavior_score(p_student uuid, p_year uuid, p_term smallint) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.brand_path_allows(p_path text, p_write boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.brand_path_allows(p_path text, p_write boolean) TO authenticated;
REVOKE ALL ON FUNCTION v2.caller_kind(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.caller_kind(p_student uuid) TO authenticated;
REVOKE ALL ON FUNCTION v2.can_do(p_allowed text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.can_do(p_allowed text[]) TO authenticated;
REVOKE ALL ON FUNCTION v2.committee_rule(p_school uuid, p_committee text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.committee_rule(p_school uuid, p_committee text) TO authenticated;
REVOKE ALL ON FUNCTION v2.current_person() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.current_person() TO authenticated;
REVOKE ALL ON FUNCTION v2.current_tenant() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.current_tenant() TO authenticated;
REVOKE ALL ON FUNCTION v2.degree_ar(n integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.degree_ar(n integer) TO authenticated;
REVOKE ALL ON FUNCTION v2.enrol_reason_ar(k text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.enrol_reason_ar(k text) TO authenticated;
REVOKE ALL ON FUNCTION v2.evidence_exists(p_path text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.evidence_exists(p_path text) TO authenticated;
REVOKE ALL ON FUNCTION v2.evidence_ok(p_entry uuid, p_path text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.evidence_ok(p_entry uuid, p_path text) TO authenticated;
REVOKE ALL ON FUNCTION v2.evidence_path_for(p_entry uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.evidence_path_for(p_entry uuid) TO authenticated;
REVOKE ALL ON FUNCTION v2.fn_absence_days(p_student uuid, p_year uuid, p_excused boolean) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_absence_task_done(p_task uuid, p_ev jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_accept_excuse(p_claim uuid, p_by uuid, p_note text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_acknowledge_mail(p_ack uuid, p_signed boolean, p_kind text, p_refused boolean, p_reason text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_act_as(p_role text, p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_action_items_expanded(p_action integer) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_add_working_days(p_school uuid, p_from date, p_days integer) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_apply_absence(p_student uuid, p_date date, p_term smallint, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_approve_mail_item(p_item uuid, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_attendance_balance(p_student uuid, p_year uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_attendance_state(p_student uuid, p_year uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_audit() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_behavior_balance(p_student uuid, p_year uuid, p_term smallint) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_clear_test(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.fn_clear_test(p_school uuid) TO authenticated;
REVOKE ALL ON FUNCTION v2.fn_close(p_school text, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_close_day(p_school uuid, p_date date, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_close_day_inner(p_school uuid, p_date date, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_conduct_list(p_stage text, p_mode text, p_target text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_day_classes(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_day_kind(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_day_list(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_day_log(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_day_summary(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_decide_excuse(p_claim uuid, p_accept boolean, p_by uuid, p_note text, p_principal_ext boolean) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_default_role() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_digits(p text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_display_name(p_name text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_duty_autofill(p_school uuid, p_weekday smallint, p_zone text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_duty_eligible(p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_duty_today(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_entitlement(p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_errors(p_days integer, p_kind text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_excuse_window(p_school uuid, p_absence date, p_submitted date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_find_student(p_q text, p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form(p_form smallint, p_student uuid, p_ref uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form_auto(p_form smallint, p_doc jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form_core(p_form smallint, p_student uuid, p_ref uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form_deliver(p_entry uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form_derive(p_form smallint, p_data jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form_derive(p_form smallint, p_data jsonb, p_doc jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form_fields(p_form smallint, p_doc jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form_kv(p_form smallint, p_doc jsonb, p_data jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form_rows(p_form smallint, p_doc jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_form_strip(p_form smallint, p_data jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_guardian_me() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_is_excused(p_student uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_load_balance(p_school uuid, p_year uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_log_error(p_message text, p_fn text, p_screen text, p_action text, p_params jsonb, p_sqlstate text, p_detail text, p_hint text, p_context text, p_source text, p_kind text, p_ua text, p_url text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_log_incoming(p_school uuid, p_from text, p_subject text, p_received date, p_body text, p_ref text, p_secrecy text, p_doc_date date, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_mail_state(p_mail uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_me() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_missing(k v2.evidence_kinds, p_ev jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_my_duties(p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_my_now(p_school uuid, p_at timestamp with time zone) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_my_roles() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.fn_my_roles() TO authenticated;
REVOKE ALL ON FUNCTION v2.fn_my_schools() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_norm_ar(p text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_open_counsel_case(p_record uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_pending_excuses(p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_period_list(p_section uuid, p_period smallint, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_period_summary(p_section uuid, p_period smallint, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_person_silence() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_practice_balance(p_student uuid, p_year uuid, p_term smallint) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_queue_messages(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_quick_day(p_school text, p_date date, p_absent text[], p_late text[], p_late_minutes smallint, p_missed_assembly text[], p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_arrival(p_student uuid, p_date date, p_arrived time without time zone, p_decision text, p_term smallint, p_by uuid, p_note text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_assembly(p_student uuid, p_date date, p_state text, p_term smallint, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_attendance(p_student uuid, p_date date, p_state text, p_term smallint, p_minutes_late smallint, p_note text, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_behavior(p_student uuid, p_problem integer, p_term smallint, p_period smallint, p_place text, p_note text, p_victim uuid, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_dismissal(p_student uuid, p_date date, p_left time without time zone, p_reason text, p_term smallint, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_period(p_student uuid, p_date date, p_period smallint, p_state text, p_subject text, p_teacher uuid, p_minutes_late smallint, p_term smallint, p_note text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_period(p_student uuid, p_period smallint, p_state text, p_date date, p_minutes smallint, p_note text, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_permission(p_student uuid, p_date date, p_out time without time zone, p_reason text, p_requested_by text, p_periods smallint[], p_term smallint, p_by uuid, p_back time without time zone) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_practice(p_student uuid, p_code text, p_period smallint, p_subject text, p_note text, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_record_segment(p_student uuid, p_date date, p_segment text, p_state text, p_by uuid, p_term smallint, p_note text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_register_attendance(p_school uuid, p_year uuid, p_from date, p_to date, p_grade smallint, p_section text, p_student uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_register_rollup(p_level text, p_school uuid, p_year uuid, p_from date, p_to date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_reopen_day(p_school uuid, p_date date, p_reason text, p_by uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_school_days(p_school uuid, p_from date, p_to date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_section_timetable(p_section uuid, p_term smallint) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_send_prenotice(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_student_card(p_student uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_submit_excuse(p_student uuid, p_from date, p_to date, p_by text, p_channel text, p_excuse_item smallint, p_reason text, p_attachment text, p_attachment_name text, p_submitted date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_task_done(p_task uuid, p_ev jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_teaching_load(p_person uuid, p_year uuid, p_term smallint) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_term_of(p_school uuid, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_test_mode(p_school text, p_on boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.fn_test_mode(p_school text, p_on boolean) TO authenticated;
REVOKE ALL ON FUNCTION v2.fn_to_hijri(p date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_today(p_school text, p_date date) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_undo_practice(p_record uuid, p_reason text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.fn_year_open_guard() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_attendee_identity() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_event_visibility() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_grade_rules() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_guest_no_vote() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_item_needs_meeting() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_meeting_flow() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_open_case_on_refer() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_report_needs_sessions() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_session_needs_case() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_verdict_needs_filing() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.g_vote_allowed() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.grade_ar(g smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.grade_ar(g smallint) TO authenticated;
REVOKE ALL ON FUNCTION v2.has_post(p_posts text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.has_post(p_posts text[]) TO authenticated;
REVOKE ALL ON FUNCTION v2.is_absent_today(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.is_absent_today(p_student uuid) TO authenticated;
REVOKE ALL ON FUNCTION v2.is_counselor(p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.is_test_school(p_school uuid) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.ladder_auto(p_record uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.ladder_auto(p_record uuid) TO authenticated;
REVOKE ALL ON FUNCTION v2.log_action(p_school uuid, p_student uuid, p_action text, p_action_ar text, p_ref_table text, p_ref_id uuid, p_detail jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.log_action(p_school uuid, p_student uuid, p_action text, p_action_ar text, p_ref_table text, p_ref_id uuid, p_detail jsonb) TO authenticated;
REVOKE ALL ON FUNCTION v2.merit_path_allows(p_path text, p_write boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.merit_path_allows(p_path text, p_write boolean) TO authenticated;
REVOKE ALL ON FUNCTION v2.my_grant() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.my_grant() TO authenticated;
REVOKE ALL ON FUNCTION v2.my_posts() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.my_posts() TO authenticated;
REVOKE ALL ON FUNCTION v2.my_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.my_role() TO authenticated;
REVOKE ALL ON FUNCTION v2.my_school(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.my_school(p_school uuid) TO authenticated;
REVOKE ALL ON FUNCTION v2.my_seat(p_school uuid, p_committee text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.ord_ar(n integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.ord_ar(n integer) TO authenticated;
REVOKE ALL ON FUNCTION v2.owner_ar(p text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.owner_ar(p text) TO authenticated;
REVOKE ALL ON FUNCTION v2.page_ar(p text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.page_ar(p text) TO authenticated;
REVOKE ALL ON FUNCTION v2.plain_ar(t text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.plain_ar(t text) TO authenticated;
REVOKE ALL ON FUNCTION v2.quorum_of(p_school uuid, p_committee text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.quorum_of(p_school uuid, p_committee text) TO authenticated;
REVOKE ALL ON FUNCTION v2.role_ar(p text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.role_ar(p text) TO authenticated;
REVOKE ALL ON FUNCTION v2.seat_ar(p text) FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.seat_cap(p_school uuid, p_committee text, p_seat_role text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.seat_cap(p_school uuid, p_committee text, p_seat_role text) TO authenticated;
REVOKE ALL ON FUNCTION v2.stage_ar(p text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.stage_ar(p text) TO authenticated;
REVOKE ALL ON FUNCTION v2.task_form_no(p_kind text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.task_form_no(p_kind text) TO authenticated;
REVOKE ALL ON FUNCTION v2.term_of_strict(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.term_of_strict(p_school uuid, p_date date) TO authenticated;
REVOKE ALL ON FUNCTION v2.time_ar(t time without time zone) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.time_ar(t time without time zone) TO authenticated;
REVOKE ALL ON FUNCTION v2.trg_abs_task_evidence() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.trg_attendance_calendar_guard() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.trg_day_closed_guard() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.trg_mark_test() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.trg_period_guard() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.trg_task_evidence() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.trg_tt_clash() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.trg_tt_period() FROM PUBLIC;

REVOKE ALL ON FUNCTION v2.url_enc(t text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.url_enc(t text) TO authenticated;
REVOKE ALL ON FUNCTION v2.workdays_after(p_school uuid, p_from date, p_n integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION v2.workdays_after(p_school uuid, p_from date, p_n integer) TO authenticated;
REVOKE ALL ON FUNCTION v2.wrap(p_fn text, p_sql text, p_params jsonb) FROM PUBLIC;

REVOKE ALL ON FUNCTION public.v2_absence_task_delegate(p_task uuid, p_person uuid, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_delegate(p_task uuid, p_person uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_delegate(p_task uuid, p_person uuid, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_absence_task_done(p_task uuid, p_ev jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_done(p_task uuid, p_ev jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_done(p_task uuid, p_ev jsonb) TO service_role;
REVOKE ALL ON FUNCTION public.v2_absence_task_skip(p_task uuid, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_skip(p_task uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_absence_task_skip(p_task uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_account_toggle(p_person uuid, p_active boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_account_toggle(p_person uuid, p_active boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_account_toggle(p_person uuid, p_active boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_accounts_board(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_accounts_board(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_accounts_board(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_act_as(p_role text, p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_act_as(p_role text, p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_act_as(p_role text, p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_action_log(p_school uuid, p_student uuid, p_limit integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_action_log(p_school uuid, p_student uuid, p_limit integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_action_log(p_school uuid, p_student uuid, p_limit integer) TO service_role;
REVOKE ALL ON FUNCTION public.v2_advice_for(p_problem integer, p_occurrence smallint, p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_advice_for(p_problem integer, p_occurrence smallint, p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_advice_for(p_problem integer, p_occurrence smallint, p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_advice_save(p_school uuid, p_problem integer, p_occurrence smallint, p_text text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_advice_save(p_school uuid, p_problem integer, p_occurrence smallint, p_text text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_advice_save(p_school uuid, p_problem integer, p_occurrence smallint, p_text text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_age_ar(p_birth date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_age_ar(p_birth date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_age_ar(p_birth date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_arrival_check(p_school uuid, p_at time without time zone) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_arrival_check(p_school uuid, p_at time without time zone) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_arrival_check(p_school uuid, p_at time without time zone) TO service_role;
REVOKE ALL ON FUNCTION public.v2_assign_add(p_school uuid, p_person uuid, p_post text, p_letter_no text, p_letter_date date, p_started_on date, p_entitled boolean, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_assign_add(p_school uuid, p_person uuid, p_post text, p_letter_no text, p_letter_date date, p_started_on date, p_entitled boolean, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_assign_add(p_school uuid, p_person uuid, p_post text, p_letter_no text, p_letter_date date, p_started_on date, p_entitled boolean, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_assign_end(p_assignment uuid, p_ended_on date, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_assign_end(p_assignment uuid, p_ended_on date, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_assign_end(p_assignment uuid, p_ended_on date, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_attach(p_student uuid, p_kind text, p_file_name text, p_storage_path text, p_mime text, p_size_kb integer, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_attach(p_student uuid, p_kind text, p_file_name text, p_storage_path text, p_mime text, p_size_kb integer, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_attach(p_student uuid, p_kind text, p_file_name text, p_storage_path text, p_mime text, p_size_kb integer, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_attachments(p_student uuid, p_kind text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_attachments(p_student uuid, p_kind text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_attachments(p_student uuid, p_kind text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_bank(p_key text, p_problem integer, p_school uuid, p_all boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_bank(p_key text, p_problem integer, p_school uuid, p_all boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_bank(p_key text, p_problem integer, p_school uuid, p_all boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_bank_save(p_school uuid, p_id uuid, p_key text, p_problem integer, p_text text, p_ord smallint, p_active boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_bank_save(p_school uuid, p_id uuid, p_key text, p_problem integer, p_text text, p_ord smallint, p_active boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_bank_save(p_school uuid, p_id uuid, p_key text, p_problem integer, p_text text, p_ord smallint, p_active boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_brand_card(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_brand_card(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_brand_card(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_brand_save(p_school uuid, p_logo_path text, p_logo_position text, p_show_ministry boolean, p_primary text, p_accent text, p_header text, p_footer text, p_clear text[]) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_brand_save(p_school uuid, p_logo_path text, p_logo_position text, p_show_ministry boolean, p_primary text, p_accent text, p_header text, p_footer text, p_clear text[]) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_brand_save(p_school uuid, p_logo_path text, p_logo_position text, p_show_ministry boolean, p_primary text, p_accent text, p_header text, p_footer text, p_clear text[]) TO service_role;
REVOKE ALL ON FUNCTION public.v2_brand_upload_path(p_school uuid, p_kind text, p_ext text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_brand_upload_path(p_school uuid, p_kind text, p_ext text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_brand_upload_path(p_school uuid, p_kind text, p_ext text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_branding(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_branding(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_branding(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_break_remove(p_school uuid, p_break uuid, p_why text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_break_remove(p_school uuid, p_break uuid, p_why text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_break_remove(p_school uuid, p_break uuid, p_why text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_break_save(p_school uuid, p_break uuid, p_kind text, p_label text, p_starts time without time zone, p_ends time without time zone, p_after smallint, p_needs_duty boolean, p_min_staff smallint, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_break_save(p_school uuid, p_break uuid, p_kind text, p_label text, p_starts time without time zone, p_ends time without time zone, p_after smallint, p_needs_duty boolean, p_min_staff smallint, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_break_save(p_school uuid, p_break uuid, p_kind text, p_label text, p_starts time without time zone, p_ends time without time zone, p_after smallint, p_needs_duty boolean, p_min_staff smallint, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_breaks(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_breaks(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_breaks(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_calendar_board(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_calendar_board(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_calendar_board(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_case_card(p_case uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_case_card(p_case uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_case_card(p_case uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_case_report(p_case uuid, p_opinion text, p_recommend text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_case_report(p_case uuid, p_opinion text, p_recommend text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_case_report(p_case uuid, p_opinion text, p_recommend text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_case_report_card(p_student uuid, p_problem integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_case_report_card(p_student uuid, p_problem integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_case_report_card(p_student uuid, p_problem integer) TO service_role;
REVOKE ALL ON FUNCTION public.v2_case_write(p_case uuid, p_student_view text, p_observed text, p_factors text, p_plan text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_case_write(p_case uuid, p_student_view text, p_observed text, p_factors text, p_plan text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_case_write(p_case uuid, p_student_view text, p_observed text, p_factors text, p_plan text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_census_assign(p_student uuid, p_task uuid, p_person uuid, p_days smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_census_assign(p_student uuid, p_task uuid, p_person uuid, p_days smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_census_assign(p_student uuid, p_task uuid, p_person uuid, p_days smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_census_file(p_census uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_suggestion text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_census_file(p_census uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_suggestion text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_census_file(p_census uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_suggestion text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_census_item_save(p_school uuid, p_item uuid, p_polarity text, p_icon text, p_text text, p_hint text, p_ord smallint, p_active boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_census_item_save(p_school uuid, p_item uuid, p_polarity text, p_icon text, p_text text, p_hint text, p_ord smallint, p_active boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_census_item_save(p_school uuid, p_item uuid, p_polarity text, p_icon text, p_text text, p_hint text, p_ord smallint, p_active boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_census_list(p_school uuid, p_all boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_census_list(p_school uuid, p_all boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_census_list(p_school uuid, p_all boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_census_of(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_census_of(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_census_of(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_census_review(p_census uuid, p_accept boolean, p_why text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_census_review(p_census uuid, p_accept boolean, p_why text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_census_review(p_census uuid, p_accept boolean, p_why text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_census_self(p_student uuid, p_task uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_limit text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_census_self(p_student uuid, p_task uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_limit text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_census_self(p_student uuid, p_task uuid, p_neg uuid[], p_pos uuid[], p_causes text, p_limit text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_census_sweep(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_census_sweep(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_census_sweep(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_close_day(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_close_day(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_close_day(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_board(p_school uuid, p_committee text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_board(p_school uuid, p_committee text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_board(p_school uuid, p_committee text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_close(p_school uuid, p_committee text, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_close(p_school uuid, p_committee text, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_close(p_school uuid, p_committee text, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_create(p_school uuid, p_key text, p_label text, p_purpose text, p_seats jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_create(p_school uuid, p_key text, p_label text, p_purpose text, p_seats jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_create(p_school uuid, p_key text, p_label text, p_purpose text, p_seats jsonb) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_duties(p_school uuid, p_committee text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_duties(p_school uuid, p_committee text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_duties(p_school uuid, p_committee text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_duty_save(p_school uuid, p_committee text, p_duty uuid, p_text text, p_cadence text, p_ord smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_duty_save(p_school uuid, p_committee text, p_duty uuid, p_text text, p_cadence text, p_ord smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_duty_save(p_school uuid, p_committee text, p_duty uuid, p_text text, p_cadence text, p_ord smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_quorum(p_school uuid, p_committee text, p_min smallint, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_quorum(p_school uuid, p_committee text, p_min smallint, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_quorum(p_school uuid, p_committee text, p_min smallint, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_rules(p_school uuid, p_committee text, p_quorum smallint, p_allow_remote boolean, p_tie_rule text, p_note text, p_quorum_mode text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_rules(p_school uuid, p_committee text, p_quorum smallint, p_allow_remote boolean, p_tie_rule text, p_note text, p_quorum_mode text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_rules(p_school uuid, p_committee text, p_quorum smallint, p_allow_remote boolean, p_tie_rule text, p_note text, p_quorum_mode text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_rules_get(p_school uuid, p_committee text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_rules_get(p_school uuid, p_committee text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_rules_get(p_school uuid, p_committee text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_seat(p_school uuid, p_committee text, p_seat_role text, p_person uuid, p_post_key text, p_nominated_by text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat(p_school uuid, p_committee text, p_seat_role text, p_person uuid, p_post_key text, p_nominated_by text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat(p_school uuid, p_committee text, p_seat_role text, p_person uuid, p_post_key text, p_nominated_by text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_seat_count(p_school uuid, p_committee text, p_seat_role text, p_count smallint, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat_count(p_school uuid, p_committee text, p_seat_role text, p_count smallint, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_seat_count(p_school uuid, p_committee text, p_seat_role text, p_count smallint, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_task_done(p_item uuid, p_note text, p_evidence text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_task_done(p_item uuid, p_note text, p_evidence text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_task_done(p_item uuid, p_note text, p_evidence text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committee_unseat(p_school uuid, p_committee text, p_person uuid, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committee_unseat(p_school uuid, p_committee text, p_person uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committee_unseat(p_school uuid, p_committee text, p_person uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_committees_list(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_committees_list(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_committees_list(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_conduct_list(p_student uuid, p_mode text, p_target text, p_stage text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_conduct_list(p_student uuid, p_mode text, p_target text, p_stage text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_conduct_list(p_student uuid, p_mode text, p_target text, p_stage text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_contact_log(p_student uuid, p_task uuid, p_channel text, p_outcome text, p_summary text, p_guardian_say text, p_at time without time zone, p_right_number text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_contact_log(p_student uuid, p_task uuid, p_channel text, p_outcome text, p_summary text, p_guardian_say text, p_at time without time zone, p_right_number text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_contact_log(p_student uuid, p_task uuid, p_channel text, p_outcome text, p_summary text, p_guardian_say text, p_at time without time zone, p_right_number text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_contacts_of(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_contacts_of(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_contacts_of(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_counsel_board(p_school uuid, p_state text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_counsel_board(p_school uuid, p_state text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_counsel_board(p_school uuid, p_state text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_day_build(p_school uuid, p_assembly time without time zone, p_period_minutes smallint, p_periods smallint, p_breaks jsonb, p_apply text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_day_build(p_school uuid, p_assembly time without time zone, p_period_minutes smallint, p_periods smallint, p_breaks jsonb, p_apply text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_day_build(p_school uuid, p_assembly time without time zone, p_period_minutes smallint, p_periods smallint, p_breaks jsonb, p_apply text) TO service_role;
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
REVOKE ALL ON FUNCTION public.v2_day_plan(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_day_plan(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_day_plan(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_day_rules(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_day_rules(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_day_rules(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_day_summary(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_day_summary(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_day_summary(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_decide_excuse(p_claim uuid, p_accept boolean, p_note text, p_principal_ext boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_decide_excuse(p_claim uuid, p_accept boolean, p_note text, p_principal_ext boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_decide_excuse(p_claim uuid, p_accept boolean, p_note text, p_principal_ext boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_default_role() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_default_role() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_default_role() TO service_role;
REVOKE ALL ON FUNCTION public.v2_delegate_add(p_school uuid, p_post text, p_to uuid, p_starts date, p_ends date, p_reason text, p_letter text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_delegate_add(p_school uuid, p_post text, p_to uuid, p_starts date, p_ends date, p_reason text, p_letter text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_delegate_add(p_school uuid, p_post text, p_to uuid, p_starts date, p_ends date, p_reason text, p_letter text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_delegate_revoke(p_delegation uuid, p_why text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_delegate_revoke(p_delegation uuid, p_why text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_delegate_revoke(p_delegation uuid, p_why text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_delegations_board(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_delegations_board(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_delegations_board(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_draft_apply(p_draft uuid, p_confirm text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_draft_apply(p_draft uuid, p_confirm text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_draft_apply(p_draft uuid, p_confirm text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_draft_cancel(p_draft uuid, p_why text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_draft_cancel(p_draft uuid, p_why text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_draft_cancel(p_draft uuid, p_why text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_draft_card(p_draft uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_draft_card(p_draft uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_draft_card(p_draft uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_drafts_list(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_drafts_list(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_drafts_list(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_duty_autofill(p_school uuid, p_weekday smallint, p_zone text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_duty_autofill(p_school uuid, p_weekday smallint, p_zone text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_duty_autofill(p_school uuid, p_weekday smallint, p_zone text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_duty_cadences() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_duty_cadences() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_duty_cadences() TO service_role;
REVOKE ALL ON FUNCTION public.v2_duty_eligible(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_duty_eligible(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_duty_eligible(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_duty_today(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_duty_today(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_duty_today(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_enrol_reasons() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_enrol_reasons() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_enrol_reasons() TO service_role;
REVOKE ALL ON FUNCTION public.v2_enrolment_end(p_school uuid, p_student uuid, p_reason text, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_enrolment_end(p_school uuid, p_student uuid, p_reason text, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_enrolment_end(p_school uuid, p_student uuid, p_reason text, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_entries_pending(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_entries_pending(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_entries_pending(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_entry_delegate(p_entry uuid, p_person uuid, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_entry_delegate(p_entry uuid, p_person uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_entry_delegate(p_entry uuid, p_person uuid, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_entry_file(p_entry uuid, p_what text, p_evidence_path text, p_evidence_desc text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_entry_file(p_entry uuid, p_what text, p_evidence_path text, p_evidence_desc text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_entry_file(p_entry uuid, p_what text, p_evidence_path text, p_evidence_desc text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_entry_grade(p_entry uuid, p_points numeric, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_entry_grade(p_entry uuid, p_points numeric, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_entry_grade(p_entry uuid, p_points numeric, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_entry_verdict(p_entry uuid, p_verdict text, p_note text, p_file text) FROM PUBLIC;
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
REVOKE ALL ON FUNCTION public.v2_exception_add(p_school uuid, p_rule_kind text, p_rule_ref text, p_system_says text, p_school_does text, p_reason text, p_source text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_exception_add(p_school uuid, p_rule_kind text, p_rule_ref text, p_system_says text, p_school_does text, p_reason text, p_source text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_exception_add(p_school uuid, p_rule_kind text, p_rule_ref text, p_system_says text, p_school_does text, p_reason text, p_source text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_exception_kinds() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_exception_kinds() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_exception_kinds() TO service_role;
REVOKE ALL ON FUNCTION public.v2_exceptions_board(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_exceptions_board(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_exceptions_board(p_school uuid) TO service_role;
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
REVOKE ALL ON FUNCTION public.v2_forms_catalog(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_forms_catalog(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_forms_catalog(p_school uuid) TO service_role;
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
REVOKE ALL ON FUNCTION public.v2_guardian_message(p_record uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_message(p_record uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_message(p_record uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_pending(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_pending(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_pending(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_read(p_event uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_read(p_event uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_read(p_event uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_reply(p_student uuid, p_event uuid, p_kind text, p_reply text, p_note text, p_suggested date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_reply(p_student uuid, p_event uuid, p_kind text, p_reply text, p_note text, p_suggested date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_reply(p_student uuid, p_event uuid, p_kind text, p_reply text, p_note text, p_suggested date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_save(p_student uuid, p_guardian uuid, p_full_name text, p_relation text, p_national_id text, p_phone text, p_work_phone text, p_home_phone text, p_workplace text, p_is_primary boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_save(p_student uuid, p_guardian uuid, p_full_name text, p_relation text, p_national_id text, p_phone text, p_work_phone text, p_home_phone text, p_workplace text, p_is_primary boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_save(p_student uuid, p_guardian uuid, p_full_name text, p_relation text, p_national_id text, p_phone text, p_work_phone text, p_home_phone text, p_workplace text, p_is_primary boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardian_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_attachment_name text, p_excuse_item smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardian_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_attachment_name text, p_excuse_item smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardian_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_attachment_name text, p_excuse_item smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_guardians_of(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_guardians_of(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_guardians_of(p_student uuid) TO service_role;
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
REVOKE ALL ON FUNCTION public.v2_meeting_approve(p_meeting uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_approve(p_meeting uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_approve(p_meeting uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_attend(p_meeting uuid, p_person uuid, p_state text, p_excuse text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meeting_call(p_school uuid, p_committee text, p_kind text, p_held_on date, p_started time without time zone, p_place text, p_agenda text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_call(p_school uuid, p_committee text, p_kind text, p_held_on date, p_started time without time zone, p_place text, p_agenda text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_call(p_school uuid, p_committee text, p_kind text, p_held_on date, p_started time without time zone, p_place text, p_agenda text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meeting_card(p_meeting uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_card(p_meeting uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_card(p_meeting uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meeting_carry_over(p_meeting uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_carry_over(p_meeting uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_carry_over(p_meeting uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_close_item(p_item uuid, p_body text, p_decision text, p_recommend text, p_owner uuid, p_due date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meeting_invite(p_meeting uuid, p_kind text, p_person uuid, p_student uuid, p_guardian uuid, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_invite(p_meeting uuid, p_kind text, p_person uuid, p_student uuid, p_guardian uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_invite(p_meeting uuid, p_kind text, p_person uuid, p_student uuid, p_guardian uuid, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meeting_item(p_meeting uuid, p_kind text, p_title text, p_student uuid, p_record uuid, p_opp uuid, p_duty uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_item(p_meeting uuid, p_kind text, p_title text, p_student uuid, p_record uuid, p_opp uuid, p_duty uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_item(p_meeting uuid, p_kind text, p_title text, p_student uuid, p_record uuid, p_opp uuid, p_duty uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meeting_minute(p_meeting uuid, p_ended time without time zone) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_minute(p_meeting uuid, p_ended time without time zone) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_minute(p_meeting uuid, p_ended time without time zone) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meeting_vote(p_item uuid, p_vote text, p_note text, p_change_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meeting_vote(p_item uuid, p_vote text, p_note text, p_change_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meeting_vote(p_item uuid, p_vote text, p_note text, p_change_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_meetings_list(p_school uuid, p_committee text, p_status text, p_days integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_meetings_list(p_school uuid, p_committee text, p_status text, p_days integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_meetings_list(p_school uuid, p_committee text, p_status text, p_days integer) TO service_role;
REVOKE ALL ON FUNCTION public.v2_merits() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_merits() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_merits() TO service_role;
REVOKE ALL ON FUNCTION public.v2_message_template(p_school uuid, p_key text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_message_template(p_school uuid, p_key text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_message_template(p_school uuid, p_key text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_message_template_save(p_school uuid, p_key text, p_body text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_message_template_save(p_school uuid, p_key text, p_body text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_message_template_save(p_school uuid, p_key text, p_body text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_my_acting(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_acting(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_acting(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_my_census(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_census(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_census(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_my_committee_tasks(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_committee_tasks(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_committee_tasks(p_school uuid) TO service_role;
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
REVOKE ALL ON FUNCTION public.v2_my_score(p_student uuid, p_term smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_score(p_student uuid, p_term smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_score(p_student uuid, p_term smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_my_sections(p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_my_sections(p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_my_sections(p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_now_slot(p_school uuid, p_at time without time zone) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_now_slot(p_school uuid, p_at time without time zone) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_now_slot(p_school uuid, p_at time without time zone) TO service_role;
REVOKE ALL ON FUNCTION public.v2_opp_card(p_opp uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_opp_card(p_opp uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_card(p_opp uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_opp_close(p_opp uuid, p_why text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_opp_close(p_opp uuid, p_why text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_close(p_opp uuid, p_why text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_opp_join(p_opp uuid, p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_opp_join(p_opp uuid, p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_join(p_opp uuid, p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_opp_open(p_school uuid, p_merit integer, p_kind text, p_title text, p_when text, p_capacity smallint, p_held_by uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_opp_open(p_school uuid, p_merit integer, p_kind text, p_title text, p_when text, p_capacity smallint, p_held_by uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_open(p_school uuid, p_merit integer, p_kind text, p_title text, p_when text, p_capacity smallint, p_held_by uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_opp_plan(p_opp uuid, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_opp_plan(p_opp uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opp_plan(p_opp uuid, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_opps_list(p_school uuid, p_state text, p_days integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_opps_list(p_school uuid, p_state text, p_days integer) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_opps_list(p_school uuid, p_state text, p_days integer) TO service_role;
REVOKE ALL ON FUNCTION public.v2_opps_open_for(p_student uuid) FROM PUBLIC;
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
REVOKE ALL ON FUNCTION public.v2_periods(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_periods(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_periods(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_plan_final(p_plan uuid, p_confirm text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_plan_final(p_plan uuid, p_confirm text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_plan_final(p_plan uuid, p_confirm text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_plan_of(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_plan_of(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_plan_of(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_plan_opinion(p_plan uuid, p_who text, p_text text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_plan_opinion(p_plan uuid, p_who text, p_text text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_plan_opinion(p_plan uuid, p_who text, p_text text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_plan_remove(p_school uuid, p_plan uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_plan_remove(p_school uuid, p_plan uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_plan_remove(p_school uuid, p_plan uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_plan_save(p_school uuid, p_plan uuid, p_grade smallint, p_subject text, p_slots smallint, p_ord smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_plan_save(p_school uuid, p_plan uuid, p_grade smallint, p_subject text, p_slots smallint, p_ord smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_plan_save(p_school uuid, p_plan uuid, p_grade smallint, p_subject text, p_slots smallint, p_ord smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_plan_write(p_student uuid, p_record uuid, p_task uuid, p_plan uuid, p_desc text, p_manifest text, p_ante text, p_conseq text, p_gain text, p_prior text, p_target text, p_steps text, p_starts date, p_ends date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_plan_write(p_student uuid, p_record uuid, p_task uuid, p_plan uuid, p_desc text, p_manifest text, p_ante text, p_conseq text, p_gain text, p_prior text, p_target text, p_steps text, p_starts date, p_ends date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_plan_write(p_student uuid, p_record uuid, p_task uuid, p_plan uuid, p_desc text, p_manifest text, p_ante text, p_conseq text, p_gain text, p_prior text, p_target text, p_steps text, p_starts date, p_ends date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_portal_toggle(p_kind text, p_id uuid, p_open boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_portal_toggle(p_kind text, p_id uuid, p_open boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_portal_toggle(p_kind text, p_id uuid, p_open boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_posts_list() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_posts_list() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_posts_list() TO service_role;
REVOKE ALL ON FUNCTION public.v2_practice_save(p_school uuid, p_code text, p_title text, p_points numeric, p_polarity text, p_scope text, p_kind text, p_zone text, p_once_per_day boolean, p_threshold_count smallint, p_threshold_days smallint, p_escalate_to integer, p_escalate_note text, p_note text, p_ord smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_practice_save(p_school uuid, p_code text, p_title text, p_points numeric, p_polarity text, p_scope text, p_kind text, p_zone text, p_once_per_day boolean, p_threshold_count smallint, p_threshold_days smallint, p_escalate_to integer, p_escalate_note text, p_note text, p_ord smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_practice_save(p_school uuid, p_code text, p_title text, p_points numeric, p_polarity text, p_scope text, p_kind text, p_zone text, p_once_per_day boolean, p_threshold_count smallint, p_threshold_days smallint, p_escalate_to integer, p_escalate_note text, p_note text, p_ord smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_practice_scopes(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_practice_scopes(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_practice_scopes(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_practice_state(p_school uuid, p_code text, p_state text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_practice_state(p_school uuid, p_code text, p_state text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_practice_state(p_school uuid, p_code text, p_state text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_practices(p_school uuid, p_scope text, p_polarity text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_practices(p_school uuid, p_scope text, p_polarity text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_practices(p_school uuid, p_scope text, p_polarity text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_practices_hidden(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_practices_hidden(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_practices_hidden(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_problems(p_school uuid, p_degree smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_problems(p_school uuid, p_degree smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_problems(p_school uuid, p_degree smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_queue_messages(p_school uuid, p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_queue_messages(p_school uuid, p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_queue_messages(p_school uuid, p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_quota_board(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_quota_board(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_quota_board(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_quota_save(p_school uuid, p_post text, p_min smallint, p_max smallint, p_standby_max smallint, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_quota_save(p_school uuid, p_post text, p_min smallint, p_max smallint, p_standby_max smallint, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_quota_save(p_school uuid, p_post text, p_min smallint, p_max smallint, p_standby_max smallint, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_record_advice(p_record uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_record_advice(p_record uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_record_advice(p_record uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_record_amend(p_record uuid, p_place text, p_note text, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_record_amend(p_record uuid, p_place text, p_note text, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_record_amend(p_record uuid, p_place text, p_note text, p_injury boolean, p_damage boolean, p_seizure boolean, p_seizure_legal boolean) TO service_role;
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
REVOKE ALL ON FUNCTION public.v2_refer_committee(p_record uuid, p_task uuid, p_why text, p_ask text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_refer_committee(p_record uuid, p_task uuid, p_why text, p_ask text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_refer_committee(p_record uuid, p_task uuid, p_why text, p_ask text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_reference(p_key text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_reference(p_key text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_reference(p_key text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_reopen_day(p_school uuid, p_date date, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_reopen_day(p_school uuid, p_date date, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_reopen_day(p_school uuid, p_date date, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_response_check(p_record uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_response_check(p_record uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_response_check(p_record uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_school_card(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_school_card(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_school_card(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_scope_upsert(p_school uuid, p_key text, p_label text, p_ord smallint, p_active boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_scope_upsert(p_school uuid, p_key text, p_label text, p_ord smallint, p_active boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_scope_upsert(p_school uuid, p_key text, p_label text, p_ord smallint, p_active boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_section_timetable(p_section uuid, p_term smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_section_timetable(p_section uuid, p_term smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_section_timetable(p_section uuid, p_term smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_sections(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_sections(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_sections(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_session_add(p_case uuid, p_on date, p_minutes smallint, p_discussed text, p_response text, p_next text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_session_add(p_case uuid, p_on date, p_minutes smallint, p_discussed text, p_response text, p_next text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_session_add(p_case uuid, p_on date, p_minutes smallint, p_discussed text, p_response text, p_next text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_setting_rows(p_key text, p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_setting_rows(p_key text, p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_setting_rows(p_key text, p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_setting_update(p_key text, p_id text, p_patch jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_setting_update(p_key text, p_id text, p_patch jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_setting_update(p_key text, p_id text, p_patch jsonb) TO service_role;
REVOKE ALL ON FUNCTION public.v2_settings_catalog() FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_settings_catalog() TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_settings_catalog() TO service_role;
REVOKE ALL ON FUNCTION public.v2_signature_save(p_school uuid, p_person uuid, p_image_ref text, p_valid_from date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_signature_save(p_school uuid, p_person uuid, p_image_ref text, p_valid_from date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_signature_save(p_school uuid, p_person uuid, p_image_ref text, p_valid_from date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_slot_check(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_slot_check(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_slot_check(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_slot_delete(p_slot uuid, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_slot_delete(p_slot uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_slot_delete(p_slot uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_slot_save(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text, p_subject text, p_room text, p_note text, p_force boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_slot_save(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text, p_subject text, p_room text, p_note text, p_force boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_slot_save(p_school uuid, p_slot uuid, p_weekday smallint, p_period smallint, p_section uuid, p_person uuid, p_kind text, p_subject text, p_room text, p_note text, p_force boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_staff_board(p_school uuid, p_q text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_staff_board(p_school uuid, p_q text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_staff_board(p_school uuid, p_q text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_staff_list(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_staff_list(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_staff_list(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_staff_save(p_school uuid, p_person uuid, p_full_name text, p_national_id text, p_employee_no text, p_phone text, p_email text, p_major text, p_rank text, p_qualification text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_staff_save(p_school uuid, p_person uuid, p_full_name text, p_national_id text, p_employee_no text, p_phone text, p_email text, p_major text, p_rank text, p_qualification text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_staff_save(p_school uuid, p_person uuid, p_full_name text, p_national_id text, p_employee_no text, p_phone text, p_email text, p_major text, p_rank text, p_qualification text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_stamp_save(p_school uuid, p_image_ref text, p_valid_from date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_stamp_save(p_school uuid, p_image_ref text, p_valid_from date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_stamp_save(p_school uuid, p_image_ref text, p_valid_from date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_structure_board(p_school uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_structure_board(p_school uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_structure_board(p_school uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_structure_set(p_school uuid, p_code text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_structure_set(p_school uuid, p_code text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_structure_set(p_school uuid, p_code text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_student_absence_tasks(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_student_absence_tasks(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_student_absence_tasks(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_student_card(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_student_card(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_student_card(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_student_save(p_school uuid, p_student uuid, p_full_name text, p_student_no text, p_national_id text, p_nationality text, p_birth_hijri text, p_sex text, p_phone text, p_grade smallint, p_section text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_student_save(p_school uuid, p_student uuid, p_full_name text, p_student_no text, p_national_id text, p_nationality text, p_birth_hijri text, p_sex text, p_phone text, p_grade smallint, p_section text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_student_save(p_school uuid, p_student uuid, p_full_name text, p_student_no text, p_national_id text, p_nationality text, p_birth_hijri text, p_sex text, p_phone text, p_grade smallint, p_section text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_student_tasks(p_student uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_student_tasks(p_student uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_student_tasks(p_student uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_student_timeline(p_student uuid, p_as text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_student_timeline(p_student uuid, p_as text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_student_timeline(p_student uuid, p_as text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_students_board(p_school uuid, p_grade smallint, p_section text, p_q text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_students_board(p_school uuid, p_grade smallint, p_section text, p_q text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_students_board(p_school uuid, p_grade smallint, p_section text, p_q text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_by text, p_channel text, p_excuse_item smallint, p_attachment_name text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_by text, p_channel text, p_excuse_item smallint, p_attachment_name text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_submit_excuse(p_student uuid, p_from date, p_to date, p_reason text, p_by text, p_channel text, p_excuse_item smallint, p_attachment_name text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_task_card(p_task uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_task_card(p_task uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_task_card(p_task uuid) TO service_role;
REVOKE ALL ON FUNCTION public.v2_task_delegate(p_task uuid, p_person uuid, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_task_delegate(p_task uuid, p_person uuid, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_task_delegate(p_task uuid, p_person uuid, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_task_done(p_task uuid, p_ev jsonb) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_task_done(p_task uuid, p_ev jsonb) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_task_done(p_task uuid, p_ev jsonb) TO service_role;
REVOKE ALL ON FUNCTION public.v2_task_evidence(p_task uuid, p_on date, p_text text, p_file text, p_ref text, p_people text, p_signed boolean, p_refuse text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_task_evidence(p_task uuid, p_on date, p_text text, p_file text, p_ref text, p_people text, p_signed boolean, p_refuse text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_task_evidence(p_task uuid, p_on date, p_text text, p_file text, p_ref text, p_people text, p_signed boolean, p_refuse text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_task_skip(p_task uuid, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_task_skip(p_task uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_task_skip(p_task uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_teacher_subject(p_school uuid, p_person uuid, p_subject text, p_main boolean, p_remove boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_teacher_subject(p_school uuid, p_person uuid, p_subject text, p_main boolean, p_remove boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_teacher_subject(p_school uuid, p_person uuid, p_subject text, p_main boolean, p_remove boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_term_save(p_school uuid, p_year uuid, p_term uuid, p_number smallint, p_starts date, p_ends date, p_current boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_term_save(p_school uuid, p_year uuid, p_term uuid, p_number smallint, p_starts date, p_ends date, p_current boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_term_save(p_school uuid, p_year uuid, p_term uuid, p_number smallint, p_starts date, p_ends date, p_current boolean) TO service_role;
REVOKE ALL ON FUNCTION public.v2_timetable_board(p_school uuid, p_person uuid, p_section uuid, p_weekday smallint) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_timetable_board(p_school uuid, p_person uuid, p_section uuid, p_weekday smallint) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_timetable_board(p_school uuid, p_person uuid, p_section uuid, p_weekday smallint) TO service_role;
REVOKE ALL ON FUNCTION public.v2_timetable_suggest(p_school uuid, p_keep_fixed boolean, p_note text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_timetable_suggest(p_school uuid, p_keep_fixed boolean, p_note text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_timetable_suggest(p_school uuid, p_keep_fixed boolean, p_note text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_undo_practice(p_record uuid, p_reason text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_undo_practice(p_record uuid, p_reason text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_undo_practice(p_record uuid, p_reason text) TO service_role;
REVOKE ALL ON FUNCTION public.v2_weekday(p_date date) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_weekday(p_date date) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_weekday(p_date date) TO service_role;
REVOKE ALL ON FUNCTION public.v2_year_save(p_school uuid, p_year uuid, p_name text, p_starts date, p_ends date, p_current boolean) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.v2_year_save(p_school uuid, p_year uuid, p_name text, p_starts date, p_ends date, p_current boolean) TO authenticated;
GRANT EXECUTE ON FUNCTION public.v2_year_save(p_school uuid, p_year uuid, p_name text, p_starts date, p_ends date, p_current boolean) TO service_role;
-- دوالٌّ بلا ACL صريح (الافتراضيّ: EXECUTE لـ PUBLIC): 5

