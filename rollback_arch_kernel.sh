#!/bin/bash

# Script for installing LTS kernel in Arch Linux (keeping current kernel)
# Supports mainline and CachyOS kernels

set -e

# Language detection based on LANG variable
if [[ "$LANG" == ru_RU.UTF-8* ]] || [[ "$LANG" == ru_* ]]; then
    SCRIPT_LANG="ru"
else
    SCRIPT_LANG="en"
fi

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Russian language texts
declare -A TEXTS_RU=(
    ["info"]="[ИНФО]"
    ["success"]="[УСПЕХ]"
    ["warning"]="[ВНИМАНИЕ]"
    ["error"]="[ОШИБКА]"
    ["root_check_fail"]="Скрипт должен быть запущен от имени root!"
    ["internet_check"]="Проверка подключения к интернету..."
    ["internet_fail"]="Нет подключения к интернету!"
    ["internet_ok"]="Подключение к интернету есть"
    ["current_kernel"]="Текущее ядро:"
    ["mainline_detected"]="Обнаружено mainline ядро"
    ["cachyos_detected"]="Обнаружено CachyOS ядро"
    ["lts_already"]="LTS ядро уже установлено!"
    ["lts_check_drivers"]="Скрипт проверит NVIDIA драйверы и обновит систему"
    ["unknown_kernel"]="Не удалось определить тип текущего ядра!"
    ["supported_kernels"]="Поддерживаются только: linux (mainline), linux-cachyos, linux-lts"
    ["nvidia_detected"]="Обнаружен драйвер"
    ["nvidia_lts_detected"]="Обнаружен драйвер nvidia-lts"
    ["nvidia_dkms_detected"]="Обнаружен драйвер nvidia-dkms"
    ["nvidia_open_dkms_detected"]="Обнаружен драйвер nvidia-open-dkms"
    ["no_nvidia"]="NVIDIA драйверы не обнаружены"
    ["backup_bootloader"]="Создание резервной копии конфигурации загрузчика..."
    ["backup_systemd_boot"]="Резервная копия systemd-boot создана"
    ["backup_grub"]="Резервная копия GRUB создана"
    ["updating_system"]="Обновление системы..."
    ["system_updated"]="Система обновлена"
    ["checking_old_nvidia"]="Проверка старых NVIDIA драйверов..."
    ["removing_nvidia"]="Будет удален драйвер"
    ["nvidia_replaced_dkms"]="заменен на"
    ["dkms_already"]="DKMS драйверы уже используются, пропускаем удаление"
    ["continue_nvidia_replace"]="Продолжить с заменой драйвера? (y/N):"
    ["old_nvidia_removed"]="Старый NVIDIA драйвер удален"
    ["old_driver_kept"]="Старый драйвер оставлен, но может конфликтовать с DKMS версией"
    ["installing_lts"]="Установка LTS ядра и заголовков..."
    ["lts_installed"]="LTS ядро и заголовки установлены"
    ["no_nvidia_skip"]="NVIDIA драйверы не используются, пропускаем"
    ["switching_nvidia"]="Переключение NVIDIA драйвера на DKMS версию..."
    ["installing_target"]="Установка"
    ["nvidia_dkms_installed"]="NVIDIA DKMS драйвер установлен:"
    ["installing_dkms_deps"]="Установка зависимостей для DKMS..."
    ["dkms_deps_installed"]="Зависимости DKMS установлены"
    ["updating_initramfs"]="Обновление initramfs..."
    ["initramfs_updated"]="Initramfs обновлен"
    ["updating_bootloader"]="Обновление конфигурации загрузчика..."
    ["updating_grub"]="Обновление конфигурации GRUB..."
    ["grub_updated"]="Конфигурация GRUB обновлена"
    ["systemd_boot_found"]="Найден systemd-boot"
    ["systemd_boot_auto"]="systemd-boot должен автоматически обнаружить новое ядро"
    ["cleaning_cache"]="Очистка кеша пакетов..."
    ["cache_cleaned"]="Кеш пакетов очищен"
    ["verifying_install"]="Проверка установки..."
    ["lts_kernel_ok"]="LTS ядро установлено"
    ["lts_kernel_fail"]="LTS ядро не найдено!"
    ["lts_headers_ok"]="Заголовки LTS ядра установлены"
    ["lts_headers_fail"]="Заголовки LTS ядра не найдены!"
    ["installed_kernels"]="Установленные ядра:"
    ["nvidia_dkms_ok"]="NVIDIA DKMS драйвер установлен"
    ["nvidia_dkms_warning"]="NVIDIA DKMS драйвер может быть не установлен корректно"
    ["script_title"]="=== Скрипт установки LTS ядра (с сохранением текущего) ==="
    ["supported_info"]="Поддерживаемые ядра: mainline (linux), CachyOS (linux-cachyos)"
    ["detected_config"]="=== Обнаруженная конфигурация ==="
    ["current_kernel_info"]="Текущее ядро:"
    ["nvidia_driver_info"]="NVIDIA драйвер:"
    ["not_detected"]="не обнаружен"
    ["continue_install"]="Продолжить с установкой LTS ядра? (y/N):"
    ["cancelled"]="Операция отменена пользователем"
    ["starting_install"]="=== Начинаем процесс установки LTS ядра ==="
    ["install_success"]="=== УСТАНОВКА LTS ЯДРА ЗАВЕРШЕНА УСПЕШНО! ==="
    ["reboot_required"]="ВНИМАНИЕ: Необходимо перезагрузить систему для применения изменений!"
    ["check_lts_boot"]="После перезагрузки убедитесь, что загрузилось LTS ядро."
    ["old_kernel_kept"]="Старое ядро"
    ["kept_as_backup"]="сохранено как резервное."
    ["bootloader_choice"]="Вы можете выбрать нужное ядро в меню загрузчика."
    ["reboot_now"]="Перезагрузить сейчас? (y/N):"
    ["rebooting"]="Перезагрузка системы..."
    ["reboot_later"]="Не забудьте перезагрузить систему позже!"
    ["install_error"]="=== ОШИБКА ПРИ ПРОВЕРКЕ УСТАНОВКИ ==="
    ["check_before_reboot"]="Проверьте систему перед перезагрузкой!"
    ["script_interrupted"]="Скрипт прерван пользователем"
)

