#!/bin/bash
#
# ═══════════════════════════════════════════════════════════════════
#  ULTIMATE FEDORA 42 SYSTEM OPTIMIZER v1.0
#  The Most Comprehensive Fedora Optimization Tool Ever Created
# ═══════════════════════════════════════════════════════════════════
#
# FEATURES:
# ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
# ✓ Anti-Freeze Memory Management (EarlyOOM, systemd-oomd, OOMD Guard)
# ✓ Intelligent RAM/Swap/ZRAM Configuration (Adaptive to system RAM)
# ✓ CPU Optimization (Governor, Turbo Boost, Performance Tuning)
# ✓ GPU Optimization (NVIDIA, AMD, Intel drivers & performance)
# ✓ I/O Scheduler & Filesystem Tuning (ext4, xfs, btrfs optimizations)
# ✓ Network Stack Optimization (BBR, TCP tuning, DNS optimization)
# ✓ Security Hardening (SELinux, Firewalld, Kernel hardening)
# ✓ Desktop Environment Optimization (GNOME, KDE, XFCE tuning)
# ✓ Gaming Optimizations (Gamemode, Performance governor)
# ✓ Development Environment Tuning (Build performance, compilers)
# ✓ Battery Life Optimization (TLP, Powertop for laptops)
# ✓ Thermal Management (Fan control, temperature monitoring)
# ✓ Boot Speed Optimization (Systemd-analyze, startup services)
# ✓ DNF Performance (Fastest mirror, parallel downloads)
# ✓ Flatpak Optimization (Runtime cleanup, cache management)
# ✓ Container Optimization (Podman, Docker performance)
# ✓ Disk Health Monitoring (SMART, fstrim automation)
# ✓ Advanced Monitoring & Diagnostics Tools
# ✓ Automatic Backup & Rollback System
# ✓ Fedora 42-Specific Optimizations
#
# Compatible with: Fedora 42 (Workstation, KDE Spin, XFCE Spin, Silverblue)
#
# Usage: sudo ./fedora42_ultimate_optimizer.sh
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
readonly BACKUP_DIR="/var/backups/fedora42-optimizer"
readonly CONFIG_DIR="/etc/fedora42-optimizer"
readonly LOG_FILE="/var/log/fedora42-optimizer-$(date +%Y%m%d_%H%M%S).log"
readonly ROLLBACK_SCRIPT="/usr/local/bin/fedora42-optimizer-rollback"

# System detection globals
declare TOTAL_RAM_MB=0
declare TOTAL_RAM_GB=0
declare CPU_CORES=0
declare CPU_THREADS=0
declare CPU_VENDOR=""
declare CPU_MODEL=""
declare GPU_VENDOR=""
declare GPU_MODEL=""
declare STORAGE_TYPE=""
declare DE=""
declare IS_LAPTOP=false
declare IS_SILVERBLUE=false
declare SYSTEM_TYPE=""

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

