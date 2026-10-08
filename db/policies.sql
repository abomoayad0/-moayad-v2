-- policies.sql
-- مستخرَجٌ من القاعدة qbhuuuiyitsgumrgjkme من الكتالوج (pg_catalog)، لا من الذاكرة.

-- ── absence_cases · md5 37470f6e5240df037ce6dd460c816d31
CREATE POLICY ac_t ON v2.absence_cases AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── absence_excuse_claims · md5 915b35da34858e3cffc485e754b5d546
CREATE POLICY exc_sch ON v2.absence_excuse_claims AS PERMISSIVE FOR SELECT TO authenticated
    USING (v2.my_school(school_id));
CREATE POLICY exc_t ON v2.absence_excuse_claims AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.students s
  WHERE ((s.id = absence_excuse_claims.student_id) AND v2.my_school(s.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.students s
  WHERE ((s.id = absence_excuse_claims.student_id) AND v2.my_school(s.school_id)))));

-- ── absence_excuses · md5 2228f7f8a2184ea8072c7832987d56e7
CREATE POLICY absence_excuses_read ON v2.absence_excuses AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── absence_ladder · md5 63168a24cdd9b264eff75c192f5fa0b2
CREATE POLICY absence_ladder_read ON v2.absence_ladder AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── absence_ladder_items · md5 5e9e7e463b23a0a560ffd252b6356f8f
CREATE POLICY ali_read ON v2.absence_ladder_items AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── absence_tasks · md5 27434238ccae00aedde4d04ae442c4f5
CREATE POLICY atsk_t ON v2.absence_tasks AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.absence_cases c
  WHERE ((c.id = absence_tasks.case_id) AND v2.my_school(c.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.absence_cases c
  WHERE ((c.id = absence_tasks.case_id) AND v2.my_school(c.school_id)))));

-- ── academic_years · md5 3028b56e42d53b6bad4aa0ba0c6819d6
CREATE POLICY academic_years_tenant ON v2.academic_years AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── action_log · md5 e488af5979e7f7b5efc5facc8505567f
CREATE POLICY al_read ON v2.action_log AS PERMISSIVE FOR SELECT TO authenticated
    USING (v2.my_school(school_id));

-- ── app_users · md5 f2cd24157b99eaa9a0993324be344709
CREATE POLICY app_users_own ON v2.app_users AS PERMISSIVE FOR SELECT TO authenticated
    USING ((tenant_id = v2.current_tenant()));

-- ── assignments · md5 d43b65bb9ddf9f98e6f2859097f10478
CREATE POLICY assignments_tenant ON v2.assignments AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── attachments · md5 395ede40f567a2a8e304ad7d4ddfe70b
CREATE POLICY att_school ON v2.attachments AS PERMISSIVE FOR ALL TO authenticated
    USING ((v2.my_school(school_id) OR (guardian_id IN ( SELECT guardians.id
   FROM v2.guardians
  WHERE (guardians.user_id = auth.uid())))))
    WITH CHECK ((v2.my_school(school_id) OR (guardian_id IN ( SELECT guardians.id
   FROM v2.guardians
  WHERE (guardians.user_id = auth.uid())))));

-- ── attendance · md5 2ac0ea8da0bc3b843fb259b825942561
CREATE POLICY att_t ON v2.attendance AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── attendance_ledger · md5 7b6622d6059092cb9f0ad4d19b55da1e
CREATE POLICY attl_t ON v2.attendance_ledger AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── behavior_census · md5 727930e305638d3b05d0a3fa279a8136
CREATE POLICY bc_tenant ON v2.behavior_census AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── behavior_ledger · md5 f048b58e2976b9a2398f04362c66ebf4
CREATE POLICY bl_tenant ON v2.behavior_ledger AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── behavior_plan_counts · md5 f2f3f469f98ac263c874cb050f29b153
CREATE POLICY bpc_t ON v2.behavior_plan_counts AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM (v2.behavior_plans p
     JOIN v2.students s ON ((s.id = p.student_id)))
  WHERE ((p.id = behavior_plan_counts.plan_id) AND v2.my_school(s.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM (v2.behavior_plans p
     JOIN v2.students s ON ((s.id = p.student_id)))
  WHERE ((p.id = behavior_plan_counts.plan_id) AND v2.my_school(s.school_id)))));