# English language texts
declare -A TEXTS_EN=(
    ["info"]="[INFO]"
    ["success"]="[SUCCESS]"
    ["warning"]="[WARNING]"
    ["error"]="[ERROR]"
    ["root_check_fail"]="Script must be run as root!"
    ["internet_check"]="Checking internet connection..."
    ["internet_fail"]="No internet connection!"
    ["internet_ok"]="Internet connection is available"
    ["current_kernel"]="Current kernel:"
    ["mainline_detected"]="Mainline kernel detected"
    ["cachyos_detected"]="CachyOS kernel detected"
    ["lts_already"]="LTS kernel is already installed!"
    ["lts_check_drivers"]="Script will check NVIDIA drivers and update system"
    ["unknown_kernel"]="Could not determine current kernel type!"
    ["supported_kernels"]="Only supported: linux (mainline), linux-cachyos, linux-lts"
    ["nvidia_detected"]="Detected driver"
    ["nvidia_lts_detected"]="Detected driver nvidia-lts"
    ["nvidia_dkms_detected"]="Detected driver nvidia-dkms"
    ["nvidia_open_dkms_detected"]="Detected driver nvidia-open-dkms"
    ["no_nvidia"]="NVIDIA drivers not detected"
    ["backup_bootloader"]="Creating bootloader configuration backup..."
    ["backup_systemd_boot"]="systemd-boot backup created"
    ["backup_grub"]="GRUB backup created"
    ["updating_system"]="Updating system..."
    ["system_updated"]="System updated"
    ["checking_old_nvidia"]="Checking old NVIDIA drivers..."
    ["removing_nvidia"]="Will remove driver"
    ["nvidia_replaced_dkms"]="replaced with"
    ["dkms_already"]="DKMS drivers already in use, skipping removal"
    ["continue_nvidia_replace"]="Continue with driver replacement? (y/N):"
    ["old_nvidia_removed"]="Old NVIDIA driver removed"
    ["old_driver_kept"]="Old driver kept, but may conflict with DKMS version"
    ["installing_lts"]="Installing LTS kernel and headers..."
    ["lts_installed"]="LTS kernel and headers installed"
    ["no_nvidia_skip"]="NVIDIA drivers not in use, skipping"
    ["switching_nvidia"]="Switching NVIDIA driver to DKMS version..."
    ["installing_target"]="Installing"
    ["nvidia_dkms_installed"]="NVIDIA DKMS driver installed:"
    ["installing_dkms_deps"]="Installing DKMS dependencies..."
    ["dkms_deps_installed"]="DKMS dependencies installed"
    ["updating_initramfs"]="Updating initramfs..."
    ["initramfs_updated"]="Initramfs updated"
    ["updating_bootloader"]="Updating bootloader configuration..."
    ["updating_grub"]="Updating GRUB configuration..."
    ["grub_updated"]="GRUB configuration updated"
    ["systemd_boot_found"]="Found systemd-boot"
    ["systemd_boot_auto"]="systemd-boot should automatically detect new kernel"
    ["cleaning_cache"]="Cleaning package cache..."
    ["cache_cleaned"]="Package cache cleaned"
    ["verifying_install"]="Verifying installation..."
    ["lts_kernel_ok"]="LTS kernel installed"
    ["lts_kernel_fail"]="LTS kernel not found!"
    ["lts_headers_ok"]="LTS kernel headers installed"
    ["lts_headers_fail"]="LTS kernel headers not found!"
    ["installed_kernels"]="Installed kernels:"
    ["nvidia_dkms_ok"]="NVIDIA DKMS driver installed"
    ["nvidia_dkms_warning"]="NVIDIA DKMS driver may not be installed correctly"
    ["script_title"]="=== LTS Kernel Installation Script (keeping current kernel) ==="
    ["supported_info"]="Supported kernels: mainline (linux), CachyOS (linux-cachyos)"
    ["detected_config"]="=== Detected Configuration ==="
    ["current_kernel_info"]="Current kernel:"
    ["nvidia_driver_info"]="NVIDIA driver:"
    ["not_detected"]="not detected"
    ["continue_install"]="Continue with LTS kernel installation? (y/N):"
    ["cancelled"]="Operation cancelled by user"
    ["starting_install"]="=== Starting LTS kernel installation process ==="
    ["install_success"]="=== LTS KERNEL INSTALLATION COMPLETED SUCCESSFULLY! ==="
    ["reboot_required"]="WARNING: System reboot is required to apply changes!"
    ["check_lts_boot"]="After reboot, make sure LTS kernel is loaded."
    ["old_kernel_kept"]="Old kernel"
    ["kept_as_backup"]="kept as backup."
    ["bootloader_choice"]="You can select the desired kernel in bootloader menu."
    ["reboot_now"]="Reboot now? (y/N):"
    ["rebooting"]="Rebooting system..."
    ["reboot_later"]="Don't forget to reboot the system later!"
    ["install_error"]="=== ERROR DURING INSTALLATION VERIFICATION ==="
    ["check_before_reboot"]="Check the system before rebooting!"
    ["script_interrupted"]="Script interrupted by user"
)

