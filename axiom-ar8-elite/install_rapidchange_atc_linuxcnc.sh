#!/bin/bash

# Check if script is being executed
if [ "$0" != "$BASH_SOURCE" ]; then
    echo "Error: Script must be executed, not sourced"
    exit 1
fi

# Enable error checking
set -e

# Check if running in bash
if [ -z "$BASH_VERSION" ]; then
    echo "Error: This script requires bash to run"
    exit 1
fi

# Check script permissions
if [ ! -x "$0" ]; then
    echo "Error: Script is not executable. Please run:"
    echo "chmod +x $0"
    exit 1
fi

# Function to check basic requirements
check_requirements() {
    # Check if we're on Linux
    if [ "$(uname)" != "Linux" ]; then
        echo "Error: This script must be run on Linux"
        exit 1
    fi
    
    # Check for required commands
    local required_commands=("find" "sed" "grep" "chmod")
    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &> /dev/null; then
            echo "Error: Required command '$cmd' not found"
            exit 1
        fi
    done
    
    # Check if LinuxCNC configs directory structure exists
    if [ ! -d "/home/$(whoami)/linuxcnc" ]; then
        echo "Error: LinuxCNC directory not found in home directory"
        echo "Are you sure LinuxCNC is installed?"
        exit 1
    fi
}

# Repository information
REPO_URL="https://github.com/KennethThompson/printnc_qtdragon_hd_config.git"
REPO_BRANCH="rapidatc"
REPO_ZIP_URL="https://github.com/KennethThompson/printnc_qtdragon_hd_config/archive/refs/heads/rapidatc.zip"
TEMP_DIR="/tmp/rapidchange_atc_temp"

# Function to check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

