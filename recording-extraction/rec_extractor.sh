#!/bin/bash

# --- Configuration ---
SOURCE_DIR="/var/spool/asterisk/monitorDONE/MP3"
TARGET_BASE_DIR="./extracted_recordings"
INPUT_FILE="numbers.txt"

# Create base directory if it doesn't exist
mkdir -p "$TARGET_BASE_DIR"

if [[ ! -f "$INPUT_FILE" ]]; then
    echo "Error: $INPUT_FILE not found!"
    exit 1
fi

echo "Bulk recording search script made by Debjit"
echo "Starting high-speed file system search..."

# Loop through each number in the text file
while IFS= read -r phone || [[ -n "$phone" ]]; do
    # Clean the input (remove spaces/hidden characters)
    phone=$(echo "$phone" | xargs)
    
    if [[ -z "$phone" ]]; then continue; fi

    echo "Searching for recordings for: $phone"
    
    # Create the destination folder
    DEST_FOLDER="$TARGET_BASE_DIR/$phone"
    mkdir -p "$DEST_FOLDER"

    # Search the directory for any file containing the phone number in the name
    # We use -maxdepth 1 to keep it fast and avoid subdirectories
    find "$SOURCE_DIR" -maxdepth 1 -type f -name "*$phone*" -exec cp -v {} "$DEST_FOLDER/" \;

    # Count how many were found
    COUNT=$(ls -1 "$DEST_FOLDER" | wc -l)
    if [ "$COUNT" -eq 0 ]; then
        echo "  --> No files found for $phone"
        rmdir "$DEST_FOLDER" # Optional: remove empty folder
    else
        echo "  --> Success: Found $COUNT recordings."
    fi

done < "$INPUT_FILE"

echo "------------------------------------------"
echo "Done! Check the '$TARGET_BASE_DIR' folder."
