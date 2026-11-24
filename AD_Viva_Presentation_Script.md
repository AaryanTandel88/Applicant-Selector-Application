# Application Development (AD) Capstone Project
## 7-Minute Video Evaluation Recording Script

> **Evaluation Component:** Capstone Project — Application Development (AD) Video Evaluation  
> **Target Duration:** ~7:00 to 7:30 minutes (well under the 10-minute cap)  
> **Language Level:** Simple, natural spoken English (easy to speak and clear for professors)  
> **Key Reminder:** Keep your screen shared and visible throughout. Show your live running app, folder structure, code files, and terminal test outputs.

---

### ⏱️ Video Timing Roadmap

| Timestamp | Section | Topic & What to Show |
| :--- | :--- | :--- |
| **0:00 – 0:30** (~30s) | **Introduction** | Self-intro, project title, and DRDO problem statement |
| **0:30 – 1:50** (~1m 20s) | **Q1: Application Overview & Workflow** | Problem solved, platform choice, features, live workflow demo |
| **1:50 – 3:10** (~1m 20s) | **Q2: Architecture & Code Organization** | Tech stack, folder structure, clean client/server separation |
| **3:10 – 4:30** (~1m 20s) | **Q3: User Interaction & State Handling** | Input flow, what happens on submit, error guards |
| **4:30 – 5:50** (~1m 20s) | **Q4: Core Feature Logic & Testing** | Adaptive ladder algorithm, testing edge cases with npm script |
| **5:50 – 6:50** (~1m 00s) | **Q5: Challenges, Stability & Completeness** | Offline answer scoring challenge, debugging, limitations |
| **6:50 – 7:15** (~25s) | **Conclusion** | Brief summary and wrap-up |

---

## 🎬 [0:00 – 0:30] Introduction

**What to show on screen:**
- Open your browser at `http://localhost:5173` showing the **Examiner Dashboard**, or show your VS Code workspace with `Applicant-Selector-Application`.

**What to say:**
> *"Hello respected professor and evaluators. My name is [Your Name], and today I am presenting my Application Development Capstone Project: the **RAC DRDO Adaptive Interview & Candidate Screening System**.*
>
> *This application is an AI-assisted, fully offline, and deterministic screening and oral interview platform built for the **Recruitment and Assessment Centre (RAC), DRDO** to assess candidates for scientific posts like Scientist 'C' in Advanced System Development.*
>
> *Over the next seven minutes, I will demonstrate the running application, our project structure, core code implementation, and testing."*

---

## 🖥️ [0:30 – 1:50] Q1. What application did you build, and how does it work?

**What to show on screen:**
- In the browser running at `http://localhost:5173`:
  1. Click **"Setup New Interview"** (`/setup`).
  2. Select candidate **"Dr. Vikram Sharma"** and post **"Scientist 'C' - ASD"**.
  3. Click **"Start Interview"** to show the live interview room (`/interview/:sessionId`).
  4. Type a short answer and click **"Submit Answer"** to demonstrate the question adapting.

**What to say:**
> *"Starting with Question 1: What problem does this application solve?*
>
> *In technical defence recruitment, human interview panels often face scoring subjectivity, inconsistent question depth, and manual resume matching. Our application automates and standardizes this with a fair, offline adaptive interview system.*
>
> *Why did we build this as a full-stack web application?*
> *We needed a responsive interface for boardroom examiners that works across different devices on an isolated local network, without requiring complex desktop installations on every machine.*
>
> *What are the main features?*
> *1. **Skill Suitability Screening:** Matches candidate skills against job post requirements using domain synonyms and weighted percentages.*
> *2. **Adaptive Technical Ladder:** Dynamically changes question difficulty between EASY, MEDIUM, and HARD based on candidate answer performance.*
> *3. **Anti-Gaming Answer Scorer:** Scores free-text answers deterministically without external cloud AI APIs.*
> *4. **Assessment Dossier:** Generates an immutable final evaluation report with topic strengths and recommendations.*
>
> *Which features did I personally implement?*
> *I personally developed the **Adaptive Interview Engine**, the **Answer Submission API**, and the **Interactive Interview Room UI**.*
>
> *As you can see on screen in this complete workflow: an interview is initiated, the candidate answers a technical question, the system scores the answer immediately, and the ladder decides whether to advance to a harder question or re-ask in a simplified way."*

