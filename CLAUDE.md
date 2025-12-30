# Claude Code Instructions for ohschooldata

## Commit Messages
- Do NOT include "Generated with Claude Code" in commit messages
- Do NOT include "Co-Authored-By: Claude" in commit messages
- Do NOT mention Claude or AI assistance in PR descriptions

## Package Conventions
- Follow tidyverse style guide
- Use roxygen2 for documentation
- All exported functions should have examples
- Cache downloaded data to avoid repeated API calls

## Ohio-Specific Notes
- IRN (Information Retrieval Number) is 6 digits for districts/schools
- Data source: Ohio Department of Education and Workforce (ODEW)
- Primary data system: EMIS (Education Management Information System)
- District types: city, local, exempted village, joint vocational
