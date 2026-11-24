# Application Development (AD) Capstone Project
## Video Evaluation Script — Short Paragraph Format (~7 Minutes)

---

### 🎬 Introduction: Project Overview (~45 Seconds)

**[Show running app at localhost:5173 or VS Code project]**

Hello respected professor and evaluators. My name is [Your Name], and today I am presenting my Application Development Capstone Project: the **RAC DRDO Adaptive Interview & Candidate Screening System**.

This application is an AI-assisted, fully offline, and deterministic screening and oral assessment platform designed for the **Recruitment and Assessment Centre (RAC), DRDO**. Its purpose is to evaluate candidates applying for technical scientific positions, such as Scientist 'C' in Advanced System Development. The system addresses the common problems of human interview bias, inconsistent questioning, and manual skill verification. It automates candidate pre-screening through skill matching, conducts real-time adaptive questioning where difficulty scales based on answer quality, scores technical answers deterministically without relying on external cloud APIs, and produces an audit-ready evaluation report for the board.

---

### 🖥️ Q1. What application did you build, and how does it work? (~1 Minute 15 Seconds)

**[Show live running app: Setup Wizard -> Start Interview -> Submit an Answer]**

I built a full-stack automated screening and adaptive interview web platform. In technical recruitment for defence organizations like DRDO, human interview boards often face subjective scoring bias, uneven questioning depth, and time-consuming manual skill checks. We chose a full-stack web application with an Express backend and a React frontend because it allows boardroom examiners to run assessments on any device across a secure local network without installing separate software on every workstation.

The system features candidate skill-match screening, a dynamic question ladder spanning Easy, Medium, and Hard tiers, an offline answer scorer with anti-gaming checks, and automated assessment dossier generation. I personally implemented the core adaptive interview engine, the answer evaluation API pipeline, and the real-time interview room interface. As demonstrated on my screen, an examiner selects a candidate and post, the session begins with warm-up icebreakers, and as the candidate answers technical questions, the system evaluates their response immediately and dynamically adapts the difficulty.

---

### 📂 Q2. How have you structured and organized your application? (~1 Minute 15 Seconds)

**[Show VS Code folder tree: client/src, server/src, and adaptiveEngine.js]**

For our technology stack, we used Node.js with Express on the backend because of its fast, asynchronous request handling, and PostgreSQL with Prisma ORM to maintain strict relational data integrity. On the frontend, we used React with Vite and Tailwind CSS to build a clean, responsive user interface. For natural language processing, we used the offline `natural` library to perform Porter stemming and TF-IDF similarity, ensuring that defence interview data never leaves the local environment.

The codebase is organized into a clean client-server architecture. In the `client` directory, we have separate folders for pages like the Setup Wizard, Interview Room, and Dossier Report, alongside reusable UI components. In the `server` directory, we separated concerns across routes, data models, configuration files, and services like `interviewService.js` and `adaptiveEngine.js`. User interaction is strictly decoupled from business logic: the React client only handles form inputs and visual state, while all question selection, mathematical scoring, and database transactions execute securely on the backend server.

---

### 🔄 Q3. How does your application handle user interactions and application state? (~1 Minute 15 Seconds)

**[Show answer submission in UI, then show interviewService.js transaction code]**

The application captures user interactions through setup forms, dropdown selectors, and an auto-expanding text box where candidates enter their technical answers. When the candidate clicks 'Submit Answer', the frontend disables the button to prevent duplicate submissions and dispatches a POST request to our API endpoint.

Internally, the backend runs the answer through our deterministic scorer, calculating relevancy, keyword coverage, and correctness to assign a verdict of Strong, Partial, or Irrelevant. The engine's state machine then evaluates this verdict against question availability to determine the next action, such as advancing difficulty or serving a simplified re-ask. All changes—recording the answer, updating the active question cursor in `SessionState`, and logging the audit step in `DecisionLog`—are committed together inside a single atomic database transaction. If a user submits empty text or invalid inputs, client-side guards block the request, and backend anti-gaming rules flag it as a zero-score submission without crashing the server.

---

### ⚙️ Q4. How did you implement and test your application’s core functionality? (~1 Minute 15 Seconds)

**[Show adaptiveEngine.js code, then run "npm run test:decision" in terminal]**

The primary feature I implemented is the **Adaptive Question Ladder Engine** inside `adaptiveEngine.js`. This module is designed as a pure deterministic state machine with zero side effects. It monitors safety thresholds, capping the interview at ten technical questions and triggering an early stop if a candidate struggles with three consecutive irrelevant answers. In the technical phase, a Strong verdict on an Easy question advances difficulty to Medium, actively searching for linked follow-up questions through the recursive `parentQId` relationship. A Strong verdict on Medium advances the candidate to Hard, while an Irrelevant verdict triggers a simplified re-ask before shifting topics.

To verify this logic, I built an automated unit test suite in `scripts/testDecisionLogic.js` that tests over twenty decision branches. As you can see in my terminal, the tests verify that difficulty never skips levels, questions are never repeated in the same session, and early termination triggers correctly under struggling conditions. All assertions pass with one hundred percent success, proving the engine is stable and reliable.

---

### 🛡️ Q5. What challenges did you face, and how complete and stable is your application? (~1 Minute)

**[Show logicScorer.js anti-gaming rules or the final completed report screen]**

The most demanding challenge I faced was building a deterministic, offline answer evaluation engine that could score technical free text accurately without calling third-party cloud LLMs, while resisting gaming attempts like keyword stuffing. I resolved this by designing a multi-layer scoring pipeline: first, an abbreviation normalizer expands over thirty-five defence acronyms into canonical terms; second, keyword coverage is blended with TF-IDF cosine similarity to reward conceptual explanations; and third, anti-gaming heuristics penalize submissions that have high keyword density but lack natural prose stop words.

The application is functionally complete end-to-end, with candidate setup, skill screening, adaptive questioning, response scoring, and final dossier report generation fully working. As a current limitation, the system operates on typed text input. In future iterations, we plan to integrate offline speech-to-text using local models like Whisper so candidates can speak directly during boardroom interviews.

---

### 🎯 Conclusion (~20 Seconds)

**[Show final report dossier or recruiter rankings page]**

In conclusion, the RAC DRDO Adaptive Interview System is a robust, deterministic, and production-grade application built to bring transparency, consistency, and fairness to technical recruitment. All source code, database migrations, and verification tests are fully documented in our repository. Thank you very much for your time and evaluation.
