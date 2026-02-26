# Implementation Plan: VacciMap Full-Stack Application

## Overview

This implementation plan breaks down the VacciMap application into discrete coding tasks organized by development phase. The application is a full-stack infectious disease hazard map with child vaccination management, built for a 5-day hackathon timeline. The implementation uses Python 3.14 for Lambda functions, TypeScript/React for the frontend, and Terraform 1.14 for infrastructure.

## Development Timeline

- Day 1: Infrastructure setup and tool configuration
- Day 1-2: Backend Lambda functions with DynamoDB caching
- Day 2-3: Frontend React application with map visualization
- Day 3-4: Authentication and user profile features
- Day 4: AI chat and internationalization
- Day 5: Testing, bug fixes, and demo preparation

## Tasks

### Phase 1: Infrastructure Setup (Day 1)

- [x] 1. Set up project structure and tool version management
  - Create project directory structure (terraform/, lambda/, frontend/)
  - Create .tool-versions file with mise configuration (terraform 1.14.0, python 3.14.0, nodejs 24.0.0)
  - Install mise and verify tool versions
  - Create .gitignore for sensitive files (terraform.tfvars, .env, node_modules)
  - _Requirements: 17.1, 17.7_

- [ ] 2. Create Terraform module structure
  - [ ] 2.1 Create base Terraform directory structure
    - Create terraform/modules/ directories for api-gateway, lambda, dynamodb, cognito, amplify
    - Create terraform/environments/production/ directory
    - Create backend.tf for state management
    - _Requirements: 17.1_
  
  - [ ] 2.2 Implement DynamoDB Terraform modules
    - Create dynamodb module with variables for table_name, hash_key, range_key, ttl configuration
    - Configure OutbreakCache table (locationKey + diseaseType keys, ttl enabled)
    - Configure VaccineScheduleCache table (locationKey + vaccineId keys, ttl enabled)
    - Configure ChildProfiles table (childId key, parentId GSI)
    - Configure ClinicCache table (locationKey + clinicId keys, ttl enabled)
    - Set billing_mode to PAY_PER_REQUEST for free tier optimization
    - _Requirements: 17.4, 19.1, 19.2, 19.3, 19.4, 4.1, 4.2_
  
  - [ ] 2.3 Implement Cognito Terraform module
    - Create cognito module with password policy configuration (min 12 chars, uppercase, lowercase, numbers)
    - Configure email verification as auto_verified_attributes
    - Set token validity (access_token: 60 min, id_token: 60 min, refresh_token: 30 days)
    - Configure MFA as optional
    - _Requirements: 17.5, 5.2, 5.4_
  
  - [ ] 2.4 Implement Secrets Manager for Claude API key
    - Create aws_secretsmanager_secret resource for Claude API key
    - Create IAM policy for Lambda functions to access secret
    - Document manual step to set secret value via AWS Console or CLI
    - _Requirements: 14.2_

- [ ] 3. Create ECR repositories for Lambda containers
  - Create ECR repositories for outbreak-service, vaccine-service, child-service, chat-service, clinic-service
  - Configure repository policies for Lambda access
  - Document Docker build and push commands
  - _Requirements: 17.2_


- [ ] 4. Deploy initial infrastructure with Terraform
  - Run terraform init in environments/production/
  - Create terraform.tfvars with required variables (gitignored)
  - Run terraform plan and review changes
  - Run terraform apply to provision DynamoDB tables, Cognito, ECR repositories
  - Verify resources created in AWS Console
  - _Requirements: 17.1, 17.6_

- [ ] 5. Checkpoint - Infrastructure validation
  - Ensure all tests pass, ask the user if questions arise.

### Phase 2: Backend Lambda Functions (Day 1-2)

- [ ] 6. Implement Outbreak Service Lambda function
  - [ ] 6.1 Create Python Lambda function structure
    - Create lambda/outbreak-service/ directory with src/, tests/, Dockerfile, requirements.txt
    - Add dependencies: boto3, anthropic, pytest, hypothesis
    - Create handler.py with lambda_handler function signature
    - Configure environment variables: DYNAMODB_TABLE_OUTBREAK, CLAUDE_API_KEY_SECRET, LOG_LEVEL
    - _Requirements: 3.1, 3.2, 17.2_
  
  - [ ] 6.2 Implement DynamoDB cache query logic
    - Implement query_outbreak_cache(location_key) function to query DynamoDB by locationKey
    - Check TTL validity (ttl > current_timestamp)
    - Return cached data if valid, None if expired or missing
    - _Requirements: 3.4, 4.5_
  
  - [ ] 6.3 Implement Claude API integration with web_search
    - Implement call_claude_api(location_key) function using anthropic SDK
    - Configure model: claude-sonnet-4-20250514, tool: web_search_20250305
    - Set timeout to 30 seconds
    - Parse response to extract disease data and citation URLs
    - _Requirements: 3.1, 3.2, 3.6, 3.7_
  
  - [ ] 6.4 Implement cache storage with TTL
    - Implement store_outbreak_cache(location_key, disease_data) function
    - Calculate ttl = current_timestamp + 21600 (6 hours)
    - Store each disease as separate item with locationKey + diseaseType composite key
    - Include caseCount, weeklyChange, reportDate, severity, citationUrls attributes
    - _Requirements: 3.3, 4.2, 4.4_
  
  - [ ] 6.5 Implement error handling and fallback logic
    - Add try-except for Claude API timeout (return cached data ignoring TTL)
    - Add try-except for DynamoDB errors (retry 3x with exponential backoff)
    - Return HTTP 500 with generic error message if all retries fail
    - Log detailed errors server-side without exposing sensitive data
    - _Requirements: 3.5, 16.1, 16.4, 16.5, 16.6_
  
  - [ ]* 6.6 Write property test for cache TTL configuration
    - **Property 6: Cache TTL Configuration**
    - **Validates: Requirements 3.3, 4.4, 15.2**
    - Use Hypothesis to generate random timestamps
    - Verify TTL is set to current_time + 21600 for outbreak data
  
  - [ ]* 6.7 Write property test for cache hit performance
    - **Property 7: Cache Hit Performance**
    - **Validates: Requirements 3.4**
    - Use Hypothesis to generate cached data with valid TTL
    - Verify Claude API is not called when cache is valid
  
  - [ ]* 6.8 Write property test for Claude API fallback
    - **Property 8: Claude API Fallback**
    - **Validates: Requirements 3.5, 15.5, 16.1**
    - Simulate Claude API failures
    - Verify most recent cached data is returned regardless of TTL


