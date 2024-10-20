#!/bin/bash

# Function to convert sizes from GB to MB
gb_to_mb() {
    echo $(($1 * 1024))
}

# Function to perform the write test
write_test() {
    local size_mb=$1
    local file=$2
    dd if=/dev/zero bs=1M count=$size_mb | pv -s ${size_mb}M | dd of=$file conv=fdatasync
}

# Function to perform the read test
read_test() {
    local file=$1
    dd if=$file of=/dev/null bs=1M | pv
}

# Request user input
read -p "Enter the total size you want to write in GB: " total_size_gb
read -p "Enter the size of each file in GB: " file_size_gb

# Convert GB to MB
total_size_mb=$(gb_to_mb $total_size_gb)
file_size_mb=$(gb_to_mb $file_size_gb)

# Calculate the number of files
num_files=$((total_size_mb / file_size_mb))

echo "Starting write tests..."

for i in $(seq 1 $num_files)
do
    echo "Creating and writing file testfile$i..."
    write_test $file_size_mb "./testfile$i"
done

echo "Write tests completed."

# Ask the user if they want to proceed with the read tests
read -p "Do you want to proceed with the read tests? (y/n): " proceed_read

if [ "$proceed_read" = "y" ] || [ "$proceed_read" = "Y" ]; then
    echo "Starting read tests..."
    for i in $(seq 1 $num_files)
    do
        echo "Reading file testfile$i..."
        read_test "./testfile$i"
    done
    echo "Read tests completed."
else
    echo "Read tests skipped."
fi

# Clean up test files
read -p "Do you want to remove the test files? (y/n): " clean_up
if [ "$clean_up" = "y" ] || [ "$clean_up" = "Y" ]; then
    rm ./testfile*
    echo "Test files removed."
else
    echo "Test files kept."
fi

echo "All tests completed."
