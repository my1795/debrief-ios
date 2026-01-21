#!/bin/bash
#
# seed_emulator.sh
# Seeds Firebase Emulator with test data for UI testing
#
# Usage: ./seed_emulator.sh [SCENARIO]
# Example: ./seed_emulator.sh BASIC_USER
#
# Prerequisites:
#   - Firebase Emulator running (firebase emulators:start --only firestore,auth)
#   - curl and jq installed
#

set -e

FIRESTORE_HOST="${FIRESTORE_HOST:-localhost:8080}"
AUTH_HOST="${AUTH_HOST:-localhost:9099}"
PROJECT_ID="${PROJECT_ID:-debrief-dev}"

SCENARIO="${1:-BASIC_USER}"
USER_ID="${USER_ID:-test-user-123}"
USER_EMAIL="${USER_EMAIL:-test@example.com}"

echo "🧪 Seeding Firebase Emulator with scenario: $SCENARIO"
echo "   Firestore: $FIRESTORE_HOST"
echo "   Auth: $AUTH_HOST"
echo "   Project: $PROJECT_ID"
echo "   User: $USER_ID ($USER_EMAIL)"
echo ""

# Helper function to create Firestore document
create_document() {
    local collection=$1
    local doc_id=$2
    local data=$3

    curl -s -X PATCH \
        "http://$FIRESTORE_HOST/v1/projects/$PROJECT_ID/databases/(default)/documents/$collection/$doc_id" \
        -H "Content-Type: application/json" \
        -d "$data" > /dev/null

    echo "   ✅ Created $collection/$doc_id"
}

# Helper to generate timestamp (milliseconds)
now_ms() {
    echo $(($(date +%s) * 1000))
}

# Calculate billing week (Sunday to Sunday)
billing_week_start() {
    # Get last Sunday
    local day_of_week=$(date +%u)
    local days_since_sunday=$((day_of_week % 7))
    date -v-${days_since_sunday}d +%s | awk '{print $1 * 1000}'
}

billing_week_end() {
    # Get next Sunday
    local day_of_week=$(date +%u)
    local days_until_sunday=$((7 - day_of_week % 7))
    date -v+${days_until_sunday}d +%s | awk '{print $1 * 1000}'
}

# Clear existing data
echo "🗑️  Clearing existing data..."
curl -s -X DELETE "http://$FIRESTORE_HOST/emulator/v1/projects/$PROJECT_ID/databases/(default)/documents" > /dev/null 2>&1 || true

# Scenario configurations
case $SCENARIO in
    "EMPTY_USER")
        DEBRIEF_COUNT=0
        USED_MINUTES=0
        TIER="FREE"
        STORAGE_MB=0
        CONTACT_COUNT=0
        ;;
    "BASIC_USER")
        DEBRIEF_COUNT=8
        USED_MINUTES=15
        TIER="FREE"
        STORAGE_MB=125
        CONTACT_COUNT=25
        ;;
    "POWER_USER")
        DEBRIEF_COUNT=75
        USED_MINUTES=120
        TIER="PRO"
        STORAGE_MB=800
        CONTACT_COUNT=100
        ;;
    "NEAR_QUOTA_LIMIT")
        DEBRIEF_COUNT=45
        USED_MINUTES=27
        TIER="FREE"
        STORAGE_MB=450
        CONTACT_COUNT=25
        ;;
    "QUOTA_EXCEEDED")
        DEBRIEF_COUNT=51
        USED_MINUTES=35
        TIER="FREE"
        STORAGE_MB=510
        CONTACT_COUNT=25
        ;;
    "PRO_USER")
        DEBRIEF_COUNT=50
        USED_MINUTES=200
        TIER="PRO"
        STORAGE_MB=500
        CONTACT_COUNT=50
        ;;
    "PERSONAL_USER")
        DEBRIEF_COUNT=30
        USED_MINUTES=100
        TIER="PERSONAL"
        STORAGE_MB=300
        CONTACT_COUNT=40
        ;;
    *)
        DEBRIEF_COUNT=10
        USED_MINUTES=20
        TIER="FREE"
        STORAGE_MB=100
        CONTACT_COUNT=20
        ;;
esac

echo "📋 Scenario configuration:"
echo "   Debriefs: $DEBRIEF_COUNT"
echo "   Minutes: $USED_MINUTES"
echo "   Tier: $TIER"
echo "   Storage: ${STORAGE_MB}MB"
echo "   Contacts: $CONTACT_COUNT"
echo ""

# Create user document
echo "👤 Creating user..."
USER_DOC=$(cat <<EOF
{
    "fields": {
        "id": {"stringValue": "$USER_ID"},
        "email": {"stringValue": "$USER_EMAIL"},
        "createdAt": {"integerValue": "$(now_ms)"},
        "updatedAt": {"integerValue": "$(now_ms)"}
    }
}
EOF
)
create_document "users" "$USER_ID" "$USER_DOC"

# Create user_plans document
echo "📊 Creating user plan..."
BILLING_START=$(billing_week_start)
BILLING_END=$(billing_week_end)
USED_SECONDS=$((USED_MINUTES * 60))

