# 07 - HedraSoulHub

## Overview
HedraSoulHub represents the deepest layer of the system's cognitive architecture, managing semantic, episodic, and working memory indexes.

## Architecture & Integration
- **Next.js App Router:** `/app/memory`
- **State Management:** The `memories` slice in Zustand manages local context buffering and hydration.
- **UI Visualizations:** Uses `NxMemoryMiniGraph`, `NxTagCloud`, and `NxActivityHeatmap`.

## Key Features
- **Memory Consolidation:** Automatic summarization of episodic data into semantic knowledge.
- **Context Retrieval:** Visualization of how the AI searches and retrieves relevant memories for current tasks.
- **Manual Intervention:** Ability to purge or edit specific context units from the neural partition.