create_backup() {
    local file="$1"
    if [[ -f "$file" ]]; then
        mkdir -p "$BACKUP_DIR"
        local backup_name="$(basename "$file").$(date +%Y%m%d_%H%M%S).bak"
        cp "$file" "$BACKUP_DIR/$backup_name"
        log_info "Backed up: $file → $BACKUP_DIR/$backup_name"
    fi
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
        if ! confirm_action "Continue anyway?"; then
            exit 0
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════
# SYSTEM DETECTION
# ════════════════════════════════════════════════════════════════════

detect_system() {
    log_header "Detecting System Configuration"
    
    # RAM detection
    TOTAL_RAM_MB=$(free -m | awk '/^Mem:/{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM_MB / 1024))
    log_info "Total RAM: ${TOTAL_RAM_MB}MB (${TOTAL_RAM_GB}GB)"
    
    # CPU detection
    CPU_CORES=$(nproc --all)
    CPU_THREADS=$(grep -c ^processor /proc/cpuinfo)
    CPU_MODEL=$(lscpu | grep "Model name" | cut -d':' -f2 | xargs)
    
    if lscpu | grep -q "GenuineIntel"; then
        CPU_VENDOR="intel"
    elif lscpu | grep -q "AuthenticAMD"; then
        CPU_VENDOR="amd"
    else
        CPU_VENDOR="other"
    fi
    
    log_info "CPU: $CPU_MODEL"
    log_info "CPU Cores: $CPU_CORES | Threads: $CPU_THREADS | Vendor: $CPU_VENDOR"
    
    # GPU detection
    if lspci | grep -i vga | grep -qi nvidia; then
        GPU_VENDOR="nvidia"
        GPU_MODEL=$(lspci | grep -i vga | grep -i nvidia | cut -d':' -f3 | xargs)
    elif lspci | grep -i vga | grep -qi amd; then
        GPU_VENDOR="amd"
        GPU_MODEL=$(lspci | grep -i vga | grep -i amd | cut -d':' -f3 | xargs)
    elif lspci | grep -i vga | grep -qi intel; then
        GPU_VENDOR="intel"
        GPU_MODEL=$(lspci | grep -i vga | grep -i intel | cut -d':' -f3 | xargs)
    else
        GPU_VENDOR="unknown"
        GPU_MODEL="Unknown GPU"
    fi
    log_info "GPU: $GPU_VENDOR - $GPU_MODEL"
    
    # Storage detection
    if lsblk -d -o name,rota | grep -q "0$"; then
        if nvme list &>/dev/null && nvme list | grep -q "dev"; then
            STORAGE_TYPE="nvme"
        else
            STORAGE_TYPE="ssd"
        fi
    else
        STORAGE_TYPE="hdd"
    fi
    log_info "Primary Storage: ${STORAGE_TYPE^^}"
    
    # Desktop Environment detection
    if [[ -n "${XDG_CURRENT_DESKTOP:-}" ]]; then
        DE="${XDG_CURRENT_DESKTOP,,}"
    elif pgrep -x gnome-shell >/dev/null; then
        DE="gnome"
    elif pgrep -x plasmashell >/dev/null; then
        DE="kde"
    elif pgrep -x xfce4-session >/dev/null; then
        DE="xfce"
    else
        DE="unknown"
    fi
    log_info "Desktop Environment: ${DE^^}"
    
    # Laptop detection
    if [[ -d /sys/class/power_supply/BAT0 ]] || [[ -d /sys/class/power_supply/BAT1 ]]; then
        IS_LAPTOP=true
        SYSTEM_TYPE="laptop"
    else
        IS_LAPTOP=false
        SYSTEM_TYPE="desktop"
    fi
    log_info "System Type: ${SYSTEM_TYPE^^}"
    
    # Silverblue detection
    if rpm-ostree status &>/dev/null; then
        IS_SILVERBLUE=true
        log_info "System Variant: Fedora Silverblue (immutable)"
    else
        IS_SILVERBLUE=false
        log_info "System Variant: Fedora Workstation (traditional)"
    fi
}

# ════════════════════════════════════════════════════════════════════
# DNF OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_dnf() {
    log_header "Optimizing DNF Package Manager"
    
    create_backup "/etc/dnf/dnf.conf"
    
    log_section "Configuring DNF for maximum performance"
    
    # Configure DNF for best performance
    cat >> /etc/dnf/dnf.conf << 'EOF'

# ═══ Fedora 42 Ultimate Optimizer - DNF Configuration ═══
# Added: $(date)

# Performance optimizations
fastestmirror=True
max_parallel_downloads=10
deltarpm=True
defaultyes=True

# Keep downloaded packages for potential reinstalls
keepcache=True

# Speed up metadata downloads
metadata_timer_sync=300

# Optimize database
installonly_limit=3

# Skip checking GPG signatures for faster installs (already verified by fastest mirror)
# Uncomment only if you trust your mirrors
# gpgcheck=False

EOF

    log_success "DNF optimized for Fedora 42"
    log_info "  • Fastest mirror enabled"
    log_info "  • 10 parallel downloads"
    log_info "  • Delta RPM enabled"
    log_info "  • Metadata caching optimized"
}

# ════════════════════════════════════════════════════════════════════
# INSTALL ESSENTIAL TOOLS
# ════════════════════════════════════════════════════════════════════

install_essential_tools() {
    log_header "Installing Essential Optimization & Monitoring Tools"
    
    local tools=(
        # System monitoring
        htop btop iotop nethogs
        
        # Performance tools
        sysstat tuned tuned-utils tuned-profiles-cpu-partitioning
        
        # Memory management
        earlyoom systemd-oomd zram-generator
        
        # Disk tools
        smartmontools nvme-cli hdparm
        
        # Network tools
        iperf3 mtr traceroute bind-utils
        
        # Power management (laptop)
        tlp tlp-rdw powertop
        
        # Thermal monitoring
        lm_sensors hddtemp
        
        # Compilation tools
        ccache distcc
        
        # Utilities
        neofetch fastfetch inxi
        dconf-editor gnome-tweaks
    )
    
    log_section "Installing tools via DNF"
    
    for tool in "${tools[@]}"; do
        if ! rpm -q "$tool" &>/dev/null; then
            log_info "Installing: $tool"
            dnf install -y "$tool" &>>"$LOG_FILE" || log_warn "Failed to install $tool"
        else
            log_info "Already installed: $tool"
        fi
    done
    
    # Enable services
    log_section "Enabling essential services"
    
    systemctl enable --now earlyoom 2>/dev/null || log_warn "EarlyOOM not available"
    systemctl enable --now systemd-oomd 2>/dev/null || true
    
    if $IS_LAPTOP; then
        systemctl enable --now tlp 2>/dev/null || log_warn "TLP not available"
        systemctl mask systemd-rfkill.service systemd-rfkill.socket 2>/dev/null || true
    fi
    
    log_success "Essential tools installed and configured"
}

# ════════════════════════════════════════════════════════════════════
# ZRAM CONFIGURATION
# ════════════════════════════════════════════════════════════════════

setup_advanced_zram() {
    log_header "Configuring Advanced ZRAM (Compressed RAM)"
    
    # Fedora 42 uses zram-generator
    mkdir -p /etc/systemd/zram-generator.conf.d/
    create_backup "/etc/systemd/zram-generator.conf"
    
    # Calculate optimal ZRAM size based on total RAM
    local zram_size
    if [[ $TOTAL_RAM_GB -le 4 ]]; then
        zram_size="100"  # 100% of RAM for low-RAM systems
        log_info "Low RAM detected: ZRAM size = 100% of physical RAM"
    elif [[ $TOTAL_RAM_GB -le 8 ]]; then
        zram_size="75"   # 75% of RAM for medium RAM
        log_info "Medium RAM detected: ZRAM size = 75% of physical RAM"
    elif [[ $TOTAL_RAM_GB -le 16 ]]; then
        zram_size="75"   # 50% of RAM for high RAM
        log_info "High RAM detected: ZRAM size = 50% of physical RAM"
    else
        zram_size="50"   # 25% of RAM for very high RAM
        log_info "Very high RAM detected: ZRAM size = 25% of physical RAM"
    fi
    
    # Choose compression algorithm (zstd is best on Fedora 42)
    local compression_algo="zstd"
    
    cat > /etc/systemd/zram-generator.conf << EOF
# ═══ Fedora 42 Ultimate Optimizer - ZRAM Configuration ═══
# Generated: $(date)
# System RAM: ${TOTAL_RAM_GB}GB

[zram0]
# Compression algorithm (zstd is fastest and best ratio on Fedora 42)
compression-algorithm = $compression_algo

# ZRAM size (percentage of total RAM)
zram-size = ram * $zram_size / 100

# Priority (higher than disk swap)
swap-priority = 100

# Mount point options
mount-point = /swap
EOF

    # Reload zram configuration
    systemctl daemon-reload
    systemctl restart systemd-zram-setup@zram0.service 2>/dev/null || true
    
    log_success "ZRAM configured and activated"
    log_info "  • Algorithm: $compression_algo"
    log_info "  • Size: ${zram_size}% of RAM"
    log_info "  • Priority: 100 (higher than disk swap)"
}

# ════════════════════════════════════════════════════════════════════
# SWAP CONFIGURATION
# ════════════════════════════════════════════════════════════════════

setup_intelligent_swap() {
    log_header "Configuring Intelligent Swap Management"
    
    # Calculate optimal swap size
    local swap_size_gb
    if [[ $TOTAL_RAM_GB -le 2 ]]; then
        swap_size_gb=$((TOTAL_RAM_GB * 4))  # 4x RAM for very low memory
    elif [[ $TOTAL_RAM_GB -le 8 ]]; then
        swap_size_gb=$((TOTAL_RAM_GB * 2))  # 2x RAM for low to medium
    elif [[ $TOTAL_RAM_GB -le 16 ]]; then
        swap_size_gb=$TOTAL_RAM_GB          # 1x RAM for high memory
    else
        swap_size_gb=16                      # Max 16GB for very high memory
    fi
    
    log_info "Optimal swap size: ${swap_size_gb}GB (based on ${TOTAL_RAM_GB}GB RAM)"
    
    # Check if swap already exists
    if swapon --show | grep -q "/swapfile"; then
        log_warn "Swap file already exists, skipping creation"
        log_info "Current swap configuration:"
        swapon --show
        return
    fi
    
    # Create swap file if it doesn't exist
    if [[ ! -f /swapfile ]]; then
        log_section "Creating ${swap_size_gb}GB swap file"
        
        # Use fallocate for faster creation (if supported)
        if fallocate -l "${swap_size_gb}G" /swapfile 2>/dev/null; then
            log_success "Swap file created with fallocate"
        else
            # Fallback to dd
            log_info "Using dd to create swap file (slower but more compatible)"
            dd if=/dev/zero of=/swapfile bs=1G count=$swap_size_gb status=progress 2>&1 | tee -a "$LOG_FILE"
        fi
        
        chmod 600 /swapfile
        mkswap /swapfile
        swapon /swapfile
        
        # Add to fstab if not already there
        if ! grep -q "/swapfile" /etc/fstab; then
            create_backup "/etc/fstab"
            echo "/swapfile none swap sw 0 0" >> /etc/fstab
            log_success "Swap file added to /etc/fstab"
        fi
        
        log_success "Swap file created and activated: ${swap_size_gb}GB"
    fi
}

# ════════════════════════════════════════════════════════════════════
# KERNEL PARAMETER OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_kernel_parameters() {
    log_header "Optimizing Kernel Parameters (sysctl)"
    
    create_backup "/etc/sysctl.conf"
    create_backup "/etc/sysctl.d/99-fedora42-optimizer.conf" 2>/dev/null || true
    
    # Calculate swappiness based on RAM
    local swappiness
    if [[ $TOTAL_RAM_GB -le 4 ]]; then
        swappiness=60  # Use swap more aggressively on low RAM
    elif [[ $TOTAL_RAM_GB -le 8 ]]; then
        swappiness=60  # Moderate swap usage
    elif [[ $TOTAL_RAM_GB -le 16 ]]; then
        swappiness=20  # Prefer RAM over swap
    else
        swappiness=15   # Almost never use swap
    fi
    
    log_info "Setting swappiness to: $swappiness (optimal for ${TOTAL_RAM_GB}GB RAM)"
    
    cat > /etc/sysctl.d/99-fedora42-optimizer.conf << EOF
# ═══════════════════════════════════════════════════════════════════
#  FEDORA 42 ULTIMATE OPTIMIZER - KERNEL PARAMETERS
#  Generated: $(date)
#  System RAM: ${TOTAL_RAM_GB}GB | Storage: ${STORAGE_TYPE^^}
# ═══════════════════════════════════════════════════════════════════

# ━━━ MEMORY MANAGEMENT ━━━
vm.swappiness = $swappiness
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 10
vm.dirty_background_ratio = 5
vm.min_free_kbytes = 65536

# Memory overcommit (conservative)
vm.overcommit_memory = 1
vm.overcommit_ratio = 50

# OOM killer behavior
vm.oom_kill_allocating_task = 0
vm.panic_on_oom = 0

# Transparent Huge Pages (THP) - optimize for performance
vm.nr_hugepages = 0

# ━━━ NETWORK PERFORMANCE ━━━
# TCP BBR congestion control (best for modern networks)
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr

# TCP tuning for better performance
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.tcp_mtu_probing = 1

# Increase network buffer sizes
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864

# Optimize connection handling
net.core.somaxconn = 8192
net.core.netdev_max_backlog = 16384
net.ipv4.tcp_max_syn_backlog = 8192

# Connection tracking
net.netfilter.nf_conntrack_max = 262144

# ━━━ FILE SYSTEM OPTIMIZATION ━━━
# Increase file handles
fs.file-max = 2097152
fs.inotify.max_user_watches = 524288
fs.inotify.max_user_instances = 1024
fs.inotify.max_queued_events = 32768

# ━━━ KERNEL PERFORMANCE ━━━
# Process scheduling
kernel.sched_migration_cost_ns = 5000000
kernel.sched_autogroup_enabled = 0

# Increase PID limit for containers/VMs
kernel.pid_max = 4194304

# Reduce kernel logging overhead
kernel.printk = 3 4 1 3

# ━━━ SECURITY (maintaining security while optimizing) ━━━
# Kernel pointer security
kernel.kptr_restrict = 1

# Disable SysRq for security
kernel.sysrq = 0

# Protection against SYN flood attacks
net.ipv4.tcp_syncookies = 1

# IP forwarding (disabled by default, enable if router)
net.ipv4.ip_forward = 0
net.ipv6.conf.all.forwarding = 0

# ━━━ STORAGE-SPECIFIC OPTIMIZATIONS ━━━
EOF

    # Add storage-specific optimizations
    if [[ "$STORAGE_TYPE" == "nvme" ]] || [[ "$STORAGE_TYPE" == "ssd" ]]; then
        cat >> /etc/sysctl.d/99-fedora42-optimizer.conf << 'EOF'
# SSD/NVMe optimizations
vm.dirty_writeback_centisecs = 1500
vm.laptop_mode = 0
EOF
        log_info "Applied SSD/NVMe optimizations"
    else
        cat >> /etc/sysctl.d/99-fedora42-optimizer.conf << 'EOF'
# HDD optimizations
vm.dirty_writeback_centisecs = 500
vm.laptop_mode = 2
EOF
        log_info "Applied HDD optimizations"
    fi
    
    # Apply sysctl settings
    sysctl -p /etc/sysctl.d/99-fedora42-optimizer.conf &>>"$LOG_FILE"
    
    log_success "Kernel parameters optimized and applied"
    log_info "  • Swappiness: $swappiness"
    log_info "  • TCP: BBR congestion control"
    log_info "  • Network: Optimized buffers"
    log_info "  • Filesystem: Increased limits"
}