- [ ] 7. Implement Vaccine Service Lambda function
  - [ ] 7.1 Create Python Lambda function structure
    - Create lambda/vaccine-service/ directory with src/, tests/, Dockerfile, requirements.txt
    - Create handler.py with lambda_handler function signature
    - Configure environment variables: DYNAMODB_TABLE_VACCINE, CLAUDE_API_KEY_SECRET, LOG_LEVEL
    - _Requirements: 7.1, 17.2_
  
  - [ ] 7.2 Implement vaccination schedule retrieval with Claude API
    - Implement get_vaccination_schedule(location_key) function using Claude API web_search
    - Parse response to extract vaccine information (name, recommendedAgeMonths, doses, mandatory, subsidy, guidelines)
    - Generate UUID v4 for each vaccineId
    - Extract citation URLs from web_search results
    - _Requirements: 7.1, 7.3, 7.7_
  
  - [ ] 7.3 Implement vaccine schedule caching with 30-day TTL
    - Implement store_vaccine_cache(location_key, vaccines) function
    - Calculate ttl = current_timestamp + 2592000 (30 days)
    - Store each vaccine as separate item with locationKey + vaccineId composite key
    - _Requirements: 7.2, 15.3_
  
  - [ ] 7.4 Implement JWT validation and parentId extraction
    - Parse JWT token from Authorization header
    - Extract sub claim as parentId
    - Return 401 if token is invalid or missing
    - _Requirements: 11.2, 11.5, 11.6_
  
  - [ ]* 7.5 Write property test for vaccination schedule retrieval
    - **Property 18: Vaccination Schedule Retrieval**
    - **Validates: Requirements 7.1**
    - Use Hypothesis to generate location keys
    - Verify Claude API is called for schedule retrieval
  
  - [ ]* 7.6 Write unit tests for vaccine service
    - Test valid JWT returns vaccination schedule
    - Test invalid JWT returns 401
    - Test cache hit returns cached data

- [ ] 8. Implement Child Profile Service Lambda function
  - [ ] 8.1 Create Python Lambda function structure
    - Create lambda/child-service/ directory with src/, tests/, Dockerfile, requirements.txt
    - Create handler.py with route handling for GET, POST, PUT, DELETE operations
    - Configure environment variables: DYNAMODB_TABLE_CHILD, LOG_LEVEL
    - _Requirements: 6.1, 17.2_
  
  - [ ] 8.2 Implement child profile CRUD operations
    - Implement list_children(parent_id) to query by parentId GSI
    - Implement create_child(parent_id, profile_data) with UUID v4 generation for childId
    - Implement update_child(parent_id, child_id, profile_data) with ownership verification
    - Implement delete_child(parent_id, child_id) with ownership verification
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_
  
  - [ ] 8.3 Implement input validation
    - Validate birthDate is not in future
    - Validate name is required and max 100 characters
    - Validate gender is optional enum (male|female|other)
    - Validate location fields (country, prefecture, city) are required
    - _Requirements: 6.7_
  
  - [ ] 8.4 Implement vaccination due date calculation
    - Implement calculate_due_date(birth_date, recommended_age_months) function
    - Implement categorize_vaccination_status(due_date, completion_date, scheduled_date) function
    - Return status: completed, upcoming, overdue (>30 days past due), or scheduled
    - _Requirements: 7.4, 7.5, 7.6_
  
  - [ ]* 8.5 Write property test for child ID generation
    - **Property 15: Child ID Generation**
    - **Validates: Requirements 6.1, 19.6**
    - Use Hypothesis to generate profile data
    - Verify childId is valid UUID v4 format
  
  - [ ]* 8.6 Write property test for ownership verification
    - **Property 16: Child Profile Ownership**
    - **Validates: Requirements 6.3, 6.4, 6.5, 14.3**
    - Use Hypothesis to generate parentId and childId combinations
    - Verify operations fail when parentId doesn't match JWT sub claim
  
  - [ ]* 8.7 Write property test for future date validation
    - **Property 17: Future Date Validation**
    - **Validates: Requirements 6.7, 8.4**
    - Use Hypothesis to generate dates including future dates
    - Verify future dates are rejected