-- ── behavior_plans · md5 183ce1782405aa39002e003938a4201b
CREATE POLICY bp_t ON v2.behavior_plans AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.students s
  WHERE ((s.id = behavior_plans.student_id) AND v2.my_school(s.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.students s
  WHERE ((s.id = behavior_plans.student_id) AND v2.my_school(s.school_id)))));
CREATE POLICY bp_tenant ON v2.behavior_plans AS PERMISSIVE FOR ALL TO authenticated
    USING (((school_id IS NULL) OR v2.my_school(school_id)))
    WITH CHECK (((school_id IS NULL) OR v2.my_school(school_id)));

-- ── behavior_records · md5 463df52d7e2dbc27ef6b29c2ae56e066
CREATE POLICY br_tenant ON v2.behavior_records AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── behavior_tasks · md5 e896f6a9c7a6dd0415449655363a255a
CREATE POLICY bt_tenant ON v2.behavior_tasks AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.behavior_records r
  WHERE ((r.id = behavior_tasks.record_id) AND v2.my_school(r.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.behavior_records r
  WHERE ((r.id = behavior_tasks.record_id) AND v2.my_school(r.school_id)))));

-- ── brand_tokens · md5 5518c6a43a44569e2156a7c36ef0e31b
CREATE POLICY brand_read ON v2.brand_tokens AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── branding · md5 c55e79d9ab13097bdf87d0dc62ff0848
CREATE POLICY br_t ON v2.branding AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── break_slots · md5 4537522fe69311f6f3875edf61d17398
CREATE POLICY bs_tenant ON v2.break_slots AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── calendar_days · md5 aa476d6454441d75060b5a11c8e7d0cd
CREATE POLICY calendar_days_read ON v2.calendar_days AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── calendar_entries · md5 ec7a3d68e9808fb82ca76a73590e9852
CREATE POLICY calendar_entries_tenant ON v2.calendar_entries AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── calendar_holidays · md5 b7808deb351c075c2d5049772fbb52b4
CREATE POLICY calendar_holidays_read ON v2.calendar_holidays AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── calendar_milestones · md5 e5910ae0ee57c0c62c64d6a1eb8c670c
CREATE POLICY calendar_milestones_read ON v2.calendar_milestones AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── calendar_rules · md5 0477afe3365150d46daaa6ed562a3b03
CREATE POLICY cr_read ON v2.calendar_rules AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── calendar_scopes · md5 276fd9cad96db903c9d2e7a34e9238c4
CREATE POLICY calendar_scopes_read ON v2.calendar_scopes AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── calendar_term_stats · md5 05c3d11d1fc72e093653260445af6ffb
CREATE POLICY calendar_term_stats_read ON v2.calendar_term_stats AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── calendar_weeks · md5 33e3b9c0189bf352af18e2f86beaf483
CREATE POLICY calendar_weeks_read ON v2.calendar_weeks AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── calendar_years · md5 5e7775ab5349d65370eb3873cce0ae5d
CREATE POLICY calendar_years_read ON v2.calendar_years AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── card_doors · md5 d53a7c89868f8f8e9c1d06cc3fda32a2
CREATE POLICY card_doors_read ON v2.card_doors AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── card_matrix · md5 6b5e523fe724309ceae5de69626c2489
CREATE POLICY card_matrix_read ON v2.card_matrix AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── card_steps · md5 ca2d6d18e5c5ded0bacd4ce30e17fd33
CREATE POLICY card_steps_read ON v2.card_steps AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── card_values · md5 fe08fd9a01a20fed12eb502e4407e82c
CREATE POLICY card_values_read ON v2.card_values AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── case_docs · md5 b7e2470e7456be096acbae50618f8219
CREATE POLICY cd_t ON v2.case_docs AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.behavior_records r
  WHERE ((r.id = case_docs.record_id) AND v2.my_school(r.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.behavior_records r
  WHERE ((r.id = case_docs.record_id) AND v2.my_school(r.school_id)))));

-- ── census_items · md5 e7b85021705c735121cc106fa2e89091
CREATE POLICY ci_read ON v2.census_items AS PERMISSIVE FOR SELECT TO authenticated
    USING (((school_id IS NULL) OR v2.my_school(school_id)));
CREATE POLICY ci_write ON v2.census_items AS PERMISSIVE FOR ALL TO authenticated
    USING (((school_id IS NOT NULL) AND v2.my_school(school_id)))
    WITH CHECK (((school_id IS NOT NULL) AND v2.my_school(school_id)));