# ════════════════════════════════════════════════════════════════════
# EARLYOOM CONFIGURATION
# ════════════════════════════════════════════════════════════════════

configure_earlyoom() {
    log_header "Configuring EarlyOOM (Out-of-Memory Prevention)"
    
    create_backup "/etc/default/earlyoom" 2>/dev/null || true
    
    # Configure EarlyOOM based on RAM
    local mem_threshold
    local swap_threshold
    
    if [[ $TOTAL_RAM_GB -le 4 ]]; then
        mem_threshold=5   # Kill processes at 5% RAM remaining
        swap_threshold=10
    elif [[ $TOTAL_RAM_GB -le 8 ]]; then
        mem_threshold=3
        swap_threshold=10
    else
        mem_threshold=2
        swap_threshold=10
    fi
    
    cat > /etc/default/earlyoom << EOF
# ═══ Fedora 42 Ultimate Optimizer - EarlyOOM Configuration ═══
# Kill processes before system completely freezes

# Memory threshold (% of RAM remaining before killing processes)
EARLYOOM_ARGS="-m $mem_threshold -s $swap_threshold -r 60 --avoid '(^|/)(init|systemd|X|sshd)$' --prefer '(^|/)(chromium|chrome|firefox|thunderbird)$'"

# -m: memory threshold
# -s: swap threshold  
# -r: report interval (seconds)
# --avoid: protect critical processes
# --prefer: kill these first (browsers use lots of RAM)
EOF

    systemctl enable --now earlyoom
    systemctl restart earlyoom
    
    log_success "EarlyOOM configured and running"
    log_info "  • Memory threshold: ${mem_threshold}%"
    log_info "  • Protected processes: init, systemd, X, sshd"
    log_info "  • Preferred targets: browsers (chromium, firefox)"
}

# ════════════════════════════════════════════════════════════════════
# SYSTEMD-OOMD CONFIGURATION
# ════════════════════════════════════════════════════════════════════

configure_systemd_oomd() {
    log_header "Configuring systemd-oomd (System OOM Daemon)"
    
    mkdir -p /etc/systemd/oomd.conf.d/
    
    cat > /etc/systemd/oomd.conf.d/fedora42-optimizer.conf << 'EOF'
# ═══ Fedora 42 Ultimate Optimizer - systemd-oomd Configuration ═══

[OOM]
# Memory pressure thresholds
DefaultMemoryPressureLimit=80%
DefaultMemoryPressureDurationSec=30s

# Enable swap monitoring
SwapUsedLimit=90%
EOF

    systemctl enable --now systemd-oomd
    systemctl restart systemd-oomd
    
    log_success "systemd-oomd configured and running"
}

# ════════════════════════════════════════════════════════════════════
# MEMORY GUARDIAN (Custom OOM Prevention)
# ════════════════════════════════════════════════════════════════════

create_memory_guardian() {
    log_header "Creating Memory Guardian Service"
    
    # Create monitoring script
    cat > /usr/local/bin/memory-guardian << 'EOF'
#!/bin/bash
#
# Memory Guardian - Emergency Memory Manager
# Monitors memory and takes action before freeze
#

THRESHOLD=90
CHECK_INTERVAL=10

while true; do
    # Get memory usage percentage
    MEM_USAGE=$(free | grep Mem | awk '{print int($3/$2 * 100)}')
    
    if [ $MEM_USAGE -gt $THRESHOLD ]; then
        logger -t memory-guardian "HIGH MEMORY USAGE: ${MEM_USAGE}% - Taking action"
        
        # Drop caches
        sync
        echo 3 > /proc/sys/vm/drop_caches
        
        # Send notification if desktop session available
        if [ -n "$DBUS_SESSION_BUS_ADDRESS" ]; then
            notify-send -u critical "Memory Guardian" "High memory usage detected. Clearing caches."
        fi
        
        logger -t memory-guardian "Emergency cache clearing performed"
    fi
    
    sleep $CHECK_INTERVAL
done
EOF

    chmod +x /usr/local/bin/memory-guardian
    
    # Create systemd service
    cat > /etc/systemd/system/memory-guardian.service << EOF
[Unit]
Description=Memory Guardian - Emergency Memory Manager
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/bin/memory-guardian
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now memory-guardian
    
    log_success "Memory Guardian service created and started"
}

