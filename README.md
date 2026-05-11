# GitHub Actions — CI Pipeline for React App

## Project Structure

```
.
├── .github/
│   └── workflows/
│       └── ci.yml          # CI workflow definition
├── public/
│   └── index.html
├── src/
│   ├── App.css
│   ├── App.js
│   ├── App.test.js
│   └── index.js
└── package.json
```

---

## How the CI Pipeline Works

| Concept | Details |
|---|---|
| **Trigger** | Push to the `development` branch |
| **Runner** | Self-hosted (your own machine or server) |
| **Steps** | Checkout → Setup Node.js → Install deps → Test → Build → Upload artifact |

### Workflow Steps Explained

1. **Checkout code** — Downloads the latest commit from the `development` branch onto the runner.
2. **Set up Node.js** — Installs Node 20 and enables `npm` cache for faster runs.
3. **Install dependencies** — `npm ci` performs a clean, reproducible install from `package-lock.json`.
4. **Run tests** — Executes Jest via `react-scripts test`. The `--watchAll=false` flag (set in `package.json`) makes it exit after one run so the pipeline doesn't hang.
5. **Build application** — `npm run build` creates an optimised production bundle in the `build/` folder.
6. **Upload artefact** — The `build/` folder is uploaded so it can be downloaded from the Actions run summary.

---

## Setting Up the Self-Hosted Runner

> These steps are performed once per machine that will act as a runner.

1. In your GitHub repository go to **Settings → Actions → Runners → New self-hosted runner**.
2. Choose your operating system and follow the on-screen commands to download and configure the runner agent.
3. Make sure **Node.js 20+** is installed on the runner machine.
4. Start the runner:

   ```bash
   # Linux / macOS
   ./run.sh

   # Windows (PowerShell)
   .\run.cmd
   ```

5. Confirm the runner shows as **Idle** in **Settings → Actions → Runners**.

The workflow uses `runs-on: self-hosted`, which targets any registered self-hosted runner. You can add custom labels (e.g. `runs-on: [self-hosted, linux]`) to target a specific machine.

---

## Running the Pipeline

```bash
# 1. Make sure you are on the development branch
git checkout -b development   # or: git checkout development

# 2. Make a change and commit it
git add .
git commit -m "feat: initial React app"

# 3. Push — this triggers the workflow automatically
git push origin development
```

After pushing, open the **Actions** tab in your GitHub repository to watch the pipeline run in real time.

---

## Debugging Pipeline Failures

| Symptom | Where to look | Common fix |
|---|---|---|
| Workflow never starts | Actions tab — no run appears | Confirm the push reached the `development` branch; check branch name spelling in `ci.yml` |
| Runner not found | Job shows "Waiting for a runner" | Start the runner agent on your machine (`./run.sh` / `.\run.cmd`) |
| Dependency install fails | `Install dependencies` step log | Delete `node_modules` locally, run `npm install`, commit the updated `package-lock.json` |
| Tests fail | `Run tests` step log | Read the Jest error output; fix the failing test or the component |
| Build fails | `Build application` step log | Check for ESLint errors; treat warnings as errors with `CI=true` (default in `react-scripts`) |

---

## Key Concepts Covered

- **CI/CD** — Continuous Integration automatically validates every change, reducing manual effort and human error.
- **Workflow** — A YAML file (`.github/workflows/ci.yml`) that defines when and how automation runs.
- **Job** — A group of steps that run on the same runner (`build-and-test`).
- **Step** — A single task within a job (checkout, install, test, build).
- **Runner** — The machine that executes the job. This project uses a **self-hosted runner** for full control over the environment.
- **Artifact** — The compiled `build/` folder, uploaded so it can be inspected or deployed after the run.