-- ── class_practices · md5 94e73afa30743dde70df1636decad129
CREATE POLICY cp_read ON v2.class_practices AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── class_sections · md5 da8c47ae7df1b13ec27582591b6e5ac2
CREATE POLICY class_sections_t ON v2.class_sections AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── committee_duties · md5 52fb8fab5661f7290190856477622c5e
CREATE POLICY cd_read ON v2.committee_duties AS PERMISSIVE FOR SELECT TO authenticated
    USING (((school_id IS NULL) OR v2.my_school(school_id)));
CREATE POLICY cd_write ON v2.committee_duties AS PERMISSIVE FOR ALL TO authenticated
    USING (((school_id IS NOT NULL) AND v2.my_school(school_id)))
    WITH CHECK (((school_id IS NOT NULL) AND v2.my_school(school_id)));

-- ── committee_meetings · md5 6e3a22aeec7463f18a23829c25121ea4
CREATE POLICY committee_meetings_tenant ON v2.committee_meetings AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── committee_members · md5 535caea9bd9eea44a2334d6fbfa9c30f
CREATE POLICY committee_members_tenant ON v2.committee_members AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── committee_school_rules · md5 f8582dbd42cf39e2cbdfdd4a5a78c356
CREATE POLICY csr_tenant ON v2.committee_school_rules AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── committee_seats · md5 bcf744d10ba54b62ac4502b7bd70bb84
CREATE POLICY committee_seats_read ON v2.committee_seats AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── committees · md5 229e621a0549eba6e3ee340eea74f3a8
CREATE POLICY committees_read ON v2.committees AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── conduct_action_items · md5 196eb4254febb96c25361e48e9c986bd
CREATE POLICY cai_read ON v2.conduct_action_items AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── conduct_actions · md5 b05c2e467ed3b8491d3ab0f86720be61
CREATE POLICY conduct_actions_read ON v2.conduct_actions AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── conduct_advice · md5 d068633c6cc0eede6bbeed127bed3a0d
CREATE POLICY ca_read ON v2.conduct_advice AS PERMISSIVE FOR SELECT TO authenticated
    USING (((school_id IS NULL) OR v2.my_school(school_id)));
CREATE POLICY ca_write ON v2.conduct_advice AS PERMISSIVE FOR ALL TO authenticated
    USING (((school_id IS NOT NULL) AND v2.my_school(school_id)))
    WITH CHECK (((school_id IS NOT NULL) AND v2.my_school(school_id)));

-- ── conduct_degrees · md5 6c0171c7e9d7132ab27b16014f879d30
CREATE POLICY conduct_degrees_read ON v2.conduct_degrees AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── conduct_merits · md5 05b8f75ee021b4f5ca7bb5283c68290a
CREATE POLICY conduct_merits_read ON v2.conduct_merits AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── conduct_problems · md5 aed35734104e0370c76bd9bf12eb45db
CREATE POLICY conduct_problems_read ON v2.conduct_problems AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── conduct_rules · md5 e456259289f62f70d46d263af14ff60a
CREATE POLICY conduct_rules_read ON v2.conduct_rules AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── conduct_universal · md5 90893fe713f423aacbdeedf3d180a80d
CREATE POLICY conduct_universal_read ON v2.conduct_universal AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── counsel_cases · md5 c5f3365b88bc6077b01671793e0a2b24
CREATE POLICY counsel_cases_tenant ON v2.counsel_cases AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── counsel_reports · md5 9b1254cc5405b1158b03a953d5c9c639
CREATE POLICY counsel_reports_tenant ON v2.counsel_reports AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.counsel_cases c
  WHERE ((c.id = counsel_reports.case_id) AND v2.my_school(c.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.counsel_cases c
  WHERE ((c.id = counsel_reports.case_id) AND v2.my_school(c.school_id)))));

-- ── counsel_sessions · md5 b0cdf470d44d8aef58d46a7c6000528e
CREATE POLICY counsel_sessions_tenant ON v2.counsel_sessions AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.counsel_cases c
  WHERE ((c.id = counsel_sessions.case_id) AND v2.my_school(c.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.counsel_cases c
  WHERE ((c.id = counsel_sessions.case_id) AND v2.my_school(c.school_id)))));

