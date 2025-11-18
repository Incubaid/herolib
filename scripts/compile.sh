#!/bin/bash
# compile.sh - Script to compile each module in the herolib/lib directory
# This script compiles each module in the lib directory to ensure they build correctly

set -e  # Exit on error

# Default settings
CONCURRENT=false
MAX_JOBS=4  # Default number of concurrent jobs

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -c|--concurrent)
            CONCURRENT=true
            shift
            ;;
        -j|--jobs)
            MAX_JOBS="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo "Options:"
            echo "  -c, --concurrent    Enable concurrent compilation"
            echo "  -j, --jobs N        Set maximum number of concurrent jobs (default: 4)"
            echo "  -h, --help          Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use -h or --help for usage information"
            exit 1
            ;;
    esac
done

# Color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="$SCRIPT_DIR/lib"

# V compiler flags based on the project's test script
V_FLAGS="-stats -enable-globals -n -w -gc none -d use_openssl -shared"

# Log file for compilation results
LOG_FILE="$SCRIPT_DIR/compile_results.log"
> "$LOG_FILE"  # Clear log file

# Summary log file
SUMMARY_FILE="$SCRIPT_DIR/compile_summary.log"
> "$SUMMARY_FILE"  # Clear summary file

# Cache directory for storing timestamps of last successful compilation
CACHE_DIR="$SCRIPT_DIR/.compile_cache"
mkdir -p "$CACHE_DIR"

# Create temporary directory for compiled binaries
mkdir -p "$SCRIPT_DIR/tmp"

# Create a directory for temporary output files
TEMP_DIR="$SCRIPT_DIR/.temp_compile"
mkdir -p "$TEMP_DIR"

# Trap for cleaning up on exit
cleanup() {
    echo "Cleaning up..."
    # Kill any remaining child processes
    jobs -p | xargs kill -9 2>/dev/null || true
    # Remove temporary directories
    rm -rf "$TEMP_DIR" "$SCRIPT_DIR/tmp" 2>/dev/null || true
    exit 0
}

# Set up traps for various signals
trap cleanup EXIT INT TERM

# Define modules to skip entirely due to known compilation issues
SKIP_MODULES=("flist" "openai" "mycelium" "vastai" "rclone" "sendgrid" "mailclient" "ipapi" "runpod" "postgresql_client" "meilisearch" "livekit" "wireguard" "_archive" "clients")

# Function to check if a module should be skipped
should_skip_module() {
    local module_name="$1"
    
    for skip_module in "${SKIP_MODULES[@]}"; do
        if [[ "$module_name" == "$skip_module" ]]; then
            return 0  # true, should skip
        fi
    done
    
    return 1  # false, should not skip
}

# Function to check if a module needs recompilation
needs_module_recompilation() {
    local module_path="$1"
    local module_name="$(basename "$module_path")"
    local cache_file="$CACHE_DIR/$module_name.timestamp"
    
    # If cache file doesn't exist, module needs recompilation
    if [ ! -f "$cache_file" ]; then
        return 0  # true, needs recompilation
    fi
    
    # Check if any .v file in the module is newer than the last compilation
    if find "$module_path" -name "*.v" -type f -newer "$cache_file" | grep -q .; then
        return 0  # true, needs recompilation
    fi
    
    return 1  # false, doesn't need recompilation
}

# Function to update the cache timestamp for a module
update_module_cache() {
    local module_path="$1"
    local module_name="$(basename "$module_path")"
    local cache_file="$CACHE_DIR/$module_name.timestamp"
    
    # Update the timestamp
    touch "$cache_file"
}

# Function to check if a directory is a module (contains .v files directly, not just in subdirectories)
is_module() {
    local dir_path="$1"
    
    # Check if there are any .v files directly in this directory (not in subdirectories)
    if [ -n "$(find "$dir_path" -maxdepth 1 -name "*.v" -type f -print -quit)" ]; then
        return 0  # true, is a module
    fi
    
    return 1  # false, not a module
}

