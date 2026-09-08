#!/usr/bin/env bash
# Cleanup script for the CV repo.
# Removes template leftovers, moves stray images into assets/img,
# and strips the inherited Google Tag Manager container from index.html.
# It only reports what it does. Nothing is committed or pushed:
# review with `git status` first, then commit yourself.

set -u
cd /workspaces/CV || { echo "Not in the CV workspace. Aborting."; exit 1; }

echo "== Backing up index.html to index.html.bak =="
cp index.html index.html.bak

# ---------------------------------------------------------------
# 1. Delete template leftovers
# ---------------------------------------------------------------
remove() {
  local target="$1"
  if [ -e "$target" ]; then
    if git ls-files --error-unmatch "$target" >/dev/null 2>&1; then
      git rm -r -q --ignore-unmatch "$target" && echo "removed (tracked):   $target"
    else
      rm -rf "$target" && echo "removed (untracked): $target"
    fi
  else
    echo "not present:         $target"
  fi
}

echo
echo "== Removing template leftovers =="
remove "assets/resume/Varad_Bhogayata_Resume.pdf"
remove "assets/Music Video"
remove "CODE_OF_CONDUCT.md"
remove "allfileshas.txt"
remove "examples"

# The mistyped git file has spaces in its name, so match it by pattern.
shopt -s nullglob
for stray in "et --hard"*; do
  remove "$stray"
done
shopt -u nullglob

# If assets/resume is now empty, drop it too.
if [ -d "assets/resume" ] && [ -z "$(ls -A assets/resume)" ]; then
  rmdir assets/resume && echo "removed empty dir:   assets/resume"
fi

# ---------------------------------------------------------------
# 2. Move your own stray images into assets/img
# ---------------------------------------------------------------
echo
echo "== Moving stray images into assets/img =="
mkdir -p assets/img
shopt -s nullglob
for img in graduationlicence.png graduationmaster.png pointsportPDV.jpg \
           "Profile picture polo.png" "PICTURE - Specialist"*; do
  if [ -e "$img" ]; then
    if git ls-files --error-unmatch "$img" >/dev/null 2>&1; then
      git mv "$img" assets/img/ 2>/dev/null && echo "moved: $img -> assets/img/"
    else
      mv "$img" assets/img/ && echo "moved: $img -> assets/img/"
    fi
  fi
done
shopt -u nullglob

# ---------------------------------------------------------------
# 3. Strip the inherited Google Tag Manager container
# ---------------------------------------------------------------
echo
echo "== Removing Google Tag Manager (GTM-PGZH8HT) from index.html =="
if grep -q "GTM-PGZH8HT" index.html; then
  python3 - <<'PYEOF'
import re
p = 'index.html'
s = open(p, encoding='utf-8').read()
before = s

# Head script block
s = re.sub(r'[ \t]*<!-- Google Tag Manager -->.*?<!-- End Google Tag Manager -->\n',
           '', s, flags=re.S)
# Body noscript block
s = re.sub(r'[ \t]*<!-- Google Tag Manager \(noscript\) -->.*?</noscript>\n',
           '', s, flags=re.S)

if 'GTM-PGZH8HT' in s:
    print("  WARNING: some GTM markup remains, remove it by hand.")
open(p, 'w', encoding='utf-8').write(s)
print("  index.html: %d characters removed" % (len(before) - len(s)))
PYEOF
else
  echo "  no GTM found, nothing to do"
fi

# ---------------------------------------------------------------
# 4. Report
# ---------------------------------------------------------------
echo
echo "== Files the site actually needs (checking they survived) =="
for needed in assets/img/passport-new.jpg assets/img/bg.png \
              assets/img/white-ai-wallpaper.jpg \
              assets/vendor/typed.js/typed.min.js \
              assets/Video/self-assessment-app.mp4 \
              assets/Video/gym-weight-training.mp4 \
              assets/Video/igcse-workbook.mp4 \
              assets/Video/timetable-planner.mp4; do
  [ -e "$needed" ] && echo "  OK      $needed" || echo "  MISSING $needed"
done

echo
echo "== Done. Nothing has been committed. =="
echo "Next: open your site locally or check git status, then run:"
echo "  git add -A"
echo "  git commit -m \"Remove template leftovers and inherited GTM container\""
echo "  git push"
echo
echo "If something broke, restore the HTML with:  mv index.html.bak index.html"
echo "Once you are happy, delete the backup:      rm index.html.bak"