---

## 📂 [1:50 – 3:10] Q2. How have you structured and organized your application?

**What to show on screen:**
- Switch to VS Code and show the project explorer:
  - Expand `client/src` (`pages/`, `components/`, `services/`).
  - Expand `server/src` (`routes/`, `services/`, `engine/`, `config/`).
- Open `server/src/engine/adaptiveEngine.js` or `server/src/app.js`.

**What to say:**
> *"Moving to Question 2: Architecture and code organization.*
>
> *For our tech stack:*
> *- **Backend:** We used **Node.js with Express.js** for clean REST APIs, and **PostgreSQL with Prisma ORM** for strong relational data integrity.*
> *- **Frontend:** We used **React with Vite and Tailwind CSS** for a fast, component-driven user interface.*
> *- **NLP Processing:** We used offline libraries like `natural` for Porter stemming and TF-IDF calculation, ensuring complete defence data confidentiality.*
>
> *How is the code organized?*
> *As you can see in VS Code:*
> *- The `client/` folder is divided into `pages/` (like SetupWizard, InterviewRoom, and DossierReport), reusable `components/`, and API client services.*
> *- The `server/` folder follows a strict layered architecture:*
>   - `routes/` handles HTTP request validation and routing.
>   - `services/` contains core business workflows like `interviewService.js`.*
>   - `engine/` houses `adaptiveEngine.js`, which is a pure state-machine function.*
>   - `config/` holds all scoring thresholds and weights, avoiding any magic numbers in our logic.*
>
> *How is user interaction separated from business logic?*
> *The React frontend only handles user inputs and visual rendering. All scoring math, state transitions, and database writes live securely on the backend, ensuring candidate evaluations cannot be altered from the browser."*

---

## 🔄 [3:10 – 4:30] Q3. How does your application handle user interactions and application state?

**What to show on screen:**
- On the running interview room page, show the answer text box and submit button.
- Type an answer and submit it.
- Open `server/src/services/interviewService.js` and highlight lines around `submitAnswer` where `prisma.$transaction` runs.

**What to say:**
> *"Addressing Question 3: User interactions and state handling.*
>
> *How does the application receive input?*
> *The candidate types their response into an auto-expanding text box with character counters, while examiners interact using setup forms, filters, and boardroom action buttons.*
>
> *What happens internally when an answer is submitted?*
> *When the candidate clicks 'Submit Answer':*
> *1. The frontend disables the submit button to prevent double submissions and makes a POST request to `/api/interviews/:sessionId/answer`.*
> *2. On the backend, `answerScoringService` evaluates the answer for relevancy and correctness, assigning a verdict: `STRONG`, `PARTIAL`, or `IRRELEVANT`.*
> *3. The pure function `decideNext()` evaluates the verdict, question pool availability, and interview history to select the next action.*
> *4. Inside an **atomic database transaction**, the system saves the `Response`, updates `SessionState` with the new difficulty and question ID, and logs the step in `DecisionLog`.*
> *5. The response sanitizes the next question—stripping away ideal answers and grading keywords—and sends it back to update the React state.*
>
> *How do we handle invalid inputs?*
> *If an answer is empty, frontend validation stops it, and backend anti-gaming rules flag it as `NO_ANSWER`. If an invalid session ID is requested, the backend returns clean 400 or 404 HTTP errors with helpful messages without crashing."*

---

## ⚙️ [4:30 – 5:50] Q4. How did you implement and test your application’s core functionality?

**What to show on screen:**
- Open `server/src/engine/adaptiveEngine.js` showing the `decideNext` function.
- Open your terminal and run:
  `npm run test:decision` (or `npm run test:db` from the server directory).