-- ── day_closures · md5 33b5aa7a1c544342820e741f9f9924fb
CREATE POLICY dc_t ON v2.day_closures AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── day_reversals · md5 4755454232a2f10d840bd34cc7587bcb
CREATE POLICY dr_t ON v2.day_reversals AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── day_segments · md5 37575eb827a84c9f896f6bdebcc49c91
CREATE POLICY dsg_read ON v2.day_segments AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── day_settings · md5 6d895d2f7d958d0994a0a239dc17c2be
CREATE POLICY ds_t ON v2.day_settings AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── delegations · md5 2f774da9cb68f2b193ab929fc3fc1b4e
CREATE POLICY dlg_tenant ON v2.delegations AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── dismissal_records · md5 0f4d4465b052e9a3ad47445e9e3fd881
CREATE POLICY dismissal_records_t ON v2.dismissal_records AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── dismissal_settings · md5 6b7ad468a22c7f635a1dd3bfe38ed978
CREATE POLICY dismissal_settings_t ON v2.dismissal_settings AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── doc_deliveries · md5 94c9b29afe2432e31f754db8b07ac0dc
CREATE POLICY dd_t ON v2.doc_deliveries AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM (v2.case_docs d
     JOIN v2.behavior_records r ON ((r.id = d.record_id)))
  WHERE ((d.id = doc_deliveries.doc_id) AND v2.my_school(r.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM (v2.case_docs d
     JOIN v2.behavior_records r ON ((r.id = d.record_id)))
  WHERE ((d.id = doc_deliveries.doc_id) AND v2.my_school(r.school_id)))));

-- ── doc_signatures · md5 2d0dd235dcdbe90ff876115e5c7b70a4
CREATE POLICY ds_t ON v2.doc_signatures AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM (v2.case_docs d
     JOIN v2.behavior_records r ON ((r.id = d.record_id)))
  WHERE ((d.id = doc_signatures.doc_id) AND v2.my_school(r.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM (v2.case_docs d
     JOIN v2.behavior_records r ON ((r.id = d.record_id)))
  WHERE ((d.id = doc_signatures.doc_id) AND v2.my_school(r.school_id)))));

-- ── duty_log · md5 e3ca8b11db501052217341d377669e2b
CREATE POLICY duty_log_t ON v2.duty_log AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── duty_roster · md5 1c8bbdb32342068b0a8077e95016e8f3
CREATE POLICY duty_roster_t ON v2.duty_roster AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── duty_zones · md5 5012a9aab7bc59b495a8014bc2ce07d2
CREATE POLICY duty_zones_t ON v2.duty_zones AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── enrolments · md5 0d7e1e3d9c70fd578a1001b0a783a52c
CREATE POLICY enrolments_tenant ON v2.enrolments AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── entry_permits · md5 420fc4840088962154942dd420235526
CREATE POLICY ep_t ON v2.entry_permits AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── error_log · md5 12ac2e9708ba2d0608000705b00b96bb
CREATE POLICY el_ins ON v2.error_log AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK (true);
CREATE POLICY el_sel ON v2.error_log AS PERMISSIVE FOR SELECT TO authenticated
    USING ((v2.my_grant() = ANY (ARRAY['owner'::text, 'admin'::text])));

-- ── event_deliveries · md5 1f9df97aaf1cbfbcc1bdfef8c6d06df7
CREATE POLICY ed_t ON v2.event_deliveries AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.events e
  WHERE ((e.id = event_deliveries.event_id) AND v2.my_school(e.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.events e
  WHERE ((e.id = event_deliveries.event_id) AND v2.my_school(e.school_id)))));

-- ── events · md5 8797bb236a3bd3592b67ea73d428d6b5
CREATE POLICY ev_t ON v2.events AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── evidence_kinds · md5 01f6ef2f717cb0dafc1ed359f6b7a4c7
CREATE POLICY ek_read ON v2.evidence_kinds AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── exceptions · md5 cf925acaf0958322acf34997dbf196ec
CREATE POLICY exceptions_tenant ON v2.exceptions AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── form_entries · md5 3da412b0a288d4a5db1bee9534ef0b2c
CREATE POLICY fe_t ON v2.form_entries AS PERMISSIVE FOR ALL TO authenticated
    USING ((v2.my_school(school_id) OR (student_id IN ( SELECT guardians.student_id
   FROM v2.guardians
  WHERE ((guardians.user_id = auth.uid()) AND guardians.portal_active)))))
    WITH CHECK (v2.my_school(school_id));

-- ── form_inbox · md5 2d176d9a8a3f0951cb599b9e51389d38
CREATE POLICY fi_t ON v2.form_inbox AS PERMISSIVE FOR ALL TO authenticated
    USING (((guardian_id IN ( SELECT guardians.id
   FROM v2.guardians
  WHERE ((guardians.user_id = auth.uid()) AND guardians.portal_active))) OR (entry_id IN ( SELECT e.id
   FROM v2.form_entries e
  WHERE v2.my_school(e.school_id)))))
    WITH CHECK (true);

