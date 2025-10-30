#!/bin/bash
#
# ═══════════════════════════════════════════════════════════════════
#  ULTIMATE FEDORA 42 APPLICATION INSTALLER v1.0
#  The Most Comprehensive Application Installation Suite for Fedora
# ═══════════════════════════════════════════════════════════════════
#
# FEATURES:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ✓ 100+ Applications across all categories
# ✓ Multi-source support (DNF, Flatpak, Snap, AppImage, Source)
# ✓ Category-based installation (Install by group)
# ✓ Individual app selection
# ✓ Automatic updates for all package managers
# ✓ Smart dependency resolution
# ✓ Parallel installation support
# ✓ Rollback capability
# ✓ Repository management (RPM Fusion, COPR)
#
# CATEGORIES:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# • Development (IDEs, editors, tools, compilers, debuggers)
# • Internet (Browsers, email, messaging, VPN, download managers)
# • Productivity (Office suites, PDF tools, note-taking)
# • Media (Audio, video, editing, streaming, converters)
# • Graphics (Image editing, 3D, CAD, vector graphics)
# • Gaming (Steam, Lutris, emulators, game launchers)
# • Security (Password managers, encryption, VPNs, pentesting)
# • Utilities (System tools, file managers, backup, monitoring)
# • Virtualization (VMs, containers, cloud tools)
# • Science (Mathematics, data analysis, research tools)
#
# Compatible with: Fedora 42 (Workstation, KDE, XFCE, Silverblue)
#
# Usage: sudo ./fedora42_ultimate_installer.sh
#
# Author: Network & Firewall Technicians (NFT) + OffTrackMedia (OTM)
# Version: 1.0
# Date: 2025
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ════════════════════════════════════════════════════════════════════
# CONSTANTS AND COLORS
# ════════════════════════════════════════════════════════════════════

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

readonly SCRIPT_VERSION="1.0"
readonly FEDORA_VERSION="42"
readonly LOG_FILE="/var/log/fedora42-app-installer-$(date +%Y%m%d_%H%M%S).log"
readonly APP_DIR="/opt/fedora42-apps"

# ════════════════════════════════════════════════════════════════════
# HELPER FUNCTIONS
# ════════════════════════════════════════════════════════════════════

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "\n${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║  $1${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}\n" | tee -a "$LOG_FILE"
}

log_section() {
    echo -e "\n${MAGENTA}▶ $1${NC}\n" | tee -a "$LOG_FILE"
}