# Function to compile a module
compile_module() {
    local module_path="$1"
    local module_name="$(basename "$module_path")"
    local output_file="$TEMP_DIR/${module_name}.log"
    local result_file="$TEMP_DIR/${module_name}.result"
    
    # Initialize the result file
    echo "pending" > "$result_file"
    
    # Check if this module should be skipped
    if should_skip_module "$module_name"; then
        echo "Skipping problematic module: $module_name" > "$output_file"
        echo "skipped|${module_path#$LIB_DIR/}|" >> "$SUMMARY_FILE"
        echo "skipped" > "$result_file"
        return 0
    fi
    
    # Check if this is actually a module (has .v files directly)
    if ! is_module "$module_path"; then
        echo "$module_name is not a module (no direct .v files), skipping" > "$output_file"
        echo "not_module|${module_path#$LIB_DIR/}|" >> "$SUMMARY_FILE"
        echo "skipped" > "$result_file"
        return 0
    fi
    
    echo "Compiling module: $module_name" > "$output_file"
    
    # Check if the module needs recompilation
    if ! needs_module_recompilation "$module_path"; then
        echo "  No changes detected in $module_name, skipping compilation" >> "$output_file"
        echo "cached|${module_path#$LIB_DIR/}|" >> "$SUMMARY_FILE"
        echo "cached" > "$result_file"
        return 0
    fi
    
    # Record start time
    local start_time=$(date +%s.%N)
    
    # Try to compile the module - redirect both stdout and stderr to the output file
    if v $V_FLAGS -o "$SCRIPT_DIR/tmp/$module_name" "$module_path" >> "$output_file" 2>&1; then
        # Calculate compilation time
        local end_time=$(date +%s.%N)
        local compile_time=$(echo "$end_time - $start_time" | bc)
        
        echo "  Successfully compiled $module_name" >> "$output_file"
        # Update the cache timestamp
        update_module_cache "$module_path"
        
        # Log result
        echo "success|${module_path#$LIB_DIR/}|$compile_time" >> "$SUMMARY_FILE"
        echo "success" > "$result_file"
        return 0
    else
        echo "  Failed to compile $module_name" >> "$output_file"
        
        # Log result
        echo "failed|${module_path#$LIB_DIR/}|" >> "$SUMMARY_FILE"
        echo "failed" > "$result_file"
        return 1
    fi
}

