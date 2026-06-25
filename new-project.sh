#!/usr/bin/env bash
set -euo pipefail

# Print help message
usage() {
  echo "Usage: $0 -n <project-name> [-t <target-dir>]"
  echo "  -n: Name of the new project/app (e.g., my-service)"
  echo "  -t: Target directory path where the new project will be created (optional)"
  exit 1
}

NAME=""
TARGET_DIR=""

while getopts "n:t:h" opt; do
  case $opt in
    n) NAME=$OPTARG ;;
    t) TARGET_DIR=$OPTARG ;;
    h|*) usage ;;
  esac
done

if [ -z "$NAME" ]; then
  echo "Error: Project name (-n) is required."
  usage
fi

if [ -n "${BASH_SOURCE[0]:-}" ] && [ -f "${BASH_SOURCE[0]}" ]; then
  REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  REPO_ROOT="$PWD"
fi
LOCAL_TEMPLATE_DIR=""

if [ -d "$REPO_ROOT/template" ]; then
  LOCAL_TEMPLATE_DIR="$REPO_ROOT/template"
elif [ -d "$PWD/template" ]; then
  LOCAL_TEMPLATE_DIR="$PWD/template"
fi

if [ -z "$TARGET_DIR" ]; then
  TARGET_DIR="$REPO_ROOT/$NAME"
fi

if [ -d "$TARGET_DIR" ]; then
  echo "Error: Target directory '$TARGET_DIR' already exists. Choose a different name or path."
  exit 1
fi

echo "Creating project '$NAME' in: $TARGET_DIR"

if [ -n "$LOCAL_TEMPLATE_DIR" ]; then
  echo "Using local template directory..."
  cp -r "$LOCAL_TEMPLATE_DIR" "$TARGET_DIR"
else
  echo "Local template directory not found. Downloading template from GitHub (akikungz/homelab)..."
  ZIP_URL="https://github.com/akikungz/homelab/archive/refs/heads/main.zip"
  TEMP_ZIP=$(mktemp).zip
  TEMP_DIR=$(mktemp -d)
  
  if curl -L -s -o "$TEMP_ZIP" "$ZIP_URL"; then
    unzip -q "$TEMP_ZIP" -d "$TEMP_DIR"
    EXTRACTED_TEMPLATE="$TEMP_DIR/homelab-main/template"
    if [ ! -d "$EXTRACTED_TEMPLATE" ]; then
      EXTRACTED_TEMPLATE=$(find "$TEMP_DIR" -maxdepth 2 -type d -name "template" | head -n 1)
    fi
    
    if [ -d "$EXTRACTED_TEMPLATE" ]; then
      cp -r "$EXTRACTED_TEMPLATE" "$TARGET_DIR"
    else
      echo "Error: Could not find template folder in the downloaded archive."
      rm -rf "$TEMP_ZIP" "$TEMP_DIR"
      exit 1
    fi
  else
    echo "Error: Failed to download template archive."
    rm -rf "$TEMP_ZIP" "$TEMP_DIR"
    exit 1
  fi
  rm -rf "$TEMP_ZIP" "$TEMP_DIR"
fi

# Rename 'template-app' in all text files within target directory
# Perl is used for high portability across macOS (BSD) and Linux (GNU) environments without sed-i syntax variance.
find "$TARGET_DIR" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.md" -o -name "*.txt" -o -name "*.json" -o -name "*.example" -o -name "*.config" -o -name "*.secret" \) -exec perl -pi -e "s/template-app/$NAME/g" {} +
find "$TARGET_DIR" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.md" -o -name "*.txt" -o -name "*.json" -o -name "*.example" -o -name "*.config" -o -name "*.secret" \) -exec perl -pi -e "s/template\//$NAME\//g" {} +
find "$TARGET_DIR" -type f \( -name "*.yaml" -o -name "*.yml" -o -name "*.md" -o -name "*.txt" -o -name "*.json" -o -name "*.example" -o -name "*.config" -o -name "*.secret" \) -exec perl -pi -e "s/Kubernetes Kustomize Application Template/Kubernetes Kustomize - $NAME/g" {} +

# Auto-initialize .env files from templates in overlays
if [ -d "$TARGET_DIR/overlays" ]; then
  for env_dir in "$TARGET_DIR/overlays"/*/; do
    if [ -d "$env_dir" ]; then
      # Config env
      if [ -f "${env_dir}.env.config.example" ]; then
        cp "${env_dir}.env.config.example" "${env_dir}.env.config"
        perl -pi -e "s/template-app/$NAME/g" "${env_dir}.env.config"
      fi
      # Secret env
      if [ -f "${env_dir}.env.secret.example" ]; then
        cp "${env_dir}.env.secret.example" "${env_dir}.env.secret"
        perl -pi -e "s/template-app/$NAME/g" "${env_dir}.env.secret"
      fi
    fi
  done
fi

echo -e "\nSuccessfully created project '$NAME'!"
echo "Next Steps:"
echo "1. Review the configuration files in: $TARGET_DIR"
echo "2. Edit the generated .env.config and .env.secret files in overlays."
echo "3. Deploy using: kubectl apply -k $NAME/overlays/development (from the repo root)"