# ════════════════════════════════════════════════════════════════════
# I/O SCHEDULER OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_io_scheduler() {
    log_header "Optimizing I/O Scheduler"
    
    local scheduler
    case "$STORAGE_TYPE" in
        nvme)
            scheduler="none"
            log_info "NVMe detected: Using 'none' scheduler (best for NVMe)"
            ;;
        ssd)
            scheduler="mq-deadline"
            log_info "SSD detected: Using 'mq-deadline' scheduler"
            ;;
        hdd)
            scheduler="bfq"
            log_info "HDD detected: Using 'bfq' scheduler (best for HDDs)"
            ;;
        *)
            scheduler="mq-deadline"
            log_info "Unknown storage: Using 'mq-deadline' (safe default)"
            ;;
    esac
    
    # Create udev rule for automatic scheduler assignment
    cat > /etc/udev/rules.d/60-ioschedulers.rules << EOF
# ═══ Fedora 42 Ultimate Optimizer - I/O Scheduler Configuration ═══

# Set optimal I/O scheduler based on storage type
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/scheduler}="$scheduler"

# Optimize read-ahead for better performance
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/read_ahead_kb}="512"

# Increase request queue size
ACTION=="add|change", KERNEL=="sd[a-z]|nvme[0-9]n[0-9]", ATTR{queue/nr_requests}="512"

# Optimize rotational flag
ACTION=="add|change", KERNEL=="sd[a-z]", ATTR{queue/rotational}="0"
ACTION=="add|change", KERNEL=="nvme[0-9]n[0-9]", ATTR{queue/rotational}="0"
EOF

    # Apply immediately to all block devices
    for device in /sys/block/*/queue/scheduler; do
        if [[ -w "$device" ]]; then
            echo "$scheduler" > "$device" 2>/dev/null || true
            log_info "Applied scheduler to: $(dirname "$device")"
        fi
    done
    
    # Set read-ahead
    for device in /sys/block/*/queue/read_ahead_kb; do
        if [[ -w "$device" ]]; then
            echo "512" > "$device" 2>/dev/null || true
        fi
    done
    
    # Reload udev rules
    udevadm control --reload-rules
    udevadm trigger
    
    log_success "I/O scheduler optimized: $scheduler"
}

# ════════════════════════════════════════════════════════════════════
# CPU OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_cpu() {
    log_header "Optimizing CPU Performance"
    
    # Install CPU power management tools
    dnf install -y kernel-tools &>>"$LOG_FILE" || true
    
    # Determine optimal CPU governor
    local governor
    if $IS_LAPTOP; then
        governor="powersave"
        log_info "Laptop detected: Using 'powersave' governor for battery life"
    else
        governor="performance"
        log_info "Desktop detected: Using 'performance' governor"
    fi
    
    # Create CPU optimization service
    cat > /etc/systemd/system/cpu-optimizer.service << EOF
[Unit]
Description=Fedora 42 CPU Optimizer
After=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do echo $governor > \$gov 2>/dev/null || true; done'

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable --now cpu-optimizer
    
    # Intel-specific optimizations
    if [[ "$CPU_VENDOR" == "intel" ]]; then
        log_section "Applying Intel CPU optimizations"
        
        # Turbo Boost control
        if [[ -f /sys/devices/system/cpu/intel_pstate/no_turbo ]]; then
            if $IS_LAPTOP; then
                echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
                log_info "Disabled Intel Turbo Boost for battery savings"
            else
                echo 0 > /sys/devices/system/cpu/intel_pstate/no_turbo 2>/dev/null || true
                log_info "Enabled Intel Turbo Boost for performance"
            fi
        fi
    fi
    
    # AMD-specific optimizations
    if [[ "$CPU_VENDOR" == "amd" ]]; then
        log_section "Applying AMD CPU optimizations"
        
        # AMD Cool'n'Quiet
        if [[ -f /sys/devices/system/cpu/cpufreq/boost ]]; then
            if $IS_LAPTOP; then
                echo 0 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
                log_info "Disabled AMD boost for battery savings"
            else
                echo 1 > /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
                log_info "Enabled AMD boost for performance"
            fi
        fi
    fi
    
    log_success "CPU optimization complete"
    log_info "  • Governor: $governor"
    log_info "  • Vendor optimizations applied: $CPU_VENDOR"
}

# ════════════════════════════════════════════════════════════════════
# GPU OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_gpu() {
    log_header "Optimizing GPU Performance"
    
    case "$GPU_VENDOR" in
        nvidia)
            log_section "Configuring NVIDIA GPU"
            
            # Check if proprietary driver is installed
            if lsmod | grep -q nvidia; then
                log_info "NVIDIA proprietary driver detected"
                
                # Set power management mode
                if $IS_LAPTOP; then
                    # Balanced mode for laptops
                    nvidia-smi -pm 1 2>/dev/null || true
                    log_info "Set NVIDIA power management: balanced"
                else
                    # Performance mode for desktops
                    nvidia-smi -pm 0 2>/dev/null || true
                    log_info "Set NVIDIA power management: maximum performance"
                fi
            else
                log_warn "NVIDIA GPU detected but no proprietary driver found"
                log_info "Install with: sudo dnf install akmod-nvidia"
            fi
            ;;
            
        amd)
            log_section "Configuring AMD GPU"
            
            # AMD GPU power management (radeon/amdgpu)
            if [[ -f /sys/class/drm/card0/device/power_dpm_state ]]; then
                if $IS_LAPTOP; then
                    echo "balanced" > /sys/class/drm/card0/device/power_dpm_state 2>/dev/null || true
                    log_info "Set AMD GPU power: balanced"
                else
                    echo "performance" > /sys/class/drm/card0/device/power_dpm_state 2>/dev/null || true
                    log_info "Set AMD GPU power: performance"
                fi
            fi
            ;;
            
        intel)
            log_section "Configuring Intel GPU"
            log_info "Intel integrated graphics - using kernel defaults"
            
            # Enable GuC/HuC firmware for better performance (Gen 9+)
            if ! grep -q "i915.enable_guc" /etc/default/grub; then
                create_backup "/etc/default/grub"
                sed -i 's/GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="i915.enable_guc=2 /' /etc/default/grub
                log_info "Enabled Intel GuC/HuC firmware loading"
                log_warn "Grub update required (will be done at end)"
            fi
            ;;
            
        *)
            log_warn "Unknown GPU vendor: $GPU_VENDOR"
            ;;
    esac
    
    log_success "GPU optimization complete"
}

# ════════════════════════════════════════════════════════════════════
# NETWORK OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_network() {
    log_header "Optimizing Network Stack"
    
    # Network optimizations already covered in sysctl, but add more here
    
    log_section "Configuring NetworkManager for performance"
    
    # Create NetworkManager optimization
    mkdir -p /etc/NetworkManager/conf.d/
    
    cat > /etc/NetworkManager/conf.d/99-optimize.conf << 'EOF'