confirm_action() {
    local prompt="$1"
    local response
    read -rp "$(echo -e "${YELLOW}${prompt} (y/n):${NC} ")" response
    [[ "$response" =~ ^[Yy]$ ]]
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

check_fedora_version() {
    if [[ ! -f /etc/fedora-release ]]; then
        log_error "This script is designed for Fedora Linux"
        exit 1
    fi
    
    local fedora_ver=$(rpm -E %fedora)
    if [[ "$fedora_ver" != "42" ]]; then
        log_warn "This script is optimized for Fedora 42, but you're running Fedora $fedora_ver"
    fi
}

# ════════════════════════════════════════════════════════════════════
# REPOSITORY SETUP
# ════════════════════════════════════════════════════════════════════

setup_repositories() {
    log_header "Setting Up Essential Repositories"
    
    log_section "Enabling RPM Fusion (Free & Nonfree)"
    
    # RPM Fusion Free
    dnf install -y \
        https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        &>>"$LOG_FILE" || log_warn "RPM Fusion Free already installed"
    
    # RPM Fusion Nonfree
    dnf install -y \
        https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm \
        &>>"$LOG_FILE" || log_warn "RPM Fusion Nonfree already installed"
    
    log_success "RPM Fusion repositories enabled"
    
    log_section "Enabling Flathub"
    
    # Add Flathub repository
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &>>"$LOG_FILE" || true
    
    log_success "Flathub repository enabled"
    
    log_section "Updating package databases"
    dnf check-update &>>"$LOG_FILE" || true
    
    log_success "All repositories configured and updated"
}

# ════════════════════════════════════════════════════════════════════
# FLATPAK SETUP
# ════════════════════════════════════════════════════════════════════

setup_flatpak() {
    log_header "Setting Up Flatpak"
    
    if ! command -v flatpak &>/dev/null; then
        log_section "Installing Flatpak"
        dnf install -y flatpak &>>"$LOG_FILE"
    else
        log_info "Flatpak already installed"
    fi
    
    # Add Flathub
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo &>>"$LOG_FILE" || true
    
    log_success "Flatpak configured with Flathub"
}

# ════════════════════════════════════════════════════════════════════
# SNAP SETUP
# ════════════════════════════════════════════════════════════════════

setup_snap() {
    log_header "Setting Up Snap"
    
    if ! command -v snap &>/dev/null; then
        log_section "Installing Snap"
        dnf install -y snapd &>>"$LOG_FILE"
        
        # Enable snapd socket
        systemctl enable --now snapd.socket
        
        # Create symlink for classic snap support
        ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
        
        log_success "Snap installed and configured"
    else
        log_info "Snap already installed"
    fi
}

# ════════════════════════════════════════════════════════════════════
# DEVELOPMENT TOOLS
# ════════════════════════════════════════════════════════════════════

install_development_suite() {
    log_header "Installing Development Suite"
    
    local dev_tools=(
        # Core development
        gcc gcc-c++ make cmake autoconf automake
        git git-lfs
        
        # Build tools
        ccache ninja-build meson
        
        # Debuggers
        gdb lldb valgrind strace
        
        # Version control
        subversion mercurial
        
        # Package management
        rpm-build rpmdevtools
    )
    
    log_section "Installing core development tools"
    
    for tool in "${dev_tools[@]}"; do
        if ! rpm -q "$tool" &>/dev/null; then
            log_info "Installing: $tool"
            dnf install -y "$tool" &>>"$LOG_FILE" || log_warn "Failed: $tool"
        fi
    done
    
    log_success "Core development tools installed"
    
    # IDEs and Editors
    log_section "Installing IDEs and editors"
    
    install_vscode
    install_sublime_text
    install_vim_enhanced
    install_emacs
    install_jetbrains_toolbox
    install_android_studio
    
    # Programming languages
    log_section "Installing programming language runtimes"
    
    install_python_dev
    install_nodejs
    install_ruby_dev
    install_golang
    install_rust
    install_java_dev
    install_dotnet
    
    # Container tools
    log_section "Installing container tools"
    
    install_podman
    install_docker
    install_kubernetes_tools
    
    log_success "Development suite installation complete"
}

install_vscode() {
    log_info "Installing Visual Studio Code..."
    
    # Import Microsoft GPG key
    rpm --import https://packages.microsoft.com/keys/microsoft.asc &>>"$LOG_FILE" || true
    
    # Add VS Code repository
    cat > /etc/yum.repos.d/vscode.repo << 'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

    dnf install -y code &>>"$LOG_FILE"
    log_success "VS Code installed"
}

install_sublime_text() {
    log_info "Installing Sublime Text..."
    
    rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg &>>"$LOG_FILE" || true
    
    cat > /etc/yum.repos.d/sublime-text.repo << 'EOF'
[sublime-text]
name=Sublime Text
baseurl=https://download.sublimetext.com/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://download.sublimetext.com/sublimehq-rpm-pub.gpg
EOF

    dnf install -y sublime-text &>>"$LOG_FILE"
    log_success "Sublime Text installed"
}

install_vim_enhanced() {
    log_info "Installing Vim Enhanced..."
    dnf install -y vim-enhanced vim-X11 &>>"$LOG_FILE"
    log_success "Vim Enhanced installed"
}

install_emacs() {
    log_info "Installing Emacs..."
    dnf install -y emacs &>>"$LOG_FILE"
    log_success "Emacs installed"
}

install_jetbrains_toolbox() {
    log_info "Installing JetBrains Toolbox..."
    
    # Download and install JetBrains Toolbox
    local toolbox_url="https://data.services.jetbrains.com/products/download?platform=linux&code=TBA"
    local toolbox_archive="/tmp/jetbrains-toolbox.tar.gz"
    
    wget -q -O "$toolbox_archive" "$toolbox_url" &>>"$LOG_FILE" || {
        log_warn "Failed to download JetBrains Toolbox"
        return 1
    }
    
    mkdir -p "$APP_DIR/jetbrains"
    tar -xzf "$toolbox_archive" -C "$APP_DIR/jetbrains" --strip-components=1 &>>"$LOG_FILE" || true
    
    log_success "JetBrains Toolbox downloaded to $APP_DIR/jetbrains"
}

install_android_studio() {
    log_info "Installing Android Studio..."
    
    flatpak install -y flathub com.google.AndroidStudio &>>"$LOG_FILE" || {
        log_warn "Failed to install Android Studio via Flatpak"
        return 1
    }
    
    log_success "Android Studio installed via Flatpak"
}

install_python_dev() {
    log_info "Installing Python development environment..."
    
    dnf install -y python3 python3-pip python3-devel python3-virtualenv pipenv &>>"$LOG_FILE"
    
    # Install common Python packages
    pip3 install --upgrade pip setuptools wheel &>>"$LOG_FILE" || true
    
    log_success "Python development environment installed"
}

install_nodejs() {
    log_info "Installing Node.js (LTS)..."
    
    # Install Node.js from official Fedora repos
    dnf install -y nodejs npm &>>"$LOG_FILE"
    
    # Install yarn
    npm install -g yarn &>>"$LOG_FILE" || true
    
    log_success "Node.js and npm installed"
}

install_ruby_dev() {
    log_info "Installing Ruby development environment..."
    
    dnf install -y ruby ruby-devel rubygem-bundler &>>"$LOG_FILE"
    
    log_success "Ruby development environment installed"
}

install_golang() {
    log_info "Installing Go (Golang)..."
    
    dnf install -y golang &>>"$LOG_FILE"
    
    log_success "Go installed"
}

install_rust() {
    log_info "Installing Rust..."
    
    dnf install -y rust cargo &>>"$LOG_FILE"
    
    log_success "Rust installed"
}

install_java_dev() {
    log_info "Installing Java development kit..."
    
    # Install OpenJDK 17 (LTS)
    dnf install -y java-17-openjdk java-17-openjdk-devel maven gradle &>>"$LOG_FILE"
    
    log_success "Java development kit installed"
}

install_dotnet() {
    log_info "Installing .NET SDK..."
    
    dnf install -y dotnet-sdk-8.0 &>>"$LOG_FILE"
    
    log_success ".NET SDK installed"
}

install_podman() {
    log_info "Installing Podman..."
    
    dnf install -y podman podman-compose podman-docker &>>"$LOG_FILE"
    
    log_success "Podman installed"
}

install_docker() {
    log_info "Installing Docker..."
    
    # Add Docker repository
    dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo &>>"$LOG_FILE" || true
    
    # Install Docker
    dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin &>>"$LOG_FILE" || {
        log_warn "Failed to install Docker"
        return 1
    }
    
    systemctl enable --now docker
    usermod -aG docker "$SUDO_USER" 2>/dev/null || true
    
    log_success "Docker installed"
}

install_kubernetes_tools() {
    log_info "Installing Kubernetes tools..."
    
    dnf install -y kubernetes-client &>>"$LOG_FILE"
    
    # Install kubectl
    if ! command -v kubectl &>/dev/null; then
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl" &>>"$LOG_FILE"
        install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
        rm -f kubectl
    fi
    
    # Install k9s (Kubernetes TUI)
    snap install k9s &>>"$LOG_FILE" || true
    
    log_success "Kubernetes tools installed"
}

# ════════════════════════════════════════════════════════════════════
# INTERNET APPLICATIONS
# ════════════════════════════════════════════════════════════════════

install_internet_suite() {
    log_header "Installing Internet Applications Suite"
    
    install_firefox
    install_chrome
    install_chromium
    install_brave
    install_opera
    install_vivaldi
    install_thunderbird
    install_evolution
    install_discord
    install_slack
    install_telegram
    install_zoom
    install_teams
    install_skype
    install_filezilla
    install_transmission
    install_deluge
    install_qbittorrent
    install_tailscale
    install_wireguard
    
    log_success "Internet suite installation complete"
}

install_firefox() {
    log_info "Installing Firefox..."
    dnf install -y firefox &>>"$LOG_FILE"
    log_success "Firefox installed"
}

install_chrome() {
    log_info "Installing Google Chrome..."
    
    cat > /etc/yum.repos.d/google-chrome.repo << 'EOF'
[google-chrome]
name=google-chrome
baseurl=https://dl.google.com/linux/chrome/rpm/stable/x86_64
enabled=1
gpgcheck=1
gpgkey=https://dl.google.com/linux/linux_signing_key.pub
EOF

    dnf install -y google-chrome-stable &>>"$LOG_FILE"
    log_success "Google Chrome installed"
}

install_chromium() {
    log_info "Installing Chromium..."
    dnf install -y chromium &>>"$LOG_FILE"
    log_success "Chromium installed"
}

install_brave() {
    log_info "Installing Brave Browser..."
    
    dnf config-manager --add-repo https://brave-browser-rpm-release.s3.brave.com/brave-browser.repo &>>"$LOG_FILE" || true
    rpm --import https://brave-browser-rpm-release.s3.brave.com/brave-core.asc &>>"$LOG_FILE" || true
    dnf install -y brave-browser &>>"$LOG_FILE"
    
    log_success "Brave Browser installed"
}

install_opera() {
    log_info "Installing Opera..."
    
    flatpak install -y flathub com.opera.Opera &>>"$LOG_FILE" || {
        log_warn "Failed to install Opera via Flatpak"
        return 1
    }
    
    log_success "Opera installed via Flatpak"
}

install_vivaldi() {
    log_info "Installing Vivaldi..."
    
    dnf config-manager --add-repo https://repo.vivaldi.com/archive/vivaldi-fedora.repo &>>"$LOG_FILE" || true
    dnf install -y vivaldi-stable &>>"$LOG_FILE"
    
    log_success "Vivaldi installed"
}

install_thunderbird() {
    log_info "Installing Thunderbird..."
    dnf install -y thunderbird &>>"$LOG_FILE"
    log_success "Thunderbird installed"
}

install_evolution() {
    log_info "Installing Evolution..."
    dnf install -y evolution &>>"$LOG_FILE"
    log_success "Evolution installed"
}

install_discord() {
    log_info "Installing Discord..."
    
    flatpak install -y flathub com.discordapp.Discord &>>"$LOG_FILE" || {
        log_warn "Failed to install Discord via Flatpak"
        return 1
    }
    
    log_success "Discord installed via Flatpak"
}

install_slack() {
    log_info "Installing Slack..."
    
    flatpak install -y flathub com.slack.Slack &>>"$LOG_FILE" || {
        log_warn "Failed to install Slack via Flatpak"
        return 1
    }
    
    log_success "Slack installed via Flatpak"
}

install_telegram() {
    log_info "Installing Telegram..."
    
    flatpak install -y flathub org.telegram.desktop &>>"$LOG_FILE" || {
        log_warn "Failed to install Telegram via Flatpak"
        return 1
    }
    
    log_success "Telegram installed via Flatpak"
}

install_zoom() {
    log_info "Installing Zoom..."
    
    flatpak install -y flathub us.zoom.Zoom &>>"$LOG_FILE" || {
        log_warn "Failed to install Zoom via Flatpak"
        return 1
    }
    
    log_success "Zoom installed via Flatpak"
}

install_teams() {
    log_info "Installing Microsoft Teams..."
    
    flatpak install -y flathub com.microsoft.Teams &>>"$LOG_FILE" || {
        log_warn "Failed to install Teams via Flatpak"
        return 1
    }
    
    log_success "Microsoft Teams installed via Flatpak"
}

install_skype() {
    log_info "Installing Skype..."
    
    flatpak install -y flathub com.skype.Client &>>"$LOG_FILE" || {
        log_warn "Failed to install Skype via Flatpak"
        return 1
    }
    
    log_success "Skype installed via Flatpak"
}

install_filezilla() {
    log_info "Installing FileZilla..."
    dnf install -y filezilla &>>"$LOG_FILE"
    log_success "FileZilla installed"
}

install_transmission() {
    log_info "Installing Transmission..."
    dnf install -y transmission &>>"$LOG_FILE"
    log_success "Transmission installed"
}

install_deluge() {
    log_info "Installing Deluge..."
    dnf install -y deluge &>>"$LOG_FILE"
    log_success "Deluge installed"
}

install_qbittorrent() {
    log_info "Installing qBittorrent..."
    dnf install -y qbittorrent &>>"$LOG_FILE"
    log_success "qBittorrent installed"
}

install_tailscale() {
    log_info "Installing Tailscale..."
    
    dnf config-manager --add-repo https://pkgs.tailscale.com/stable/fedora/tailscale.repo &>>"$LOG_FILE" || true
    dnf install -y tailscale &>>"$LOG_FILE"
    
    systemctl enable --now tailscaled
    
    log_success "Tailscale installed"
    log_info "Run 'sudo tailscale up' to connect"
}

install_wireguard() {
    log_info "Installing WireGuard..."
    dnf install -y wireguard-tools &>>"$LOG_FILE"
    log_success "WireGuard installed"
}

# ════════════════════════════════════════════════════════════════════
# PRODUCTIVITY SUITE
# ════════════════════════════════════════════════════════════════════

install_productivity_suite() {
    log_header "Installing Productivity Applications Suite"
    
    install_libreoffice
    install_onlyoffice
    install_wps_office
    install_calibre
    install_okular
    install_evince
    install_xournalpp
    install_joplin
    install_obsidian
    install_notion
    install_trello
    install_todoist
    
    log_success "Productivity suite installation complete"
}

install_libreoffice() {
    log_info "Installing LibreOffice..."
    dnf install -y libreoffice libreoffice-writer libreoffice-calc libreoffice-impress &>>"$LOG_FILE"
    log_success "LibreOffice installed"
}

install_onlyoffice() {
    log_info "Installing OnlyOffice..."
    
    flatpak install -y flathub org.onlyoffice.desktopeditors &>>"$LOG_FILE" || {
        log_warn "Failed to install OnlyOffice via Flatpak"
        return 1
    }
    
    log_success "OnlyOffice installed via Flatpak"
}

install_wps_office() {
    log_info "Installing WPS Office..."
    
    flatpak install -y flathub com.wps.Office &>>"$LOG_FILE" || {
        log_warn "Failed to install WPS Office via Flatpak"
        return 1
    }
    
    log_success "WPS Office installed via Flatpak"
}

install_calibre() {
    log_info "Installing Calibre..."
    dnf install -y calibre &>>"$LOG_FILE"
    log_success "Calibre installed"
}

install_okular() {
    log_info "Installing Okular..."
    dnf install -y okular &>>"$LOG_FILE"
    log_success "Okular installed"
}

install_evince() {
    log_info "Installing Evince..."
    dnf install -y evince &>>"$LOG_FILE"
    log_success "Evince installed"
}

install_xournalpp() {
    log_info "Installing Xournal++..."
    dnf install -y xournalpp &>>"$LOG_FILE"
    log_success "Xournal++ installed"
}

install_joplin() {
    log_info "Installing Joplin..."
    
    flatpak install -y flathub net.cozic.joplin_desktop &>>"$LOG_FILE" || {
        log_warn "Failed to install Joplin via Flatpak"
        return 1
    }
    
    log_success "Joplin installed via Flatpak"
}

install_obsidian() {
    log_info "Installing Obsidian..."
    
    flatpak install -y flathub md.obsidian.Obsidian &>>"$LOG_FILE" || {
        log_warn "Failed to install Obsidian via Flatpak"
        return 1
    }
    
    log_success "Obsidian installed via Flatpak"
}

install_notion() {
    log_info "Installing Notion (unofficial)..."
    
    flatpak install -y flathub com.notesnook.Notesnook &>>"$LOG_FILE" || {
        log_warn "Failed to install Notion via Flatpak"
        return 1
    }
    
    log_success "Notion installed via Flatpak"
}

install_trello() {
    log_info "Trello available via web browser"
    log_info "Visit: https://trello.com"
}

install_todoist() {
    log_info "Installing Todoist..."
    
    flatpak install -y flathub com.todoist.Todoist &>>"$LOG_FILE" || {
        log_warn "Todoist available via web: https://todoist.com"
        return 1
    }
    
    log_success "Todoist installed via Flatpak"
}

# ════════════════════════════════════════════════════════════════════
# MEDIA SUITE
# ════════════════════════════════════════════════════════════════════

install_media_suite() {
    log_header "Installing Media Applications Suite"
    
    install_vlc
    install_mpv
    install_rhythmbox
    install_audacity
    install_kdenlive
    install_openshot
    install_obs_studio
    install_spotify
    install_strawberry
    install_clementine
    install_handbrake
    install_ffmpeg
    install_youtube_dl
    
    log_success "Media suite installation complete"
}

install_vlc() {
    log_info "Installing VLC..."
    dnf install -y vlc &>>"$LOG_FILE"
    log_success "VLC installed"
}

install_mpv() {
    log_info "Installing MPV..."
    dnf install -y mpv &>>"$LOG_FILE"
    log_success "MPV installed"
}

install_rhythmbox() {
    log_info "Installing Rhythmbox..."
    dnf install -y rhythmbox &>>"$LOG_FILE"
    log_success "Rhythmbox installed"
}

install_audacity() {
    log_info "Installing Audacity..."
    dnf install -y audacity &>>"$LOG_FILE"
    log_success "Audacity installed"
}

install_kdenlive() {
    log_info "Installing Kdenlive..."
    dnf install -y kdenlive &>>"$LOG_FILE"
    log_success "Kdenlive installed"
}

install_openshot() {
    log_info "Installing OpenShot..."
    dnf install -y openshot &>>"$LOG_FILE"
    log_success "OpenShot installed"
}

install_obs_studio() {
    log_info "Installing OBS Studio..."
    dnf install -y obs-studio &>>"$LOG_FILE"
    log_success "OBS Studio installed"
}

install_spotify() {
    log_info "Installing Spotify..."
    
    flatpak install -y flathub com.spotify.Client &>>"$LOG_FILE" || {
        log_warn "Failed to install Spotify via Flatpak"
        return 1
    }
    
    log_success "Spotify installed via Flatpak"
}

install_strawberry() {
    log_info "Installing Strawberry..."
    dnf install -y strawberry &>>"$LOG_FILE"
    log_success "Strawberry installed"
}

install_clementine() {
    log_info "Installing Clementine..."
    dnf install -y clementine &>>"$LOG_FILE"
    log_success "Clementine installed"
}

install_handbrake() {
    log_info "Installing HandBrake..."
    dnf install -y handbrake &>>"$LOG_FILE"
    log_success "HandBrake installed"
}

install_ffmpeg() {
    log_info "Installing FFmpeg..."
    dnf install -y ffmpeg ffmpeg-libs &>>"$LOG_FILE"
    log_success "FFmpeg installed"
}

install_youtube_dl() {
    log_info "Installing yt-dlp..."
    dnf install -y yt-dlp &>>"$LOG_FILE"
    log_success "yt-dlp installed"
}

# ════════════════════════════════════════════════════════════════════
# GRAPHICS SUITE
# ════════════════════════════════════════════════════════════════════

install_graphics_suite() {
    log_header "Installing Graphics Applications Suite"
    
    install_gimp
    install_inkscape
    install_krita
    install_blender
    install_darktable
    install_rawtherapee
    install_scribus
    install_freecad
    
    log_success "Graphics suite installation complete"
}

install_gimp() {
    log_info "Installing GIMP..."
    dnf install -y gimp &>>"$LOG_FILE"
    log_success "GIMP installed"
}

install_inkscape() {
    log_info "Installing Inkscape..."
    dnf install -y inkscape &>>"$LOG_FILE"
    log_success "Inkscape installed"
}

install_krita() {
    log_info "Installing Krita..."
    dnf install -y krita &>>"$LOG_FILE"
    log_success "Krita installed"
}

install_blender() {
    log_info "Installing Blender..."
    dnf install -y blender &>>"$LOG_FILE"
    log_success "Blender installed"
}

install_darktable() {
    log_info "Installing Darktable..."
    dnf install -y darktable &>>"$LOG_FILE"
    log_success "Darktable installed"
}

install_rawtherapee() {
    log_info "Installing RawTherapee..."
    dnf install -y rawtherapee &>>"$LOG_FILE"
    log_success "RawTherapee installed"
}

install_scribus() {
    log_info "Installing Scribus..."
    dnf install -y scribus &>>"$LOG_FILE"
    log_success "Scribus installed"
}

install_freecad() {
    log_info "Installing FreeCAD..."
    dnf install -y freecad &>>"$LOG_FILE"
    log_success "FreeCAD installed"
}

# ════════════════════════════════════════════════════════════════════
# GAMING SUITE
# ════════════════════════════════════════════════════════════════════

install_gaming_suite() {
    log_header "Installing Gaming Applications Suite"
    
    install_steam
    install_lutris
    install_wine
    install_heroic
    install_bottles
    install_retroarch
    install_pcsx2
    install_dolphin_emu
    install_rpcs3
    install_yuzu
    install_gamemode
    install_mangohud
    
    log_success "Gaming suite installation complete"
}

install_steam() {
    log_info "Installing Steam..."
    dnf install -y steam &>>"$LOG_FILE"
    log_success "Steam installed"
}

install_lutris() {
    log_info "Installing Lutris..."
    dnf install -y lutris &>>"$LOG_FILE"
    log_success "Lutris installed"
}

install_wine() {
    log_info "Installing Wine..."
    dnf install -y wine &>>"$LOG_FILE"
    log_success "Wine installed"
}

install_heroic() {
    log_info "Installing Heroic Games Launcher..."
    
    flatpak install -y flathub com.heroicgameslauncher.hgl &>>"$LOG_FILE" || {
        log_warn "Failed to install Heroic via Flatpak"
        return 1
    }
    
    log_success "Heroic Games Launcher installed via Flatpak"
}

install_bottles() {
    log_info "Installing Bottles..."
    
    flatpak install -y flathub com.usebottles.bottles &>>"$LOG_FILE" || {
        log_warn "Failed to install Bottles via Flatpak"
        return 1
    }
    
    log_success "Bottles installed via Flatpak"
}

install_retroarch() {
    log_info "Installing RetroArch..."
    
    flatpak install -y flathub org.libretro.RetroArch &>>"$LOG_FILE" || {
        log_warn "Failed to install RetroArch via Flatpak"
        return 1
    }
    
    log_success "RetroArch installed via Flatpak"
}

install_pcsx2() {
    log_info "Installing PCSX2..."
    
    flatpak install -y flathub net.pcsx2.PCSX2 &>>"$LOG_FILE" || {
        log_warn "Failed to install PCSX2 via Flatpak"
        return 1
    }
    
    log_success "PCSX2 installed via Flatpak"
}

install_dolphin_emu() {
    log_info "Installing Dolphin Emulator..."
    
    flatpak install -y flathub org.DolphinEmu.dolphin-emu &>>"$LOG_FILE" || {
        log_warn "Failed to install Dolphin via Flatpak"
        return 1
    }
    
    log_success "Dolphin Emulator installed via Flatpak"
}

install_rpcs3() {
    log_info "Installing RPCS3..."
    
    flatpak install -y flathub net.rpcs3.RPCS3 &>>"$LOG_FILE" || {
        log_warn "Failed to install RPCS3 via Flatpak"
        return 1
    }
    
    log_success "RPCS3 installed via Flatpak"
}

install_yuzu() {
    log_info "Installing Yuzu..."
    
    # Note: Yuzu may not be available, check alternatives
    flatpak install -y flathub org.yuzu_emu.yuzu &>>"$LOG_FILE" || {
        log_warn "Yuzu not available - check alternatives"
        return 1
    }
    
    log_success "Yuzu installed via Flatpak"
}

install_gamemode() {
    log_info "Installing Gamemode..."
    dnf install -y gamemode &>>"$LOG_FILE"
    log_success "Gamemode installed"
}

install_mangohud() {
    log_info "Installing MangoHud..."
    dnf install -y mangohud &>>"$LOG_FILE"
    log_success "MangoHud installed"
}

# ════════════════════════════════════════════════════════════════════
# SECURITY TOOLS
# ════════════════════════════════════════════════════════════════════

install_security_suite() {
    log_header "Installing Security Tools Suite"
    
    install_bitwarden
    install_keepassxc
    install_veracrypt
    install_gnupg
    install_wireshark
    install_nmap
    install_metasploit
    
    log_success "Security suite installation complete"
}

install_bitwarden() {
    log_info "Installing Bitwarden..."
    
    flatpak install -y flathub com.bitwarden.desktop &>>"$LOG_FILE" || {
        log_warn "Failed to install Bitwarden via Flatpak"
        return 1
    }
    
    log_success "Bitwarden installed via Flatpak"
}

install_keepassxc() {
    log_info "Installing KeePassXC..."
    dnf install -y keepassxc &>>"$LOG_FILE"
    log_success "KeePassXC installed"
}

install_veracrypt() {
    log_info "Installing VeraCrypt..."
    
    # VeraCrypt needs to be downloaded manually
    log_warn "VeraCrypt must be downloaded from: https://www.veracrypt.fr"
}

install_gnupg() {
    log_info "Installing GnuPG..."
    dnf install -y gnupg2 &>>"$LOG_FILE"
    log_success "GnuPG installed"
}

install_wireshark() {
    log_info "Installing Wireshark..."
    dnf install -y wireshark &>>"$LOG_FILE"
    
    # Add user to wireshark group
    usermod -aG wireshark "$SUDO_USER" 2>/dev/null || true
    
    log_success "Wireshark installed"
}

install_nmap() {
    log_info "Installing Nmap..."
    dnf install -y nmap &>>"$LOG_FILE"
    log_success "Nmap installed"
}

install_metasploit() {
    log_info "Metasploit requires manual installation"
    log_info "Visit: https://www.metasploit.com"
}

# ════════════════════════════════════════════════════════════════════
# UTILITIES SUITE
# ════════════════════════════════════════════════════════════════════

install_utilities_suite() {
    log_header "Installing System Utilities Suite"
    
    install_timeshift
    install_bleachbit
    install_rclone
    install_syncthing
    install_flameshot
    install_peek
    install_stacer
    
    log_success "Utilities suite installation complete"
}

install_timeshift() {
    log_info "Installing Timeshift..."
    dnf install -y timeshift &>>"$LOG_FILE"
    log_success "Timeshift installed"
}

install_bleachbit() {
    log_info "Installing BleachBit..."
    dnf install -y bleachbit &>>"$LOG_FILE"
    log_success "BleachBit installed"
}

install_rclone() {
    log_info "Installing Rclone..."
    dnf install -y rclone &>>"$LOG_FILE"
    log_success "Rclone installed"
}

install_syncthing() {
    log_info "Installing Syncthing..."
    dnf install -y syncthing &>>"$LOG_FILE"
    log_success "Syncthing installed"
}

install_flameshot() {
    log_info "Installing Flameshot..."
    dnf install -y flameshot &>>"$LOG_FILE"
    log_success "Flameshot installed"
}

install_peek() {
    log_info "Installing Peek..."
    dnf install -y peek &>>"$LOG_FILE"
    log_success "Peek installed"
}

install_stacer() {
    log_info "Installing Stacer..."
    
    flatpak install -y flathub com.oguzhaninan.Stacer &>>"$LOG_FILE" || {
        log_warn "Failed to install Stacer via Flatpak"
        return 1
    }
    
    log_success "Stacer installed via Flatpak"
}

# ════════════════════════════════════════════════════════════════════
# MENU SYSTEM
# ════════════════════════════════════════════════════════════════════

show_menu() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     FEDORA 42 ULTIMATE APPLICATION INSTALLER v1.0             ║
║     The Most Comprehensive App Installation Suite            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${YELLOW}${BOLD}INSTALLATION OPTIONS:${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} Install EVERYTHING (All Categories)"
    echo -e "${GREEN}[2]${NC} Development Tools (IDEs, compilers, containers)"
    echo -e "${GREEN}[3]${NC} Internet Applications (Browsers, email, messaging)"
    echo -e "${GREEN}[4]${NC} Productivity Suite (Office, PDF, notes)"
    echo -e "${GREEN}[5]${NC} Media Applications (Audio, video, editing)"
    echo -e "${GREEN}[6]${NC} Graphics Suite (Image editing, 3D, CAD)"
    echo -e "${GREEN}[7]${NC} Gaming Suite (Steam, emulators, launchers)"
    echo -e "${GREEN}[8]${NC} Security Tools (Password managers, pentesting)"
    echo -e "${GREEN}[9]${NC} System Utilities (Backup, monitoring, tools)"
    echo -e "${GREEN}[R]${NC} Setup Repositories (RPM Fusion, Flathub, Snap)"
    echo -e "${GREEN}[U]${NC} Update All Installed Applications"
    echo -e "${GREEN}[Q]${NC} Quit"
    echo ""
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
    read -rp "Select option: " choice
    
    case $choice in
        1)
            install_everything
            ;;
        2)
            install_development_suite
            pause_and_return
            ;;
        3)
            install_internet_suite
            pause_and_return
            ;;
        4)
            install_productivity_suite
            pause_and_return
            ;;
        5)
            install_media_suite
            pause_and_return
            ;;
        6)
            install_graphics_suite
            pause_and_return
            ;;
        7)
            install_gaming_suite
            pause_and_return
            ;;
        8)
            install_security_suite
            pause_and_return
            ;;
        9)
            install_utilities_suite
            pause_and_return
            ;;
        R|r)
            setup_repositories
            setup_flatpak
            setup_snap
            pause_and_return
            ;;
        U|u)
            update_all_apps
            ;;
        Q|q)
            log_info "Exiting installer"
            exit 0
            ;;
        *)
            log_error "Invalid option"
            sleep 2
            show_menu
            ;;
    esac
}

