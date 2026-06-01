# 04 - Temporal & Spatial Awareness

## Purpose

Temporal & Spatial Awareness define Nexus's ability to reason about time, location, and situational context.
These capabilities enable the assistant to offer timely, place-aware recommendations, reminders, and insights.

## Scope

- Event scheduling and temporal reasoning
- Time decay and memory relevancy
- Location-aware behavior and contextual triggers
- Calendar and timezone sensitivity
- Temporal summaries and contextual reminders
- Spatial classification and geo-fencing

## Core Capabilities

### Temporal Reasoning

Understand temporal expressions, deadlines, recurrences, and relative time references.
Nexus should interpret phrases like `next Monday`, `later today`, `after my meeting`, and `in two hours` accurately.

### Time Decay & Relevance

Adjust memory and recommendation relevance over time.
Older events and context should decay unless explicitly marked as evergreen or high-priority.

### Scheduling Awareness

Integrate with calendars, reminders, and timeline views.
Support availability checks, event suggestions, and follow-up reminders.

### Timezone Sensitivity

Handle user and contact time zones consistently.
Normalize and localize dates/times across workflows and communication.

### Spatial Context

Leverage location signals to adapt behavior and suggestions.
This includes recognizing places, travel context, and proximity-based triggers.

### Geo-fencing & Location Rules

Use location-aware rules for notifications, mode switching, and device-aware interactions.
Support conditions like `when I arrive at the office` or `if I am near the airport`.

## Feature Set

### Temporal Extraction

- Parse relative and absolute temporal expressions
- Extract schedule constraints from natural language
- Recognize temporal intent in user commands and messages

### Contextual Reminders

- Create reminders based on time, location, and event context
- Support natural language reminder creation and follow-up
- Trigger reminders with respect to user availability and priority

### Event Summaries

- Summarize past and upcoming events for a time window
- Provide daily, weekly, and monthly overviews
- Present timeline context for planning and decision-making

### Time-based Prioritization

- Prioritize tasks and suggestions based on deadlines and urgency
- Adjust recommendations when schedules change or conflicts arise
- Escalate overdue items and highlight critical follow-ups

### Location-aware Notifications

- Tailor notifications to current user location and travel mode
- Silence or adjust delivery based on spatial context
- Offer place-specific suggestions and routing guidance

### Temporal Memory Anchors

- Link memory entries to timestamps and event contexts
- Support retrieval by date, time period, and event association
- Use temporal anchors to enhance recall and relevance

### Seasonal and Recurring Patterns

- Detect recurring patterns and periodic behavior
- Use seasonal signals for proactive recommendations
- Adapt to holidays, weekends, and business cycles

## APIs and Integration

### `POST /temporal/parse`

- Parses natural language expressions into normalized schedule data

### `POST /temporal/reminders`

- Creates reminder events with optional spatial triggers

### `GET /temporal/calendar-summary`

- Returns a temporal overview for a selected range

### `POST /spatial/context`

- Evaluates location context and returns relevant actions

## Implementation Patterns

- Use a canonical time model with timezone-aware timestamps
- Keep location context lightweight and privacy-safe
- Combine temporal and spatial signals to improve relevance
- Use memory decay models for time-based prioritization

## Example Use Cases

- `Remind me to call Sam after my 2 PM meeting`
- `Summarize what happened last Thursday`
- `Mute notifications when I arrive at the gym`
- `Suggest follow-up actions before my flight tomorrow`

## Notes

- Temporal awareness is essential for effective planning and follow-up
- Spatial awareness must respect privacy and permission boundaries
- The system should expose clear user controls for time and location behavior
