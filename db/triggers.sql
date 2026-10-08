-- triggers.sql
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.

-- ── absence_cases · md5 8e4774b668b5fba02417fd671e20c93b
CREATE TRIGGER mark_test BEFORE INSERT ON v2.absence_cases FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── absence_excuse_claims · md5 0497286ec8b04bf89306f38565b09b41
CREATE TRIGGER mark_test BEFORE INSERT ON v2.absence_excuse_claims FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── absence_tasks · md5 2403ea308af6820ad567e7f887c6f953
CREATE TRIGGER task_evidence BEFORE INSERT ON v2.absence_tasks FOR EACH ROW EXECUTE FUNCTION v2.trg_abs_task_evidence();

-- ── assignments · md5 480e8730f5c32601879cfb7b6851b91f
CREATE TRIGGER trg_year_guard_assign BEFORE INSERT OR UPDATE ON v2.assignments FOR EACH ROW EXECUTE FUNCTION v2.fn_year_open_guard();

-- ── attachments · md5 413f098ec511cd28bfafab493594df1c
CREATE TRIGGER mark_test BEFORE INSERT ON v2.attachments FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── attendance · md5 fb83b8c3689c11663350120004670041
CREATE TRIGGER attendance_calendar_guard BEFORE INSERT OR UPDATE ON v2.attendance FOR EACH ROW EXECUTE FUNCTION v2.trg_attendance_calendar_guard();
CREATE TRIGGER day_closed_guard BEFORE INSERT OR UPDATE ON v2.attendance FOR EACH ROW EXECUTE FUNCTION v2.trg_day_closed_guard();
CREATE TRIGGER mark_test BEFORE INSERT ON v2.attendance FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── attendance_ledger · md5 8596862a8b6b5dd3a8141b50c5db4c62
CREATE TRIGGER mark_test BEFORE INSERT ON v2.attendance_ledger FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── behavior_records · md5 3c6dc30a9c912dc41a4c5c8ce503a70b
CREATE TRIGGER mark_test BEFORE INSERT ON v2.behavior_records FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── behavior_tasks · md5 ca3c91a5f146355534f672453e47d23f
CREATE TRIGGER t_open_case_on_refer AFTER INSERT ON v2.behavior_tasks FOR EACH ROW EXECUTE FUNCTION v2.g_open_case_on_refer();
CREATE TRIGGER t_police_after_guardian BEFORE UPDATE OF status ON v2.behavior_tasks FOR EACH ROW EXECUTE FUNCTION v2.trg_police_after_guardian();
CREATE TRIGGER t_record_settle AFTER INSERT OR DELETE OR UPDATE OF status ON v2.behavior_tasks FOR EACH ROW EXECUTE FUNCTION v2.trg_record_settle();
CREATE TRIGGER task_evidence BEFORE INSERT ON v2.behavior_tasks FOR EACH ROW EXECUTE FUNCTION v2.trg_task_evidence();

-- ── calendar_entries · md5 4911db044f51aa18ef7d89a59c90c0e1
CREATE TRIGGER trg_year_guard_calendar BEFORE INSERT OR UPDATE ON v2.calendar_entries FOR EACH ROW EXECUTE FUNCTION v2.fn_year_open_guard();

-- ── committee_meetings · md5 0e95d09ae432a27d8f8b7d9b335bf371
CREATE TRIGGER t_meeting_flow BEFORE INSERT OR UPDATE ON v2.committee_meetings FOR EACH ROW EXECUTE FUNCTION v2.g_meeting_flow();

-- ── committee_members · md5 11d7394558dd798039d1714f9b4921e7
CREATE TRIGGER trg_year_guard_members BEFORE INSERT OR UPDATE ON v2.committee_members FOR EACH ROW EXECUTE FUNCTION v2.fn_year_open_guard();

-- ── counsel_reports · md5 7786513da0c23833d98967bbb4dbeea7
CREATE TRIGGER t_report_needs_sessions BEFORE INSERT ON v2.counsel_reports FOR EACH ROW EXECUTE FUNCTION v2.g_report_needs_sessions();

-- ── counsel_sessions · md5 a5a98dc1e7bcb11e1cba5e9d54af955b
CREATE TRIGGER t_session_needs_case BEFORE INSERT ON v2.counsel_sessions FOR EACH ROW EXECUTE FUNCTION v2.g_session_needs_case();

-- ── day_closures · md5 8610fdda155b5977c61948030192fc12
CREATE TRIGGER mark_test BEFORE INSERT ON v2.day_closures FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── dismissal_records · md5 8279b403c2c382515ad61e8313e56017
CREATE TRIGGER mark_test BEFORE INSERT ON v2.dismissal_records FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── duty_log · md5 cd236421877a786dfd2e2f8751cd41e8
CREATE TRIGGER mark_test BEFORE INSERT ON v2.duty_log FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── entry_permits · md5 8a908849879e5f5bdfb9546b7021818e
CREATE TRIGGER mark_test BEFORE INSERT ON v2.entry_permits FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── events · md5 2578b3f3bcf7ba11f5c897abe441ee02
CREATE TRIGGER mark_test BEFORE INSERT ON v2.events FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();
CREATE TRIGGER t_event_visibility BEFORE INSERT OR UPDATE ON v2.events FOR EACH ROW EXECUTE FUNCTION v2.g_event_visibility();

