# Requirements Document

## Introduction

VacciMap is an infectious disease hazard map and child vaccination management application designed to support parents in making informed health decisions for their children. The system combines real-time infectious disease outbreak monitoring with personalized vaccination schedule management, leveraging AI-powered data retrieval and risk assessment. The application targets a 5-day development timeline for the TerraCode Convergence hackathon.

## Glossary

- **VacciMap_System**: The complete application including frontend, backend, and infrastructure components
- **Hazard_Map**: Interactive geographic visualization displaying infectious disease risk levels by region
- **Disease_Data_Service**: Backend service that retrieves and caches infectious disease outbreak information
- **Claude_API**: Anthropic's Claude AI service with web_search capability for real-time data retrieval
- **Outbreak_Cache**: DynamoDB table storing disease outbreak data with 6-hour TTL
- **Vaccine_Schedule_Cache**: DynamoDB table storing vaccination schedules with 30-day TTL
- **Child_Profile**: User-created record containing child information and vaccination history
- **Location_Key**: Hierarchical identifier format "country#prefecture#ward" (e.g., "japan#tokyo#nerima")
- **Risk_Level**: Categorical disease severity: Low (green), Moderate (yellow), High (red), Critical (dark red)
- **Authentication_Service**: Amazon Cognito-based user authentication and authorization system
- **AI_Chat_Service**: Claude API-powered conversational interface for health guidance
- **API_Gateway**: Amazon API Gateway with API key protection for backend endpoints
- **Parent_User**: Authenticated user who manages child profiles and vaccination records
- **Public_User**: Unauthenticated user accessing the hazard map
- **Citation_URL**: Source reference URL from Claude web_search results
- **Clinic_Cache**: DynamoDB table storing nearby clinic information with 7-day TTL

## Requirements

### Requirement 1: Infectious Disease Hazard Map Display

**User Story:** As a parent or public user, I want to view an interactive map showing infectious disease risk levels by region, so that I can assess health risks in my area.

#### Acceptance Criteria

1. THE Hazard_Map SHALL display geographic regions using Leaflet and OpenStreetMap tiles
2. THE Hazard_Map SHALL color-code regions based on Risk_Level: green for Low, yellow for Moderate, red for High, dark red for Critical
3. THE Hazard_Map SHALL support Japan (Tokyo, Osaka prefectures) and US states as geographic regions
4. WHEN a Public_User clicks a region, THE Hazard_Map SHALL display a side panel with area information and disease data
5. THE Hazard_Map SHALL render within 3 seconds on a 4G network connection
6. THE Hazard_Map SHALL display disease types: influenza, COVID-19, RSV, norovirus, mycoplasma, pertussis, measles
7. FOR ALL displayed outbreak data, THE Hazard_Map SHALL include Citation_URLs from the data source

### Requirement 2: Address and Postal Code Search

**User Story:** As a user, I want to search for locations by address or postal code, so that I can quickly find disease risk information for specific areas.

#### Acceptance Criteria

1. THE Hazard_Map SHALL provide a search input field accepting address or postal code text
2. WHEN a user submits a search query, THE Hazard_Map SHALL center the map on the matching location within 2 seconds
3. WHEN a search query matches multiple locations, THE Hazard_Map SHALL display a selection list
4. WHEN a search query matches no locations, THE Hazard_Map SHALL display an error message
5. THE Hazard_Map SHALL support Japanese addresses and postal codes (〒123-4567 format)
6. THE Hazard_Map SHALL support US addresses and ZIP codes (12345 or 12345-6789 format)

### Requirement 3: Real-Time Disease Data Retrieval

**User Story:** As a system administrator, I want disease data retrieved from current web sources, so that users receive accurate and timely outbreak information.

#### Acceptance Criteria

1. WHEN outbreak data is requested for a Location_Key, THE Disease_Data_Service SHALL query Claude_API with web_search_20250305 tool
2. THE Disease_Data_Service SHALL use Claude model claude-sonnet-4-20250514 for all web_search requests
3. WHEN Claude_API returns disease data, THE Disease_Data_Service SHALL store it in Outbreak_Cache with 6-hour TTL (21,600 seconds)
4. WHEN cached data exists and TTL has not expired, THE Disease_Data_Service SHALL return cached data within 200 milliseconds
5. WHEN Claude_API request fails, THE Disease_Data_Service SHALL return the most recent cached data if available
6. THE Disease_Data_Service SHALL include Citation_URLs from Claude web_search results in all responses
7. THE Disease_Data_Service SHALL set request timeout to 30 seconds for Claude_API calls
8. THE Disease_Data_Service SHALL retrieve data for the 3-tier location hierarchy: Country, Prefecture/State, Ward/City