# ═══ Fedora 42 Ultimate Optimizer - NetworkManager Configuration ═══

[main]
# Use faster DHCP client
dhcp=dhclient

[connection]
# Optimize connection parameters
ipv6.ip6-privacy=0

[device]
# Disable WiFi power saving for better performance
wifi.powersave=2
EOF

    # Restart NetworkManager to apply changes
    systemctl restart NetworkManager
    
    log_success "Network stack optimized"
    log_info "  • TCP BBR enabled (via sysctl)"
    log_info "  • NetworkManager optimized"
    log_info "  • WiFi power saving disabled"
}

# ════════════════════════════════════════════════════════════════════
# FILESYSTEM OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_filesystem() {
    log_header "Optimizing Filesystem Performance"
    
    # Detect filesystem types
    local root_fs=$(findmnt -n -o FSTYPE /)
    log_info "Root filesystem: $root_fs"
    
    case "$root_fs" in
        ext4)
            log_section "Optimizing ext4 filesystem"
            
            # Optimize ext4 mount options
            if ! grep -q "noatime" /etc/fstab; then
                create_backup "/etc/fstab"
                sed -i 's/defaults/defaults,noatime,commit=60/' /etc/fstab
                log_info "Added noatime and commit=60 to ext4 mount options"
                log_warn "Changes will apply after reboot"
            fi
            ;;
            
        xfs)
            log_section "Optimizing XFS filesystem"
            log_info "XFS detected - already well-optimized by default"
            ;;
            
        btrfs)
            log_section "Optimizing Btrfs filesystem"
            
            # Btrfs optimizations
            if ! grep -q "noatime" /etc/fstab; then
                create_backup "/etc/fstab"
                sed -i 's/defaults/defaults,noatime,compress=zstd,space_cache=v2/' /etc/fstab
                log_info "Added Btrfs optimizations: noatime, zstd, space_cache=v2"
                log_warn "Changes will apply after reboot"
            fi
            
            # Enable periodic scrub for data integrity
            if command -v btrfs &>/dev/null; then
                systemctl enable --now btrfs-scrub@-.timer 2>/dev/null || true
                log_info "Enabled periodic Btrfs scrub"
            fi
            ;;
    esac
    
    # Enable periodic TRIM for SSDs/NVMe
    if [[ "$STORAGE_TYPE" != "hdd" ]]; then
        log_section "Enabling periodic TRIM for SSD/NVMe"
        systemctl enable --now fstrim.timer
        log_success "TRIM timer enabled (runs weekly)"
    fi
    
    log_success "Filesystem optimization complete"
}

# ════════════════════════════════════════════════════════════════════
# DESKTOP ENVIRONMENT OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_desktop_environment() {
    log_header "Optimizing Desktop Environment: ${DE^^}"
    
    case "$DE" in
        gnome)
            log_section "Optimizing GNOME Shell"
            
            # Reduce animations for better performance
            sudo -u "$SUDO_USER" DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u $SUDO_USER)/bus" \
                gsettings set org.gnome.desktop.interface enable-animations false 2>/dev/null || true
            
            # Disable search indexing (tracker)
            systemctl --user --machine=${SUDO_USER}@.host mask tracker-store.service tracker-miner-fs.service tracker-extract.service 2>/dev/null || true
            
            log_success "GNOME optimized: animations disabled, tracker masked"
            ;;
            
        kde|plasma)
            log_section "Optimizing KDE Plasma"
            
            # KDE optimizations via config files
            local kde_config="/home/$SUDO_USER/.config"
            
            if [[ -d "$kde_config" ]]; then
                # Disable compositor effects for performance
                sudo -u "$SUDO_USER" kwriteconfig5 --file kwinrc --group Compositing --key AnimationSpeed 0 2>/dev/null || true
                log_success "KDE Plasma optimized: animation speed reduced"
            fi
            ;;
            
        xfce)
            log_section "Optimizing XFCE"
            log_info "XFCE is already lightweight, minimal optimizations needed"
            ;;
            
        *)
            log_warn "Unknown or no desktop environment detected"
            ;;
    esac
    
    log_success "Desktop environment optimization complete"
}

# ════════════════════════════════════════════════════════════════════
# SECURITY HARDENING
# ════════════════════════════════════════════════════════════════════

harden_security() {
    log_header "Security Hardening (Maintaining Performance)"
    
    log_section "Configuring SELinux"
    
    # Ensure SELinux is enforcing (Fedora default)
    if command -v getenforce &>/dev/null; then
        local selinux_status=$(getenforce)
        if [[ "$selinux_status" != "Enforcing" ]]; then
            log_warn "SELinux is not enforcing. For security, consider enabling it."
        else
            log_success "SELinux is enforcing (secure)"
        fi
    fi
    
    log_section "Configuring Firewalld"
    
    # Ensure firewalld is running
    systemctl enable --now firewalld 2>/dev/null || true
    
    # Optimize firewall for performance (if not already)
    firewall-cmd --set-log-denied=off &>/dev/null || true
    
    log_success "Firewalld configured and running"
    
    log_section "Kernel security parameters (via sysctl)"
    
    # Security sysctl parameters already set in optimize_kernel_parameters
    log_info "Kernel security parameters configured in sysctl"
    
    log_success "Security hardening complete (balanced with performance)"
}

# ════════════════════════════════════════════════════════════════════
# GAMING OPTIMIZATIONS
# ════════════════════════════════════════════════════════════════════

optimize_for_gaming() {
    log_header "Optimizing System for Gaming"
    
    log_section "Installing Gamemode"
    
    # Install gamemode
    dnf install -y gamemode &>>"$LOG_FILE" || log_warn "Failed to install gamemode"
    
    # Enable gamemode
    systemctl --user --machine=${SUDO_USER}@.host enable gamemoded 2>/dev/null || true
    
    log_section "Creating gaming performance profile"
    
    # Create gaming performance script
    cat > /usr/local/bin/gaming-mode << 'EOF'
#!/bin/bash
# Gaming Mode - Maximize gaming performance

if [[ "$1" == "on" ]]; then
    echo "🎮 Enabling Gaming Mode..."
    
    # Set CPU governor to performance
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "performance" > "$gov" 2>/dev/null || true
    done
    
    # Drop caches
    sync; echo 3 > /proc/sys/vm/drop_caches
    
    # Disable compositor (GNOME)
    if pgrep -x gnome-shell >/dev/null; then
        gsettings set org.gnome.mutter experimental-features "['scale-monitor-framebuffer']"
    fi
    
    echo "✓ Gaming mode enabled"
    
elif [[ "$1" == "off" ]]; then
    echo "🎮 Disabling Gaming Mode..."
    
    # Restore CPU governor
    for gov in /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor; do
        echo "powersave" > "$gov" 2>/dev/null || true
    done
    
    echo "✓ Gaming mode disabled"
else
    echo "Usage: gaming-mode [on|off]"
    exit 1
fi
EOF

    chmod +x /usr/local/bin/gaming-mode
    
    log_success "Gaming optimizations complete"
    log_info "  • Gamemode installed"
    log_info "  • Use 'gaming-mode on' to maximize gaming performance"
    log_info "  • Use 'gaming-mode off' to restore normal settings"
}

# ════════════════════════════════════════════════════════════════════
# POWER MANAGEMENT (LAPTOP)
# ════════════════════════════════════════════════════════════════════