-- ── exceptions · md5 dc2e80bc5f14be53469e18ec20d02a2d
CREATE TRIGGER trg_year_guard_exc BEFORE INSERT OR UPDATE ON v2.exceptions FOR EACH ROW EXECUTE FUNCTION v2.fn_year_open_guard();

-- ── form_entries · md5 20cc02d840a5ddd039ad4b1e334d6e1d
CREATE TRIGGER mark_test BEFORE INSERT ON v2.form_entries FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── form_inbox · md5 dfa445ed0139dc9e56f08b4245dd472d
CREATE TRIGGER mark_test BEFORE INSERT ON v2.form_inbox FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── incoming_mail · md5 8314339cbcbccdf5356c823f05b12ea1
CREATE TRIGGER mark_test BEFORE INSERT ON v2.incoming_mail FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── meeting_attendance · md5 ff33cee99f45edea2a669a6fef83597d
CREATE TRIGGER t_attendee_identity BEFORE INSERT OR UPDATE ON v2.meeting_attendance FOR EACH ROW EXECUTE FUNCTION v2.g_attendee_identity();

-- ── meeting_items · md5 08fe65c4a19eb28e5c5305671718edc3
CREATE TRIGGER t_item_needs_meeting BEFORE INSERT OR UPDATE ON v2.meeting_items FOR EACH ROW EXECUTE FUNCTION v2.g_item_needs_meeting();

-- ── meeting_votes · md5 9466ceb866807ce83fde1732f08a84f5
CREATE TRIGGER t_vote_allowed BEFORE INSERT OR UPDATE ON v2.meeting_votes FOR EACH ROW EXECUTE FUNCTION v2.g_vote_allowed();

-- ── merit_entries · md5 ecee45d2efededbc064c3104b61fb485
CREATE TRIGGER t_grade_rules BEFORE INSERT OR UPDATE ON v2.merit_entries FOR EACH ROW EXECUTE FUNCTION v2.g_grade_rules();
CREATE TRIGGER t_verdict_needs_filing BEFORE INSERT OR UPDATE ON v2.merit_entries FOR EACH ROW EXECUTE FUNCTION v2.g_verdict_needs_filing();

-- ── outbox · md5 a2ac2a03c8c6a7f17ae3c63e36235973
CREATE TRIGGER mark_test BEFORE INSERT ON v2.outbox FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── outgoing_mail · md5 3d97d61e36732f61387100e5129259aa
CREATE TRIGGER mark_test BEFORE INSERT ON v2.outgoing_mail FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── people · md5 412ca5db1e16b5fcbb22a29506637eee
CREATE TRIGGER trg_person_silence BEFORE INSERT OR UPDATE OF status ON v2.people FOR EACH ROW EXECUTE FUNCTION v2.fn_person_silence();

-- ── period_attendance · md5 250a560b6e5ee956d09e8672c58621b9
CREATE TRIGGER mark_test BEFORE INSERT ON v2.period_attendance FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();
CREATE TRIGGER period_guard BEFORE INSERT OR UPDATE ON v2.period_attendance FOR EACH ROW EXECUTE FUNCTION v2.trg_period_guard();

-- ── practice_points · md5 5b11b68d89fe0668684864394c5b58dd
CREATE TRIGGER mark_test BEFORE INSERT ON v2.practice_points FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── practice_records · md5 e6fa7dc51d6e3b7998cd3b64a3124082
CREATE TRIGGER mark_test BEFORE INSERT ON v2.practice_records FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── school_seats · md5 1b6d2578b2571a964bdcce030749f3ef
CREATE TRIGGER trg_year_guard_seats BEFORE INSERT OR UPDATE ON v2.school_seats FOR EACH ROW EXECUTE FUNCTION v2.fn_year_open_guard();

-- ── student_permissions · md5 0c142894c7779b1775b5b9e954ba8edc
CREATE TRIGGER mark_test BEFORE INSERT ON v2.student_permissions FOR EACH ROW EXECUTE FUNCTION v2.trg_mark_test();

-- ── timetable · md5 38e741398d1d57020849e8b9a59473e6
CREATE TRIGGER tt_clash BEFORE INSERT OR UPDATE ON v2.timetable FOR EACH ROW EXECUTE FUNCTION v2.trg_tt_clash();
CREATE TRIGGER tt_period BEFORE INSERT OR UPDATE ON v2.timetable FOR EACH ROW EXECUTE FUNCTION v2.trg_tt_period();

