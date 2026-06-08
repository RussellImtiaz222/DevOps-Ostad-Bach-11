# Job Search Automation

Local tools to turn your resume into a repeatable job search workflow:

- Extract a simple candidate profile from your resume.
- Score job descriptions against your resume keywords.
- Track applications in a CSV file.
- Export a prioritized shortlist.

This starter intentionally does not auto-apply to jobs. It helps you find and rank good matches, then keeps the application workflow organized.

## Quick Start

Install the project locally:

```powershell
python -m pip install -e .
```

1. Put your resume in `data/resume/`.
   Supported formats:
   - `.txt` and `.md` work with no extra packages.
   - `.pdf` needs `pypdf`.
   - `.docx` needs `python-docx`.

2. Create a profile from your resume:

```powershell
job-search profile data/resume/your-resume.txt
```

3. Score a job description:

```powershell
job-search score data/jobs/sample-job.txt
```

4. Add an application to the tracker:

```powershell
job-search add "Example Company" "Data Analyst" "https://example.com/job" --status "Interested"
```

5. View tracked applications:

```powershell
job-search list
```

## Suggested Workflow

1. Save promising job descriptions into `data/jobs/`.
2. Run `score` for each job description.
3. Add strong matches to the tracker.
4. Tailor your resume and cover letter for the highest-scoring jobs.
5. Update statuses as you apply, interview, and follow up.

## Files

- `data/resume/` - your resume files.
- `data/jobs/` - job descriptions to score.
- `data/applications.csv` - application tracker.
- `src/job_search_automation/` - automation code.

## Next Improvements

- Add job board search integrations.
- Generate tailored resume bullet suggestions.
- Generate draft cover letters.
- Add follow-up reminders.
- Build a small dashboard.
## Module 8 DevOps Assignment

The complete Terraform, CI/CD, Grafana, Loki, Promtail, Node Exporter, and dashboard solution is in [devops/README.md](devops/README.md).