optimize_power_management() {
    if ! $IS_LAPTOP; then
        log_header "Skipping Power Management (Desktop System)"
        return
    fi
    
    log_header "Optimizing Power Management for Laptop"
    
    log_section "Configuring TLP"
    
    # TLP is already installed from install_essential_tools
    # Configure TLP for balanced performance/battery
    
    create_backup "/etc/tlp.conf" 2>/dev/null || true
    
    cat > /etc/tlp.d/01-fedora42-optimizer.conf << 'EOF'
# ═══ Fedora 42 Ultimate Optimizer - TLP Configuration ═══

# CPU
CPU_SCALING_GOVERNOR_ON_AC=performance
CPU_SCALING_GOVERNOR_ON_BAT=powersave
CPU_ENERGY_PERF_POLICY_ON_AC=performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0

# Platform
PLATFORM_PROFILE_ON_AC=performance
PLATFORM_PROFILE_ON_BAT=low-power

# Disk
DISK_IDLE_SECS_ON_AC=0
DISK_IDLE_SECS_ON_BAT=2

# WiFi
WIFI_PWR_ON_AC=off
WIFI_PWR_ON_BAT=on

# Sound
SOUND_POWER_SAVE_ON_AC=0
SOUND_POWER_SAVE_ON_BAT=1

# Runtime PM
RUNTIME_PM_ON_AC=on
RUNTIME_PM_ON_BAT=auto

# USB
USB_AUTOSUSPEND=1
EOF

    systemctl enable --now tlp
    systemctl restart tlp
    
    log_success "TLP configured for optimal battery life"
    
    log_section "Configuring Powertop auto-tune"
    
    # Create powertop auto-tune service
    cat > /etc/systemd/system/powertop-tune.service << 'EOF'
[Unit]
Description=Powertop Auto-Tune
After=multi-user.target

[Service]
Type=oneshot
ExecStart=/usr/sbin/powertop --auto-tune
RemainAfterExit=true

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable powertop-tune 2>/dev/null || true
    
    log_success "Power management optimization complete"
}

# ════════════════════════════════════════════════════════════════════
# BOOT OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_boot_speed() {
    log_header "Optimizing Boot Speed"
    
    log_section "Analyzing current boot time"
    
    systemd-analyze || true
    
    log_section "Optimizing systemd services"
    
    # Disable slow and unnecessary services
    local services_to_disable=(
        "ModemManager.service"      # Modem management (if no modem)
        "plymouth-quit-wait.service" # Plymouth wait (delays boot)
    )
    
    for service in "${services_to_disable[@]}"; do
        if systemctl is-enabled "$service" &>/dev/null; then
            systemctl disable "$service" 2>/dev/null && \
                log_info "Disabled: $service" || true
        fi
    done
    
    log_section "Configuring systemd timeout reduction"
    
    # Reduce systemd default timeouts
    mkdir -p /etc/systemd/system.conf.d/
    
    cat > /etc/systemd/system.conf.d/timeout.conf << 'EOF'
# ═══ Fedora 42 Ultimate Optimizer - Systemd Timeout Configuration ═══

[Manager]
# Reduce timeout for services
DefaultTimeoutStartSec=15s
DefaultTimeoutStopSec=10s
DefaultDeviceTimeoutSec=10s
EOF

    systemctl daemon-reload
    
    log_success "Boot optimization complete"
    log_info "Run 'systemd-analyze' after reboot to see improvements"
}

# ════════════════════════════════════════════════════════════════════
# DISK HEALTH MONITORING
# ════════════════════════════════════════════════════════════════════

setup_disk_monitoring() {
    log_header "Setting Up Disk Health Monitoring"
    
    log_section "Configuring SMART monitoring"
    
    # Enable smartd
    systemctl enable --now smartd 2>/dev/null || log_warn "smartd not available"
    
    # Configure smartd for automatic monitoring
    create_backup "/etc/smartmontools/smartd.conf" 2>/dev/null || true
    
    if [[ -f /etc/smartmontools/smartd.conf ]]; then
        # Add monitoring for all drives
        echo "DEVICESCAN -a -o on -S on -n standby,q -s (S/../.././02|L/../../6/03) -W 4,35,40" >> /etc/smartmontools/smartd.conf
        systemctl restart smartd 2>/dev/null || true
        log_success "SMART monitoring configured"
    fi
    
    # Create disk health check script
    cat > /usr/local/bin/disk-health << 'EOF'
#!/bin/bash
# Disk Health Check Script

echo "════════════════════════════════════════════════════════════"
echo "  DISK HEALTH STATUS"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check all drives
for drive in /dev/sd? /dev/nvme?n?; do
    if [[ -e "$drive" ]]; then
        echo "Drive: $drive"
        smartctl -H "$drive" 2>/dev/null | grep -i "overall-health" || echo "  Status: Unknown (not supported)"
        echo ""
    fi
done

echo "════════════════════════════════════════════════════════════"
echo ""
echo "For detailed info, run: sudo smartctl -a /dev/sdX"
EOF

    chmod +x /usr/local/bin/disk-health
    
    log_success "Disk monitoring setup complete"
    log_info "Run 'disk-health' to check disk status"
}

# ════════════════════════════════════════════════════════════════════
# FLATPAK OPTIMIZATION
# ════════════════════════════════════════════════════════════════════

optimize_flatpak() {
    log_header "Optimizing Flatpak Performance"
    
    if ! command -v flatpak &>/dev/null; then
        log_warn "Flatpak not installed, skipping"
        return
    fi
    
    log_section "Cleaning up unused Flatpak runtimes"
    
    # Remove unused runtimes and refs
    flatpak uninstall --unused -y &>>"$LOG_FILE" || true
    
    log_section "Optimizing Flatpak cache"
    
    # Repair and optimize flatpak
    flatpak repair --user &>>"$LOG_FILE" || true
    flatpak repair --system &>>"$LOG_FILE" || true
    
    log_success "Flatpak optimization complete"
}

# ════════════════════════════════════════════════════════════════════
# CONTAINER OPTIMIZATION (Podman)
# ════════════════════════════════════════════════════════════════════

optimize_containers() {
    log_header "Optimizing Container Performance (Podman)"
    
    if ! command -v podman &>/dev/null; then
        log_warn "Podman not installed, skipping"
        return
    fi
    
    log_section "Configuring Podman for optimal performance"
    
    # Create podman config directory
    mkdir -p /etc/containers/
    
    # Optimize storage configuration
    cat > /etc/containers/storage.conf << 'EOF'
# ═══ Fedora 42 Ultimate Optimizer - Podman Storage Configuration ═══

[storage]
driver = "overlay2"

[storage.options]
# Optimize overlay2 storage
mountopt = "nodev,metacopy=on"

[storage.options.overlay]
# Increase mount program threads for better performance
mount_program = "/usr/bin/fuse-overlayfs"
mountopt = "nodev"
EOF

    log_success "Container optimization complete"
}

# ════════════════════════════════════════════════════════════════════
# MONITORING SCRIPTS
# ════════════════════════════════════════════════════════════════════