- Show the passing test results in the terminal.

**What to say:**
> *"Now for Question 4: Core feature implementation and testing.*
>
> *The core feature I implemented is the **Adaptive Question Ladder Engine**.*
> *Let us look at `adaptiveEngine.js` on my screen. This function acts as a deterministic state machine:*
> *- It checks safety stop rules: if the candidate reaches 10 technical questions, or scores 3 consecutive `IRRELEVANT` answers, it automatically ends the session.*
> *- In Phase 1, it delivers warm-up icebreakers that don't penalize difficulty.*
> *- In Phase 2, for technical questions:*
>   - A `STRONG` verdict on an `EASY` question promotes difficulty to `MEDIUM`.*
>   - If a linked follow-up exists via `parentQId`, it directly serves that connected question.*
>   - A `STRONG` verdict on `MEDIUM` promotes difficulty to `HARD`.*
>   - An `IRRELEVANT` verdict triggers a simplified re-ask once before moving to another topic.*
>
> *How did I test this feature?*
> *As you can see in my terminal, I wrote an automated test suite in `scripts/testDecisionLogic.js` that verifies over 20 decision branches:*
> *- Checking that difficulty only increments by one level at a time.*
> *- Guaranteeing that no question is ever repeated in the same session.*
> *- Confirming early-stop conditions when a candidate is struggling.*
> *All tests pass with 100% assertions, confirming our decision logic is reliable."*

---

## 🛡️ [5:50 – 6:50] Q5. What challenges did you face, and how complete and stable is your application?

**What to show on screen:**
- Open `server/src/scorers/logicScorer.js` showing anti-gaming checks (`KEYWORD_STUFFING`, `TOO_SHORT`).
- Alternatively, show the final report dossier screen (`/report/:sessionId`) with topic scores and recommendation badges.

**What to say:**
> *"Finally, Question 5: Challenges, stability, and completeness.*
>
> *What was the most challenging part I personally solved?*
> *The hardest challenge was building an **offline, deterministic answer scorer** that evaluates technical answers accurately without cloud LLMs, while resisting gaming attempts like keyword stuffing.*
>
> *How did I resolve it?*
> *I implemented a multi-stage scoring pipeline:*
> *1. First, an abbreviation normalizer expands over 35 defence acronyms—like MBSE, V&V, and MIL-STD-1553B—into full phrases.*
> *2. Second, I blended keyword coverage with TF-IDF cosine similarity so candidates must explain concepts, not just name-drop.*
> *3. Third, I added anti-gaming checks: if an answer has high keyword density but low prose stopwords, the engine detects keyword stuffing and applies a penalty multiplier.*
>
> *How complete is the application, and what are its limitations?*
> *The application is functionally complete end-to-end: setup, candidate screening, adaptive questioning, scoring, database persistence, and dossier report generation are all working.*
> *As a current limitation, answers are currently submitted via text input. For future development, adding offline speech-to-text with a local model like Whisper would enable direct voice answers during boardroom interviews."*

---

## 🎯 [6:50 – 7:15] Conclusion

**What to show on screen:**
- Show the web app UI or final terminal screen with tests passed.

**What to say:**
> *"To wrap up: the RAC DRDO Adaptive Interview System is a complete, stable, and deterministic application designed for fair, transparent defence recruitment.*
>
> *All source code, database migrations, and test scripts are fully documented and available in our repository.*
>
> *Thank you very much for your time and evaluation."*

---

### 💡 Quick Tips for Your Recording
1. **Screen Layout:** Have your browser (`localhost:5173`) on one half of your screen and VS Code on the other half (or smoothly switch between them using `Cmd + Tab`).
2. **Pacing:** Speak naturally and at a calm, conversational speed. The word count is designed so you comfortably land around **7 minutes** without rushing.
3. **Pre-check:** Start your dev server (`npm run dev`) before pressing record so all your clicks and transitions respond instantly!
