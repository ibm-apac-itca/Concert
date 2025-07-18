#!/bin/bash

source vars.sh

# Configuration - Set these variables before running
INSTANCE_ID="${INSTANCE_ID:-your_instance_id}"
API_KEY="${API_KEY:-your_api_key}"
CONCERT_URL="${CONCERT_URL:-https://your-concert-url}"
TOOLKIT_DATA_DIR="${HOME}/toolkit-data"

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

# Function to run grype scan
run_grype_scan() {
    local image="$1"
    local component_name="$2"
    local output_file="$3"
    
    echo "Running grype scan for: $image"
    echo "Output file: $output_file"
    
    # Run grype scan
    grype "$image" --scope all-layers -o cyclonedx-json > "$output_file"
    
    local scan_exit_code=$?
    if [ $scan_exit_code -ne 0 ]; then
        echo "ERROR: Grype scan failed for $image with exit code $scan_exit_code"
        return 1
    fi
    
    # Check if output file was created and is not empty
    if [ ! -f "$output_file" ] || [ ! -s "$output_file" ]; then
        echo "ERROR: Output file is missing or empty: $output_file"
        return 1
    fi
    
    echo "Grype scan completed successfully for: $image"
    echo "Output saved to: $output_file"
    return 0
}

# Function to upload scan results
upload_scan_results() {
    local component_name="$1"
    local image="$2"
    local scan_file="$3"
    
    echo "Uploading scan results: $scan_file"
    
    # Upload the scan file
    local response=$(curl -k --silent --write-out "HTTPSTATUS:%{http_code}" \
        -X "POST" \
        -H "accept: application/json" \
        -H "InstanceID: ${INSTANCE_ID}" \
        -H "Authorization: C_API_KEY ${API_KEY}" \
        -H "Content-Type: multipart/form-data" \
        -F "data_type=package_sbom" \
        -F "filename=@${scan_file}" \
        "${CONCERT_URL}/ingestion/api/v1/upload_files")
    
    # Extract HTTP status code
    local http_code=$(echo "$response" | tr -d '\n' | sed -e 's/.*HTTPSTATUS://')
    local body=$(echo "$response" | sed -e 's/HTTPSTATUS:.*//g')
    
    if [[ "$http_code" -eq 200 ]] || [[ "$http_code" -eq 201 ]]; then
        echo "✓ Successfully uploaded: $component_name"
        if [[ -n "$body" ]]; then
            echo "  Response: $body"
        fi
        return 0
    else
        echo "✗ Failed to upload: $component_name"
        echo "  HTTP Status: $http_code"
        if [[ -n "$body" ]]; then
            echo "  Response: $body"
        fi
        return 1
    fi
}

# Function to cleanup old scan files (optional)
cleanup_old_files() {
    local keep_files="$1"
    
    if [[ "$keep_files" != "true" ]]; then
        echo "Cleaning up scan files..."
        rm -f "${TOOLKIT_DATA_DIR}"/rs-*-grype.json
        echo "Cleanup completed"
    else
        echo "Keeping scan files in: $TOOLKIT_DATA_DIR"
    fi
}

# Function to check prerequisites
check_prerequisites() {
    # Check if grype is installed
    if ! command -v grype &> /dev/null; then
        echo "ERROR: grype is not installed or not in PATH"
        echo "Please install grype first: https://github.com/anchore/grype#installation"
        return 1
    fi
    
    # Check if curl is installed
    if ! command -v curl &> /dev/null; then
        echo "ERROR: curl is not installed or not in PATH"
        return 1
    fi
    
    # Check grype version
    local grype_version=$(grype version 2>/dev/null | grep "^grype" | awk '{print $2}')
    echo "Using grype version: $grype_version"
    
    return 0
}

# Main execution
main() {
    echo "RobotShop Grype Scanner and Upload Script"
    echo "========================================"
    echo ""
    
    # Check prerequisites
    if ! check_prerequisites; then
        exit 1
    fi
    
    # Check required environment variables
    if [ -z "$INSTANCE_ID" ] || [ "$INSTANCE_ID" = "your_instance_id" ]; then
        echo "ERROR: INSTANCE_ID environment variable is not set"
        echo "Please set: export INSTANCE_ID='your_actual_instance_id'"
        exit 1
    fi
    
    if [ -z "$API_KEY" ] || [ "$API_KEY" = "your_api_key" ]; then
        echo "ERROR: API_KEY environment variable is not set"
        echo "Please set: export API_KEY='your_actual_api_key'"
        exit 1
    fi
    
    if [ -z "$CONCERT_URL" ] || [ "$CONCERT_URL" = "https://your-concert-url" ]; then
        echo "ERROR: CONCERT_URL environment variable is not set"
        echo "Please set: export CONCERT_URL='https://your-concert-url'"
        exit 1
    fi
    
    # Create toolkit data directory if it doesn't exist
    mkdir -p "$TOOLKIT_DATA_DIR"
    
    echo "Configuration:"
    echo "  Concert URL: $CONCERT_URL"
    echo "  Instance ID: $INSTANCE_ID"
    echo "  Output Directory: $TOOLKIT_DATA_DIR"
    echo "  Total images to scan: ${#IMAGES[@]}"
    echo ""
    
    # Ask if user wants to keep scan files
    read -p "Keep scan files after upload? (y/n): " keep_files_input
    local keep_files="false"
    if [[ "$keep_files_input" =~ ^[Yy]$ ]]; then
        keep_files="true"
    fi
    
    echo ""
    echo "Starting grype scanning and upload process..."
    echo "-------------------------------------------"
    
    local success_count=0
    local failure_count=0
    
    # Process each image
    for image in "${IMAGES[@]}"; do
        local component_name=$(get_component_name "$image")
        local output_file="${TOOLKIT_DATA_DIR}/${component_name}-grype.json"
        
        echo ""
        echo "Processing: $image ($component_name)"
        echo "-------------------------------------------"
        
        # Run grype scan
        if run_grype_scan "$image" "$component_name" "$output_file"; then
            # Upload results if scan was successful
            if upload_scan_results "$component_name" "$image" "$output_file"; then
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
        
        echo "-------------------------------------------"
        
        # Small delay to avoid overwhelming the API
        sleep 2
    done
    
    echo ""
    echo "Processing complete!"
    echo "==================="
    echo "Successful: $success_count"
    echo "Failed: $failure_count"
    echo "Total: ${#IMAGES[@]}"
    echo ""
    
    # Cleanup if requested
    cleanup_old_files "$keep_files"
    
    if [ $failure_count -gt 0 ]; then
        echo "Some operations failed. Please check the error messages above."
        exit 1
    else
        echo "All images scanned and uploaded successfully!"
    fi
}

# Handle script interruption
trap 'echo ""; echo "Script interrupted. Cleaning up..."; cleanup_old_files "false"; exit 1' INT

# Run main function
main "$@"