# Function to run modules in parallel with a maximum number of concurrent jobs
run_parallel() {
    local modules=("$@")
    local total=${#modules[@]}
    local completed=0
    local running=0
    local pids=()
    local module_indices=()
    
    echo "Running $total modules in parallel (max $MAX_JOBS jobs at once)"
    
    # Initialize arrays to track jobs
    for ((i=0; i<$total; i++)); do
        pids[$i]=-1
    done
    
    # Start initial batch of jobs
    local next_job=0
    while [[ $next_job -lt $total && $running -lt $MAX_JOBS ]]; do
        compile_module "${modules[$next_job]}" > /dev/null 2>&1 &
        pids[$next_job]=$!
        ((running++))
        ((next_job++))
    done
    
    # Display progress indicator
    display_progress() {
        local current=$1
        local total=$2
        local percent=$((current * 100 / total))
        local bar_length=50
        local filled_length=$((percent * bar_length / 100))
        
        printf "\r[" >&2
        for ((i=0; i<bar_length; i++)); do
            if [ $i -lt $filled_length ]; then
                printf "#" >&2
            else
                printf " " >&2
            fi
        done
        printf "] %d%% (%d/%d modules)" $percent $current $total >&2
    }
    
    # Monitor running jobs and start new ones as needed
    while [[ $completed -lt $total ]]; do
        display_progress $completed $total
        
        # Check for completed jobs
        for ((i=0; i<$total; i++)); do
            if [[ ${pids[$i]} -gt 0 ]]; then
                if ! kill -0 ${pids[$i]} 2>/dev/null; then
                    # Job completed
                    local module_path="${modules[$i]}"
                    local module_name="$(basename "$module_path")"
                    local output_file="$TEMP_DIR/${module_name}.log"
                    
                    # Add output to log file
                    if [[ -f "$output_file" ]]; then
                        cat "$output_file" >> "$LOG_FILE"
                    fi
                    
                    # Mark job as completed
                    pids[$i]=-2
                    ((completed++))
                    ((running--))
                    
                    # Start a new job if available
                    if [[ $next_job -lt $total ]]; then
                        compile_module "${modules[$next_job]}" > /dev/null 2>&1 &
                        pids[$next_job]=$!
                        ((running++))
                        ((next_job++))
                    fi
                fi
            fi
        done
        
        # Brief pause to avoid excessive CPU usage
        sleep 0.1
    done
    
    # Clear the progress line
    printf "\r%$(tput cols)s\r" ""
    
    # Wait for any remaining background jobs
    wait
}

# Function to find all modules in a directory (recursively)
find_modules() {
    local dir_path="$1"
    local modules=()
    
    # Check if this directory is a module itself
    if is_module "$dir_path"; then
        modules+=("$dir_path")
    fi
    
    # Look for modules in subdirectories (only one level deep)
    for subdir in "$dir_path"/*; do
        if [ -d "$subdir" ]; then
            local subdir_name="$(basename "$subdir")"
            
            # Skip if this is in the skip list
            if should_skip_module "$subdir_name"; then
                echo -e "${YELLOW}Skipping problematic module: $subdir_name${NC}"
                echo "Skipping problematic module: $subdir_name" >> "$LOG_FILE"
                echo "skipped|${subdir#$LIB_DIR/}|" >> "$SUMMARY_FILE"
                continue
            fi
            
            # Check if this subdirectory is a module
            if is_module "$subdir"; then
                modules+=("$subdir")
            fi
        fi
    done
    
    echo "${modules[@]}"
}

echo "===== Starting compilation of all modules in lib ====="
echo "===== Starting compilation of all modules in lib =====" >> "$LOG_FILE"

# Define priority modules to compile first
PRIORITY_MODULES=("biz" "builder" "core" "crystallib" "jsonrpc" "jsonschema")

echo -e "${YELLOW}Attempting to compile each module as a whole...${NC}"
echo "Attempting to compile each module as a whole..." >> "$LOG_FILE"

# Collect all modules to compile
all_modules=()

# First add priority modules
for module_name in "${PRIORITY_MODULES[@]}"; do
    module_dir="$LIB_DIR/$module_name"
    if [ -d "$module_dir" ]; then
        # Find all modules in this directory
        modules=($(find_modules "$module_dir"))
        all_modules+=("${modules[@]}")
    fi
done

# Then add remaining modules
for module_dir in "$LIB_DIR"/*; do
    if [ -d "$module_dir" ]; then
        module_name="$(basename "$module_dir")"
        # Skip modules already compiled in priority list
        if [[ " ${PRIORITY_MODULES[*]} " =~ " $module_name " ]]; then
            continue
        fi
        
        # Find all modules in this directory
        modules=($(find_modules "$module_dir"))
        all_modules+=("${modules[@]}")
    fi
done

# Debug: print all modules found
echo "Found ${#all_modules[@]} modules to compile" >> "$LOG_FILE"
for module in "${all_modules[@]}"; do
    echo "  - $module" >> "$LOG_FILE"
done

# Compile modules (either in parallel or sequentially)
if $CONCURRENT; then
    run_parallel "${all_modules[@]}"
else
    # Sequential compilation
    for module_path in "${all_modules[@]}"; do
        # Display module being compiled
        module_name="$(basename "$module_path")"
        echo -e "${YELLOW}Compiling module: $module_name${NC}"
        
        # Compile the module
        compile_module "$module_path" > /dev/null 2>&1
        
        # Display result
        output_file="$TEMP_DIR/${module_name}.log"
        result_file="$TEMP_DIR/${module_name}.result"
        
        if [[ -f "$output_file" ]]; then
            cat "$output_file" >> "$LOG_FILE"
            
            # Display with color based on result
            result=$(cat "$result_file")
            if [[ "$result" == "success" ]]; then
                echo -e "${GREEN}  Successfully compiled $module_name${NC}"
            elif [[ "$result" == "failed" ]]; then
                echo -e "${RED}  Failed to compile $module_name${NC}"
            elif [[ "$result" == "cached" ]]; then
                echo -e "${GREEN}  No changes detected in $module_name, skipping compilation${NC}"
            else
                echo -e "${YELLOW}  Skipped $module_name${NC}"
            fi
        fi
    done
fi

# Count successes and failures
success_count=$(grep -c "^success|" "$SUMMARY_FILE" || echo 0)
failure_count=$(grep -c "^failed|" "$SUMMARY_FILE" || echo 0)
cached_count=$(grep -c "^cached|" "$SUMMARY_FILE" || echo 0)
skipped_count=$(grep -c "^skipped|" "$SUMMARY_FILE" || echo 0)
not_module_count=$(grep -c "^not_module|" "$SUMMARY_FILE" || echo 0)

echo "===== Compilation complete ====="
echo -e "${GREEN}Successfully compiled: $success_count modules${NC}"
echo -e "${GREEN}Cached (no changes): $cached_count modules${NC}"
echo -e "${YELLOW}Skipped: $skipped_count modules${NC}"
echo -e "${YELLOW}Not modules: $not_module_count directories${NC}"
echo -e "${RED}Failed to compile: $failure_count modules${NC}"
echo "See $LOG_FILE for detailed compilation results"

echo "===== Compilation complete =====" >> "$LOG_FILE"
echo "Successfully compiled: $success_count modules" >> "$LOG_FILE"
echo "Cached (no changes): $cached_count modules" >> "$LOG_FILE"
echo "Skipped: $skipped_count modules" >> "$LOG_FILE"
echo "Not modules: $not_module_count directories" >> "$LOG_FILE"
echo "Failed to compile: $failure_count modules" >> "$LOG_FILE"

# Print detailed summary
echo ""
echo "===== Module Compilation Summary ====="
echo ""

# Print successful modules first, sorted by compilation time
echo "Successful compilations:"
grep "^success|" "$SUMMARY_FILE" | sort -t'|' -k3,3n | while IFS='|' read -r status path time; do
    # Color code based on compilation time
    time_color="$GREEN"
    if (( $(echo "$time > 10.0" | bc -l) )); then
        time_color="$RED"
    elif (( $(echo "$time > 1.0" | bc -l) )); then
        time_color="$YELLOW"
    fi
    
    echo -e "✅  $path\t${time_color}${time}s${NC}"
done

# Print cached modules
echo ""
echo "Cached modules (no changes detected):"
grep "^cached|" "$SUMMARY_FILE" | sort | while IFS='|' read -r status path time; do
    echo -e "🔄  $path\t${GREEN}CACHED${NC}"
done

# Print skipped modules
echo ""
echo "Skipped modules:"
grep "^skipped|" "$SUMMARY_FILE" | sort | while IFS='|' read -r status path time; do
    echo -e "⏭️  $path\t${YELLOW}SKIPPED${NC}"
done

# Print not modules
echo ""
echo "Not modules (directories without direct .v files):"
grep "^not_module|" "$SUMMARY_FILE" | sort | while IFS='|' read -r status path time; do
    echo -e "📁  $path\t${YELLOW}NOT MODULE${NC}"
done

# Print failed modules
echo ""
echo "Failed modules:"
grep "^failed|" "$SUMMARY_FILE" | sort | while IFS='|' read -r status path time; do
    echo -e "❌  $path\t${RED}FAILED${NC}"
done

echo ""
echo "===== End of Summary ====="

# Exit with error code if any module failed to compile
if [ $failure_count -gt 0 ]; then
    exit 1
fi

exit 0
