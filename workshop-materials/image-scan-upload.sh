#!/bin/bash

# Configuration - Set these variables before running
source vars.sh

TOOLKIT_DATA_DIR="${HOME}/toolkit-data"
ROBOT_SHOP_DIR="${HOME}/robot-shop"

# Array of robotshop images from crictl output
declare -a IMAGES=(
    "docker.io/robotshop/rs-cart:latest"
    "docker.io/robotshop/rs-catalogue:latest"
    "docker.io/robotshop/rs-dispatch:latest"
    "docker.io/robotshop/rs-load:latest"
    "docker.io/robotshop/rs-mongodb:latest"
    "docker.io/robotshop/rs-mysql-db:latest"
    "docker.io/robotshop/rs-payment:latest"
    "docker.io/robotshop/rs-ratings:latest"
    "docker.io/robotshop/rs-shipping:latest"
    "docker.io/robotshop/rs-user:latest"
    "docker.io/robotshop/rs-web:latest"
)

# Function to extract component name from image
get_component_name() {
    local image="$1"
    # Extract component name (e.g., rs-cart from docker.io/robotshop/rs-cart:latest)
    echo "$image" | sed 's|docker.io/robotshop/||' | sed 's|:.*||'
}

# Function to run image scan
run_image_scan() {
    local image="$1"
    local component_name="$2"
    
    echo "Running image scan for: $image"
    
    # Set environment variables for the scan
    export COMPONENT_IMAGE_NAME="${image%:*}"  # Remove tag
    export COMPONENT_IMAGE_TAG="${image##*:}"  # Get tag only
    
    # Run podman image scan
    podman run \
        -v "${ROBOT_SHOP_DIR}:/concert-sample-src" \
        -v "${TOOLKIT_DATA_DIR}:/toolkit-data" \
        icr.io/cpopen/ibm-concert-toolkit:latest \
        bash -c "image-scan --images ${COMPONENT_IMAGE_NAME}:${COMPONENT_IMAGE_TAG}"
    
    local scan_exit_code=$?
    if [ $scan_exit_code -ne 0 ]; then
        echo "ERROR: Image scan failed for $image with exit code $scan_exit_code"
        return 1
    fi
    
    echo "Image scan completed successfully for: $image"
    return 0
}

# Function to upload scan results
upload_scan_results() {
    local component_name="$1"
    local image="$2"
    
    # Look for the generated SBOM file
    # The filename pattern might vary, adjust as needed
    local sbom_file="${TOOLKIT_DATA_DIR}/${component_name}_sbom.json"
    
    # Alternative patterns to look for if the above doesn't work
    if [ ! -f "$sbom_file" ]; then
        # Try different naming patterns
        sbom_file=$(find "${TOOLKIT_DATA_DIR}" -name "*${component_name}*sbom*.json" | head -1)
        
        if [ ! -f "$sbom_file" ]; then
            sbom_file=$(find "${TOOLKIT_DATA_DIR}" -name "*sbom*.json" -newer "${TOOLKIT_DATA_DIR}" | head -1)
        fi
    fi
    
    if [ ! -f "$sbom_file" ]; then
        echo "ERROR: SBOM file not found for $component_name"
        echo "Looking in: $TOOLKIT_DATA_DIR"
        ls -la "$TOOLKIT_DATA_DIR"
        return 1
    fi
    
    echo "Uploading SBOM file: $sbom_file"
    
    # Upload the SBOM file
    curl -k -X "POST" \
        -H "accept: application/json" \
        -H "InstanceID: ${INSTANCE_ID}" \
        -H "Authorization: C_API_KEY ${API_KEY}" \
        -H "Content-Type: multipart/form-data" \
        -F "data_type=package_sbom" \
        -F "filename=@${sbom_file}" \
        "${CONCERT_URL}/ingestion/api/v1/upload_files"
    
    local upload_exit_code=$?
    if [ $upload_exit_code -ne 0 ]; then
        echo "ERROR: Upload failed for $component_name with exit code $upload_exit_code"
        return 1
    fi
    
    echo "Upload completed successfully for: $component_name"
    return 0
}

# Main execution
main() {
    echo "Starting robotshop image scanning and upload process..."
    echo "Total images to process: ${#IMAGES[@]}"
    echo "----------------------------------------"
    
    # Check required environment variables
    if [ -z "$INSTANCE_ID" ] || [ -z "$API_KEY" ] || [ -z "$CONCERT_URL" ]; then
        echo "ERROR: Required environment variables not set:"
        echo "  INSTANCE_ID: $INSTANCE_ID"
        echo "  API_KEY: $API_KEY"
        echo "  CONCERT_URL: $CONCERT_URL"
        echo "Please set these variables before running the script."
        exit 1
    fi
    
    # Create toolkit data directory if it doesn't exist
    mkdir -p "$TOOLKIT_DATA_DIR"
    
    local success_count=0
    local failure_count=0
    
    # Process each image
    for image in "${IMAGES[@]}"; do
        local component_name=$(get_component_name "$image")
        
        echo ""
        echo "Processing: $image ($component_name)"
        echo "----------------------------------------"
        
        # Run image scan
        if run_image_scan "$image" "$component_name"; then
            # Upload results if scan was successful
            if upload_scan_results "$component_name" "$image"; then
                ((success_count++))
                echo "✓ Successfully processed: $image"
            else
                ((failure_count++))
                echo "✗ Failed to upload: $image"
            fi
        else
            ((failure_count++))
            echo "✗ Failed to scan: $image"
        fi
        
        echo "----------------------------------------"
    done
    
    echo ""
    echo "Processing complete!"
    echo "Successful: $success_count"
    echo "Failed: $failure_count"
    echo "Total: ${#IMAGES[@]}"
    
    if [ $failure_count -gt 0 ]; then
        exit 1
    fi
}

# Run main function
main "$@"