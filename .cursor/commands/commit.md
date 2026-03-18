# Incremental conventional commit

Review all staged and unstaged changes in the working tree.

Group related changes into logical, minimal commits. For each group:

1. Stage only the files belonging to that group
2. Write a commit message following the Conventional Commits rule (`conventional-commits.mdc`)
3. Present the proposed commit (files + message) to the user and **wait for explicit confirmation** before running `git commit`
4. After the user confirms, commit

Repeat until all changes are committed.
