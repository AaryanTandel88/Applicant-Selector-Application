-- ============================================================================
-- RAC DRDO Adaptive Interview System — Sample Data Records (DML)
-- ============================================================================

-- 1. Subjects
INSERT INTO "Subject" (id, name, "createdAt", "updatedAt") VALUES
('asd-sub-001', 'Advanced System Development (ASD)', NOW(), NOW()),
('esd-sub-002', 'Embedded Systems Design (ESD)', NOW(), NOW())
ON CONFLICT (name) DO NOTHING;

-- 2. Topics
INSERT INTO "Topic" (id, "subjectId", name, "createdAt", "updatedAt") VALUES
('asd-top-req', 'asd-sub-001', 'Requirements Analysis', NOW(), NOW()),
('asd-top-arch', 'asd-sub-001', 'System Architecture', NOW(), NOW()),
('asd-top-vv', 'asd-sub-001', 'Verification and Validation (V&V)', NOW(), NOW()),
('asd-top-iface', 'asd-sub-001', 'Interface Management', NOW(), NOW())
ON CONFLICT ("subjectId", name) DO NOTHING;

-- 3. Questions with Hierarchy (EASY Parent -> MEDIUM Follow-up)
INSERT INTO "Question" (id, "topicId", difficulty, "levelTag", "questionText", "simplifiedText", "idealAnswer", keywords, "parentQId", source, status, "createdAt", "updatedAt") VALUES
('asd-req-e1', 'asd-top-req', 'EASY', 'TECHNICAL',
 'What is the fundamental difference between functional and non-functional requirements in missile avionics systems?',
 'What is the main difference between what an avionics system does and how well it does it?',
 'Functional requirements define specific behaviors and mathematical calculations such as guidance laws and actuator commands, whereas non-functional requirements specify performance constraints, reliability attributes like MTBF, latency deadlines, and military compliance.',
 ARRAY['functional requirements', 'non-functional requirements', 'avionics', 'latency', 'MTBF'],
 NULL, 'BANK', 'ACTIVE', NOW(), NOW()),

('asd-req-m1', 'asd-top-req', 'MEDIUM', 'TECHNICAL',
 'Explain how a bidirectional Requirements Traceability Matrix (RTM) maps operational requirements down to verification test procedures under DO-178C.',
 'How does an RTM trace requirements to test cases in safety-critical systems?',
 'A bidirectional RTM establishes forward and backward traceability between high-level operational requirements, software requirements specifications (SRS), source code components, and verification test cases, satisfying DO-178C structural coverage.',
 ARRAY['RTM', 'requirements traceability', 'DO-178C', 'test cases', 'verification'],
 'asd-req-e1', 'BANK', 'ACTIVE', NOW(), NOW()),

('asd-ice-1', NULL, 'EASY', 'ICEBREAKER',
 'Briefly walk us through your academic or industrial background in defence systems and embedded technologies.',
 NULL, '', ARRAY['background', 'education', 'experience', 'projects'],
 NULL, 'BANK', 'ACTIVE', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

-- 4. Posts & Required Competencies
INSERT INTO "Post" (id, title, "subjectId", level, "createdAt", "updatedAt") VALUES
('post-asd-sc-c', 'Scientist ''C'' - Advanced System Development', 'asd-sub-001', 'Scientist ''C''', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO "PostSkill" (id, "postId", "skillName", weight, "isMandatory", "createdAt", "updatedAt") VALUES
('ps-001', 'post-asd-sc-c', 'Model-Based Systems Engineering (MBSE)', 5, true, NOW(), NOW()),
('ps-002', 'post-asd-sc-c', 'Requirements Analysis & Traceability', 5, true, NOW(), NOW()),
('ps-003', 'post-asd-sc-c', 'Verification and Validation (V&V)', 5, true, NOW(), NOW()),
('ps-004', 'post-asd-sc-c', 'MIL-STD-1553B Avionics Bus Architecture', 4, true, NOW(), NOW()),
('ps-005', 'post-asd-sc-c', 'Real-Time Operating Systems (RTOS)', 4, false, NOW(), NOW())
ON CONFLICT ("postId", "skillName") DO NOTHING;

-- 5. Candidate Profile & Declared Skills
INSERT INTO "Candidate" (id, name, "postApplied", "experienceLevel", "createdAt", "updatedAt") VALUES
('cand-001', 'Dr. Vikram Sharma', 'Scientist ''C'' - Advanced System Development', 'Senior Systems Architect (8 Yrs)', NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO "CandidateSkill" (id, "candidateId", "skillName", "createdAt") VALUES
(gen_random_uuid(), 'cand-001', 'MBSE', NOW()),
(gen_random_uuid(), 'cand-001', 'Requirements Traceability Matrix', NOW()),
(gen_random_uuid(), 'cand-001', 'V&V', NOW()),
(gen_random_uuid(), 'cand-001', 'MIL-STD-1553B', NOW()),
(gen_random_uuid(), 'cand-001', 'RTOS', NOW())
ON CONFLICT ("candidateId", "skillName") DO NOTHING;

-- 6. Interview Session & State Machine Record
INSERT INTO "Session" (id, "candidateId", "startTime", "endTime", "createdAt", "updatedAt") VALUES
('sess-001', 'cand-001', NOW(), NULL, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

INSERT INTO "SessionState" (id, "sessionId", "currentTopicId", "currentDifficulty", "currentQuestionId", phase, "technicalCount", "icebreakerCount", "consecutiveIrrelevant", "topicProgress", status, "createdAt", "updatedAt") VALUES
('state-001', 'sess-001', 'asd-top-req', 'MEDIUM', 'asd-req-m1', 'TECHNICAL', 1, 1, 0,
 '{"asd-top-req": {"easyAsked": 1, "lastVerdict": "STRONG"}}'::jsonb,
 'ACTIVE', NOW(), NOW())
ON CONFLICT ("sessionId") DO NOTHING;

-- 7. Response Record
INSERT INTO "Response" (id, "sessionId", "questionId", "answerText", "relevancyScore", "correctnessScore", "answerScore", verdict, breakdown, "isReask", timestamp) VALUES
('resp-001', 'sess-001', 'asd-req-e1',
 'Functional requirements define operational behavior like trajectory calculation; non-functional specify MTBF reliability, latency bounds, and MIL-STD compliance.',
 0.7295, 0.9208, 0.8443, 'STRONG',
 '{"matchedKeywords": ["functional requirements", "non-functional requirements", "avionics", "MTBF"], "flags": []}'::jsonb,
 false, NOW())
ON CONFLICT ("sessionId", "questionId", "isReask") DO NOTHING;

-- 8. Decision Log Entry
INSERT INTO "DecisionLog" (id, "sessionId", step, "questionId", verdict, "fromDifficulty", "toDifficulty", action, reason, "createdAt") VALUES
(gen_random_uuid(), 'sess-001', 2, 'asd-req-e1', 'STRONG', 'EASY', 'MEDIUM', 'NEXT_HARDER',
 'Candidate demonstrated strong mastery on EASY requirements question. Advancing to linked MEDIUM follow-up question.', NOW())
ON CONFLICT DO NOTHING;
