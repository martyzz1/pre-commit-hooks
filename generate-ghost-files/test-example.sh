#!/usr/bin/env bash

# Test script to demonstrate the generate-ghost-files hook
# This creates sample versioned files and shows how the hook processes them

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}Creating test directory structure...${NC}"

# Create test directory structure
mkdir -p test-project/src/libs/schemas/order-status-event
mkdir -p test-project/src/workers/order-status-event
mkdir -p test-project/src/libs/schemas/user-profile
mkdir -p test-project/src/workers/user-profile

cd test-project

# Initialize git repository
git init
git config user.name "Test User"
git config user.email "test@example.com"

echo -e "${GREEN}Creating sample versioned files...${NC}"

# Create sample schema files
cat > src/libs/schemas/order-status-event/order-status-event-1.0.0.json << 'EOF'
{
  "type": "object",
  "properties": {
    "orderId": {"type": "string"},
    "status": {"type": "string", "enum": ["pending", "processing"]},
    "timestamp": {"type": "string", "format": "date-time"}
  },
  "required": ["orderId", "status"]
}
EOF

cat > src/libs/schemas/order-status-event/order-status-event-1.0.1.json << 'EOF'
{
  "type": "object",
  "properties": {
    "orderId": {"type": "string"},
    "status": {"type": "string", "enum": ["pending", "processing", "completed"]},
    "timestamp": {"type": "string", "format": "date-time"},
    "metadata": {"type": "object"}
  },
  "required": ["orderId", "status"]
}
EOF

# Create sample handler files
cat > src/workers/order-status-event/order-status-event-1.0.0.ts << 'EOF'
export interface OrderStatusEvent {
  orderId: string;
  status: 'pending' | 'processing';
  timestamp: string;
}

export function processOrderStatus(event: OrderStatusEvent): void {
  console.log(`Processing order ${event.orderId} with status ${event.status}`);
}
EOF

cat > src/workers/order-status-event/order-status-event-1.0.1.ts << 'EOF'
export interface OrderStatusEvent {
  orderId: string;
  status: 'pending' | 'processing' | 'completed';
  timestamp: string;
  metadata?: Record<string, any>;
}

export function processOrderStatus(event: OrderStatusEvent): void {
  console.log(`Processing order ${event.orderId} with status ${event.status}`);
  if (event.metadata) {
    console.log('Additional metadata:', event.metadata);
  }
}
EOF

# Create sample user profile files
cat > src/libs/schemas/user-profile/user-profile-2.0.0.json << 'EOF'
{
  "type": "object",
  "properties": {
    "userId": {"type": "string"},
    "email": {"type": "string", "format": "email"},
    "name": {"type": "string"}
  },
  "required": ["userId", "email"]
}
EOF

cat > src/workers/user-profile/user-profile-2.0.0.ts << 'EOF'
export interface UserProfile {
  userId: string;
  email: string;
  name?: string;
}

export function processUserProfile(profile: UserProfile): void {
  console.log(`Processing user ${profile.userId}`);
}
EOF

echo -e "${GREEN}Initial commit...${NC}"
git add .
git commit -m "Initial commit with versioned files"

echo -e "${GREEN}Running the generate-ghost-files hook...${NC}"
echo -e "${BLUE}Note: This will create ghost files and stage them in git${NC}"

# Run the hook (assuming it's in the parent directory)
# First argument: ghost suffix, then directories to scan
../generate-ghost-files.sh ".ghost" "src/libs/schemas" "src/workers"

echo -e "${GREEN}Checking what files were created and staged...${NC}"
echo -e "${BLUE}Git status:${NC}"
git status

echo -e "${BLUE}Ghost files created:${NC}"
find . -name "*.ghost" -type f

echo -e "${BLUE}Content of order-status-event.ghost:${NC}"
cat src/libs/schemas/order-status-event/order-status-event.json.ghost

echo -e "${BLUE}Content of order-status-event.ts.ghost:${NC}"
cat src/workers/order-status-event/order-status-event.ts.ghost

echo -e "${GREEN}Test completed!${NC}"
echo -e "${BLUE}To clean up, run: cd .. && rm -rf test-project${NC}"

