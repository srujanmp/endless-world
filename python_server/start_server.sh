#!/bin/bash
cd "$(dirname "$0")"

# Create a virtual environment if it doesn't exist
if [ ! -d "venv" ]; then
    python3 -m venv venv
fi

# Activate the virtual environment
source venv/bin/activate

# Install requirements
pip install -r requirements.txt

# Run the server
python3 main.py

# Wait for user input before closing
read -n 1 -s -r -p "Press any key to continue..."
echo