### Requirement 4: Outbreak Data Storage

**User Story:** As a system, I want to cache disease outbreak data efficiently, so that I minimize API costs and improve response times.

#### Acceptance Criteria

1. THE Outbreak_Cache SHALL use Location_Key as partition key and diseaseType as sort key
2. THE Outbreak_Cache SHALL store attributes: caseCount, weeklyChange, reportDate, severity, citationUrls, ttl
3. THE Outbreak_Cache SHALL automatically delete records when ttl timestamp is reached
4. WHEN storing outbreak data, THE Disease_Data_Service SHALL set ttl to current timestamp plus 21,600 seconds
5. THE Outbreak_Cache SHALL support query operations by Location_Key returning all disease types for that location

### Requirement 5: User Registration and Authentication

**User Story:** As a parent, I want to create an account with email verification, so that I can securely manage my children's health information.

#### Acceptance Criteria

1. WHEN a user submits registration with email and password, THE Authentication_Service SHALL create a Cognito user account
2. THE Authentication_Service SHALL require passwords with minimum 12 characters including uppercase, lowercase, and numbers
3. WHEN a user account is created, THE Authentication_Service SHALL send a verification email to the provided address
4. WHEN a user submits valid credentials, THE Authentication_Service SHALL return a JWT token valid for 60 minutes
5. THE Authentication_Service SHALL support password reset via email verification code
6. WHEN a JWT token expires, THE Authentication_Service SHALL require re-authentication
7. THE Authentication_Service SHALL store user identifier as Cognito sub attribute

### Requirement 6: Child Profile Management

**User Story:** As a parent, I want to create and manage profiles for my children, so that I can track their vaccination schedules and health information.

#### Acceptance Criteria

1. WHEN a Parent_User creates a child profile, THE VacciMap_System SHALL generate a unique childId using UUID format
2. THE VacciMap_System SHALL store child profile attributes: parentId, name, birthDate, gender, country, region, city, vaccinationRecords
3. WHEN a Parent_User requests child profiles, THE VacciMap_System SHALL return only profiles where parentId matches the JWT sub claim
4. WHEN a Parent_User updates a child profile, THE VacciMap_System SHALL verify parentId matches JWT sub claim before allowing modification
5. WHEN a Parent_User deletes a child profile, THE VacciMap_System SHALL verify parentId matches JWT sub claim before deletion
6. THE VacciMap_System SHALL support multiple child profiles per Parent_User
7. THE VacciMap_System SHALL validate birthDate is not in the future

### Requirement 7: Vaccination Schedule Generation

**User Story:** As a parent, I want an automatically generated vaccination schedule for my child based on their location and birthdate, so that I know which vaccines are recommended and when.

#### Acceptance Criteria

1. WHEN a child profile is created, THE VacciMap_System SHALL query Claude_API with web_search to retrieve vaccination schedule for the child's Location_Key
2. THE VacciMap_System SHALL store vaccination schedules in Vaccine_Schedule_Cache with 30-day TTL (2,592,000 seconds)
3. THE Vaccine_Schedule_Cache SHALL store attributes: vaccineName, recommendedAgeMonths, doses, mandatory, subsidyAvailable, guidelines, citationUrls, ttl
4. THE VacciMap_System SHALL calculate vaccination due dates based on child birthDate and recommendedAgeMonths
5. THE VacciMap_System SHALL categorize vaccinations as: completed, upcoming, overdue, or scheduled
6. WHEN a vaccination is overdue by more than 30 days, THE VacciMap_System SHALL mark it with overdue status
7. THE VacciMap_System SHALL include Citation_URLs from vaccination schedule sources

### Requirement 8: Vaccination Record Tracking

**User Story:** As a parent, I want to record when my child receives vaccinations, so that I can maintain an accurate immunization history.

#### Acceptance Criteria

1. WHEN a Parent_User marks a vaccination as completed, THE VacciMap_System SHALL store completionDate in vaccinationRecords array
2. THE VacciMap_System SHALL update vaccination status from upcoming or overdue to completed when completionDate is set
3. WHEN a Parent_User schedules a vaccination, THE VacciMap_System SHALL store scheduledDate in vaccinationRecords array
4. THE VacciMap_System SHALL validate completionDate is not in the future
5. THE VacciMap_System SHALL allow Parent_User to add notes to vaccination records with maximum 500 characters

### Requirement 9: AI-Powered Health Chat

**User Story:** As a parent, I want to ask health-related questions and receive AI-powered guidance based on my child's profile and current outbreak data, so that I can make informed decisions.

#### Acceptance Criteria

