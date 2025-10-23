#!/bin/bash
# Apple notarization functions

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh"

notarize_dmg() {
    local dmg_path="$1"
    local apple_id="$2"
    local team_id="$3"
    local app_password="$4"

    print_step "Notarizing with Apple"

    # Check credentials
    if [ -z "$apple_id" ] || [ -z "$team_id" ] || [ -z "$app_password" ]; then
        print_warning "Notarization credentials not set - skipping"
        return 1
    fi

    echo "Submitting for notarization..."
    echo "File: $dmg_path"

    # Submit for notarization
    local output=$(xcrun notarytool submit "$dmg_path" \
        --apple-id "$apple_id" \
        --team-id "$team_id" \
        --password "$app_password" \
        2>&1 | tee notarization-submit.log)

    # Extract submission ID
    local submission_id=$(echo "$output" | grep -o "id: [a-f0-9-]*" | head -1 | awk '{print $2}')

    if [ -z "$submission_id" ]; then
        print_error "Failed to get submission ID from notarization service"
    fi

    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "Submission ID: $submission_id"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Waiting for notarization (this can take 1-5 minutes)..."

    # Poll for status
    local max_wait=600  # 10 minutes
    local poll_interval=10
    local elapsed=0
    local status=""

    while [ $elapsed -lt $max_wait ]; do
        sleep $poll_interval
        elapsed=$((elapsed + poll_interval))

        local status_output=$(xcrun notarytool info "$submission_id" \
            --apple-id "$apple_id" \
            --team-id "$team_id" \
            --password "$app_password" 2>&1)

        if echo "$status_output" | grep -q "status:"; then
            status=$(echo "$status_output" | grep "status:" | awk '{print $2}')
            echo -n "."

            if [ "$status" = "Accepted" ]; then
                echo ""
                print_success "Notarization accepted!"
                break
            elif [ "$status" = "Invalid" ] || [ "$status" = "Rejected" ]; then
                echo ""
                print_error "Notarization failed with status: $status"
            fi
        fi
    done

    echo "$status_output" > notarization-status.log

    # Check for timeout
    if [ $elapsed -ge $max_wait ] && [ "$status" != "Accepted" ]; then
        echo ""
        print_warning "Notarization timed out after $max_wait seconds"
        echo "Submission ID: $submission_id"
        echo "Check status manually with: xcrun notarytool info $submission_id ..."
        print_error "Notarization did not complete in time"
    fi

    # Staple if accepted
    if [ "$status" = "Accepted" ]; then
        staple_notarization "$dmg_path"
        echo "$status"
        return 0
    else
        # Fetch failure log
        xcrun notarytool log "$submission_id" \
            --apple-id "$apple_id" \
            --team-id "$team_id" \
            --password "$app_password" \
            notarization-failure.json 2>/dev/null

        if [ -f "notarization-failure.json" ]; then
            echo ""
            echo "Failure details saved to: notarization-failure.json"

            if command -v jq &> /dev/null; then
                echo ""
                echo "Issues found:"
                jq -r '.issues[]? | "  • [\(.severity)] \(.message)"' notarization-failure.json 2>/dev/null || true
            fi
        fi

        exit 1
    fi
}

staple_notarization() {
    local dmg_path="$1"

    echo "Stapling notarization ticket to DMG..."

    if xcrun stapler staple "$dmg_path" 2>&1; then
        print_success "Notarization ticket stapled"

        if spctl -a -vv -t install "$dmg_path" 2>&1 | grep -q "source=Notarized Developer ID"; then
            print_success "DMG is properly notarized and stapled"
        else
            print_warning "DMG may not be properly stapled - verification failed"
        fi
    else
        print_warning "Stapling failed - users will need internet to verify"
    fi
}
