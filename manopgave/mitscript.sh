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
  printf "\033[%d;%dH${W}Glædelig Jul!${RS}" "$row" "$((cx - 7))"
  ((row+=2))
  
  printf "\033[%d;%dHTip: Prøv --fireworks eller --snow" "$row" "$((cx - 18))"
  
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

  # Launch position (center of screen)
  local launch_x=$((w / 2))
  local target_y=$((h / 4))
  
  # Pick a color for this rocket
  local colors=("31" "32" "33" "34" "35" "36" "91" "92" "93" "94" "95" "96")
  local col="\033[${colors[$((RANDOM % ${#colors[@]}))]}m"
  local rs="\033[0m"

  clear_screen

  # === PHASE 1: Rocket launch (bottom to target) ===
  for ((y = h - 2; y > target_y; y--)); do
    if check_quit; then
      show_cursor
      return
    fi
    
    clear_screen
    
    # Draw rocket with trail
    printf "\033[%d;%dH${col}▲${rs}" "$y" "$launch_x"
    printf "\033[%d;%dH${col}│${rs}" "$((y + 1))" "$launch_x"
    if ((y + 2 < h - 1)); then
      printf "\033[%d;%dH\033[33m*${rs}" "$((y + 2))" "$launch_x"
    fi
    if ((y + 3 < h - 1)); then
      printf "\033[%d;%dH\033[31m.${rs}" "$((y + 3))" "$launch_x"
    fi
    
    # Footer
    printf "\033[%d;1HRaket affyret! 🚀" "$h"
    
    sleep 0.03
  done

  # === PHASE 2: Explosion (expanding) ===
  local explosion_chars=("*" "✦" "✷" "◦" "·")
  for ((radius = 1; radius <= 8; radius++)); do
    if check_quit; then
      show_cursor
      return
    fi
    
    clear_screen
    
    # Draw explosion rays in 8 directions with sparkle effect
    local dx dy nx ny
    for dx in -1 0 1; do
      for dy in -1 0 1; do
        for ((r = 1; r <= radius; r++)); do
          nx=$((launch_x + dx * r * 2))
          ny=$((target_y + dy * r))
          if ((nx > 0 && nx < w && ny > 0 && ny < h - 1)); then
            local char="${explosion_chars[$((RANDOM % ${#explosion_chars[@]}))]}"
            ((r == radius)) && char="✸"
            printf "\033[%d;%dH${col}%s${rs}" "$ny" "$nx" "$char"
          fi
        done
      done
    done
    
    # Center burst
    printf "\033[%d;%dH${col}💥${rs}" "$target_y" "$launch_x"
    
    printf "\033[%d;1H🎆 BOOM! 🎆" "$h"
    sleep 0.08
  done

  # === PHASE 3: Sparkle and fade out ===
  for ((fade = 8; fade >= 1; fade--)); do
    if check_quit; then
      show_cursor
      return
    fi
    
    clear_screen
    
    # Fading sparks falling down
    for dx in -1 0 1; do
      for dy in -1 0 1; do
        local r=$fade
        nx=$((launch_x + dx * r * 2 + (RANDOM % 3) - 1))
        ny=$((target_y + dy * r + (8 - fade)))
        if ((nx > 0 && nx < w && ny > 0 && ny < h - 1)); then
          local fade_char="·"
          ((fade > 4)) && fade_char="."
          ((fade > 6)) && fade_char="*"
          printf "\033[%d;%dH${col}%s${rs}" "$ny" "$nx" "$fade_char"
        fi
      done
    done
    
    printf "\033[%d;1H✨ Fyrværkeri ✨" "$h"
    sleep 0.1
  done

  # Final message
  clear_screen
  printf "\033[%d;%dH🎆 Godt Nytår! 🎆" "$((h/2))" "$((w/2 - 9))"
  printf "\033[%d;1H\n" "$h"
  sleep 1.5
  
  show_cursor
}

effect_snow() {
  hide_cursor
  local w h
  w=$(cols)
  h=$(lines)

  # Setup non-blocking input
  if [[ -t 0 ]]; then
    stty -echo -icanon min 0 time 1 2>/dev/null || true
  fi

  # Initialize snowflake positions - all start at top
  declare -a snow_x snow_y snow_speed snow_active
  local num_flakes=$((w / 3))
  for ((f = 0; f < num_flakes; f++)); do
    snow_x[$f]=$((1 + RANDOM % w))
    snow_y[$f]=$((-(RANDOM % (h / 2))))  # Start above screen, staggered
    snow_speed[$f]=$((1 + RANDOM % 2))   # Random fall speed
    snow_active[$f]=1
  done

  local flakes=("❄" "❅" "❆" "*" "." "·")
  local ground_snow=""
  
  # Build ground accumulation area
  declare -a ground
  for ((x = 0; x <= w; x++)); do
    ground[$x]=0
  done

  local all_landed=0
  local frame=0

  while ((all_landed == 0)); do
    if check_quit; then
      show_cursor
      return
    fi

    clear_screen
    all_landed=1

    # Draw and move snowflakes
    for ((f = 0; f < num_flakes; f++)); do
      if ((snow_active[$f] == 0)); then
        continue
      fi

      local x=${snow_x[$f]}
      local y=${snow_y[$f]}
      local spd=${snow_speed[$f]}

      # Draw flake if on screen
      if ((y > 0 && y < h - 2 && x > 0 && x <= w)); then
        local flake="${flakes[$((RANDOM % ${#flakes[@]}))]}"
        printf "\033[%d;%dH\033[97m%s\033[0m" "$y" "$x" "$flake"
        all_landed=0
      fi

      # Move flake down
      y=$((y + spd))
      x=$((x + (RANDOM % 3) - 1))

      # Wrap horizontally
      ((x < 1)) && x=$w
      ((x > w)) && x=1

      # Check if landed
      if ((y >= h - 2)); then
        snow_active[$f]=0
        # Add to ground pile
        if ((x > 0 && x <= w)); then
          ground[$x]=$((ground[$x] + 1))
        fi
      else
        snow_x[$f]=$x
        snow_y[$f]=$y
        if ((y > 0)); then
          all_landed=0
        fi
      fi
    done

    # Draw accumulated snow on ground
    for ((x = 1; x <= w; x++)); do
      local pile=${ground[$x]:-0}
      if ((pile > 0)); then
        local snow_char="░"
        ((pile > 1)) && snow_char="▒"
        ((pile > 2)) && snow_char="▓"
        ((pile > 3)) && snow_char="█"
        printf "\033[%d;%dH\033[97m%s\033[0m" "$((h - 1))" "$x" "$snow_char"
      fi
    done

    # Footer
    ((frame++))
    printf "\033[%d;1H❄️ Sne falder... Tryk 'q' for at stoppe" "$h"

    sleep 0.05
  done

  # Final message
  clear_screen
  
  # Draw final snow pile
  for ((x = 1; x <= w; x++)); do
    local pile=${ground[$x]:-0}
    if ((pile > 0)); then
      local snow_char="░"
      ((pile > 1)) && snow_char="▒"
      ((pile > 2)) && snow_char="▓"
      ((pile > 3)) && snow_char="█"
      printf "\033[%d;%dH\033[97m%s\033[0m" "$((h - 1))" "$x" "$snow_char"
    fi
  done

  printf "\033[%d;%dH❄️ Sneen er faldet! ❄️"  "$((h/2))" "$((w/2 - 11))"
  printf "\033[%d;%dH\n ❄️ Kør forsigtigt ud i trafikken! ❄️"  "$((h/2))" "$((w/2 - 11))"
  printf "\033[%d;1H\n" "$h"
  sleep 1.5

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