1. WHEN a Parent_User sends a chat message, THE AI_Chat_Service SHALL stream responses using Claude_API
2. THE AI_Chat_Service SHALL include child profile data and current outbreak data for the child's Location_Key as context
3. THE AI_Chat_Service SHALL display disclaimer: "This is not a substitute for professional medical advice"
4. THE AI_Chat_Service SHALL maintain conversation history within the user session
5. THE AI_Chat_Service SHALL support Japanese and English languages based on user preference
6. WHEN Claude_API streaming fails, THE AI_Chat_Service SHALL display an error message and retain previous conversation history
7. THE AI_Chat_Service SHALL verify JWT token before processing chat requests

### Requirement 10: Multi-Language Support

**User Story:** As a user, I want the interface in my preferred language, so that I can understand the information clearly.

#### Acceptance Criteria

1. WHEN the application loads, THE VacciMap_System SHALL detect language from navigator.language browser property
2. THE VacciMap_System SHALL support Japanese (ja) and English (en) interface languages
3. THE VacciMap_System SHALL provide a manual language toggle in the application header
4. WHEN language is Japanese, THE VacciMap_System SHALL format dates as YYYY年MM月DD日
5. WHEN language is English, THE VacciMap_System SHALL format dates as MMM DD, YYYY
6. THE VacciMap_System SHALL translate all UI text, labels, and messages to the selected language
7. THE VacciMap_System SHALL persist language preference in browser localStorage

### Requirement 11: API Gateway Protection

**User Story:** As a system administrator, I want API endpoints protected from unauthorized access, so that I can prevent abuse and control costs.

#### Acceptance Criteria

1. THE API_Gateway SHALL require an API key for all public endpoints: /outbreak, /risk, /clinics
2. THE API_Gateway SHALL require valid JWT token for all private endpoints: /children, /vaccines, /chat
3. WHEN a request lacks required API key, THE API_Gateway SHALL return HTTP 403 Forbidden status
4. WHEN a request has invalid JWT token, THE API_Gateway SHALL return HTTP 401 Unauthorized status
5. THE API_Gateway SHALL validate JWT token signature matches Cognito user pool configuration
6. THE API_Gateway SHALL extract Cognito sub claim from JWT token and pass to backend services

### Requirement 12: Nearby Clinic Information

**User Story:** As a parent, I want to find nearby clinics that provide vaccinations, so that I can schedule appointments for my child.

#### Acceptance Criteria

1. WHEN a user requests clinics for a Location_Key, THE VacciMap_System SHALL query Claude_API with web_search to retrieve clinic information
2. THE VacciMap_System SHALL store clinic data in Clinic_Cache with 7-day TTL (604,800 seconds)
3. THE Clinic_Cache SHALL store attributes: clinicName, address, phone, hours, latitude, longitude, services, citationUrls, ttl
4. THE VacciMap_System SHALL display clinics on the Hazard_Map with distinct markers
5. WHEN a user clicks a clinic marker, THE VacciMap_System SHALL display clinic details in a popup
6. THE VacciMap_System SHALL include Citation_URLs from clinic data sources

### Requirement 13: Performance Requirements

**User Story:** As a user, I want the application to load and respond quickly, so that I can access information without delays.

#### Acceptance Criteria

1. THE VacciMap_System SHALL load the home page within 2 seconds on a 4G network connection
2. THE Hazard_Map SHALL render within 3 seconds after page load
3. WHEN outbreak data is cached, THE Disease_Data_Service SHALL respond within 200 milliseconds
4. THE VacciMap_System SHALL display a loading indicator when operations exceed 500 milliseconds
5. THE AI_Chat_Service SHALL begin streaming response within 2 seconds of message submission

### Requirement 14: Security Requirements

**User Story:** As a system administrator, I want user data protected and access controlled, so that privacy and security are maintained.

#### Acceptance Criteria

1. THE VacciMap_System SHALL serve all content over HTTPS protocol
2. THE VacciMap_System SHALL store Claude API key in Lambda environment variables, not in code
3. WHEN accessing child profiles, THE VacciMap_System SHALL verify parentId matches JWT sub claim
4. THE VacciMap_System SHALL not log or expose JWT tokens, API keys, or sensitive user data
5. THE VacciMap_System SHALL sanitize all user input before storage or display
6. THE VacciMap_System SHALL implement CORS policy allowing only the Amplify frontend domain

### Requirement 15: Cost Optimization

**User Story:** As a system administrator, I want to minimize operational costs, so that the application remains financially sustainable.

#### Acceptance Criteria