# Function to get text in the appropriate language
get_text() {
    local key="$1"
    if [[ "$SCRIPT_LANG" == "ru" ]]; then
        echo "${TEXTS_RU[$key]}"
    else
        echo "${TEXTS_EN[$key]}"
    fi
}

# Message output functions
log_info() {
    echo -e "${BLUE}$(get_text "info")${NC} $1"
}

log_success() {
    echo -e "${GREEN}$(get_text "success")${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}$(get_text "warning")${NC} $1"
}

log_error() {
    echo -e "${RED}$(get_text "error")${NC} $1"
}

# Check root privileges
check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "$(get_text "root_check_fail")"
        exit 1
    fi
}

# Check internet connection
check_internet() {
    log_info "$(get_text "internet_check")"
    if ! ping -c 1 archlinux.org &> /dev/null; then
        log_error "$(get_text "internet_fail")"
        exit 1
    fi
    log_success "$(get_text "internet_ok")"
}

# Detect current kernel type
detect_current_kernel() {
    local kernel_version=$(uname -r)
    log_info "$(get_text "current_kernel") $kernel_version"
    
    if pacman -Q linux &> /dev/null; then
        CURRENT_KERNEL="mainline"
        CURRENT_KERNEL_PACKAGE="linux"
        log_info "$(get_text "mainline_detected")"
    elif pacman -Q linux-cachyos &> /dev/null; then
        CURRENT_KERNEL="cachyos"
        CURRENT_KERNEL_PACKAGE="linux-cachyos"
        log_info "$(get_text "cachyos_detected")"
    elif pacman -Q linux-lts &> /dev/null; then
        log_warning "$(get_text "lts_already")"
        log_info "$(get_text "lts_check_drivers")"
        CURRENT_KERNEL="lts"
        CURRENT_KERNEL_PACKAGE="linux-lts"
    else
        log_error "$(get_text "unknown_kernel")"
        log_info "$(get_text "supported_kernels")"
        exit 1
    fi
}