- [ ] 9. Implement AI Chat Service Lambda function
  - [ ] 9.1 Create Python Lambda function structure
    - Create lambda/chat-service/ directory with src/, tests/, Dockerfile, requirements.txt
    - Create handler.py with streaming response support
    - Configure environment variables: DYNAMODB_TABLE_CHILD, DYNAMODB_TABLE_OUTBREAK, CLAUDE_API_KEY_SECRET, LOG_LEVEL
    - _Requirements: 9.1, 17.2_
  
  - [ ] 9.2 Implement context injection for AI chat
    - Implement fetch_child_context(child_id) to retrieve child profile from DynamoDB
    - Implement fetch_outbreak_context(location_key) to retrieve outbreak data from cache
    - Build system prompt with child age, location, vaccination status, and current outbreaks
    - Include medical disclaimer in system prompt
    - _Requirements: 9.2, 9.3_
  
  - [ ] 9.3 Implement Claude API streaming
    - Implement stream_chat_response(message, conversation_history, context) function
    - Use Claude API with streaming enabled
    - Return Server-Sent Events (SSE) format for streaming
    - Handle streaming errors without clearing conversation history
    - _Requirements: 9.1, 9.4, 9.6_
  
  - [ ] 9.4 Implement language-aware responses
    - Detect language from user message or preference
    - Include language preference in Claude API request
    - Support Japanese and English responses
    - _Requirements: 9.5_
  
  - [ ]* 9.5 Write property test for context injection
    - **Property 25: AI Chat Context Injection**
    - **Validates: Requirements 9.2**
    - Use Hypothesis to generate child profiles and outbreak data
    - Verify context is included in Claude API request
  
  - [ ]* 9.6 Write property test for conversation history maintenance
    - **Property 27: Conversation History Maintenance**
    - **Validates: Requirements 9.4, 9.6**
    - Simulate streaming failures
    - Verify conversation history is retained

- [ ] 10. Implement Clinic Service Lambda function
  - [ ] 10.1 Create Python Lambda function structure
    - Create lambda/clinic-service/ directory with src/, tests/, Dockerfile, requirements.txt
    - Create handler.py with lambda_handler function signature
    - Configure environment variables: DYNAMODB_TABLE_CLINIC, CLAUDE_API_KEY_SECRET, LOG_LEVEL
    - _Requirements: 12.1, 17.2_
  
  - [ ] 10.2 Implement clinic data retrieval with Claude API
    - Implement get_clinics(location_key) function using Claude API web_search
    - Parse response to extract clinic information (name, address, phone, hours, coordinates, services)
    - Generate UUID v4 for each clinicId
    - Extract citation URLs from web_search results
    - _Requirements: 12.1, 12.3, 12.6_
  
  - [ ] 10.3 Implement clinic caching with 7-day TTL
    - Implement store_clinic_cache(location_key, clinics) function
    - Calculate ttl = current_timestamp + 604800 (7 days)
    - Store each clinic as separate item with locationKey + clinicId composite key
    - _Requirements: 12.2, 15.4_
  
  - [ ]* 10.4 Write property test for clinic data retrieval
    - **Property 36: Clinic Data Retrieval**
    - **Validates: Requirements 12.1**
    - Use Hypothesis to generate location keys
    - Verify Claude API is called with web_search

- [ ] 11. Build and deploy Lambda Docker containers
  - Create Dockerfiles for all 5 Lambda services (outbreak, vaccine, child, chat, clinic)
  - Build Docker images locally
  - Tag images for ECR repositories
  - Push images to ECR
  - Update Lambda functions with new image URIs
  - _Requirements: 17.2_

- [ ] 12. Checkpoint - Backend services validation
  - Ensure all tests pass, ask the user if questions arise.


### Phase 3: API Gateway Configuration (Day 2)

- [ ] 13. Implement API Gateway Terraform module
  - [ ] 13.1 Create API Gateway REST API resource
    - Create api-gateway module with main.tf, variables.tf, outputs.tf
    - Define aws_api_gateway_rest_api resource
    - Configure CORS with allowed origins (Amplify domain)
    - _Requirements: 14.6, 20.10_
  
  - [ ] 13.2 Configure public endpoints with API key authorization
    - Create resources and methods for GET /outbreak/{locationKey}
    - Create resources and methods for GET /risk/{locationKey}
    - Create resources and methods for GET /clinics/{locationKey}
    - Configure API key requirement for all public endpoints
    - Create aws_api_gateway_api_key and usage plan with throttling (10 req/s burst, 5 req/s steady)
    - _Requirements: 11.1, 11.3, 20.1, 20.2, 20.9_
  
  - [ ] 13.3 Configure private endpoints with JWT authorization
    - Create Cognito authorizer resource
    - Create resources and methods for GET /children, POST /children, PUT /children/{childId}, DELETE /children/{childId}
    - Create resources and methods for GET /vaccines/{locationKey}
    - Create resources and methods for POST /chat
    - Configure JWT validation for all private endpoints
    - _Requirements: 11.2, 11.4, 11.5, 20.3, 20.4, 20.5, 20.6, 20.7, 20.8_
  
  - [ ] 13.4 Configure Lambda integrations
    - Create aws_api_gateway_integration resources for all 5 Lambda functions
    - Configure request/response mappings
    - Set up Lambda permissions for API Gateway invocation
    - _Requirements: 20.10_
  
  - [ ] 13.5 Deploy API Gateway stage
    - Create aws_api_gateway_deployment resource
    - Create production stage with logging enabled
    - Output API Gateway URL for frontend configuration
    - _Requirements: 20.10_
  
  - [ ]* 13.6 Write property test for API key requirement
    - **Property 33: API Key Requirement for Public Endpoints**
    - **Validates: Requirements 11.1, 11.3**
    - Test requests without API key return 403
  
  - [ ]* 13.7 Write property test for JWT requirement
    - **Property 34: JWT Requirement for Private Endpoints**
    - **Validates: Requirements 11.2, 11.4**
    - Test requests without JWT return 401

