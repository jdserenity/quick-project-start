# Optional git init/commit and GitHub repo create/push (skipped with --no-repo).

push_to_origin_if_needed() {
  local project_dir="$1"
  local branch
  branch="$(git -C "$project_dir" branch --show-current 2>/dev/null || true)"
  [[ -z "$branch" ]] && return 0
  echo "Pushing to origin ($branch)..." >&2
  if git -C "$project_dir" push -u origin "$branch" >/dev/null 2>&1; then
    echo "Push complete." >&2
  elif git -C "$project_dir" push origin "$branch" >/dev/null 2>&1; then
    echo "Push complete." >&2
  else
    echo "Warning: push to origin failed; commits are local." >&2
  fi
}

setup_git_and_github() {
  local project_dir="$1"
  local project_name="$2"
  local repo_name="${project_name:-$(basename "$project_dir")}"
  local commit_msg="init"
  local repo_url

  if ! command -v git >/dev/null 2>&1; then
    echo "Warning: git is not installed; skipped git and GitHub setup." >&2
    return 0
  fi

  if [[ ! -d "$project_dir/.git" ]]; then
    echo "Initializing git repository..." >&2
    git -C "$project_dir" init >/dev/null
    git -C "$project_dir" branch -M main
  elif git -C "$project_dir" rev-parse --verify HEAD >/dev/null 2>&1; then
    commit_msg="Add scaffold"
  fi

  git -C "$project_dir" add -A
  if ! git -C "$project_dir" diff --cached --quiet; then
    echo "Committing: $commit_msg" >&2
    git -C "$project_dir" commit -m "$commit_msg" >/dev/null
  fi

  if git -C "$project_dir" remote get-url origin >/dev/null 2>&1; then
    echo "Remote origin already set; skipping GitHub repo create." >&2
    push_to_origin_if_needed "$project_dir"
    return 0
  fi

  if ! command -v gh >/dev/null 2>&1; then
    echo "Warning: GitHub CLI (gh) is not installed; skipped remote repo creation." >&2
    return 0
  fi

  if ! gh auth status >/dev/null 2>&1; then
    echo "Warning: gh is not authenticated; skipped remote repo creation." >&2
    return 0
  fi

  if gh repo view "$repo_name" >/dev/null 2>&1; then
    repo_url="$(gh repo view "$repo_name" --json url -q .url)"
    echo "GitHub repo $repo_name already exists; linking origin and pushing." >&2
    git -C "$project_dir" remote add origin "$repo_url"
    push_to_origin_if_needed "$project_dir"
    return 0
  fi

  echo "Creating GitHub repo $repo_name and pushing..." >&2
  if ! (
    cd "$project_dir"
    gh repo create "$repo_name" --source=. --public --push
  ); then
    echo "Warning: failed to create or push GitHub repo; local git repo is ready." >&2
  else
    echo "GitHub repo created and pushed." >&2
  fi
}
