---
name: create-ticket
description: Draft and create Jumbalaya tickets in Linear with a readiness check and explicit user approval. Use when the user invokes /create-ticket or asks to turn an idea into a Linear issue.
---

# Create a Jumbalaya Linear issue

Turn the user's idea into a reviewable Linear issue. This workflow creates tickets only; never implement the requested product change, move an existing issue, or start `/run-ticket`.

## Workflow

1. Clarify the idea before asking to create anything. Ask focused questions when missing details could materially change scope, behavior, or verification. If the user cannot answer or wants to capture an incomplete idea, preserve the gaps under **Open questions**, mark readiness accordingly, and keep the issue in Backlog; do not fill gaps by guessing.
2. Draft one issue using this description template, retaining every relevant detail the user supplied:

   ```text
   Branch: <branch name or Not assigned>
   #<Linear number> <Title>

   ## Goal
   <Outcome and reason>

   ## Requirements
   - <Requirement>
     Why: <Rationale, when supplied>

   ## Words used on this card:
   - <Term>: <Meaning>

   ## Acceptance criteria
   - <Observable result>

   ## How to test
   - <Setup, action, and expected result>

   ## Out of scope
   - <Explicit exclusions>

   ## Open questions
   - <Unresolved decision>
   ```

   Use `Not assigned` when no branch is supplied; never create or guess a branch. Preserve supplied **Why** rationales and detailed test setup/actions/results. Do not invent requirements, definitions, rationale, test steps, or product decisions; use `None specified` for an empty **Words used on this card** section and keep unresolved decisions visible under **Open questions**. The final Linear title format is `#<Linear number> - <Title>`; the numbered line in the description uses `#<Linear number> <Title>`.
3. Delegate the complete draft to the existing `scrum-master` agent for its readiness verdict and feedback. If delegation is unavailable, state that readiness was not checked; do not impersonate the scrum master or claim the issue is Ready. Ask the user about material blockers the scrum master identifies; do not invent scope to resolve them.
4. Use the connected Linear MCP tools to identify the intended team, project, and that team's Backlog state. Do not guess if multiple destinations match. Ask the user when a destination is missing or ambiguous. If Linear is unavailable or unauthenticated, explain that the user must connect/authorize it in Cursor before proceeding.
5. Before creating anything, present the exact provisional title and full description, readiness verdict and blockers, and Linear team, project, and destination. Since Linear assigns its identifier only on creation, disclose that the provisional issue will have an unnumbered `<Title>` and `#Pending <Title>` description line, and that it will appear in Backlog before final numbering. A Not ready or unchecked issue may only be created in Backlog (or another explicitly confirmed non-ready state), never Ready. If no suitable non-ready state exists, ask the user how to proceed. Wait for explicit approval of this exact provisional content and destination; an initial request to create a ticket is not approval.
6. After approval, create exactly one issue and confirm its returned link and identifier. Use the numeric part of the confirmed identifier (for example, `ASH-275` gives `275`); never predict or invent it. If creation is uncertain, check whether the issue exists before taking any further action; never blindly retry.
7. Once the number is confirmed, show the exact final title and full description with the number filled in, along with the same destination. Get a second explicit approval before updating that same issue. If the user edits the final content, show it and obtain approval again. Update only the existing issue; if the user declines, leave the provisional issue in Backlog and report that it remains unnumbered. If the number or update result is uncertain, report the blocker and verify the existing issue before any retry; do not create a duplicate or claim completion without confirmation.

## Boundaries

- An incomplete idea can be captured in Backlog with its open questions visible, but must not be presented as Ready.
- Ask and resolve material clarifying questions before the first approval. Numbering requires two approvals because Linear does not return the issue number until after the provisional issue is created.
- Do not create a branch, commit, PR, webhook, or automation as part of this skill.
- Do not request or store Linear API tokens in project files. Use Cursor's OAuth authorization for the configured Linear MCP server.
- Never create or update an issue without explicit approval of the exact displayed content and destination for that operation.