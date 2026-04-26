#!/usr/bin/env bash
set -e

TARGET_DIR="$1"

if [ -z "$TARGET_DIR" ]; then
  echo "Usage: sync_source <repo_path>"
  exit 1
fi

if [ ! -d "$TARGET_DIR/.git" ]; then
  echo "Error: $TARGET_DIR is not a git repository"
  exit 1
fi

cd "$TARGET_DIR"

echo "==> Repo: $TARGET_DIR"

# 检查 upstream
if ! git remote | grep -q upstream; then
  echo "Error: upstream remote not found"
  exit 1
fi

echo "==> Fetch upstream"
git fetch upstream --prune

echo "==> Fetch origin"
git fetch origin --prune

# upstream 分支列表
UPSTREAM_BRANCHES=$(git branch -r | grep upstream/ | grep -v 'HEAD' | sed 's|upstream/||')

echo "==> Sync upstream branches to local + origin"

for branch in $UPSTREAM_BRANCHES; do
  echo "---- Processing branch: $branch"

  # 判断本地是否已有该分支
  if git show-ref --verify --quiet refs/heads/$branch; then
    echo "      Local branch exists -> hard reset to upstream"
    git checkout "$branch"
    git reset --hard "upstream/$branch"
  else
    echo "      Create local branch from upstream"
    git checkout -B "$branch" "upstream/$branch"
  fi

  # 推送到 origin（强制同步 upstream 分支）
  echo "      Push to origin"
  git push origin "$branch" --force
done

echo "==> Done: upstream synced, origin updated"

echo "==> Summary:"
echo "   ✔ Upstream branches synced"
echo "   ✔ Origin updated"
echo "   ✔ Your custom branches untouched"
