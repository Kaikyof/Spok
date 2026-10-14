# greeting Specification

## Purpose
Greeting the caller by name over HTTP.

## Requirements

### Requirement: Greeting endpoint
The system SHALL return a greeting for a name.

#### Scenario: Known name
- **WHEN** `GET /greet?name=Ann` is called
- **THEN** the response is `Hello, Ann`