- [ ] 14. Deploy API Gateway with Terraform
  - Update terraform/environments/production/main.tf to include api-gateway module
  - Run terraform plan and review API Gateway configuration
  - Run terraform apply to create API Gateway resources
  - Test public endpoints with API key using curl or Postman
  - Test private endpoints with mock JWT token
  - _Requirements: 17.1_

- [ ] 15. Checkpoint - API Gateway validation
  - Ensure all tests pass, ask the user if questions arise.

### Phase 4: Frontend React Application (Day 2-3)

- [ ] 16. Set up React project with Vite and TypeScript
  - [ ] 16.1 Initialize React project
    - Create frontend/ directory
    - Run npm create vite@latest with React + TypeScript template
    - Install dependencies: react, react-dom, leaflet, react-leaflet, i18next, react-i18next
    - Install dev dependencies: vitest, @testing-library/react, fast-check, typescript
    - Configure vite.config.ts with environment variable support
    - _Requirements: 17.3_
  
  - [ ] 16.2 Create project structure
    - Create src/components/, src/services/, src/hooks/, src/types/, src/i18n/ directories
    - Create src/types/models.ts with TypeScript interfaces (Location, DiseaseOutbreak, ChildProfile, etc.)
    - Create src/services/api.ts with API client configuration
    - _Requirements: 18.1, 18.2, 18.3_
  
  - [ ] 16.3 Configure environment variables
    - Create .env.example with VITE_API_GATEWAY_URL, VITE_COGNITO_USER_POOL_ID, VITE_COGNITO_CLIENT_ID, VITE_API_KEY
    - Add .env to .gitignore
    - Document environment variable setup in README
    - _Requirements: 14.2_


- [ ] 17. Implement Map Component with Leaflet
  - [ ] 17.1 Create MapComponent with OpenStreetMap integration
    - Create src/components/MapComponent.tsx
    - Initialize Leaflet map with OpenStreetMap tiles
    - Set initial center and zoom level
    - Configure map bounds for Japan and US regions
    - _Requirements: 1.1, 1.3_
  
  - [ ] 17.2 Implement region coloring based on risk levels
    - Create GeoJSON layers for Japan prefectures and US states
    - Implement color mapping function: green (Low), yellow (Moderate), red (High), dark red (Critical)
    - Apply colors to regions based on outbreak data
    - _Requirements: 1.2_
  
  - [ ] 17.3 Implement region click handlers
    - Add click event listeners to region polygons
    - Fetch outbreak data for clicked region's locationKey
    - Update side panel state with region data
    - _Requirements: 1.4_
  
  - [ ] 17.4 Implement search functionality
    - Create SearchBar component with input field
    - Implement geocoding for address and postal code search
    - Support Japanese postal codes (〒123-4567) and US ZIP codes
    - Center map on search results
    - Handle multiple results with selection list
    - Display error message for no results
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6_
  
  - [ ] 17.5 Implement clinic markers
    - Fetch clinic data for visible regions
    - Display clinic markers on map with distinct icon
    - Create popup component for clinic details (name, address, phone, hours)
    - _Requirements: 12.4, 12.5_
  
  - [ ]* 17.6 Write property test for risk level color mapping
    - **Property 1: Risk Level Color Mapping**
    - **Validates: Requirements 1.2**
    - Use fast-check to generate risk levels
    - Verify correct color is applied for each risk level
  
  - [ ]* 17.7 Write property test for region click interaction
    - **Property 2: Region Click Interaction**
    - **Validates: Requirements 1.4**
    - Use fast-check to generate region data
    - Verify side panel is displayed on click
  
  - [ ]* 17.8 Write property test for search query centering
    - **Property 4: Search Query Centering**
    - **Validates: Requirements 2.2**
    - Use fast-check to generate valid addresses
    - Verify map centers on search results

- [ ] 18. Implement Side Panel Component
  - [ ] 18.1 Create SidePanel component structure
    - Create src/components/SidePanel.tsx
    - Display area information (name, population)
    - Create DiseaseCard sub-component for each disease type
    - Display 7 disease types: influenza, COVID-19, RSV, norovirus, mycoplasma, pertussis, measles
    - _Requirements: 1.4, 1.6, 18.3_
  
  - [ ] 18.2 Display disease data with citations
    - Show case count, weekly change percentage, report date, severity for each disease
    - Display citation URLs as clickable links
    - Format dates according to selected language
    - _Requirements: 1.7, 3.6_
  
  - [ ] 18.3 Display nearby clinics list
    - Fetch and display clinics for selected region
    - Show clinic name, address, phone, hours
    - Add click handler to center map on clinic location
    - _Requirements: 12.4_
  
  - [ ]* 18.4 Write property test for citation URL inclusion
    - **Property 3: Citation URL Inclusion**
    - **Validates: Requirements 1.7, 3.6, 7.7, 12.6**
    - Use fast-check to generate outbreak/vaccine/clinic data
    - Verify citation URLs are included in display


- [ ] 19. Implement API service layer
  - [ ] 19.1 Create outbreak API service
    - Create src/services/outbreakService.ts
    - Implement getOutbreakData(locationKey) function with API key header
    - Handle network errors and display cached data with "Last updated" timestamp
    - Implement retry logic for failed requests
    - _Requirements: 3.4, 16.1, 16.2_
  
  - [ ] 19.2 Create vaccine API service
    - Create src/services/vaccineService.ts
    - Implement getVaccinationSchedule(locationKey) function with JWT header
    - Handle 401 errors by redirecting to login
    - _Requirements: 7.1, 11.2_
  
  - [ ] 19.3 Create child profile API service
    - Create src/services/childService.ts
    - Implement listChildren(), createChild(data), updateChild(id, data), deleteChild(id) functions
    - Include JWT token in Authorization header for all requests
    - Handle ownership verification errors (403)
    - _Requirements: 6.3, 6.4, 6.5, 11.2_
  
  - [ ] 19.4 Create clinic API service
    - Create src/services/clinicService.ts
    - Implement getClinics(locationKey) function with API key header
    - _Requirements: 12.1_
  
  - [ ]* 19.5 Write unit tests for API services
    - Test network error handling
    - Test 401/403 error handling
    - Test retry logic