1. THE VacciMap_System SHALL use AWS free tier services for all AWS components
2. THE Disease_Data_Service SHALL cache outbreak data for 6 hours to minimize Claude_API calls
3. THE VacciMap_System SHALL cache vaccination schedules for 30 days to minimize Claude_API calls
4. THE VacciMap_System SHALL cache clinic data for 7 days to minimize Claude_API calls
5. WHEN Claude_API requests fail, THE VacciMap_System SHALL use cached data instead of retrying immediately
6. THE VacciMap_System SHALL target total Claude_API costs below $5 for the 5-day development period

### Requirement 16: Reliability and Error Handling

**User Story:** As a user, I want the application to handle errors gracefully, so that I can continue using available features when problems occur.

#### Acceptance Criteria

1. WHEN Claude_API is unavailable, THE Disease_Data_Service SHALL return the most recent cached data
2. WHEN no cached data exists and Claude_API fails, THE VacciMap_System SHALL display an error message with retry option
3. THE VacciMap_System SHALL display an offline indicator when network connectivity is lost
4. WHEN Lambda function execution fails, THE API_Gateway SHALL return HTTP 500 status with generic error message
5. THE VacciMap_System SHALL log detailed error information server-side without exposing to users
6. WHEN DynamoDB operations fail, THE VacciMap_System SHALL retry up to 3 times with exponential backoff

### Requirement 17: Infrastructure Deployment

**User Story:** As a developer, I want infrastructure defined as code, so that I can deploy and manage the application consistently.

#### Acceptance Criteria

1. THE VacciMap_System SHALL define all AWS infrastructure using Terraform 1.14
2. THE VacciMap_System SHALL deploy Lambda functions using ECR container images
3. THE VacciMap_System SHALL deploy frontend using AWS Amplify
4. THE VacciMap_System SHALL configure DynamoDB tables with TTL enabled for ttl attribute
5. THE VacciMap_System SHALL configure Cognito user pool with email verification required
6. THE VacciMap_System SHALL store Terraform state in the environments/production/ directory
7. THE VacciMap_System SHALL use mise for managing tool versions

### Requirement 18: User Interface Design

**User Story:** As a user, I want a visually appealing and easy-to-use interface, so that I can navigate the application efficiently.

#### Acceptance Criteria

1. THE VacciMap_System SHALL use dark theme with base color #0a0e1a
2. THE VacciMap_System SHALL use DM Mono font for code and data, and Noto Sans JP font for Japanese text
3. THE Hazard_Map SHALL display a side panel with area information, disease cards, and news items
4. THE VacciMap_System SHALL provide high information density without cluttering the interface
5. THE VacciMap_System SHALL be responsive and usable on desktop and mobile devices with minimum width 320px
6. THE VacciMap_System SHALL use consistent spacing, colors, and typography throughout the interface

### Requirement 19: Data Model Compliance

**User Story:** As a developer, I want clear data models for all DynamoDB tables, so that I can implement consistent data access patterns.

#### Acceptance Criteria

1. THE Outbreak_Cache SHALL use partition key locationKey (String) and sort key diseaseType (String)
2. THE Vaccine_Schedule_Cache SHALL use partition key locationKey (String) and sort key vaccineId (String)
3. THE Child_Profile table SHALL use partition key childId (String)
4. THE Clinic_Cache SHALL use partition key locationKey (String) and sort key clinicId (String)
5. THE VacciMap_System SHALL format Location_Key as "country#prefecture#ward" with lowercase values
6. THE VacciMap_System SHALL generate childId and clinicId using UUID v4 format

### Requirement 20: API Endpoint Specification

**User Story:** As a frontend developer, I want well-defined API endpoints, so that I can integrate the frontend with backend services.

#### Acceptance Criteria

1. THE API_Gateway SHALL expose GET /outbreak/{locationKey} endpoint returning outbreak data (public, API key required)
2. THE API_Gateway SHALL expose GET /risk/{locationKey} endpoint returning AI risk assessment (public, API key required)
3. THE API_Gateway SHALL expose GET /children endpoint returning child profiles (private, JWT required)
4. THE API_Gateway SHALL expose POST /children endpoint creating child profile (private, JWT required)
5. THE API_Gateway SHALL expose PUT /children/{childId} endpoint updating child profile (private, JWT required)
6. THE API_Gateway SHALL expose DELETE /children/{childId} endpoint deleting child profile (private, JWT required)
7. THE API_Gateway SHALL expose GET /vaccines/{locationKey} endpoint returning vaccination schedule (private, JWT required)
8. THE API_Gateway SHALL expose POST /chat endpoint for AI chat streaming (private, JWT required)
9. THE API_Gateway SHALL expose GET /clinics/{locationKey} endpoint returning nearby clinics (public, API key required)
10. THE API_Gateway SHALL return JSON responses with appropriate HTTP status codes