-- ── form_row_schema · md5 c8032660c597f9926f1c4894fa25f6ef
CREATE POLICY frs_r ON v2.form_row_schema AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── form_schema · md5 e12b6a13aa39dbc184498ab68ffa6555
CREATE POLICY fsch_r ON v2.form_schema AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── form_signatures · md5 fa83d3c82add45f038b0e01f85d93255
CREATE POLICY fs_t ON v2.form_signatures AS PERMISSIVE FOR ALL TO authenticated
    USING ((entry_id IN ( SELECT e.id
   FROM v2.form_entries e
  WHERE (v2.my_school(e.school_id) OR (e.student_id IN ( SELECT guardians.student_id
           FROM v2.guardians
          WHERE ((guardians.user_id = auth.uid()) AND guardians.portal_active)))))))
    WITH CHECK (true);

-- ── gaps · md5 ffcccda76c669aa2fa723b594eaa93de
CREATE POLICY gaps_read ON v2.gaps AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);
CREATE POLICY gaps_write ON v2.gaps AS PERMISSIVE FOR ALL TO authenticated
    USING ((v2.my_grant() = ANY (ARRAY['owner'::text, 'admin'::text])))
    WITH CHECK ((v2.my_grant() = ANY (ARRAY['owner'::text, 'admin'::text])));

-- ── grading_models · md5 f5562437480fe626a6e665053463a66e
CREATE POLICY grading_models_read ON v2.grading_models AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── grading_rules · md5 e4c1dc8b35ee6cce6abf71557f089035
CREATE POLICY grading_rules_read ON v2.grading_rules AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── grading_subjects · md5 56f8b9c36c3cc6bd9ab42b62d5c52e38
CREATE POLICY grading_subjects_read ON v2.grading_subjects AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── guardian_contacts · md5 6d02e4ddd39f8d2936155c5829109112
CREATE POLICY gc_tenant ON v2.guardian_contacts AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── guardian_replies · md5 d8a829ccec33bda6b5c36baa45d98e6f
CREATE POLICY gr_tenant ON v2.guardian_replies AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── guardians · md5 281835f1a2aa6a4f8e1c3ada8623a9b8
CREATE POLICY guardians_tenant ON v2.guardians AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.students s
  WHERE ((s.id = guardians.student_id) AND v2.my_school(s.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.students s
  WHERE ((s.id = guardians.student_id) AND v2.my_school(s.school_id)))));

-- ── hijri_months · md5 f72dfc70030be3c8d098247638e4c8eb
CREATE POLICY hm_read ON v2.hijri_months AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── incident_seizures · md5 4ebbf89a034e990a4edc574b82271964
CREATE POLICY isz_t ON v2.incident_seizures AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.behavior_records r
  WHERE ((r.id = incident_seizures.record_id) AND v2.my_school(r.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.behavior_records r
  WHERE ((r.id = incident_seizures.record_id) AND v2.my_school(r.school_id)))));

-- ── incident_witnesses · md5 81637eb98ded7cc7423ea15cb67d5724
CREATE POLICY iw_t ON v2.incident_witnesses AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.behavior_records r
  WHERE ((r.id = incident_witnesses.record_id) AND v2.my_school(r.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.behavior_records r
  WHERE ((r.id = incident_witnesses.record_id) AND v2.my_school(r.school_id)))));

-- ── incoming_mail · md5 fac3bf5fe023cfa16e5d62d2d54b0cfa
CREATE POLICY im_t ON v2.incoming_mail AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── inheritance_rules · md5 654d5a2d7dd7e1d8ecc90ce95735fce0
CREATE POLICY inheritance_rules_read ON v2.inheritance_rules AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── mail_acknowledgements · md5 44e1b8c1f542dcc01ff82418c8249529
CREATE POLICY mack_t ON v2.mail_acknowledgements AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.incoming_mail m
  WHERE ((m.id = mail_acknowledgements.mail_id) AND v2.my_school(m.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.incoming_mail m
  WHERE ((m.id = mail_acknowledgements.mail_id) AND v2.my_school(m.school_id)))));

