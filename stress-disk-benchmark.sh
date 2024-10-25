#!/bin/bash

# Colors for better visibility
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Debug function
debug() {
    echo "DEBUG: $1"
}

# Check if 'pv' is installed
if ! command -v pv &> /dev/null; then
    echo -e "${RED}Error: The 'pv' package is not installed.${NC}"
    echo -e "${YELLOW}Please install using: sudo apt-get install pv${NC}"
    exit 1
fi

# Function to convert sizes from GB to MB
gb_to_mb() {
    echo $(($1 * 1024))
}

# Function to list and select a disk
select_disk() {
    debug "Starting select_disk function"
    echo -e "${YELLOW}Available Disks:${NC}"
    echo "----------------------------------------"

    # Debug to check the output of df
    debug "Output of df:"
    df -h | grep '^/dev/' | grep -v '^/dev/loop'

    # Create an array to store disk information
    declare -a devices
    while IFS= read -r line; do
        devices+=("$line")
    done < <(df -h | grep '^/dev/' | grep -v '^/dev/loop' | awk '{print $1}')

    debug "Number of devices found: ${#devices[@]}"

    # For each device, get its information
    for ((i=0; i<${#devices[@]}; i++)); do
        device="${devices[$i]}"
        debug "Processing device: $device"
        info=$(df -h "$device" | tail -n 1)
        size=$(echo "$info" | awk '{print $2}')
        used=$(echo "$info" | awk '{print $3}')
        avail=$(echo "$info" | awk '{print $4}')
        usep=$(echo "$info" | awk '{print $5}')
        mount=$(echo "$info" | awk '{print $6}')

        echo "$((i+1))) $device"
        echo "   Size: $size"
        echo "   Used: $used"
        echo "   Available: $avail"
        echo "   Use: $usep"
        echo "   Mounted on: $mount"
        echo "----------------------------------------"
    done

    # If no devices are found
    if [ ${#devices[@]} -eq 0 ]; then
        echo -e "${RED}Error: No devices found${NC}"
        debug "No devices found in df"
        exit 1
    fi

    # Request user selection
    while true; do
        read -p "Enter the number of the disk (1-${#devices[@]}): " selection
        if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le "${#devices[@]}" ]; then
            selected_device="${devices[$((selection-1))]}"
            selected_mount=$(df -h "$selected_device" | tail -n 1 | awk '{print $6}')

            # Check write permissions
            if [ -w "$selected_mount" ]; then
                echo -e "${GREEN}Selected disk: $selected_device ($selected_mount)${NC}"
                echo "----------------------------------------"
                break
            else
                echo -e "${RED}Error: No write permission on $selected_mount${NC}"
                echo -e "${RED}Run the script with sudo or select another disk.${NC}"
            fi
        else
            echo -e "${RED}Invalid selection. Please enter a number between 1 and ${#devices[@]}.${NC}"
        fi
    done
    echo "$selected_mount"
}

# Call the select_disk function to allow the user to choose a disk for testing
select_disk

# Function to perform write test
write_test() {
    local size_mb=$1
    local file=$2
    echo -e "${YELLOW}Writing $size_mb MB...${NC}"
    dd if=/dev/zero bs=1M count=$size_mb 2>/dev/null | pv -s ${size_mb}M | dd of="$file" conv=fdatasync 2>/dev/null
}

# Function to perform read test
read_test() {
    local file=$1
    local size=$(stat -f %z "$file")
    echo -e "${YELLOW}Reading file...${NC}"
    dd if="$file" bs=1M 2>/dev/null | pv -s $size | dd of=/dev/null 2>/dev/null
}

# Main function
main() {
    echo -e "${GREEN}=== Disk Benchmark ===${NC}"

    # Select the disk for testing
    test_dir=$(select_disk)

    # Request user input
    while true; do
        read -p "Enter the total size for writing in GB: " total_size_gb
        if [[ "$total_size_gb" =~ ^[0-9]+$ ]]; then
            break
        else
            echo -e "${RED}Please enter a valid number.${NC}"
        fi
    done

    while true; do
        read -p "Enter the size of each file in GB: " file_size_gb
        if [[ "$file_size_gb" =~ ^[0-9]+$ ]] && [ "$file_size_gb" -le "$total_size_gb" ]; then
            break
        else
            echo -e "${RED}Please enter a valid number less than or equal to the total size.${NC}"
        fi
    done

    # Convert GB to MB
    total_size_mb=$(gb_to_mb $total_size_gb)
    file_size_mb=$(gb_to_mb $file_size_gb)

    # Calculate the number of files
    num_files=$((total_size_mb / file_size_mb))

    # Check available space
    available_space=$(df -BM --output=avail "$test_dir" | tail -n 1 | sed 's/M//')
    if [ $total_size_mb -gt $available_space ]; then
        echo -e "${RED}ERROR: Insufficient space on the disk!${NC}"
        echo -e "${RED}Required: ${total_size_mb}MB${NC}"
        echo -e "${RED}Available: ${available_space}MB${NC}"
        exit 1
    fi

    echo -e "${GREEN}Starting write tests...${NC}"

    # Create a temporary directory for tests
    test_path="${test_dir}/disk_benchmark_$$"
    mkdir -p "$test_path"

    start_time=$(date +%s)

    for i in $(seq 1 $num_files); do
        echo -e "${YELLOW}Creating and writing file testfile$i...${NC}"
        write_test $file_size_mb "${test_path}/testfile$i"
    done

    end_time=$(date +%s)
    write_duration=$((end_time - start_time))

    echo -e "${GREEN}Write tests completed in $write_duration seconds.${NC}"

    # Ask if the user wants to proceed with read tests
    read -p "Do you want to proceed with read tests? (y/n): " proceed_read

    if [ "$proceed_read" = "y" ] || [ "$proceed_read" = "Y" ]; then
        echo -e "${GREEN}Starting read tests...${NC}"
        start_time=$(date +%s)

        for i in $(seq 1 $num_files); do
            echo -e "${YELLOW}Reading file testfile$i...${NC}"
            read_test "${test_path}/testfile$i"
        done

        end_time=$(date +%s)
        read_duration=$((end_time - start_time))

        echo -e "${GREEN}Read tests completed in $read_duration seconds.${NC}"
    else
        echo -e "${YELLOW}Read tests skipped.${NC}"
    fi

    # Clean up test files
    read -p "Do you want to remove the test files? (y/n): " clean_up
    if [ "$clean_up" = "y" ] || [ "$clean_up" = "Y" ]; then
        rm -rf "$test_path"
        echo -e "${GREEN}Test files removed.${NC}"
    else
        echo -e "${YELLOW}Test files kept in: $test_path${NC}"
    fi

    # Display summary
    echo -e "\n${GREEN}=== Test Summary ===${NC}"
    echo "Test directory: $test_dir"
    echo "Total size: ${total_size_gb}GB"
    echo "Size of each file: ${file_size_gb}GB"
    echo "Number of files: $num_files"
    echo "Write time: $write_duration seconds"
    if [ "$proceed_read" = "y" ] || [ "$proceed_read" = "Y" ]; then
        echo "Read time: $read_duration seconds"
    fi
}

# Execute the main function
main