- [ ] 20. Implement loading indicators and error handling
  - Create LoadingSpinner component
  - Display loading indicator for operations > 500ms
  - Create ErrorMessage component for user-friendly error display
  - Implement offline indicator for network connectivity loss
  - _Requirements: 13.4, 16.3_

- [ ] 21. Checkpoint - Frontend map and data display validation
  - Ensure all tests pass, ask the user if questions arise.

### Phase 5: Authentication and User Features (Day 3-4)

- [ ] 22. Implement Authentication Components
  - [ ] 22.1 Create registration component
    - Create src/components/auth/RegisterForm.tsx
    - Implement form with email and password fields
    - Add password validation (min 12 chars, uppercase, lowercase, numbers)
    - Integrate with Cognito SDK for user registration
    - Display email verification message after registration
    - _Requirements: 5.1, 5.2, 5.3_
  
  - [ ] 22.2 Create login component
    - Create src/components/auth/LoginForm.tsx
    - Implement form with email and password fields
    - Integrate with Cognito SDK for authentication
    - Store JWT token in memory (not localStorage)
    - Set token expiration timer (60 minutes)
    - _Requirements: 5.4, 5.6, 14.2_
  
  - [ ] 22.3 Create password reset component
    - Create src/components/auth/PasswordResetForm.tsx
    - Implement email verification code flow
    - Integrate with Cognito SDK for password reset
    - _Requirements: 5.5_
  
  - [ ] 22.4 Implement JWT token management
    - Create src/hooks/useAuth.ts custom hook
    - Store JWT token in React state (memory only)
    - Implement token refresh logic before expiration
    - Clear token and redirect to login on expiration
    - Extract sub claim as userId
    - _Requirements: 5.4, 5.6, 5.7, 14.2_
  
  - [ ]* 22.5 Write property test for password validation
    - **Property 12: Password Validation**
    - **Validates: Requirements 5.2**
    - Use fast-check to generate passwords
    - Verify passwords < 12 chars or missing requirements are rejected
  
  - [ ]* 22.6 Write property test for JWT token expiration
    - **Property 13: JWT Token Expiration**
    - **Validates: Requirements 5.4, 5.6**
    - Simulate token expiration
    - Verify re-authentication is required


- [ ] 23. Implement Child Profile Manager
  - [ ] 23.1 Create child profile list component
    - Create src/components/profiles/ChildProfileList.tsx
    - Fetch and display all child profiles for authenticated user
    - Show name, birthdate, location for each profile
    - Add buttons for edit and delete actions
    - _Requirements: 6.3, 6.6_
  
  - [ ] 23.2 Create child profile form component
    - Create src/components/profiles/ChildProfileForm.tsx
    - Implement form fields: name, birthDate, gender, country, prefecture, city
    - Add validation for required fields and birthDate (not in future)
    - Support both create and edit modes
    - _Requirements: 6.1, 6.2, 6.7_
  
  - [ ] 23.3 Implement profile creation flow
    - Call createChild API on form submission
    - Trigger vaccination schedule generation for child's location
    - Display success message and redirect to profile detail
    - _Requirements: 6.1, 7.1_
  
  - [ ] 23.4 Implement profile update and delete
    - Call updateChild API with ownership verification
    - Call deleteChild API with confirmation dialog
    - Handle 403 errors for ownership violations
    - _Requirements: 6.4, 6.5_
  
  - [ ]* 23.5 Write property test for future date validation
    - **Property 17: Future Date Validation**
    - **Validates: Requirements 6.7, 8.4**
    - Use fast-check to generate dates including future dates
    - Verify future dates are rejected in form validation

- [ ] 24. Implement Vaccination Tracker
  - [ ] 24.1 Create vaccination timeline component
    - Create src/components/vaccinations/VaccinationTimeline.tsx
    - Display vaccinations grouped by status: completed, upcoming, overdue, scheduled
    - Show vaccine name, due date, completion date, scheduled date
    - Highlight overdue vaccinations (>30 days past due) in red
    - _Requirements: 7.5, 7.6, 8.1_
  
  - [ ] 24.2 Implement vaccination completion recording
    - Create modal/form for marking vaccination as completed
    - Add date picker for completion date (validate not in future)
    - Update vaccination status to completed
    - _Requirements: 8.1, 8.2, 8.4_
  
  - [ ] 24.3 Implement vaccination scheduling
    - Create modal/form for scheduling future vaccination
    - Add date picker for scheduled date
    - Update vaccination status to scheduled
    - _Requirements: 8.3_
  
  - [ ] 24.4 Implement vaccination notes
    - Add notes field to vaccination records (max 500 characters)
    - Display notes in timeline view
    - _Requirements: 8.5_
  
  - [ ]* 24.5 Write property test for vaccination due date calculation
    - **Property 19: Vaccination Due Date Calculation**
    - **Validates: Requirements 7.4**
    - Use fast-check to generate birth dates and recommended age months
    - Verify due date = birthDate + recommendedAgeMonths
  
  - [ ]* 24.6 Write property test for vaccination status categorization
    - **Property 20: Vaccination Status Categorization**
    - **Validates: Requirements 7.5, 7.6**
    - Use fast-check to generate vaccination records with various dates
    - Verify correct status is assigned based on dates
  
  - [ ]* 24.7 Write property test for vaccination notes length validation
    - **Property 23: Vaccination Notes Length Validation**
    - **Validates: Requirements 8.5**
    - Use fast-check to generate notes of various lengths
    - Verify notes > 500 chars are rejected