-- ── mail_attachments · md5 d3f35b3c669522eb9b7c32a49e48ca4a
CREATE POLICY ma_t ON v2.mail_attachments AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.incoming_mail m
  WHERE ((m.id = mail_attachments.mail_id) AND v2.my_school(m.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.incoming_mail m
  WHERE ((m.id = mail_attachments.mail_id) AND v2.my_school(m.school_id)))));

-- ── mail_followups · md5 2ebfffb588df965f13cf3ce153b22568
CREATE POLICY mf_t ON v2.mail_followups AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM (v2.mail_items i
     JOIN v2.incoming_mail m ON ((m.id = i.mail_id)))
  WHERE ((i.id = mail_followups.item_id) AND v2.my_school(m.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM (v2.mail_items i
     JOIN v2.incoming_mail m ON ((m.id = i.mail_id)))
  WHERE ((i.id = mail_followups.item_id) AND v2.my_school(m.school_id)))));

-- ── mail_items · md5 d642afb4de4095c16cce318c0a9d81ff
CREATE POLICY mi_t ON v2.mail_items AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.incoming_mail m
  WHERE ((m.id = mail_items.mail_id) AND v2.my_school(m.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.incoming_mail m
  WHERE ((m.id = mail_items.mail_id) AND v2.my_school(m.school_id)))));

-- ── mail_targets · md5 e3b08f5a38c4ee3caa3539381b773db7
CREATE POLICY mt_t ON v2.mail_targets AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM (v2.mail_items i
     JOIN v2.incoming_mail m ON ((m.id = i.mail_id)))
  WHERE ((i.id = mail_targets.item_id) AND v2.my_school(m.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM (v2.mail_items i
     JOIN v2.incoming_mail m ON ((m.id = i.mail_id)))
  WHERE ((i.id = mail_targets.item_id) AND v2.my_school(m.school_id)))));

-- ── meeting_attendance · md5 fe36d4ff00ad28f5d612cb5087f9cfcd
CREATE POLICY meeting_attendance_tenant ON v2.meeting_attendance AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.committee_meetings m
  WHERE ((m.id = meeting_attendance.meeting_id) AND v2.my_school(m.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.committee_meetings m
  WHERE ((m.id = meeting_attendance.meeting_id) AND v2.my_school(m.school_id)))));

-- ── meeting_items · md5 0c99a732bc30c9d0631562fdc207310f
CREATE POLICY meeting_items_tenant ON v2.meeting_items AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.committee_meetings m
  WHERE ((m.id = meeting_items.meeting_id) AND v2.my_school(m.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.committee_meetings m
  WHERE ((m.id = meeting_items.meeting_id) AND v2.my_school(m.school_id)))));

-- ── meeting_votes · md5 a9c820f0b2beaabd3d6d77e6f96ed7aa
CREATE POLICY meeting_votes_tenant ON v2.meeting_votes AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM (v2.meeting_items i
     JOIN v2.committee_meetings m ON ((m.id = i.meeting_id)))
  WHERE ((i.id = meeting_votes.item_id) AND v2.my_school(m.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM (v2.meeting_items i
     JOIN v2.committee_meetings m ON ((m.id = i.meeting_id)))
  WHERE ((i.id = meeting_votes.item_id) AND v2.my_school(m.school_id)))));

-- ── merit_entries · md5 d148f8f47af72e8bf0c7bb5748a6dd88
CREATE POLICY merit_entries_tenant ON v2.merit_entries AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.merit_opportunities o
  WHERE ((o.id = merit_entries.opp_id) AND v2.my_school(o.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.merit_opportunities o
  WHERE ((o.id = merit_entries.opp_id) AND v2.my_school(o.school_id)))));

-- ── merit_opportunities · md5 e28d99c07504c71554ab9074e805be40
CREATE POLICY merit_opps_tenant ON v2.merit_opportunities AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── message_templates · md5 92ddbecd84676352ecfd4ab09675cf6b
CREATE POLICY mt_read ON v2.message_templates AS PERMISSIVE FOR SELECT TO authenticated
    USING (((school_id IS NULL) OR v2.my_school(school_id)));
CREATE POLICY mt_write ON v2.message_templates AS PERMISSIVE FOR ALL TO authenticated
    USING (((school_id IS NOT NULL) AND v2.my_school(school_id)))
    WITH CHECK (((school_id IS NOT NULL) AND v2.my_school(school_id)));

