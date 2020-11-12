#!/bin/bash
MyShellVar=$1
MyShellVas=$2
MyShellVat=$3
osascript <<EOD
  tell application "TeXShop"
    activate
    set the front_document to the front document
    set MyAppVar to $MyShellVar
    set MyAppVas to $MyShellVas
    set MyAppVat to "$MyShellVat"
    tell front_document
      sync_preview_line theLine MyAppVar
      sync_preview_index theIndex MyAppVas
      sync_preview_name theName MyAppVat
      return 0
    end tell
  end tell
EOD
