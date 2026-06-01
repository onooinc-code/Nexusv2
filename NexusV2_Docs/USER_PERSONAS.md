# 04 - User Personas

## Overview
This document defines the key personas for Nexus, including the primary user (Hédra) and the core contact types the system must serve. It also describes their motivations, needs, and the ways Nexus must adapt its behavior for each.

---

## Primary Persona: Hédra

### Role
- Single owner and administrator of Nexus
- Uses Nexus to manage relationships, delegate tasks, and maintain a digital presence
- Relies on Nexus for both personal and business communications

### Goals
- Offload repetitive communication tasks
- Maintain emotional continuity with contacts
- Keep memory and context consistent across interactions
- Quickly receive summaries, recommendations, and action plans

### Pain Points
- Forgetting details about contacts or past conversations
- Handling too many channels and tasks simultaneously
- Losing the thread of important relationships
- Wasting time on low-value coordination work

### Requirements
- Clear oversight of autonomous agent actions
- Fast and accurate summary and report generation
- Personalization for different relationship groups
- Robust control over data privacy and memory
- Easy access to contact and task state

---

## Secondary Persona: VIP Contact

### Role
- High-value individual in Hédra's network
- May be a close family member, partner, or high-priority business contact

### Goals
- Receive fast, respectful, and well-tailored replies
- Maintain trust and rapport with Hédra
- Expect consistent tone and style

### System Behavior
- Use premium conversation personalization
- Respect strict privacy settings
- Escalate to human review for important messages
- Preserve subtle preferences and inside jokes

---

## Secondary Persona: Business Contact

### Role
- Customer, partner, or stakeholder in a professional context

### Goals
- Get accurate, polite, and actionable communication
- Receive responses aligned with contract or deal status
- Maintain a consistent brand image for Hédra

### System Behavior
- Use business tone templates
- Follow SLA and response timing rules
- Track follow-up commitments and deadlines

---

## Secondary Persona: Social Contact

### Role
- Friend, peer, or casual acquaintance

### Goals
- Enjoy natural, friendly conversation
- Have responses that feel human and emotionally aware
- Maintain personal rapport with minimal friction

### System Behavior
- Mirror tone and emoji usage
- Use informal phrasing when appropriate
- Remember personal details and preferences

---

## Secondary Persona: Service Contact

### Role
- Vendor, appointment scheduler, or automated service

### Goals
- Get clear, concise, and transactional communication
- Ensure reliability and accuracy for booking/order details

### System Behavior
- Use structured, no-nonsense replies
- Focus on action items and confirmations
- Avoid unnecessary emotional language

---

## Persona Mapping Summary
| Persona | Core Need | Nexus Behavior |
|---|---|---|
| Hédra | Oversight + delegation | Transparent control, reports, prompts |
| VIP Contact | High trust | Extra care, premium personalization |
| Business Contact | Professional outcomes | SLA-driven, factual, aligned with status |
| Social Contact | Natural rapport | Tone mirroring, casual style |
| Service Contact | Transactional accuracy | Structured, confirmatory replies |

---

## Usage Notes
- Nexus must be able to switch dynamically between persona behaviors based on contact type and message intent.
- Contact profiles combine static labels (e.g. VIP, business) with dynamic tags (e.g. mood, relationship phase) to decide which behavior mode applies.
- The system must store and expose persona-specific rules in the MemoryHub and SettingsHub for easy adjustments.
