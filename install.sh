#!/usr/bin/env zsh

SC_REPOSITORY="janoelze/scratches.sh"
SC_ARCHIVE_URL="https://github.com/$SC_REPOSITORY/archive/main.zip"
SC_UNZIPPED_ARCHIVE_NAME="scratches.sh-main"
SC_INSTALL_TYPE=""
SC_USER_FILE=""
SC_SHELL_NAME=$(echo $SHELL | awk -F"/" '{print $NF}')
SC_ALIAS="scratches"
SC_TARGET_DIR="$HOME/scratches"
SC_DIR_EXISTS=$(if [ -d "$SC_TARGET_DIR" ]; then echo "1"; else echo "0"; fi)

# Create scratches directory

if [ "$SC_DIR_EXISTS" = "1" ]; then
  rm -rf "$SC_TARGET_DIR/src/"
  SC_INSTALL_TYPE="update"
else
  mkdir -p "$SC_TARGET_DIR"
  mkdir -p "$SC_TARGET_DIR/env/"
  SC_INSTALL_TYPE="install"
fi

# Download the ZIP file and extract its contents to the target directory

curl -q -L "$SC_ARCHIVE_URL" -o repo.zip > /dev/null 2>&1
unzip -q repo.zip -d "$SC_TARGET_DIR"
mv "$SC_TARGET_DIR/$SC_UNZIPPED_ARCHIVE_NAME/" "$SC_TARGET_DIR/src/"
rm repo.zip

# Add the alias to the user's shell configuration file

if [ "$SC_SHELL_NAME" = "bash" ]; then
  SC_USER_FILE="$HOME/.bashrc"
elif [ "$SC_SHELL_NAME" = "zsh" ]; then
  SC_USER_FILE="$HOME/.zshrc"
fi

# Add alias to user's shell configuration file

if [ -f "$SC_USER_FILE" ]; then
  if ! grep -q "$SC_ALIAS" "$SC_USER_FILE"; then
    echo "alias $SC_ALIAS='$SC_TARGET_DIR/src/scratches.sh'" >> "$SC_USER_FILE"
  fi
fi

# Finish

if [ "$SC_INSTALL_TYPE" = "install" ]; then
  echo "scratches.sh installed successfully!"
else
  echo "scratches.sh updated successfully!"
fi

if [ "$SC_INSTALL_TYPE" = "install" ]; then
  if [ "$SC_SHELL_NAME" = "bash" ]; then
    echo "- Run 'source ~/.bashrc' to reload your shell configuration."
  elif [ "$SC_SHELL_NAME" = "zsh" ]; then
    echo "- Run 'source ~/.zshrc' to reload your shell configuration."
  fi
  echo "- Then run '$SC_ALIAS' to get started. :)"
fi