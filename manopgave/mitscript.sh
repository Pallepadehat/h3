#!/usr/bin/env bash
set -u

PROG="mitscript"
VERSION="1.0"

EFFECT=""
FRAMES="120"
DELAY="0.1"

cleanup() {
  command -v tput >/dev/null 2>&1 && tput cnorm || true
  if [[ -t 0 ]]; then
    stty echo icanon 2>/dev/null || true
  fi
  printf "\033[0m"
}
trap cleanup EXIT INT TERM

die() {
  printf "%s: %s\n" "$PROG" "$1" >&2
  exit "${2:-1}"
}

usage() {
  cat <<'EOF'
Brug:
  ./mitscript.sh [options]

Effekter:
  -t, --tree            Vis et juletrae (statisk).
  -f, --fireworks       Vis fyrvaerkeri (animation).
  -s, --snow            Vis sne (animation).

Indstillinger:
  -n, --frames N        Antal frames/raketter. Default: 120
  -d, --delay SECONDS   Pause mellem frames. Default: 0.1

Hjaelp:
  --man                 Aabn man-siden.
  -h, --help            Vis denne hjaelp.

Eksempler:
  ./mitscript.sh --tree
  ./mitscript.sh --fireworks -n 5
  ./mitscript.sh --snow

Stop animation: Tryk 'q' eller Ctrl+C.
EOF
}

require_number() {
  local v="$1"
  [[ "$v" =~ ^[0-9]+$ ]] || die "Forventede et heltal, fik: $v"
}

cols() { tput cols 2>/dev/null || echo 80; }
lines() { tput lines 2>/dev/null || echo 24; }

clear_screen() { printf "\033[H\033[2J"; }
hide_cursor() { printf "\033[?25l"; }
show_cursor() { printf "\033[?25h"; }

# Check for key press (non-blocking)
check_quit() {
  local key=""
  read -rsn1 -t 0.01 key 2>/dev/null || true
  [[ "$key" == "q" || "$key" == "Q" ]]
}

effect_tree() {
  clear_screen
  local w h cx
  w=$(cols)
  h=$(lines)
  cx=$((w / 2))

  # Colors
  local G="\033[32m"   # Green
  local Y="\033[33m"   # Yellow  
  local R="\033[31m"   # Red
  local B="\033[34m"   # Blue
  local M="\033[35m"   # Magenta
  local C="\033[36m"   # Cyan
  local W="\033[97m"   # White
  local RS="\033[0m"   # Reset

  local row=3

  # Star
  printf "\033[%d;%dH${Y}*${RS}" "$row" "$cx"
  ((row++))

  # Tree layers (green with colored ornaments)
  printf "\033[%d;%dH${G}/${R}o${G}\\\\${RS}" "$row" "$((cx-1))"
  ((row++))
  
  printf "\033[%d;%dH${G}/${B}o${G}_${C}o${G}\\\\${RS}" "$row" "$((cx-2))"
  ((row++))
  
  printf "\033[%d;%dH${G}/${M}o${G}_${R}o${G}_${B}o${G}\\\\${RS}" "$row" "$((cx-3))"
  ((row++))
  
  printf "\033[%d;%dH${G}/${C}o${G}_${M}o${G}_${Y}o${G}_${R}o${G}\\\\${RS}" "$row" "$((cx-4))"
  ((row++))
  
  printf "\033[%d;%dH${G}/${B}o${G}_${R}o${G}_${C}o${G}_${M}o${G}_${Y}o${G}\\\\${RS}" "$row" "$((cx-5))"
  ((row++))
  
  printf "\033[%d;%dH${G}/${Y}o${G}_${B}o${G}_${M}o${G}_${R}o${G}_${C}o${G}_${B}o${G}\\\\${RS}" "$row" "$((cx-6))"
  ((row++))

  # Trunk
  printf "\033[%d;%dH${Y}|||${RS}" "$row" "$((cx-1))"
  ((row++))
  printf "\033[%d;%dH${Y}|||${RS}" "$row" "$((cx-1))"
  ((row+=2))

  # Message
  printf "\033[%d;%dH${W}Glaedelig Jul!${RS}" "$row" "$((cx - 7))"
  ((row+=2))
  
  printf "\033[%d;%dHTip: proev --fireworks eller --snow" "$row" "$((cx - 18))"
  
  # Move cursor to bottom
  printf "\033[%d;1H\n" "$h"
}


