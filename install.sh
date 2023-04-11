#!/usr/bin/env bash

function add_alias(){
  local RC_FILE="$1"
  local ALIAS="$2"

  # Add a newline to the end of the file if it doesn't already have one
  if [ "$(tail -c 1 "$RC_FILE")" ]; then
    echo "" >> "$RC_FILE"
    echo "" >> "$RC_FILE"
  fi

  # Check if the alias is already in the file
  if [ -f "$RC_FILE" ]; then
    if ! grep -q "$ALIAS" "$RC_FILE"; then
      echo "alias $ALIAS=\"sh $TARGET_DIR/src/scratches.sh\"" >> "$RC_FILE"
    fi
  fi
}

function install_scratches(){
  local SCRATCHES_REPOSITORY="janoelze/scratches.sh"
  local REPO_URL="https://github.com/$SCRATCHES_REPOSITORY/archive/main.zip"
  local SCRATCHES_ARCHIVE_NAME="scratches.sh-main"
  local INSTALL_TYPE=""
  local ALIAS="ghscratches"

  # Define the directory to extract the contents of the ZIP file to
  local TARGET_DIR="$HOME/scratches-live"

  if [ -d "$TARGET_DIR" ]; then
    # Remove the existing directory and its contents
    rm -rf "$TARGET_DIR/src/"
    # Set the install type to "update"
    INSTALL_TYPE="update"
  else
    # Create the directory and its subdirectories
    mkdir -p "$TARGET_DIR"
    mkdir -p "$TARGET_DIR/src/"
    mkdir -p "$TARGET_DIR/projects/"
    # Set the install type to "install"
    INSTALL_TYPE="install"
  fi

  # Download the ZIP file and extract its contents to the target directory
  curl -q -L "$REPO_URL" -o repo.zip > /dev/null 2>&1
  unzip -q repo.zip -d "$TARGET_DIR/"
  mv "$TARGET_DIR/$SCRATCHES_ARCHIVE_NAME" "$TARGET_DIR/src"

  # Clean up by deleting the ZIP file
  rm repo.zip

  # Add the alias to the user's shell configuration file
  if [ -f "$HOME/.bashrc" ]; then
    add_alias "$HOME/.bashrc" "$ALIAS"
  elif [ -f "$HOME/.zshrc" ]; then
    add_alias "$HOME/.zshrc" "$ALIAS"
  fi

  if [ "$INSTALL_TYPE" = "install" ]; then
    echo "scratches.sh installed successfully!"
  else
    echo "scratches.sh updated successfully!"
  fi

  if [ "$INSTALL_TYPE" = "install" ]; then
    if [ -f "$HOME/.bashrc" ]; then
      echo "- Run 'source ~/.bashrc' to reload your shell configuration."
    elif [ -f "$HOME/.zshrc" ]; then
      echo "- Run 'source ~/.zshrc' to reload your shell configuration."
    fi
    echo "- Then run '$ALIAS' to get started. :)"
  fi
}

install_scratches