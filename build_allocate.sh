#!/bin/bash

# Fill these in if building for online use
supabase_url="your-url-here"
supabase_annon_key="your-key-here"

# targets: ios, apk, aab, macos, windows, linux
target_os="your-target-os"

# Set to true if building offline only
offline="false"

if [[ -z $(which flutter) ]]; then 
  echo "Install Flutter and add to \$PATH before running this script."
  exit 1
fi

if [[ -z $(which supabase) ]]; then 
  echo "Install Supabase CLI and add to \$PATH before running this script."
  exit 1
fi

### Flutter

flutter pub clean
flutter pub get

# Enter 1 (delete old) if prompted
dart run build_runner build
dart run icons_launcher:create
dart run flutter_native_splash:create

flutter build "$target_os" \
  --release \
  --dart-define=SUPABASE_URL="$supabase_url" \
  --dart-define=SUPABASE_ANNON_KEY="$supabase_annon_key" \
  --dart-define=OFFLINE="$offline"

if [[ $? -ne 0 ]]; then
  echo "Build Failure: See above build output for errors"
  exit 1
fi

if [[ "$offline" == "true" ]]; then
  echo "Build Successful: See \"Installation\" for next steps"
  exit 0
fi

### SUPABASE

supabase login
supabase init
supabase link
cp -r "supabase_config/functions" "supabase/"

supabase functions deploy delete_user_account


if [[ $? -ne 0 ]]; then
  echo "Supabase Failure: See the above output for errors"
  exit 1
fi

echo "Build Successful: See \"Installation\" for next steps"
exit 0