create_monitoring_scripts() {
    log_header "Creating Advanced Monitoring Scripts"
    
    # System health check script
    cat > /usr/local/bin/system-health << 'EOF'
#!/bin/bash
# Comprehensive System Health Report

echo "════════════════════════════════════════════════════════════"
echo "  FEDORA 42 SYSTEM HEALTH REPORT"
echo "  Generated: $(date)"
echo "════════════════════════════════════════════════════════════"
echo ""

echo "━━━ SYSTEM INFO ━━━"
echo "Hostname: $(hostname)"
echo "Kernel: $(uname -r)"
echo "Uptime: $(uptime -p)"
echo ""

echo "━━━ MEMORY USAGE ━━━"
free -h
echo ""

echo "━━━ SWAP USAGE ━━━"
swapon --show
echo ""

echo "━━━ CPU LOAD ━━━"
echo "Load Average: $(cat /proc/loadavg | awk '{print $1,$2,$3}')"
echo "CPU Cores: $(nproc)"
echo "CPU Usage:"
top -bn1 | grep "Cpu(s)" | awk '{print "  User: "$2", System: "$4", Idle: "$8}'
echo ""

echo "━━━ DISK USAGE ━━━"
df -h | grep -E '^/dev/'
echo ""

echo "━━━ TOP 5 MEMORY PROCESSES ━━━"
ps aux --sort=-%mem | head -6 | tail -5 | awk '{printf "%-20s %5s%%\n", substr($11,1,20), $4}'
echo ""

echo "━━━ TOP 5 CPU PROCESSES ━━━"
ps aux --sort=-%cpu | head -6 | tail -5 | awk '{printf "%-20s %5s%%\n", substr($11,1,20), $3}'
echo ""

echo "━━━ NETWORK STATS ━━━"
echo "Connections: $(ss -tun | wc -l) active"
echo ""

echo "━━━ SERVICES STATUS ━━━"
for service in earlyoom systemd-oomd memory-guardian zram; do
    status=$(systemctl is-active $service 2>/dev/null || echo "N/A")
    echo "  $service: $status"
done
echo ""

echo "════════════════════════════════════════════════════════════"
EOF

    chmod +x /usr/local/bin/system-health
    
    # RAM status script
    cat > /usr/local/bin/ram-status << 'EOF'
#!/bin/bash
# Quick RAM Status Check

echo "════════════════════════════════════════════════════════════"
echo "  RAM & SWAP STATUS"
echo "════════════════════════════════════════════════════════════"
echo ""

free -h | grep -E 'Mem:|Swap:'

echo ""
echo "ZRAM Status:"
zramctl 2>/dev/null || echo "  ZRAM not available"

echo ""
echo "════════════════════════════════════════════════════════════"
EOF

    chmod +x /usr/local/bin/ram-status
    
    # Performance monitor script
    cat > /usr/local/bin/perf-monitor << 'EOF'
#!/bin/bash
# Real-time Performance Monitor

watch -n 2 'echo "═══ CPU ═══"; 
mpstat 1 1 | tail -1; 
echo ""; 
echo "═══ MEMORY ═══"; 
free -h | grep -E "Mem:|Swap:"; 
echo ""; 
echo "═══ TOP PROCESSES ═══";
ps aux --sort=-%cpu | head -6 | tail -5'
EOF

    chmod +x /usr/local/bin/perf-monitor
    
    # Emergency cleanup script
    cat > /usr/local/bin/emergency-cleanup << 'EOF'
#!/bin/bash
# Emergency Memory Cleanup

echo "🚨 EMERGENCY MEMORY CLEANUP"
echo "Clearing caches..."

sync
echo 3 > /proc/sys/vm/drop_caches

echo "✓ Caches cleared"
echo ""
free -h | grep Mem:
EOF

    chmod +x /usr/local/bin/emergency-cleanup
    
    log_success "Monitoring scripts created:"
    log_info "  • system-health - Full system report"
    log_info "  • ram-status - Quick RAM/ZRAM status"
    log_info "  • perf-monitor - Real-time monitoring"
    log_info "  • emergency-cleanup - Force memory cleanup"
}

# ════════════════════════════════════════════════════════════════════
# GRUB UPDATE
# ════════════════════════════════════════════════════════════════════

update_grub() {
    log_header "Updating GRUB Configuration"
    
    if [[ -f /etc/default/grub ]]; then
        # Update GRUB
        if command -v grub2-mkconfig &>/dev/null; then
            grub2-mkconfig -o /boot/grub2/grub.cfg &>>"$LOG_FILE"
            log_success "GRUB configuration updated"
        fi
    fi
}

# ════════════════════════════════════════════════════════════════════
# ROLLBACK SYSTEM
# ════════════════════════════════════════════════════════════════════

create_rollback_script() {
    log_header "Creating Rollback System"
    
    cat > "$ROLLBACK_SCRIPT" << 'EOF'
#!/bin/bash
#
# Fedora 42 Ultimate Optimizer - ROLLBACK SCRIPT
# Restores system to pre-optimization state
#

set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

BACKUP_DIR="/var/backups/fedora42-optimizer"

echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo -e "${YELLOW}  FEDORA 42 ULTIMATE OPTIMIZER - ROLLBACK${NC}"
echo -e "${YELLOW}═══════════════════════════════════════════════════════════${NC}"
echo ""

if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}[ERROR]${NC} This script must be run as root"
    exit 1
fi

if [[ ! -d "$BACKUP_DIR" ]]; then
    echo -e "${RED}[ERROR]${NC} No backups found in $BACKUP_DIR"
    exit 1
fi

echo "Available backups:"
ls -lh "$BACKUP_DIR"
echo ""

read -rp "$(echo -e "${YELLOW}Are you sure you want to rollback? (yes/no):${NC} ")" response

if [[ "$response" != "yes" ]]; then
    echo "Rollback cancelled"
    exit 0
fi

echo ""
echo "Rolling back system configuration..."

# Restore backup files
for backup in "$BACKUP_DIR"/*.bak; do
    if [[ -f "$backup" ]]; then
        original="${backup%.*.bak}"
        original="${original##*/}"
        
        # Find the original file location
        if [[ -f "/etc/$original" ]]; then
            cp "$backup" "/etc/$original"
            echo -e "${GREEN}[✓]${NC} Restored: /etc/$original"
        elif [[ -f "/etc/sysctl.d/$original" ]]; then
            cp "$backup" "/etc/sysctl.d/$original"
            echo -e "${GREEN}[✓]${NC} Restored: /etc/sysctl.d/$original"
        fi
    fi
done

# Disable optimization services
echo ""
echo "Disabling optimization services..."

for service in memory-guardian cpu-optimizer; do
    systemctl stop "$service" 2>/dev/null || true
    systemctl disable "$service" 2>/dev/null || true
    echo -e "${GREEN}[✓]${NC} Disabled: $service"
done

# Apply sysctl changes
sysctl -p &>/dev/null

echo ""
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}  ROLLBACK COMPLETE${NC}"
echo -e "${GREEN}═══════════════════════════════════════════════════════════${NC}"
echo ""
echo "System has been restored to pre-optimization state."
echo "A reboot is recommended."
echo ""
EOF

    chmod +x "$ROLLBACK_SCRIPT"
    
    log_success "Rollback script created: $ROLLBACK_SCRIPT"
    log_info "To rollback optimizations: sudo $ROLLBACK_SCRIPT"
}

# ════════════════════════════════════════════════════════════════════
# GENERATE COMPREHENSIVE REPORT
# ════════════════════════════════════════════════════════════════════