-- ── name_rules · md5 f4e7ff426c9c3790f0c40e3066549e74
CREATE POLICY nr_read ON v2.name_rules AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── official_forms · md5 f15102717d27cdee1cdf7bf5028dbe98
CREATE POLICY of_read ON v2.official_forms AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── outbox · md5 1aa916197697b465a7b047e259616e8c
CREATE POLICY ob_t ON v2.outbox AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── people · md5 6edb12615969e93884b29d08b51328bb
CREATE POLICY people_rw ON v2.people AS PERMISSIVE FOR ALL TO authenticated
    USING ((tenant_id = v2.current_tenant()))
    WITH CHECK ((tenant_id = v2.current_tenant()));

-- ── period_attendance · md5 37a1612ee6985ff0e03b576aa25ccc7b
CREATE POLICY pa_t ON v2.period_attendance AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── period_slots · md5 289cb85539d9f6f492c96e0601181370
CREATE POLICY period_slots_t ON v2.period_slots AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── phrase_bank · md5 e93add4168a10b509bac7c76aa01a484
CREATE POLICY pb_read ON v2.phrase_bank AS PERMISSIVE FOR SELECT TO authenticated
    USING (((school_id IS NULL) OR v2.my_school(school_id)));
CREATE POLICY pb_write ON v2.phrase_bank AS PERMISSIVE FOR ALL TO authenticated
    USING (((school_id IS NOT NULL) AND v2.my_school(school_id)))
    WITH CHECK (((school_id IS NOT NULL) AND v2.my_school(school_id)));

-- ── posts · md5 38435ec025c1f300d5c11e70bb615fe1
CREATE POLICY posts_read ON v2.posts AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── practice_overrides · md5 ada4a056e7c445175c39e7bace02e8b6
CREATE POLICY po_tenant ON v2.practice_overrides AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── practice_points · md5 e158dbb8b6c6d731210d5c24bedfe2b1
CREATE POLICY pp_t ON v2.practice_points AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── practice_records · md5 5424ea240bc42caca569c6c21757c31d
CREATE POLICY pr_t ON v2.practice_records AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── practice_scopes · md5 a7172f1ed7523755896f3775ffcb9e0b
CREATE POLICY ps_read ON v2.practice_scopes AS PERMISSIVE FOR SELECT TO authenticated
    USING (((school_id IS NULL) OR v2.my_school(school_id)));
CREATE POLICY ps_write ON v2.practice_scopes AS PERMISSIVE FOR ALL TO authenticated
    USING (((school_id IS NOT NULL) AND v2.my_school(school_id)))
    WITH CHECK (((school_id IS NOT NULL) AND v2.my_school(school_id)));

-- ── proc_cards · md5 6dc14d51196d0e863b0eab0b2aa4f6a5
CREATE POLICY proc_cards_read ON v2.proc_cards AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── report_filers · md5 0b878ef55cf7c2911229baef908b98b7
CREATE POLICY rf_t ON v2.report_filers AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── school_custody · md5 3f417324133c169f9760b40546157b5e
CREATE POLICY cust_t ON v2.school_custody AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── school_seats · md5 11a1342dc1a92ca56d5522b2d853dff9
CREATE POLICY school_seats_tenant ON v2.school_seats AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── schools · md5 f3ef646e6bd50291b9298b9aa2eb7293
CREATE POLICY schools_rw ON v2.schools AS PERMISSIVE FOR ALL TO authenticated
    USING ((tenant_id = v2.current_tenant()))
    WITH CHECK ((tenant_id = v2.current_tenant()));

-- ── session_role · md5 f4a4984dc9135926e37b512c8a1c4c89
CREATE POLICY sr_own ON v2.session_role AS PERMISSIVE FOR ALL TO authenticated
    USING ((user_id = auth.uid()))
    WITH CHECK ((user_id = auth.uid()));

-- ── settings_catalog · md5 e4d089dc2e3dbce7b46fa2b2a5202a6d
CREATE POLICY sc_read ON v2.settings_catalog AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── signatures · md5 7ccbe0b8dec5b472bf3d751e2d9b21ba
CREATE POLICY signatures_own_update ON v2.signatures AS PERMISSIVE FOR UPDATE TO authenticated
    USING ((person_id = v2.current_person()))
    WITH CHECK ((person_id = v2.current_person()));
CREATE POLICY signatures_own_write ON v2.signatures AS PERMISSIVE FOR INSERT TO authenticated
    WITH CHECK ((person_id = v2.current_person()));
CREATE POLICY signatures_read ON v2.signatures AS PERMISSIVE FOR SELECT TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.people p
  WHERE ((p.id = signatures.person_id) AND (p.tenant_id = v2.current_tenant())))));