- [ ] 25. Checkpoint - Authentication and profiles validation
  - Ensure all tests pass, ask the user if questions arise.


### Phase 6: AI Chat and Internationalization (Day 4)

- [ ] 26. Implement AI Chat Interface
  - [ ] 26.1 Create chat component structure
    - Create src/components/chat/ChatInterface.tsx
    - Implement message list display with user and assistant messages
    - Create message input field with send button
    - Display medical disclaimer prominently
    - _Requirements: 9.1, 9.3_
  
  - [ ] 26.2 Implement streaming response display
    - Create src/services/chatService.ts with streaming support
    - Use Server-Sent Events (SSE) or fetch with ReadableStream
    - Display assistant response as it streams in
    - Show typing indicator while waiting for first token
    - _Requirements: 9.1, 13.5_
  
  - [ ] 26.3 Implement conversation history management
    - Store conversation history in React state
    - Include history in chat API requests
    - Persist history within session (clear on page refresh)
    - Retain history even when streaming fails
    - _Requirements: 9.4, 9.6_
  
  - [ ] 26.4 Implement child profile selection for context
    - Add dropdown to select child profile for chat context
    - Fetch child profile and outbreak data when profile is selected
    - Include context in chat API request
    - _Requirements: 9.2_
  
  - [ ]* 26.5 Write property test for AI chat streaming
    - **Property 24: AI Chat Streaming**
    - **Validates: Requirements 9.1**
    - Simulate streaming responses
    - Verify responses are displayed incrementally
  
  - [ ]* 26.6 Write property test for medical disclaimer display
    - **Property 26: Medical Disclaimer Display**
    - **Validates: Requirements 9.3**
    - Verify disclaimer is always visible in chat interface

- [ ] 27. Implement Internationalization (i18n)
  - [ ] 27.1 Set up i18next configuration
    - Create src/i18n/config.ts with i18next initialization
    - Create translation files: src/i18n/locales/ja.json and src/i18n/locales/en.json
    - Configure language detection from navigator.language
    - Set fallback language to English
    - _Requirements: 10.1, 10.2_
  
  - [ ] 27.2 Create translation keys for all UI text
    - Translate all labels, buttons, messages, error messages
    - Translate disease type names
    - Translate vaccination status labels
    - Ensure completeness for both Japanese and English
    - _Requirements: 10.6_
  
  - [ ] 27.3 Implement language toggle
    - Create LanguageToggle component in header
    - Switch between Japanese and English on click
    - Persist language preference in localStorage
    - _Requirements: 10.3, 10.7_
  
  - [ ] 27.4 Implement date formatting by language
    - Create src/utils/dateFormatter.ts
    - Format dates as YYYY年MM月DD日 for Japanese
    - Format dates as MMM DD, YYYY for English
    - Apply formatting to all displayed dates
    - _Requirements: 10.4, 10.5_
  
  - [ ]* 27.5 Write property test for language detection
    - **Property 29: Language Detection**
    - **Validates: Requirements 10.1**
    - Mock navigator.language with various values
    - Verify correct language is detected
  
  - [ ]* 27.6 Write property test for date formatting by language
    - **Property 30: Date Formatting by Language**
    - **Validates: Requirements 10.4, 10.5**
    - Use fast-check to generate dates
    - Verify correct format for each language
  
  - [ ]* 27.7 Write property test for UI translation completeness
    - **Property 31: UI Translation Completeness**
    - **Validates: Requirements 10.6**
    - Verify all translation keys exist in both ja.json and en.json
  
  - [ ]* 27.8 Write property test for language preference persistence
    - **Property 32: Language Preference Persistence**
    - **Validates: Requirements 10.7**
    - Simulate language selection
    - Verify preference is stored in localStorage

- [ ] 28. Checkpoint - AI chat and i18n validation
  - Ensure all tests pass, ask the user if questions arise.


### Phase 7: UI Styling and Responsive Design (Day 4)

