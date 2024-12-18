#!/bin/bash

# 检查是否安装 jq，如果没有安装，则安装
if ! command -v jq &> /dev/null; then
  echo "jq is not installed. Installing jq..."
  sudo apt-get update && sudo apt-get install jq -y
fi

# 设置 GitHub 仓库列表（可以根据需要修改）
declare -a repos=("anshaxing/Dumphash" "shadow1ng/fscan" "chainreactors/gogo")

# GitLab 仓库信息
GITLAB_REPO_URL="http://192.168.17.239:40080/sectools/syncgithubtogitlab.git"

# GitHub API 认证 Token（如果需要）
GITHUB_TOKEN="your_github_token"  # 确保替换为你的 GitHub token

# GitLab 项目路径
GITLAB_REPO_DIR="/root/SyncGithubToGitlab"

# 检查 GitLab 仓库路径是否存在
if [ ! -d "$GITLAB_REPO_DIR" ]; then
  echo "GitLab repository directory $GITLAB_REPO_DIR does not exist. Exiting..."
  exit 1
fi

# 遍历每个 GitHub 仓库
for repo in "${repos[@]}"; do
  echo "Checking for updates in $repo..."

  # 获取 GitHub 仓库的最新提交（仅返回第一个提交）
  latest_commit=$(curl -s -H "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/$repo/commits?per_page=1")
  echo "API Response: $latest_commit"
  latest_commit=$(echo $latest_commit | jq -r '.[0].sha')

  # 如果 API 请求失败或没有获取到最新提交，则跳过此仓库
  if [ "$latest_commit" == "null" ]; then
    echo "Failed to retrieve commits for $repo. Skipping..."
    continue
  fi

  # 进入 GitLab 仓库目录
  cd $GITLAB_REPO_DIR

  # 如果本地 GitLab 仓库没有该 GitHub 仓库的更新记录，初始化该仓库
  repo_name=$(basename "$repo")
  if [ ! -d "$repo_name" ]; then
    echo "Initializing $repo_name in GitLab..."
    git clone "https://github.com/$repo.git"
    cd "$repo_name"
  else
    cd "$repo_name"
    local_commit=$(git log -n 1 --pretty=format:"%H")
    
    if [ "$latest_commit" != "$local_commit" ]; then
      echo "Updating $repo_name from GitHub..."

      # 获取 GitHub 仓库的更新并合并到本地
      git fetch origin
      git pull origin main  # 或 master，根据实际分支名修改
      git merge origin/main  # 或 master，根据实际分支名修改

      # 推送到 GitLab
      git push "$GITLAB_REPO_URL" main  # 或 master，根据实际分支名修改
    else
      echo "$repo_name is already up to date."
    fi
  fi

  # 返回到 GitLab 仓库目录，准备同步下一个仓库
  cd $GITLAB_REPO_DIR
done

echo "Sync completed."