# Function to download repository
download_repository() {
    echo "Downloading RapidChange ATC files..."
    TEMP_DIR=$(mktemp -d)
    
    if check_command "git"; then
        if git clone -q -b "$REPO_BRANCH" "$REPO_URL" "$TEMP_DIR" 2>/dev/null; then
            return 0
        fi
    fi
    
    if check_command "wget"; then
        if wget -q "$REPO_ZIP_URL" -O "$TEMP_DIR/repo.zip" && check_command "unzip"; then
            if unzip -q "$TEMP_DIR/repo.zip" -d "$TEMP_DIR" 2>/dev/null; then
                mv "$TEMP_DIR"/printnc_qtdragon_hd_config-rapidatc/* "$TEMP_DIR/" 2>/dev/null
                rm -rf "$TEMP_DIR"/printnc_qtdragon_hd_config-rapidatc "$TEMP_DIR/repo.zip"
                return 0
            fi
        fi
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    echo "Error: Neither git nor wget is installed"
    rm -rf "$TEMP_DIR"
    return 1
}

# Function to copy configuration folders
copy_config_folders() {
    local target_dir="$1"
    local source_dir="$TEMP_DIR/configs/myprintnc"
    
    mkdir -p "$target_dir/qtvcp" "$target_dir/macros" 2>/dev/null
    
    if [ ! -d "$source_dir/qtvcp" ] || [ ! -d "$source_dir/macros" ]; then
        echo "Error: Source directories not found"
        return 1
    fi
    
    cp -r "$source_dir/qtvcp/"* "$target_dir/qtvcp/" 2>/dev/null
    cp -r "$source_dir/macros/"* "$target_dir/macros/" 2>/dev/null
    
    local hal_file="$source_dir/rapidatc-postgui.hal"
    if [ -f "$hal_file" ]; then
        cp "$hal_file" "$target_dir/rapidatc-postgui.hal" 2>/dev/null
        chmod 644 "$target_dir/rapidatc-postgui.hal" 2>/dev/null
        if [ ! -f "$target_dir/rapidatc-postgui.hal" ]; then
            echo "Error: Failed to copy HAL file"
            return 1
        fi
    else
        echo "Error: HAL file not found"
        return 1
    fi
    
    chmod -R 755 "$target_dir/qtvcp" "$target_dir/macros" 2>/dev/null
    chmod 644 "$target_dir/"*.hal 2>/dev/null
    
    return 0
}

# Function to check if a directory exists
check_directory() {
    if [ ! -d "$1" ]; then
        echo "Error: Directory $1 does not exist"
        return 1
    fi
    return 0
}

# Function to cleanup
cleanup() {
    if [ -d "$TEMP_DIR" ]; then
        rm -rf "$TEMP_DIR"
    fi
}

# Function to list available configurations
list_configurations() {
    local base_path="$1"
    local configs=()
    local i=1

    echo "Available machine configurations:"
    echo "================================"

    # Find all directories containing .ini files
    while IFS= read -r dir; do
        config_name=$(basename "$dir")
        configs+=("$config_name")
        echo "[$i] $config_name"
        ((i++))
    done < <(find "$base_path" -type f -name "*.ini" -exec dirname {} \; | sort -u)

    # Add manual entry option
    echo "[m] Enter manually"
    
    return 0
}

# Function to get configuration choice
get_configuration_choice() {
    local base_path="$1"
    local configs=()
    
    # Build array of configurations
    while IFS= read -r dir; do
        configs+=("$(basename "$dir")")
    done < <(find "$base_path" -type f -name "*.ini" -exec dirname {} \; | sort -u)

    while true; do
        read -p "Select configuration [1-${#configs[@]}/m]: " choice

        # Check if user wants to enter manually
        if [[ "$choice" == "m" || "$choice" == "M" ]]; then
            read -p "Enter machine configuration name: " manual_choice
            if [ -n "$manual_choice" ]; then
                echo "$manual_choice"
                return 0
            fi
        # Check if choice is a valid number
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#configs[@]}" ]; then
            echo "${configs[$choice-1]}"
            return 0
        fi

        echo "Invalid selection. Please try again."
    done
}

# Function to modify INI file
modify_ini_file() {
    local ini_file="$1"
    local machine_name="$2"
    local current_user="$3"
    local machine_dir="/home/$current_user/linuxcnc/configs/$machine_name"
    
    # Backup original file
    cp "$ini_file" "$ini_file.bak"
    
    # Process the file and add/update all required sections
    awk -v mdir="$machine_dir" '
    BEGIN { 
        in_section = ""
        sections_added["HAL"] = 0
        sections_added["DISPLAY"] = 0
        sections_added["RS274NGC"] = 0
        sections_added["PYTHON"] = 0
        sections_added["CHANGE_POSITION"] = 0
        sections_added["VERSA_TOOLSETTER"] = 0
        sections_added["PROBE"] = 0
    }
    
    # If we find a section
    /^\[.*\]/ { 
        # If we were in a section, check if we need to add entries
        if (in_section != "") {
            if (in_section == "HAL" && !sections_added["HAL"]) {
                print "POSTGUI_HALFILE = rapidatc-postgui.hal"
            }
            else if (in_section == "DISPLAY" && !sections_added["DISPLAY"]) {
                print "EMBED_TAB_NAME = ATC Demo"
                print "EMBED_TAB_COMMAND = qtvcp " mdir "/qtvcp/rapidchange"
                print "EMBED_TAB_LOCATION = stackedWidget_mainTab"
                print "LOG_FILE = " mdir "/log.log"
            }
            else if (in_section == "RS274NGC" && !sections_added["RS274NGC"]) {
                print "PARAMETER_FILE = linuxcnc.var"
                print "REMAP=M6    modalgroup=6 prolog=change_prolog ngc=tool_change epilog=change_epilog"
                print "NGCGUI_SUBFILE_PATH = ~/linuxcnc/nc_files/examples/ngcgui_lib/"
                print "SUBROUTINE_PATH = \\"
                print "~/linuxcnc/nc_files/examples/ngcgui_lib:\\"
                print "~/linuxcnc/nc_files/examples/ngcgui_lib/utilitysubs:\\"
                print "~/linuxcnc/nc_files/examples/remap-subroutines:\\"
                print "/usr/share/linuxcnc/ncfiles/remap_lib:\\"
                print mdir "/macros:\\"
                print "ON_ABORT_COMMAND=O <on_abort> call"
            }
            else if (in_section == "PYTHON" && !sections_added["PYTHON"]) {
                print "PATH_PREPEND = ~/linuxcnc/nc_files/examples/remap_lib/python-stdglue/python"
                print "TOPLEVEL = /usr/share/linuxcnc/ncfiles/remap_lib/python-stdglue/python/toplevel.py"
            }
            sections_added[in_section] = 1
        }
        
        # Get new section name using basic string manipulation
        in_section = $0
        sub(/^\[/, "", in_section)  # Remove opening bracket
        sub(/\]$/, "", in_section)  # Remove closing bracket
        print ""
        print $0
        next
    }
    
    # Print all other lines
    { print }
    
    # At end of file
    END {
        # Handle last section
        if (in_section != "") {
            if (in_section == "HAL" && !sections_added["HAL"]) {
                print "POSTGUI_HALFILE = rapidatc-postgui.hal"
            }
            else if (in_section == "DISPLAY" && !sections_added["DISPLAY"]) {
                print "EMBED_TAB_NAME = ATC Demo"
                print "EMBED_TAB_COMMAND = qtvcp " mdir "/qtvcp/rapidchange"
                print "EMBED_TAB_LOCATION = stackedWidget_mainTab"
                print "LOG_FILE = " mdir "/log.log"
            }
            else if (in_section == "RS274NGC" && !sections_added["RS274NGC"]) {
                print "PARAMETER_FILE = linuxcnc.var"
                print "REMAP=M6    modalgroup=6 prolog=change_prolog ngc=tool_change epilog=change_epilog"
                print "NGCGUI_SUBFILE_PATH = ~/linuxcnc/nc_files/examples/ngcgui_lib/"
                print "SUBROUTINE_PATH = \\"
                print "~/linuxcnc/nc_files/examples/ngcgui_lib:\\"
                print "~/linuxcnc/nc_files/examples/ngcgui_lib/utilitysubs:\\"
                print "~/linuxcnc/nc_files/examples/remap-subroutines:\\"
                print "/usr/share/linuxcnc/ncfiles/remap_lib:\\"
                print mdir "/macros:\\"
                print "ON_ABORT_COMMAND=O <on_abort> call"
            }
            else if (in_section == "PYTHON" && !sections_added["PYTHON"]) {
                print "PATH_PREPEND = ~/linuxcnc/nc_files/examples/remap_lib/python-stdglue/python"
                print "TOPLEVEL = /usr/share/linuxcnc/ncfiles/remap_lib/python-stdglue/python/toplevel.py"
            }
        }
        
        # Add missing sections at the end
        if (!sections_added["PYTHON"]) {
            print "\n[PYTHON]"
            print "PATH_PREPEND = ~/linuxcnc/nc_files/examples/remap_lib/python-stdglue/python"
            print "TOPLEVEL = /usr/share/linuxcnc/ncfiles/remap_lib/python-stdglue/python/toplevel.py"
        }
        
        if (!sections_added["CHANGE_POSITION"]) {
            print "\n[CHANGE_POSITION]"
            print "X = 100"
            print "Y = 0"
            print "Z = 0"
        }
        
        if (!sections_added["VERSA_TOOLSETTER"]) {
            print "\n[VERSA_TOOLSETTER]"
            print "X = 57.0"
            print "Y = 23.65"
            print "Z = -10"
            print "Z_MAX_CLEAR = -2"
            print "MAXPROBE = 30"
        }
        
        if (!sections_added["PROBE"]) {
            print "\n[PROBE]"
            print "USE_PROBE = versaprobe"
        }
    }' "$ini_file" > "$ini_file.tmp"
    
    # Replace original file
    mv "$ini_file.tmp" "$ini_file"
}

# Main script
main() {
    echo "RapidChange ATC Configuration Installer"
    echo "====================================="
    
    check_requirements
    
    if ! download_repository; then
        cleanup
        exit 1
    fi

    username=$(whoami)
    base_path="/home/$username/linuxcnc/configs"
    
    if ! check_directory "$base_path"; then
        echo "Error: LinuxCNC configs directory not found"
        cleanup
        exit 1
    fi

    list_configurations "$base_path"
    machine_name=$(get_configuration_choice "$base_path")
    echo "Selected configuration: $machine_name"

    machine_path="$base_path/haskins-guitars/$machine_name"
    ini_file="$machine_path/$machine_name.ini"

    if ! check_directory "$machine_path"; then
        echo "Error: Machine configuration not found"
        cleanup
        exit 1
    fi

    if [ ! -f "$ini_file" ]; then
        echo "Error: INI file not found"
        cleanup
        exit 1
    fi

    echo "Installing RapidChange ATC..."
    if ! copy_config_folders "$machine_path"; then
        echo "Error: Installation failed"
        cleanup
        exit 1
    fi

    modify_ini_file "$ini_file" "$machine_name" "$username"

    echo "Installation completed successfully!"
    cleanup
}

# Show usage if --help is specified
if [ "$1" = "--help" ]; then
    echo "Usage: $0 [--help]"
    echo ""
    echo "Options:"
    echo "  --help     Show this help message"
    exit 0
fi

# Run main function with arguments
main "$@" 