-- ── signed_forms_file · md5 5e5efdf2bad1716fefbf39b03b69f149
CREATE POLICY sff_t ON v2.signed_forms_file AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── signoffs · md5 0e54d1ee8056ea1c92ac299d17f2073d
CREATE POLICY signoffs_tenant ON v2.signoffs AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── staffing_rules · md5 43baf48e10a19256e557d34a6b94dfe4
CREATE POLICY staffing_rules_read ON v2.staffing_rules AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── stamps · md5 bff8d69c857f08863ccbfd99933960c5
CREATE POLICY stamps_tenant ON v2.stamps AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── structure_posts · md5 c87a0169afec0b28994e1cb1078f487d
CREATE POLICY structure_posts_read ON v2.structure_posts AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── structures · md5 8b8e2df2b3d93d127d05f388be8667bf
CREATE POLICY structures_read ON v2.structures AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── student_permissions · md5 211762879d03b70b058511247a86545a
CREATE POLICY sp_t ON v2.student_permissions AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── students · md5 2398ccd148e25160e8167b00b3273b80
CREATE POLICY students_tenant ON v2.students AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── study_plan_rules · md5 68f5234d500e5ac8e73aec196bae8ba8
CREATE POLICY spr_read ON v2.study_plan_rules AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── study_plans · md5 791698457a0d9ef2906265cddda04e2f
CREATE POLICY sp_read ON v2.study_plans AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── subject_plan · md5 c7843e6bcbce29ceb51f7602ebef4dba
CREATE POLICY sp_tenant ON v2.subject_plan AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── teacher_subjects · md5 5334716c874aaa914a6b87deb01de458
CREATE POLICY ts_tenant ON v2.teacher_subjects AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── teaching_assignments · md5 b47048f2ba6133de1d049248a8d98e9e
CREATE POLICY ta_t ON v2.teaching_assignments AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── teaching_loads · md5 5a958b7747dae8cd20234f1d418fe68a
CREATE POLICY tl_read ON v2.teaching_loads AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── teaching_quota · md5 33c58f17b4fb475af9a267fa70ada612
CREATE POLICY tq_tenant ON v2.teaching_quota AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── teaching_ranks · md5 18cede0bb12bbff88aa95ffda0755ee4
CREATE POLICY tr_read ON v2.teaching_ranks AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

-- ── tenants · md5 859d5704cdb737cd02d20a52e27918ba
CREATE POLICY tenants_own ON v2.tenants AS PERMISSIVE FOR SELECT TO authenticated
    USING ((id = v2.current_tenant()));

-- ── terms · md5 f1bc8cc90be9b32f6c3822958b1fe371
CREATE POLICY terms_tenant ON v2.terms AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.academic_years y
  WHERE ((y.id = terms.year_id) AND v2.my_school(y.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.academic_years y
  WHERE ((y.id = terms.year_id) AND v2.my_school(y.school_id)))));

-- ── timetable · md5 94598faf166e7c3b663d24551a834bd5
CREATE POLICY timetable_t ON v2.timetable AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── timetable_draft_slots · md5 a44f7e66c128380a17cd32bb0ce9ae0a
CREATE POLICY tds_tenant ON v2.timetable_draft_slots AS PERMISSIVE FOR ALL TO authenticated
    USING ((EXISTS ( SELECT 1
   FROM v2.timetable_drafts d
  WHERE ((d.id = timetable_draft_slots.draft_id) AND v2.my_school(d.school_id)))))
    WITH CHECK ((EXISTS ( SELECT 1
   FROM v2.timetable_drafts d
  WHERE ((d.id = timetable_draft_slots.draft_id) AND v2.my_school(d.school_id)))));

-- ── timetable_drafts · md5 13e68a192797e505c619f497fda77966
CREATE POLICY td_tenant ON v2.timetable_drafts AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── violence_cases · md5 01103e75a753d0cff66c239d3e26992c
CREATE POLICY vc_t ON v2.violence_cases AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── violence_census · md5 181ba1c0f0782c29010fc2bbc739f764
CREATE POLICY vcen_t ON v2.violence_census AS PERMISSIVE FOR ALL TO authenticated
    USING (v2.my_school(school_id))
    WITH CHECK (v2.my_school(school_id));

-- ── violence_types · md5 4dbbc9ead047b77b0f17b98e3ff06319
CREATE POLICY vt_read ON v2.violence_types AS PERMISSIVE FOR SELECT TO authenticated
    USING (true);