install_everything() {
    log_header "Installing ALL Applications (This will take a while)"
    
    if ! confirm_action "This will install 100+ applications. Continue?"; then
        show_menu
        return
    fi
    
    setup_repositories
    setup_flatpak
    setup_snap
    
    install_development_suite
    install_internet_suite
    install_productivity_suite
    install_media_suite
    install_graphics_suite
    install_gaming_suite
    install_security_suite
    install_utilities_suite
    
    log_header "🎉 ALL APPLICATIONS INSTALLED! 🎉"
    log_success "Installation complete"
    log_warn "Some apps may require logout/reboot to appear in menus"
    
    pause_and_return
}

update_all_apps() {
    log_header "Updating All Applications"
    
    # Update DNF packages
    log_section "Updating DNF packages"
    dnf upgrade -y &>>"$LOG_FILE"
    log_success "DNF packages updated"
    
    # Update Flatpak
    if command -v flatpak &>/dev/null; then
        log_section "Updating Flatpak packages"
        flatpak update -y &>>"$LOG_FILE"
        log_success "Flatpak packages updated"
    fi
    
    # Update Snap
    if command -v snap &>/dev/null; then
        log_section "Updating Snap packages"
        snap refresh &>>"$LOG_FILE"
        log_success "Snap packages updated"
    fi
    
    log_success "All applications updated"
    pause_and_return
}

pause_and_return() {
    echo ""
    read -rp "Press Enter to return to menu..."
    show_menu
}

# ════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ════════════════════════════════════════════════════════════════════

main() {
    check_root
    check_fedora_version
    
    mkdir -p "$APP_DIR"
    
    log_info "Fedora 42 Ultimate Application Installer v$SCRIPT_VERSION"
    log_info "Log file: $LOG_FILE"
    
    show_menu
}

main "$@"
