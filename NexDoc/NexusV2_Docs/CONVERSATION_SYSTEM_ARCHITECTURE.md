# Conversation System Architecture

## Chat Interface
- Built using `NxChatBubble`, `NxChatInput`, and `NxThinkingIndicator`.
- Supports multi-modal input and markdown rendering for code snippets and formatted text.

## Real-Time Messaging
- Messages are broadcasted over private `conversation.{id}` channels.
- The UI handles optimistic updates, displaying the user's message immediately while waiting for the AI/backend response.

## Intent Processing
- Conversations aren't just text; they integrate with the `/api/ai/request` endpoint to perform intent-based processing, allowing chat commands to trigger system actions or workflow executions.