USER_PLAN_DOC=$(cat <<EOF
{
    "fields": {
        "userId": {"stringValue": "$USER_ID"},
        "tier": {"stringValue": "$TIER"},
        "billingWeekStart": {"integerValue": "$BILLING_START"},
        "billingWeekEnd": {"integerValue": "$BILLING_END"},
        "weeklyUsage": {
            "mapValue": {
                "fields": {
                    "debriefCount": {"integerValue": "$DEBRIEF_COUNT"},
                    "totalSeconds": {"integerValue": "$USED_SECONDS"},
                    "actionItemsCount": {"integerValue": "$((DEBRIEF_COUNT * 2))"},
                    "uniqueContactIds": {
                        "arrayValue": {
                            "values": [
                                {"stringValue": "contact-1"},
                                {"stringValue": "contact-2"},
                                {"stringValue": "contact-3"}
                            ]
                        }
                    }
                }
            }
        },
        "usedStorageMB": {"integerValue": "$STORAGE_MB"},
        "subscriptionEnd": {"nullValue": null},
        "createdAt": {"integerValue": "$(now_ms)"},
        "updatedAt": {"integerValue": "$(now_ms)"}
    }
}
EOF
)
create_document "user_plans" "$USER_ID" "$USER_PLAN_DOC"

# Create sample debriefs
echo "📝 Creating debriefs..."
for i in $(seq 1 $((DEBRIEF_COUNT > 10 ? 10 : DEBRIEF_COUNT))); do
    DAYS_AGO=$((i - 1))
    CREATED_AT=$(date -v-${DAYS_AGO}d +%s | awk '{print $1 * 1000}')
    DEBRIEF_ID="debrief-$i"
    CONTACT_ID="contact-$((i % 5 + 1))"
    DURATION=$((120 + RANDOM % 300))

    STATE="COMPLETE"
    if [ $i -eq 1 ] && [ "$SCENARIO" = "PROCESSING_DEBRIEF" ]; then
        STATE="PROCESSING"
    fi
    if [ $i -eq 1 ] && [ "$SCENARIO" = "FAILED_DEBRIEF" ]; then
        STATE="FAILED"
    fi

    DEBRIEF_DOC=$(cat <<EOF
{
    "fields": {
        "id": {"stringValue": "$DEBRIEF_ID"},
        "userId": {"stringValue": "$USER_ID"},
        "contactId": {"stringValue": "$CONTACT_ID"},
        "contactName": {"stringValue": "Test Contact $CONTACT_ID"},
        "state": {"stringValue": "$STATE"},
        "duration": {"integerValue": "$DURATION"},
        "summary": {"stringValue": "This is a test summary for debrief $i. We discussed important topics including project updates and next steps."},
        "transcript": {"stringValue": "This is the transcript for debrief $i. Speaker 1: Hello. Speaker 2: Hi there. Speaker 1: Let's discuss the project."},
        "actionItems": {
            "arrayValue": {
                "values": [
                    {"stringValue": "Follow up on project deliverables"},
                    {"stringValue": "Schedule next meeting"}
                ]
            }
        },
        "audioUrl": {"stringValue": "gs://debrief-dev/audio/$DEBRIEF_ID.m4a"},
        "createdAt": {"integerValue": "$CREATED_AT"},
        "updatedAt": {"integerValue": "$CREATED_AT"}
    }
}
EOF
)
    create_document "debriefs" "$DEBRIEF_ID" "$DEBRIEF_DOC"
done

# Create sample contacts
echo "👥 Creating contacts..."
CONTACT_NAMES=("John Doe" "Jane Smith" "Bob Wilson" "Alice Brown" "Charlie Davis" "Eva Martinez" "Frank Johnson" "Grace Lee" "Henry Taylor" "Ivy Chen")

for i in $(seq 1 $((CONTACT_COUNT > 10 ? 10 : CONTACT_COUNT))); do
    CONTACT_ID="contact-$i"
    NAME="${CONTACT_NAMES[$((i % 10))]}"
    COMPANY="Company $i"

    CONTACT_DOC=$(cat <<EOF
{
    "fields": {
        "id": {"stringValue": "$CONTACT_ID"},
        "userId": {"stringValue": "$USER_ID"},
        "name": {"stringValue": "$NAME"},
        "handle": {"stringValue": "@${NAME// /.}"},
        "company": {"stringValue": "$COMPANY"},
        "createdAt": {"integerValue": "$(now_ms)"},
        "updatedAt": {"integerValue": "$(now_ms)"}
    }
}
EOF
)
    create_document "contacts" "$CONTACT_ID" "$CONTACT_DOC"
done

echo ""
echo "✅ Firebase Emulator seeded successfully!"
echo ""
echo "Next steps:"
echo "  1. Ensure Firebase Emulator is running:"
echo "     firebase emulators:start --only firestore,auth"
echo ""
echo "  2. Run UI tests with emulator:"
echo "     xcodebuild test -scheme debriefUITests -destination 'platform=iOS Simulator,name=iPhone 15'"
echo ""