- [ ] 29. Implement application styling
  - [ ] 29.1 Create global styles and theme
    - Create src/styles/theme.ts with color palette (base: #0a0e1a, accent colors)
    - Configure dark theme throughout application
    - Set up font imports: DM Mono for code/data, Noto Sans JP for Japanese text
    - Create src/styles/global.css with base styles
    - _Requirements: 18.1, 18.2_
  
  - [ ] 29.2 Style map and side panel layout
    - Create responsive layout with map on left, side panel on right
    - Implement high information density design
    - Add consistent spacing and typography
    - Style disease cards with severity color indicators
    - _Requirements: 18.3, 18.4, 18.6_
  
  - [ ] 29.3 Implement responsive design
    - Add media queries for mobile devices (min-width: 320px)
    - Stack map and side panel vertically on mobile
    - Adjust font sizes and spacing for smaller screens
    - Test on various viewport sizes
    - _Requirements: 18.5_
  
  - [ ]* 29.4 Write property test for responsive design support
    - **Property 44: Responsive Design Support**
    - **Validates: Requirements 18.5**
    - Use fast-check to generate viewport widths >= 320px
    - Verify interface renders without errors

- [ ] 30. Implement security measures in frontend
  - [ ] 30.1 Implement input sanitization
    - Create src/utils/sanitize.ts with XSS prevention functions
    - Sanitize all user input before display (child names, notes, search queries)
    - Use DOMPurify or similar library for HTML sanitization
    - _Requirements: 14.5_
  
  - [ ] 30.2 Implement secure token storage
    - Store JWT token in React state (memory only), not localStorage
    - Clear token on logout or expiration
    - Verify token is not exposed in logs or error messages
    - _Requirements: 14.2, 14.4_
  
  - [ ] 30.3 Implement HTTPS enforcement
    - Configure Amplify to enforce HTTPS
    - Add security headers in Amplify configuration
    - _Requirements: 14.1_
  
  - [ ]* 30.4 Write property test for input sanitization
    - **Property 40: Input Sanitization**
    - **Validates: Requirements 14.5**
    - Use fast-check to generate inputs with XSS payloads
    - Verify inputs are sanitized before storage/display

### Phase 8: Amplify Deployment (Day 4)

- [ ] 31. Configure AWS Amplify for frontend deployment
  - [ ] 31.1 Create Amplify Terraform module
    - Create amplify module in terraform/modules/amplify/
    - Configure aws_amplify_app resource with GitHub repository
    - Set up build specification for Node.js 24 and Vite
    - Configure environment variables from Terraform outputs
    - _Requirements: 17.3_
  
  - [ ] 31.2 Configure Amplify build settings
    - Create amplify.yml build specification
    - Configure preBuild: npm ci
    - Configure build: npm run build
    - Set artifacts baseDirectory to dist/
    - Configure cache for node_modules
    - _Requirements: 17.3_
  
  - [ ] 31.3 Deploy Amplify app with Terraform
    - Update terraform/environments/production/main.tf to include amplify module
    - Pass API Gateway URL, Cognito IDs, and API key as environment variables
    - Run terraform apply to create Amplify app
    - Verify automatic deployment on push to main branch
    - _Requirements: 17.3_

- [ ] 32. Configure CORS and security headers
  - Update API Gateway CORS configuration to allow Amplify domain
  - Verify CORS headers in API responses
  - Test cross-origin requests from Amplify frontend
  - _Requirements: 14.6_

- [ ] 33. Checkpoint - Frontend deployment validation
  - Ensure all tests pass, ask the user if questions arise.


### Phase 9: Integration Testing and Bug Fixes (Day 5)

- [ ] 34. Implement integration tests
  - [ ] 34.1 Set up Playwright for E2E testing
    - Install Playwright and configure for TypeScript
    - Create tests/ directory with E2E test files
    - Configure test environment with mock data
    - _Requirements: 13.1, 13.2_
  
  - [ ] 34.2 Write E2E test for user registration and login
    - Test registration flow with email verification
    - Test login flow with JWT token storage
    - Test token expiration and re-authentication
    - _Requirements: 5.1, 5.3, 5.4, 5.6_
  
  - [ ] 34.3 Write E2E test for child profile management
    - Test profile creation with vaccination schedule generation
    - Test profile update with ownership verification
    - Test profile deletion with confirmation
    - _Requirements: 6.1, 6.3, 6.4, 6.5, 7.1_
  
  - [ ] 34.4 Write E2E test for map interaction
    - Test map rendering with OpenStreetMap tiles
    - Test region click and side panel display
    - Test search functionality with address/postal code
    - Test clinic marker display and popup
    - _Requirements: 1.1, 1.4, 2.2, 12.4, 12.5_
  
  - [ ] 34.5 Write E2E test for AI chat
    - Test chat message submission with streaming response
    - Test context injection with child profile selection
    - Test conversation history maintenance
    - Test error handling when streaming fails
    - _Requirements: 9.1, 9.2, 9.4, 9.6_

- [ ] 35. Performance testing and optimization
  - [ ] 35.1 Test page load performance
    - Measure home page load time on 4G network simulation
    - Verify load time < 2 seconds
    - Optimize bundle size if needed (code splitting, lazy loading)
    - _Requirements: 13.1_
  
  - [ ] 35.2 Test map rendering performance
    - Measure map render time after page load
    - Verify render time < 3 seconds
    - Optimize GeoJSON data if needed
    - _Requirements: 1.5, 13.2_
  
  - [ ] 35.3 Test API response times
    - Measure cached data response time
    - Verify cached responses < 200ms
    - Measure AI chat first token time
    - Verify first token < 2 seconds
    - _Requirements: 13.3, 13.5_

- [ ] 36. Security testing
  - [ ] 36.1 Run security audits
    - Run npm audit for frontend dependencies
    - Run pip-audit for backend dependencies
    - Fix critical and high severity vulnerabilities
    - _Requirements: 14.1_
  
  - [ ] 36.2 Test authentication and authorization
    - Verify API key is required for public endpoints
    - Verify JWT is required for private endpoints
    - Test ownership verification for child profiles
    - Verify sensitive data is not logged or exposed
    - _Requirements: 11.1, 11.2, 14.3, 14.4_
  
  - [ ] 36.3 Test input sanitization
    - Test XSS prevention in user inputs (child names, notes, search queries)
    - Verify SQL injection prevention (use parameterized queries)
    - Test CORS configuration
    - _Requirements: 14.5, 14.6_

- [ ] 37. Bug fixes and refinements
  - Review all test results and fix failing tests
  - Address any UI/UX issues discovered during testing
  - Fix any performance bottlenecks
  - Verify all requirements are met

- [ ] 38. Checkpoint - Final testing validation
  - Ensure all tests pass, ask the user if questions arise.


### Phase 10: Documentation and Demo Preparation (Day 5)

- [ ] 39. Create project documentation
  - [ ] 39.1 Write README.md
    - Project overview and features (max 200 lines)
    - Technology stack (Python 3.14, TypeScript, React, Terraform 1.14)
    - Prerequisites and tool installation (mise)
    - Setup instructions (environment variables, Terraform, Docker)
    - Deployment instructions (Terraform apply, Docker push, Amplify)
    - _Requirements: 17.1, 17.2, 17.3, 17.7_
  
  - [ ] 39.2 Write structure.md
    - Project directory structure
    - Description of each major directory and file
    - Explanation of Terraform modules
    - Explanation of Lambda functions
    - Explanation of frontend components
  
  - [ ] 39.3 Write tech.md
    - Detailed technical architecture
    - AWS services used and configuration
    - Claude API integration details
    - Caching strategy and TTL values
    - Security measures implemented
    - Cost optimization strategies
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6_
  
  - [ ] 39.4 Create API documentation
    - Document all API endpoints with request/response examples
    - Document authentication requirements
    - Document error codes and messages
    - _Requirements: 20.1, 20.2, 20.3, 20.4, 20.5, 20.6, 20.7, 20.8, 20.9, 20.10_

- [ ] 40. Prepare demo materials
  - [ ] 40.1 Create demo script
    - Outline key features to demonstrate
    - Prepare sample data (child profiles, locations)
    - Plan demo flow (map → profiles → chat)
    - Prepare talking points for each feature
  
  - [ ] 40.2 Record demo video
    - Record screen capture of application usage
    - Demonstrate map interaction and disease data
    - Demonstrate child profile creation and vaccination tracking
    - Demonstrate AI chat with context injection
    - Demonstrate language switching
    - Keep video under 5 minutes
  
  - [ ] 40.3 Create presentation slides
    - Problem statement and solution overview
    - Technology stack and architecture diagram
    - Key features and screenshots
    - Cost optimization and AWS free tier usage
    - Future enhancements and roadmap

- [ ] 41. Prepare Devpost submission
  - [ ] 41.1 Write Devpost description
    - Inspiration and problem statement
    - What it does (feature overview)
    - How we built it (technology stack)
    - Challenges we ran into
    - Accomplishments that we're proud of
    - What we learned
    - What's next for VacciMap
  
  - [ ] 41.2 Upload demo video and screenshots
    - Upload demo video to YouTube or Vimeo
    - Take screenshots of key features
    - Upload to Devpost submission
  
  - [ ] 41.3 Add GitHub repository link
    - Ensure repository is public
    - Add comprehensive README
    - Add LICENSE file
    - Link repository in Devpost submission

- [ ] 42. Final deployment and verification
  - Run final terraform apply to ensure all infrastructure is up-to-date
  - Verify all Lambda functions are deployed with latest code
  - Verify Amplify frontend is deployed and accessible
  - Test all features in production environment
  - Verify cost tracking shows usage within free tier
  - _Requirements: 15.6_

- [ ] 43. Final checkpoint - Project completion
  - Ensure all tests pass, ask the user if questions arise.


## Notes

- Tasks marked with `*` are optional and can be skipped for faster MVP delivery
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation throughout development
- Property tests validate universal correctness properties from the design document
- Unit tests validate specific examples and edge cases
- All Lambda functions use Python 3.14 in ECR containers
- Frontend uses TypeScript/React with Node.js 24 build tooling
- Infrastructure uses Terraform 1.14 with mise for tool version management
- Development follows a 5-day hackathon timeline with daily milestones
- Cost optimization is critical: aggressive caching minimizes Claude API usage
- Security is enforced at multiple layers: API Gateway (API key + JWT), input sanitization, HTTPS

## Implementation Guidelines

### Testing Strategy
- Run `make test` before each checkpoint
- Property tests use Hypothesis (Python) and fast-check (TypeScript) with minimum 100 iterations
- Each property test must reference its design document property number
- Coverage target: 60% overall, 80% for critical paths (authentication, caching, data retrieval)

### Development Workflow
When implementing these tasks:
1. Create GitHub issue for each major task or group of related tasks
2. Create feature branch: `feat/issue-{number}-{description}`
3. Implement task and write tests
4. Run `make test` to verify
5. Commit with reference: `feat: Description (Refs #{number})`
6. Create PR linking issue: `Closes #{number}`

### Error Handling
- All Lambda functions must implement retry logic for DynamoDB (3x exponential backoff)
- All Lambda functions must return cached data when Claude API fails
- Frontend must display user-friendly error messages and loading indicators
- Never expose sensitive data (JWT tokens, API keys) in logs or error messages

### Performance Targets
- Home page load: < 2 seconds (4G network)
- Map render: < 3 seconds
- Cached API response: < 200ms
- AI chat first token: < 2 seconds
- Operations > 500ms must show loading indicator

### Security Requirements
- Store JWT tokens in memory only (React state), never localStorage
- Sanitize all user inputs before storage or display
- Verify ownership (parentId) for all child profile operations
- Use HTTPS for all communications
- Store Claude API key in AWS Secrets Manager
- Implement CORS to allow only Amplify domain

### Cost Optimization
- Cache outbreak data: 6 hours (21,600 seconds)
- Cache vaccination schedules: 30 days (2,592,000 seconds)
- Cache clinic data: 7 days (604,800 seconds)
- Target total Claude API cost: < $5 for 5-day hackathon
- Use AWS free tier for all services (Lambda, DynamoDB, API Gateway, Cognito, Amplify)

