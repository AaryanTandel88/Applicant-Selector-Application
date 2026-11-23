-- ============================================================================
-- RAC DRDO Adaptive Interview System — PostgreSQL Production Schema (DDL)
-- ============================================================================

-- 1. Enums
CREATE TYPE "Difficulty" AS ENUM ('EASY', 'MEDIUM', 'HARD');
CREATE TYPE "LevelTag" AS ENUM ('TECHNICAL', 'MANAGERIAL', 'ICEBREAKER');
CREATE TYPE "Role" AS ENUM ('ADMIN', 'EXAMINER');

-- 2. Curriculum Question Bank
CREATE TABLE "Subject" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Subject_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "Subject_name_key" ON "Subject"("name");

CREATE TABLE "Topic" (
    "id" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Topic_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Topic_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "Subject"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "Topic_subjectId_name_key" ON "Topic"("subjectId", "name");

CREATE TABLE "Question" (
    "id" TEXT NOT NULL,
    "topicId" TEXT,
    "difficulty" "Difficulty" NOT NULL,
    "questionText" TEXT NOT NULL,
    "simplifiedText" TEXT,
    "idealAnswer" TEXT NOT NULL,
    "keywords" TEXT[],
    "parentQId" TEXT,
    "levelTag" "LevelTag" NOT NULL,
    "source" TEXT NOT NULL DEFAULT 'BANK',
    "createdById" TEXT,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "aspectKeywords" TEXT[],
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Question_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Question_topicId_fkey" FOREIGN KEY ("topicId") REFERENCES "Topic"("id") ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT "Question_parentQId_fkey" FOREIGN KEY ("parentQId") REFERENCES "Question"("id") ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE INDEX "Question_topicId_difficulty_idx" ON "Question"("topicId", "difficulty");
CREATE INDEX "Question_parentQId_idx" ON "Question"("parentQId");
CREATE INDEX "Question_difficulty_idx" ON "Question"("difficulty");
CREATE INDEX "Question_levelTag_idx" ON "Question"("levelTag");

-- 3. Candidate & Interview Session Management
CREATE TABLE "Candidate" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "postApplied" TEXT NOT NULL,
    "experienceLevel" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Candidate_pkey" PRIMARY KEY ("id")
);

CREATE TABLE "Session" (
    "id" TEXT NOT NULL,
    "candidateId" TEXT NOT NULL,
    "startTime" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "endTime" TIMESTAMP(3),
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Session_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Session_candidateId_fkey" FOREIGN KEY ("candidateId") REFERENCES "Candidate"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "Session_candidateId_idx" ON "Session"("candidateId");

CREATE TABLE "Response" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "questionId" TEXT NOT NULL,
    "answerText" TEXT NOT NULL,
    "relevancyScore" DOUBLE PRECISION,
    "correctnessScore" DOUBLE PRECISION,
    "answerScore" DOUBLE PRECISION,
    "verdict" TEXT,
    "breakdown" JSONB,
    "isReask" BOOLEAN NOT NULL DEFAULT false,
    "timestamp" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Response_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Response_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Response_questionId_fkey" FOREIGN KEY ("questionId") REFERENCES "Question"("id") ON DELETE RESTRICT ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "Response_sessionId_questionId_isReask_key" ON "Response"("sessionId", "questionId", "isReask");
CREATE INDEX "Response_sessionId_idx" ON "Response"("sessionId");
CREATE INDEX "Response_questionId_idx" ON "Response"("questionId");

-- 4. Skill Match Engine
CREATE TABLE "Post" (
    "id" TEXT NOT NULL,
    "title" TEXT NOT NULL,
    "subjectId" TEXT NOT NULL,
    "level" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Post_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Post_subjectId_fkey" FOREIGN KEY ("subjectId") REFERENCES "Subject"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "Post_subjectId_idx" ON "Post"("subjectId");

CREATE TABLE "PostSkill" (
    "id" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "skillName" TEXT NOT NULL,
    "weight" INTEGER NOT NULL,
    "isMandatory" BOOLEAN NOT NULL DEFAULT false,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "PostSkill_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "PostSkill_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "PostSkill_postId_skillName_key" ON "PostSkill"("postId", "skillName");
CREATE INDEX "PostSkill_postId_idx" ON "PostSkill"("postId");

CREATE TABLE "CandidateSkill" (
    "id" TEXT NOT NULL,
    "candidateId" TEXT NOT NULL,
    "skillName" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "CandidateSkill_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "CandidateSkill_candidateId_fkey" FOREIGN KEY ("candidateId") REFERENCES "Candidate"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "CandidateSkill_candidateId_skillName_key" ON "CandidateSkill"("candidateId", "skillName");
CREATE INDEX "CandidateSkill_candidateId_idx" ON "CandidateSkill"("candidateId");

CREATE TABLE "SkillMatchResult" (
    "id" TEXT NOT NULL,
    "candidateId" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "matchPercent" DOUBLE PRECISION NOT NULL,
    "band" TEXT NOT NULL,
    "breakdown" JSONB NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "SkillMatchResult_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "SkillMatchResult_candidateId_fkey" FOREIGN KEY ("candidateId") REFERENCES "Candidate"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "SkillMatchResult_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "SkillMatchResult_candidateId_idx" ON "SkillMatchResult"("candidateId");
CREATE INDEX "SkillMatchResult_postId_idx" ON "SkillMatchResult"("postId");

-- 5. Adaptive Engine State Machine
CREATE TABLE "SessionState" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "currentTopicId" TEXT,
    "currentDifficulty" "Difficulty",
    "currentQuestionId" TEXT,
    "phase" TEXT NOT NULL DEFAULT 'ICEBREAKER',
    "technicalCount" INTEGER NOT NULL DEFAULT 0,
    "icebreakerCount" INTEGER NOT NULL DEFAULT 0,
    "consecutiveIrrelevant" INTEGER NOT NULL DEFAULT 0,
    "topicProgress" JSONB NOT NULL DEFAULT '{}'::jsonb,
    "status" TEXT NOT NULL DEFAULT 'ACTIVE',
    "endReason" TEXT,
    "expertQueue" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "SessionState_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "SessionState_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "SessionState_sessionId_key" ON "SessionState"("sessionId");

CREATE TABLE "DecisionLog" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "step" INTEGER NOT NULL,
    "questionId" TEXT,
    "verdict" TEXT,
    "fromDifficulty" TEXT,
    "toDifficulty" TEXT,
    "action" TEXT NOT NULL,
    "reason" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "DecisionLog_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "DecisionLog_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE INDEX "DecisionLog_sessionId_idx" ON "DecisionLog"("sessionId");
CREATE INDEX "DecisionLog_sessionId_step_idx" ON "DecisionLog"("sessionId", "step");

-- 6. Report Dossier & Governance
CREATE TABLE "Report" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "candidateId" TEXT NOT NULL,
    "postId" TEXT NOT NULL,
    "version" INTEGER NOT NULL DEFAULT 1,
    "generatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "configSnapshot" JSONB NOT NULL,
    "skillMatchPercent" DOUBLE PRECISION NOT NULL,
    "skillMatchBand" TEXT NOT NULL,
    "mandatoryGap" BOOLEAN NOT NULL,
    "missingMandatory" JSONB NOT NULL,
    "interviewScore" DOUBLE PRECISION NOT NULL,
    "overallScore" DOUBLE PRECISION NOT NULL,
    "systemRecommendation" TEXT NOT NULL,
    "finalRecommendation" TEXT NOT NULL,
    "terminatedEarly" BOOLEAN NOT NULL DEFAULT false,
    "endReason" TEXT,
    "questionRelevancyScore" DOUBLE PRECISION NOT NULL,
    "questionRelevancyBand" TEXT NOT NULL,
    "topicScores" JSONB NOT NULL,
    "questionTable" JSONB NOT NULL,
    "difficultyProgression" JSONB NOT NULL,
    "flags" JSONB NOT NULL,
    "decisionLog" JSONB NOT NULL,
    "boardRemarks" TEXT,
    "overriddenBy" TEXT,
    "overriddenAt" TIMESTAMP(3),
    "overrideReason" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "Report_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "Report_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Report_candidateId_fkey" FOREIGN KEY ("candidateId") REFERENCES "Candidate"("id") ON DELETE CASCADE ON UPDATE CASCADE,
    CONSTRAINT "Report_postId_fkey" FOREIGN KEY ("postId") REFERENCES "Post"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "Report_sessionId_version_key" ON "Report"("sessionId", "version");
CREATE INDEX "Report_sessionId_idx" ON "Report"("sessionId");
CREATE INDEX "Report_candidateId_idx" ON "Report"("candidateId");
CREATE INDEX "Report_postId_idx" ON "Report"("postId");

CREATE TABLE "User" (
    "id" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "username" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "Role" NOT NULL,
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

CREATE TABLE "AuditLog" (
    "id" TEXT NOT NULL,
    "userId" TEXT,
    "action" TEXT NOT NULL,
    "entityType" TEXT,
    "entityId" TEXT,
    "details" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "AuditLog_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "AuditLog_userId_fkey" FOREIGN KEY ("userId") REFERENCES "User"("id") ON DELETE SET NULL ON UPDATE CASCADE
);
CREATE INDEX "AuditLog_userId_idx" ON "AuditLog"("userId");

CREATE TABLE "CandidateAccess" (
    "id" TEXT NOT NULL,
    "sessionId" TEXT NOT NULL,
    "tokenHash" TEXT NOT NULL,
    "expiresAt" TIMESTAMP(3) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT "CandidateAccess_pkey" PRIMARY KEY ("id"),
    CONSTRAINT "CandidateAccess_sessionId_fkey" FOREIGN KEY ("sessionId") REFERENCES "Session"("id") ON DELETE CASCADE ON UPDATE CASCADE
);
CREATE UNIQUE INDEX "CandidateAccess_sessionId_key" ON "CandidateAccess"("sessionId");