# Check NVIDIA drivers
detect_nvidia_driver() {
    NVIDIA_DRIVER_TYPE=""
    
    if pacman -Q nvidia &> /dev/null; then
        NVIDIA_DRIVER_TYPE="nvidia"
        log_info "$(get_text "nvidia_detected") nvidia"
    elif pacman -Q nvidia-open &> /dev/null; then
        NVIDIA_DRIVER_TYPE="nvidia-open"
        log_info "$(get_text "nvidia_detected") nvidia-open"
    elif pacman -Q nvidia-lts &> /dev/null; then
        NVIDIA_DRIVER_TYPE="nvidia-lts"
        log_info "$(get_text "nvidia_lts_detected")"
    elif pacman -Q nvidia-open-dkms &> /dev/null; then
        NVIDIA_DRIVER_TYPE="nvidia-open-dkms"
        log_info "$(get_text "nvidia_open_dkms_detected")"
    elif pacman -Q nvidia-dkms &> /dev/null; then
        NVIDIA_DRIVER_TYPE="nvidia-dkms"
        log_info "$(get_text "nvidia_dkms_detected")"
    else
        log_info "$(get_text "no_nvidia")"
    fi
}

# Create bootloader backup
backup_bootloader() {
    log_info "$(get_text "backup_bootloader")"
    
    if [[ -f /boot/loader/entries ]]; then
        cp -r /boot/loader/entries /boot/loader/entries.backup.$(date +%Y%m%d_%H%M%S)
        log_success "$(get_text "backup_systemd_boot")"
    fi
    
    if [[ -f /boot/grub/grub.cfg ]]; then
        cp /boot/grub/grub.cfg /boot/grub/grub.cfg.backup.$(date +%Y%m%d_%H%M%S)
        log_success "$(get_text "backup_grub")"
    fi
}

# Update system
update_system() {
    log_info "$(get_text "updating_system")"
    pacman -Syu --noconfirm
    log_success "$(get_text "system_updated")"
}

# Optional removal of old NVIDIA drivers (non-DKMS versions only)
remove_old_nvidia_drivers() {
    if [[ -z "$NVIDIA_DRIVER_TYPE" ]]; then
        return
    fi
    
    log_info "$(get_text "checking_old_nvidia")"
    
    # Remove only kernel-specific drivers, keeping DKMS versions
    local packages_to_remove=""
    
    if [[ "$NVIDIA_DRIVER_TYPE" == "nvidia" ]]; then
        packages_to_remove="nvidia"
        log_info "$(get_text "removing_nvidia") nvidia ($(get_text "nvidia_replaced_dkms") nvidia-dkms)"
    elif [[ "$NVIDIA_DRIVER_TYPE" == "nvidia-open" ]]; then
        packages_to_remove="nvidia-open"
        log_info "$(get_text "removing_nvidia") nvidia-open ($(get_text "nvidia_replaced_dkms") nvidia-open-dkms)"
    else
        log_info "$(get_text "dkms_already")"
        return
    fi
    
    if [[ -n "$packages_to_remove" ]]; then
        log_warning "$(get_text "removing_nvidia") ($packages_to_remove) $(get_text "nvidia_replaced_dkms") DKMS"
        read -p "$(get_text "continue_nvidia_replace") " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pacman -Rns --noconfirm $packages_to_remove
            log_success "$(get_text "old_nvidia_removed")"
        else
            log_warning "$(get_text "old_driver_kept")"
        fi
    fi
}

# Install LTS kernel
install_lts_kernel() {
    log_info "$(get_text "installing_lts")"
    pacman -S --noconfirm linux-lts linux-lts-headers
    log_success "$(get_text "lts_installed")"
}

# Switch NVIDIA driver to DKMS version
switch_nvidia_to_dkms() {
    if [[ -z "$NVIDIA_DRIVER_TYPE" ]]; then
        log_info "$(get_text "no_nvidia_skip")"
        return
    fi
    
    log_info "$(get_text "switching_nvidia")"
    
    # Determine target DKMS package
    local target_package=""
    if [[ "$NVIDIA_DRIVER_TYPE" == "nvidia" ]] || [[ "$NVIDIA_DRIVER_TYPE" == "nvidia-lts" ]] || [[ "$NVIDIA_DRIVER_TYPE" == "nvidia-dkms" ]]; then
        target_package="nvidia-dkms"
    elif [[ "$NVIDIA_DRIVER_TYPE" == "nvidia-open" ]] || [[ "$NVIDIA_DRIVER_TYPE" == "nvidia-open-dkms" ]]; then
        target_package="nvidia-open-dkms"
    fi
    
    if [[ -n "$target_package" ]]; then
        log_info "$(get_text "installing_target") $target_package..."
        pacman -S --noconfirm $target_package
        log_success "$(get_text "nvidia_dkms_installed") $target_package"
    fi
}