effect_fireworks() {
  hide_cursor
  local w h
  w=$(cols)
  h=$(lines)

  # Setup non-blocking input
  if [[ -t 0 ]]; then
    stty -echo -icanon min 0 time 1 2>/dev/null || true
  fi

  # Number of rockets based on FRAMES parameter
  local num_rockets=$((FRAMES / 20))
  ((num_rockets < 3)) && num_rockets=3
  ((num_rockets > 15)) && num_rockets=15

  for ((rocket = 0; rocket < num_rockets; rocket++)); do
    if check_quit; then break; fi

    # Random launch position
    local launch_x=$((10 + RANDOM % (w - 20)))
    local target_y=$((4 + RANDOM % (h / 3)))
    
    # Pick a color for this rocket
    local colors=("31" "32" "33" "34" "35" "36" "91" "92" "93" "94" "95" "96")
    local col="\033[${colors[$((RANDOM % ${#colors[@]}))]}m"
    local rs="\033[0m"

    # === PHASE 1: Rocket launch (bottom to target) ===
    for ((y = h - 2; y > target_y; y -= 2)); do
      if check_quit; then break 2; fi
      
      clear_screen
      
      # Draw rocket
      printf "\033[%d;%dH${col}^${rs}" "$y" "$launch_x"
      printf "\033[%d;%dH${col}|${rs}" "$((y + 1))" "$launch_x"
      
      # Footer
      printf "\033[%d;1HRaket %d/%d - Tryk 'q' for at stoppe" "$h" "$((rocket + 1))" "$num_rockets"
      
      sleep 0.04
    done

    # === PHASE 2: Explosion (expanding) ===
    for ((radius = 1; radius <= 5; radius++)); do
      if check_quit; then break 2; fi
      
      clear_screen
      
      # Draw explosion rays in 8 directions
      local dx dy nx ny
      for dx in -1 0 1; do
        for dy in -1 0 1; do
          for ((r = 1; r <= radius; r++)); do
            nx=$((launch_x + dx * r * 2))
            ny=$((target_y + dy * r))
            if ((nx > 0 && nx < w && ny > 0 && ny < h - 1)); then
              local char="."
              ((r == radius)) && char="*"
              printf "\033[%d;%dH${col}%s${rs}" "$ny" "$nx" "$char"
            fi
          done
        done
      done
      
      # Center burst
      printf "\033[%d;%dH${col}@${rs}" "$target_y" "$launch_x"
      
      printf "\033[%d;1HRaket %d/%d - BOOM!" "$h" "$((rocket + 1))" "$num_rockets"
      sleep 0.1
    done

    # === PHASE 3: Fade out ===
    for ((fade = 5; fade >= 1; fade--)); do
      if check_quit; then break 2; fi
      
      clear_screen
      
      for dx in -1 0 1; do
        for dy in -1 0 1; do
          local r=$fade
          nx=$((launch_x + dx * r * 2))
          ny=$((target_y + dy * r))
          if ((nx > 0 && nx < w && ny > 0 && ny < h - 1)); then
            printf "\033[%d;%dH${col}.${rs}" "$ny" "$nx"
          fi
        done
      done
      
      printf "\033[%d;1HRaket %d/%d" "$h" "$((rocket + 1))" "$num_rockets"
      sleep 0.08
    done

    # Pause between rockets
    sleep 0.2
  done

  clear_screen
  printf "\033[%d;%dHFyrvaerkeri faerdigt!" "$((h/2))" "$((w/2 - 10))"
  printf "\033[%d;1H\n" "$h"
  sleep 1
  
  show_cursor
}

effect_snow() {
  hide_cursor
  local w h i
  w=$(cols)
  h=$(lines)

  # Initialize snowflake positions
  declare -a snow_x snow_y
  local num_flakes=$((w / 4))
  for ((f = 0; f < num_flakes; f++)); do
    snow_x[$f]=$((1 + RANDOM % w))
    snow_y[$f]=$((1 + RANDOM % h))
  done

  # Setup non-blocking input
  if [[ -t 0 ]]; then
    stty -echo -icanon min 0 time 1 2>/dev/null || true
  fi

  local flakes=("*" "." "+" "o")

  for ((i = 0; i < FRAMES; i++)); do
    if check_quit; then break; fi

    clear_screen

    # Draw and move snowflakes
    for ((f = 0; f < num_flakes; f++)); do
      local x=${snow_x[$f]}
      local y=${snow_y[$f]}

      # Draw flake
      if ((y > 0 && y < h - 1 && x > 0 && x <= w)); then
        local flake="${flakes[$((RANDOM % ${#flakes[@]}))]}"
        printf "\033[%d;%dH\033[97m%s\033[0m" "$y" "$x" "$flake"
      fi

      # Move flake down
      y=$((y + 1))
      x=$((x + (RANDOM % 3) - 1))

      # Reset if off screen
      if ((y >= h - 1)); then
        y=1
        x=$((1 + RANDOM % w))
      fi
      ((x < 1)) && x=$w
      ((x > w)) && x=1

      snow_x[$f]=$x
      snow_y[$f]=$y
    done

    # Footer
    printf "\033[%d;1HSne [%d/%d] - Tryk 'q' for at stoppe" "$h" "$((i + 1))" "$FRAMES"

    sleep "$DELAY"
  done

  show_cursor
}

# Parse args
if (($# == 0)); then
  usage
  exit 1
fi

while (($# > 0)); do
  case "${1:-}" in
  -t | --tree)
    EFFECT="tree"
    shift
    ;;
  -f | --fireworks)
    EFFECT="fireworks"
    shift
    ;;
  -s | --snow)
    EFFECT="snow"
    shift
    ;;
  -n | --frames)
    shift
    [[ $# -gt 0 ]] || die "Mangler vaerdi til --frames"
    require_number "$1"
    FRAMES="$1"
    shift
    ;;
  -d | --delay)
    shift
    [[ $# -gt 0 ]] || die "Mangler vaerdi til --delay"
    DELAY="$1"
    shift
    ;;
  --man)
    HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    MANFILE="$HERE/mitscript.1"
    [[ -f "$MANFILE" ]] || die "Kan ikke finde man-side: $MANFILE"
    man "$MANFILE"
    exit 0
    ;;
  -h | --help)
    usage
    exit 0
    ;;
  *)
    die "Ukendt option: $1 (brug --help)" 2
    ;;
  esac
done

case "$EFFECT" in
tree) effect_tree ;;
fireworks) effect_fireworks ;;
snow) effect_snow ;;
*) die "Vaelg en effekt: --tree, --fireworks eller --snow" ;;
esac
