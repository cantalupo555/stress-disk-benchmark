# stress-disk-benchmark

A simple yet powerful tool for benchmarking disk performance under real-world conditions. This script creates actual files on your disk, allowing you to test the behavior of your file system and disk under genuine load.

## Features

- Creates real files on the disk for a true representation of disk performance
- Allows user to specify total size and individual file size
- Performs both write and read tests
- Provides option to skip read tests if desired
- Offers cleanup option after tests are complete
- Uses `dd` and `pv` for accurate measurement and progress visualization

## Prerequisites

Before you begin, ensure you have the following installed on your system:
- Bash shell
- `dd` command (usually pre-installed on most Unix-like systems)
- `pv` command (Pipe Viewer)

To install `pv` on most Debian-based systems (including Ubuntu):
```
sudo apt-get install pv
```

On Red Hat-based systems:
```
sudo yum install pv
```

## Usage

1. Clone this repository:
   ```
   git clone https://github.com/cantalupo555/stress-disk-benchmark.git
   ```

2. Navigate to the project directory:
   ```
   cd stress-disk-benchmark
   ```

3. Make the script executable:
   ```
   chmod +x stress-disk-benchmark.sh
   ```

4. Run the script:
   ```
   ./stress-disk-benchmark.sh
   ```

5. Follow the prompts to specify the total size and individual file size for the benchmark.

6. The script will perform write tests, and then ask if you want to proceed with read tests.

7. After the tests are complete, you'll have the option to remove the test files.

## Understanding the Results

The script uses `dd` to write and read files, and `pv` to show the progress and speed of these operations. The output will show you the speed of writing and reading in real-time.

Write speed is particularly important for understanding how quickly your system can save large files or datasets. Read speed is crucial for tasks that involve accessing large amounts of data from your disk.

By creating real files, this benchmark tool allows you to see how your disk performs under actual load conditions, which can be more representative of real-world usage compared to simulated tests.

## Caution

This script creates large files on your disk. Ensure you have enough free space before running the benchmark. Also, be aware that frequent writing of large files may impact SSD lifespan, although modern SSDs are generally designed to handle significant write operations.

## Contributing

Contributions, issues, and feature requests are welcome. Feel free to check [issues page](https://github.com/cantalupo555/stress-disk-benchmark/issues) if you want to contribute.

## License

[MIT](https://choosealicense.com/licenses/mit/)