# Install necessary DKMS dependencies
install_dkms_deps() {
    log_info "$(get_text "installing_dkms_deps")"
    pacman -S --needed --noconfirm base-devel dkms
    log_success "$(get_text "dkms_deps_installed")"
}

# Update initramfs
update_initramfs() {
    log_info "$(get_text "updating_initramfs")"
    mkinitcpio -P
    log_success "$(get_text "initramfs_updated")"
}

# Update bootloader
update_bootloader() {
    log_info "$(get_text "updating_bootloader")"
    
    # Update GRUB if installed
    if command -v grub-mkconfig &> /dev/null; then
        log_info "$(get_text "updating_grub")"
        grub-mkconfig -o /boot/grub/grub.cfg
        log_success "$(get_text "grub_updated")"
    fi
    
    # For systemd-boot, generate new entries if needed
    if [[ -d /boot/loader/entries ]]; then
        log_info "$(get_text "systemd_boot_found")"
        # systemd-boot entries are usually updated automatically
        log_success "$(get_text "systemd_boot_auto")"
    fi
}

# Clean package cache
clean_package_cache() {
    log_info "$(get_text "cleaning_cache")"
    pacman -Sc --noconfirm
    log_success "$(get_text "cache_cleaned")"
}

# Verify installation
verify_installation() {
    log_info "$(get_text "verifying_install")"
    
    if pacman -Q linux-lts &> /dev/null; then
        log_success "$(get_text "lts_kernel_ok")"
    else
        log_error "$(get_text "lts_kernel_fail")"
        return 1
    fi
    
    if pacman -Q linux-lts-headers &> /dev/null; then
        log_success "$(get_text "lts_headers_ok")"
    else
        log_error "$(get_text "lts_headers_fail")"
        return 1
    fi
    
    # Show all installed kernels
    log_info "$(get_text "installed_kernels")"
    if pacman -Q linux &> /dev/null; then
        log_info "  - linux (mainline): $(pacman -Q linux | cut -d' ' -f2)"
    fi
    if pacman -Q linux-cachyos &> /dev/null; then
        log_info "  - linux-cachyos: $(pacman -Q linux-cachyos | cut -d' ' -f2)"
    fi
    if pacman -Q linux-lts &> /dev/null; then
        log_info "  - linux-lts: $(pacman -Q linux-lts | cut -d' ' -f2)"
    fi
    
    # Check NVIDIA DKMS if needed
    if [[ -n "$NVIDIA_DRIVER_TYPE" ]]; then
        if pacman -Q nvidia-dkms &> /dev/null || pacman -Q nvidia-open-dkms &> /dev/null; then
            log_success "$(get_text "nvidia_dkms_ok")"
        else
            log_warning "$(get_text "nvidia_dkms_warning")"
        fi
    fi
    
    return 0
}

# Main function
main() {
    log_info "$(get_text "script_title")"
    log_info "$(get_text "supported_info")"
    echo
    
    check_root
    check_internet
    detect_current_kernel
    detect_nvidia_driver
    
    echo
    log_info "$(get_text "detected_config")"
    log_info "$(get_text "current_kernel_info") $CURRENT_KERNEL ($CURRENT_KERNEL_PACKAGE)"
    log_info "$(get_text "nvidia_driver_info") ${NVIDIA_DRIVER_TYPE:-$(get_text "not_detected")}"
    echo
    
    read -p "$(get_text "continue_install") " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "$(get_text "cancelled")"
        exit 0
    fi
    
    echo
    log_info "$(get_text "starting_install")"
    
    backup_bootloader
    update_system
    install_dkms_deps
    install_lts_kernel
    switch_nvidia_to_dkms
    remove_old_nvidia_drivers
    update_initramfs
    update_bootloader
    clean_package_cache
    
    echo
    if verify_installation; then
        echo
        log_success "$(get_text "install_success")"
        log_warning "$(get_text "reboot_required")"
        log_warning "$(get_text "check_lts_boot")"
        log_info "$(get_text "old_kernel_kept") ($CURRENT_KERNEL_PACKAGE) $(get_text "kept_as_backup")"
        log_info "$(get_text "bootloader_choice")"
        echo
        read -p "$(get_text "reboot_now") " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            log_info "$(get_text "rebooting")"
            reboot
        else
            log_warning "$(get_text "reboot_later")"
        fi
    else
        log_error "$(get_text "install_error")"
        log_error "$(get_text "check_before_reboot")"
        exit 1
    fi
}

# Signal handling for proper termination
trap 'log_error "$(get_text "script_interrupted")"; exit 130' INT TERM

# Run main function
main "$@"