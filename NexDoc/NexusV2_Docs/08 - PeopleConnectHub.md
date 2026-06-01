# 08 - PeopleConnectHub

## Overview
PeopleConnectHub (also integrated with the Conversation and Scheduler modules) manages real-time interactions between human users and the Nexus system, including direct chats and meeting scheduling.

## Architecture & Integration
- **Next.js App Router:** `/app/conversations` and `/app/scheduler`
- **Real-Time Integration:** Heavily relies on Pusher/Laravel Echo for instant message delivery (`conversation.{id}` channels).
- **UI Components:** Employs `NxChatBubble`, `NxChatInput`, and `NxThinkingIndicator`.

## Key Features
- **Multi-Agent Chat:** Seamlessly converse with different agent personas in a unified interface.
- **Proactive AI:** Agents can initiate conversations or scheduling based on contextual triggers.
- **Intent Recognition:** Chat inputs are processed to determine if they are simple messages or actionable commands.
