#!/usr/bin/env bash
# Publishes store/site/ (VILLE's support and privacy pages) to GitHub Pages.
#
#   bash store/publish-site.sh
#
# GitHub Pages serves the gh-pages branch, which holds only these files:
#   https://blhdes.github.io/village/              support
#   https://blhdes.github.io/village/privacy.html  privacy policy
# Edit the pages in store/site/, commit, then run this again. Pages updates in about a minute.

set -euo pipefail
cd "$(dirname "$0")/.."

SITE_DIR="store/site"
BRANCH="gh-pages"
WORKTREE="$(mktemp -d)/site"
trap 'git worktree remove --force "$WORKTREE" >/dev/null 2>&1 || true' EXIT

if grep -rIq "{{" "$SITE_DIR"; then   # -I skips images, whose bytes can contain "{{"
  echo "❌ $SITE_DIR still has {{placeholders}}. Fill them before publishing." >&2
  exit 1
fi

# A temporary checkout of gh-pages, so the branch you're on stays untouched.
if git ls-remote --exit-code --heads origin "$BRANCH" >/dev/null; then
  git fetch --quiet origin "$BRANCH"
  git worktree add --quiet -B "$BRANCH" "$WORKTREE" "origin/$BRANCH"
else
  git worktree add --quiet --orphan -b "$BRANCH" "$WORKTREE"
fi

# Replace everything with the current pages. .nojekyll serves them as they are.
git -C "$WORKTREE" rm -rf --quiet --ignore-unmatch .
cp -R "$SITE_DIR"/. "$WORKTREE"/
touch "$WORKTREE/.nojekyll"
git -C "$WORKTREE" add -A

if git -C "$WORKTREE" diff --cached --quiet; then
  echo "Nothing changed: the published pages already match $SITE_DIR."
  exit 0
fi

SOURCE="$(git rev-parse --short HEAD)"
git -C "$WORKTREE" commit --quiet -m "docs: publish VILLE's support and privacy pages (from $SOURCE)"
git -C "$WORKTREE" push --quiet origin "$BRANCH"
echo "✅ Published. Live in about a minute at https://blhdes.github.io/village/"
