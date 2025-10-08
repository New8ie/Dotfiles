# ======================================
# Docker Utility Functions & Aliases
# ======================================


DOCKER_LOG="$HOME/.config/zsh/logs/docker.log"
mkdir -p "$(dirname "$DOCKER_LOG")"

# === Color Codes ===
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# ======================================
# Logging helper function
# ======================================
docker_log() {
  local DATE=$(date +"%d-%m-%Y %H:%M:%S")
  echo "[$DATE] $*" >> "$DOCKER_LOG"
}

# ======================================
# Check if Docker is running
# ======================================
check_docker() {
  # Check if docker command exists
  if ! command -v docker &>/dev/null; then
    echo "❌ Docker not found on the system."
    docker_log "❌ Docker not found."
    return 1
  fi

  # Check if the docker daemon is running
  if ! pgrep -x "dockerd" &>/dev/null; then
    echo "⚠️  Docker service is not running."
    docker_log "⚠️  Docker service is not running."
    return 1
  fi
  return 0
}

# ======================================
# Docker Functions & Aliases
# ======================================

alias dk-ps='check_docker && docker ps'
alias dk-psa='check_docker && docker ps -a'
alias dk-images='check_docker && docker images'
alias dk-prune='check_docker && docker system prune -af --volumes'
alias dk-disk='check_docker && docker system df'
alias dk-info='check_docker && docker info'
alias dk-service-log='sudo journalctl -u docker -f'

# View container logs
dk-log() {
  if [ -z "$1" ]; then
    echo "⚠️  Usage: dk-log <container_name>"
    return 1
  fi
  check_docker || return 1
  docker_log "Viewing container logs: $1"
  docker logs -f "$1"
}

# Enter container shell
dk-sh() {
  if [ -z "$1" ]; then
    echo "⚠️  Usage: dk-sh <container_name>"
    return 1
  fi
  check_docker || return 1
  docker_log "Entering container shell: $1"
  # Try /bin/bash, fall back to /bin/sh
  docker exec -it "$1" /bin/bash 2>/dev/null || docker exec -it "$1" /bin/sh
}

# Restart a container
dk-restart() {
  if [ -z "$1" ]; then
    echo "⚠️  Usage: dk-restart <container_name>"
    return 1
  fi
  check_docker || return 1
  docker_log "Restarting container: $1"
  docker restart "$1"
}

# Stop all containers
dk-stop-all() {
  check_docker || return 1
  docker_log "Stopping all containers."
  docker stop $(docker ps -q)
}

# Remove all stopped containers
dk-rm-stopped() {
  check_docker || return 1
  docker_log "Removing stopped containers."
  docker container prune -f
}

# ======================================
# Usage Help
# ======================================
dk-help() {
  # All help text colored green
  echo -e "${GREEN}📘 Docker Utility Help${NC}"
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}🔧 Available Functions & Aliases:${NC}"
  echo ""
  echo -e "${GREEN}  dk-ps            → Show running containers${NC}"
  echo -e "${GREEN}  dk-psa           → Show all containers (including stopped)${NC}"
  echo -e "${GREEN}  dk-images        → Show list of images${NC}"
  echo -e "${GREEN}  dk-prune         → Clean up unused resources${NC}"
  echo -e "${GREEN}  dk-disk          → Show Docker disk usage${NC}"
  echo -e "${GREEN}  dk-info          → Show Docker system info${NC}"
  echo -e "${GREEN}  dk-service-log   → View Docker daemon service logs${NC}"
  echo ""
  echo -e "${GREEN}  dk-log <container>     → View logs of a specific container${NC}"
  echo -e "${GREEN}  dk-sh <container>      → Enter a container's shell${NC}"
  echo -e "${GREEN}  dk-restart <container> → Restart a specific container${NC}"
  echo -e "${GREEN}  dk-stop-all            → Stop all running containers${NC}"
  echo -e "${GREEN}  dk-rm-stopped          → Remove stopped containers${NC}"
  echo ""
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}🧰 Log file: $DOCKER_LOG${NC}"
  echo -e "${GREEN}🕒 Log format: [dd-mm-yyyy HH:MM:SS]${NC}"
  echo -e "${GREEN}---------------------------------------------${NC}"
  echo -e "${GREEN}Usage examples:${NC}"
  echo -e "${GREEN}  dk-ps${NC}"
  echo -e "${GREEN}  dk-sh nginx${NC}"
  echo -e "${GREEN}  dk-log nextcloud${NC}"
  echo -e "${GREEN}  dk-prune${NC}"
  echo -e "${GREEN}---------------------------------------------${NC}"
}

echo -e "\033[0;32m✅ Docker function loaded.\033[0m"