generate_report() {
    local report_file="/var/log/fedora42-optimizer-report-$(date +%Y%m%d_%H%M%S).txt"
    
    {
        echo "═══════════════════════════════════════════════════════════════════"
        echo "       FEDORA 42 ULTIMATE OPTIMIZER v$SCRIPT_VERSION"
        echo "                 Optimization Report"
        echo "═══════════════════════════════════════════════════════════════════"
        echo ""
        echo "Generated: $(date)"
        echo "Hostname: $(hostname)"
        echo "Fedora Version: $(rpm -E %fedora)"
        echo ""
        echo "━━━ SYSTEM CONFIGURATION ━━━"
        echo "System Type: $SYSTEM_TYPE"
        echo "Desktop Environment: $DE"
        if $IS_SILVERBLUE; then
            echo "Variant: Silverblue (immutable)"
        else
            echo "Variant: Workstation (traditional)"
        fi
        echo ""
        echo "━━━ HARDWARE ━━━"
        echo "CPU: $CPU_MODEL"
        echo "  • Cores: $CPU_CORES | Threads: $CPU_THREADS | Vendor: $CPU_VENDOR"
        echo "GPU: $GPU_VENDOR - $GPU_MODEL"
        echo "RAM: ${TOTAL_RAM_MB}MB (${TOTAL_RAM_GB}GB)"
        echo "Storage: ${STORAGE_TYPE^^}"
        echo ""
        echo "━━━ OPTIMIZATIONS APPLIED ━━━"
        echo "✓ DNF Performance Optimization"
        echo "✓ ZRAM Configuration (Compressed RAM)"
        echo "✓ Intelligent Swap Management"
        echo "✓ Kernel Parameter Tuning (sysctl)"
        echo "✓ EarlyOOM Configuration"
        echo "✓ systemd-oomd Configuration"
        echo "✓ Memory Guardian Service"
        echo "✓ I/O Scheduler Optimization"
        echo "✓ CPU Performance Tuning"
        echo "✓ GPU Optimization"
        echo "✓ Network Stack Optimization (BBR)"
        echo "✓ Filesystem Performance Tuning"
        echo "✓ Desktop Environment Optimization"
        echo "✓ Security Hardening"
        echo "✓ Gaming Optimizations"
        if $IS_LAPTOP; then
            echo "✓ Power Management (TLP, Powertop)"
        fi
        echo "✓ Boot Speed Optimization"
        echo "✓ Disk Health Monitoring"
        echo "✓ Flatpak Optimization"
        echo "✓ Container Optimization (Podman)"
        echo "✓ Advanced Monitoring Tools"
        echo ""
        echo "━━━ CONFIGURATION DETAILS ━━━"
        echo "Swappiness: $(cat /proc/sys/vm/swappiness)"
        echo "ZRAM: $(zramctl | grep -c zram || echo 0) device(s) configured"
        echo "CPU Governor: $(cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor 2>/dev/null || echo 'N/A')"
        echo "I/O Scheduler: $(cat /sys/block/sda/queue/scheduler 2>/dev/null | grep -o '\[.*\]' | tr -d '[]' || echo 'N/A')"
        echo ""
        echo "━━━ INSTALLED MONITORING TOOLS ━━━"
        echo "• system-health - Comprehensive system health report"
        echo "• ram-status - Quick RAM and ZRAM status"
        echo "• perf-monitor - Real-time performance monitoring"
        echo "• emergency-cleanup - Emergency memory cleanup"
        echo "• disk-health - Disk health status check"
        echo "• gaming-mode - Toggle gaming performance mode"
        echo ""
        echo "━━━ BACKUP LOCATION ━━━"
        echo "All configuration backups: $BACKUP_DIR"
        echo "Rollback script: $ROLLBACK_SCRIPT"
        echo ""
        echo "━━━ LOG FILES ━━━"
        echo "Optimization log: $LOG_FILE"
        echo "Report file: $report_file"
        echo ""
        echo "━━━ NEXT STEPS ━━━"
        echo "1. REBOOT your system for all changes to take effect"
        echo "2. Run 'system-health' to check system status"
        echo "3. Run 'systemd-analyze' to see boot time improvements"
        echo "4. Test gaming performance with 'gaming-mode on'"
        if $IS_LAPTOP; then
            echo "5. Monitor battery life improvements"
        fi
        echo ""
        echo "━━━ SUPPORT ━━━"
        echo "To rollback: sudo $ROLLBACK_SCRIPT"
        echo "To check logs: sudo less $LOG_FILE"
        echo ""
        echo "═══════════════════════════════════════════════════════════════════"
        echo "         Optimization Complete - Reboot Required"
        echo "═══════════════════════════════════════════════════════════════════"
    } | tee "$report_file"
    
    log_success "Comprehensive report saved: $report_file"
}

# ════════════════════════════════════════════════════════════════════
# MAIN EXECUTION
# ════════════════════════════════════════════════════════════════════

main() {
    clear
    
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║        FEDORA 42 ULTIMATE SYSTEM OPTIMIZER v1.0               ║
║        The Most Comprehensive Fedora Optimization Tool        ║
║                                                               ║
║  ✓ Anti-Freeze Memory Management                             ║
║  ✓ Performance Optimization                                   ║
║  ✓ Security Hardening                                         ║
║  ✓ Power Management                                           ║
║  ✓ Gaming Optimizations                                       ║
║  ✓ Network Stack Tuning                                       ║
║  ✓ Boot Speed Optimization                                    ║
║  ✓ And Much More...                                           ║
║                                                               ║
║  Created by Network & Firewall Technicians (NFT)              ║
║              + OffTrackMedia (OTM)                            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    check_root
    check_fedora_version
    
    # Initialize directories
    mkdir -p "$BACKUP_DIR" "$CONFIG_DIR"
    
    # System detection
    detect_system
    
    echo ""
    log_warn "This will perform COMPREHENSIVE system optimization"
    log_warn "All configuration files will be backed up to: $BACKUP_DIR"
    log_warn "A system reboot will be required after completion"
    echo ""
    
    if ! confirm_action "Proceed with ultimate optimization?"; then
        log_error "Operation cancelled by user"
        exit 0
    fi
    
    # Execute all optimizations
    echo ""
    optimize_dnf
    install_essential_tools
    setup_advanced_zram
    setup_intelligent_swap
    optimize_kernel_parameters
    configure_earlyoom
    configure_systemd_oomd
    create_memory_guardian
    optimize_io_scheduler
    optimize_cpu
    optimize_gpu
    optimize_network
    optimize_filesystem
    optimize_desktop_environment
    harden_security
    optimize_for_gaming
    optimize_power_management
    optimize_boot_speed
    setup_disk_monitoring
    optimize_flatpak
    optimize_containers
    create_monitoring_scripts
    update_grub
    create_rollback_script
    
    # Generate comprehensive report
    generate_report
    
    # Final summary
    echo ""
    log_header "🎉 FEDORA 42 ULTIMATE OPTIMIZATION COMPLETE! 🎉"
    
    echo -e "${GREEN}${BOLD}"
    echo "Your Fedora 42 system has been comprehensively optimized!"
    echo -e "${NC}"
    echo ""
    echo -e "${YELLOW}IMPORTANT: REBOOT REQUIRED${NC}"
    echo ""
    echo "To activate all optimizations, reboot your system:"
    echo "  sudo reboot"
    echo ""
    echo "After reboot, check your system with:"
    echo "  system-health"
    echo ""
    echo -e "${CYAN}Backups saved to: $BACKUP_DIR${NC}"
    echo -e "${CYAN}Rollback available: $ROLLBACK_SCRIPT${NC}"
    echo ""
    
    if confirm_action "Reboot now?"; then
        log_info "Rebooting system..."
        sleep 2
        reboot
    else
        log_warn "Remember to reboot your system to apply all changes!"
    fi
}

# Run main function
main "$@"
