# Coacher App - Testing Guide

## Overview
This document outlines the key user flows and features that testers should verify to ensure the app functions correctly across different scenarios and device types.

## Device Testing Requirements
- **iPhone SE (small screen)** - Critical for text wrapping and UI layout
- **iPhone 15/15 Pro (standard screen)** - Primary testing device
- **iPhone 15 Pro Max (large screen)** - Verify scaling and spacing
- **Both Light and Dark modes** - Test all UI elements in both themes

---

## 1. Onboarding Flow

### Test Steps:
1. **First Launch**
   - App should show onboarding screens
   - Verify all text is readable and buttons are accessible
   - Test navigation between onboarding steps
   - Complete the onboarding process

2. **Settings Access**
   - Go to Settings → "Replay Onboarding"
   - Verify onboarding can be restarted
   - Test accessibility labels and hints

---

## 2. Main Navigation & Today View

### Test Steps:
1. **Today View Layout**
   - Verify all sections are visible and properly spaced
   - Test section expansion/collapse functionality
   - Check that "Last Night's Prep" only shows during day phase
   - Verify "Morning Focus" and "Prep Tonight" are expanded by default

2. **Action Buttons**
   - Test "I Need Help" button (blue color #4DA6FF)
   - Test "I Did Great" button (green color)
   - Verify accessibility labels and hints
   - Test button functionality on different screen sizes

---

## 3. Morning Focus Section

### Test Steps:
1. **Text Input Fields**
   - **Step 1 - My Why**: Enter motivation text
   - **Step 2 - Challenge**: Select different challenge types
     - Test "Other" option shows additional text field
   - **Step 3 - My Swap**: Enter healthy alternative
   - **Step 4 - Commit**: Fill both "Today I will..." and "instead of..." fields

2. **UI Elements**
   - Verify rounded corners on all text input areas
   - Test dark mode background colors for text inputs
   - Check text wrapping on small screens (iPhone SE)
   - Verify accessibility labels for all text fields

3. **Data Persistence**
   - Enter text in fields, navigate away, return to verify data is saved
   - Test auto-save functionality

---

## 4. "I Need Help" Flow

### Test Steps:
1. **Category Selection**
   - Test all 4 craving types:
     - **Stress/Emotional**: "Feeling overwhelmed, anxious, or emotionally triggered"
     - **Habit/Automatic**: "Automatic behavior, time/place triggers, or routine"
     - **Physical/Biological**: "Hunger, thirst, tiredness, or physical need"
     - **Other/Not Sure**: "Not sure what's causing this craving"
   - Verify text wrapping on small screens
   - Test accessibility labels and hints

2. **Mini Coach Flow**
   - **Introduction Step**: Verify progress bar and content
   - **Action Step**: Test quick actions display
   - **Capture Step**: 
     - Test voice recording (auto-start, 20-second limit)
     - Test text input option
     - Verify transcription works
     - Test "Edit Text" functionality
   - **Save Step**: Verify final review and completion

3. **Error Handling**
   - Test failed voice recording scenarios
   - Verify error alerts with proper options
   - Test empty recording handling

---

## 5. "I Did Great" Success Capture Flow

### Test Steps:
1. **Success Type Selection**
   - Test all 4 success types:
     - **Great Choice**: "made a healthier choice"
     - **Prepared something ahead**: "Prepared something that set you up for success"
     - **Habit Win**: "Stuck to a good habit or routine"
     - **Other Success**: "Any other win or positive moment"
   - Verify bright blue text in dark mode (#007AFF)
   - Test background colors in dark mode
   - Check text wrapping on small screens

2. **Capture Options**
   - **Text Capture**:
     - Test text input with border outline
     - Verify dark mode text box visibility
     - Test keyboard dismissal
   - **Voice Capture**:
     - Test auto-start recording
     - Verify transcription display
     - Test "Edit Text" functionality
     - Test "Save Success" completion

3. **UI Elements**
   - Verify star icon is fully visible on small screens
   - Test scrolling on iPhone SE for capture options
   - Check navigation and cancel functionality

---

## 6. AI Coach Area

### Test Steps:
1. **Initial Model Loading**
   - **First Launch**: Verify SparkleProgressView appears with progress bar and sparkles
   - **Progress Bar**: Check that progress bar shows realistic loading progress (2-3 minutes)
   - **Loading States**: Verify "Preparing your AI coach..." message during loading
   - **Completion**: Confirm progress bar completes to 100% when model is ready

2. **Chat Interface**
   - **Welcome Message**: Verify "I'm here to help you build healthier habits..." appears when loaded
   - **Text Input**: Test message input field with proper placeholder text
   - **Send Button**: Verify button is disabled during loading and enabled when ready
   - **Auto-scroll**: Test that screen scrolls to show user's question at top when sent

3. **Response Generation**
   - **Thinking Indicator**: Verify simple spinner + "Thinking..." appears during response generation
   - **No Progress Bar**: Confirm SparkleProgressView does NOT appear during response generation
   - **Response Display**: Test AI responses appear in chat bubbles with proper formatting
   - **Dark Mode Text**: Verify AI responses use white text in dark mode for readability

4. **Model Loading States**
   - **Background Loading**: Test that model loads invisibly in background on app launch
   - **Onboarding**: Verify users can complete onboarding while model loads in background
   - **Coach Screen**: Test different states:
     - Loading: SparkleProgressView with progress bar
     - Ready: Welcome message and functional chat
     - Error: Retry button and error message
     - Generating: Simple spinner for responses

5. **Error Handling**
   - **Model Load Failure**: Test retry functionality if model fails to load
   - **Network Issues**: Verify graceful handling of download failures
   - **Memory Issues**: Test behavior with limited device memory

6. **UI Elements**
   - **Progress Bar**: Verify SparkleProgressView has:
     - Blue gradient progress bar (300px width)
     - White sparkles that appear and fade
     - Realistic progress timing (slow start, slower middle, quick finish)
     - Completion animation to 100%
   - **Chat Bubbles**: Test proper styling:
     - User messages: Blue background, white text, right-aligned
     - AI messages: Card background, primary text color, left-aligned
     - Timestamps: Secondary text color, proper positioning
   - **Input Area**: Verify rounded corners and proper styling

7. **Performance Testing**
   - **Model Size**: Verify app stays under 4GB limit with MLX models
   - **Loading Time**: Test realistic loading times (2-3 minutes for first load)
   - **Memory Usage**: Monitor memory consumption during model loading
   - **Response Speed**: Test response generation speed after model is loaded

8. **Accessibility**
   - **VoiceOver**: Test chat interface with VoiceOver enabled
   - **Accessibility Labels**: Verify all buttons and inputs have proper labels
   - **Keyboard Navigation**: Test tab navigation through chat interface
   - **Screen Reader**: Ensure chat messages are properly announced

---

## 7. Settings & Personalization

### Test Steps:
1. **Name Field**
   - Test text input with proper background in dark mode
   - Verify data persistence
   - Test accessibility labels

2. **Animation Toggle**
   - Test celebration animations on/off
   - Verify setting persistence

3. **Navigation**
   - Test keyboard dismissal
   - Verify scroll dismissal

---

## 8. Timeline & History Views

### Test Steps:
1. **Timeline Navigation**
   - Test scrolling between different days
   - Verify "Today" section is properly highlighted
   - Test action buttons in timeline view

2. **History Display**
   - Verify timestamps are shown (user preference)
   - Test different entry types display correctly
   - Check dark mode text colors (blue → white)

---

## 9. Accessibility Testing

### Test Steps:
1. **VoiceOver Navigation**
   - Enable VoiceOver and test all interactive elements
   - Verify all buttons have proper labels and hints
   - Test text input accessibility
   - Verify section expansion/collapse with VoiceOver

2. **Accessibility Labels**
   - Test all custom accessibility labels
   - Verify hints provide helpful context
   - Check button traits (isButton, isSelected)

---

## 10. Dark Mode Specific Testing

### Test Steps:
1. **Color Adaptations**
   - Verify blue text uses bright blue (#007AFF) in dark mode
   - Test text input backgrounds use secondarySystemBackground
   - Check success category backgrounds in dark mode
   - Verify all text remains readable

2. **UI Elements**
   - Test all borders and outlines are visible
   - Verify button colors adapt properly
   - Check icon visibility and contrast

---

## 11. Small Screen Testing (iPhone SE)

### Test Steps:
1. **Text Wrapping**
   - Verify all text wraps properly without cutoff
   - Test "What's happening with..." text in MiniCoach
   - Check success type descriptions wrap correctly
   - Verify button text fits properly

2. **Layout Issues**
   - Test star icon visibility in "I Did Great" screen
   - Verify scrolling works for cut-off content
   - Check all buttons are accessible
   - Test keyboard doesn't squish content

---

## 12. Error Scenarios

### Test Steps:
1. **Voice Recording Failures**
   - Test microphone permission denied
   - Test recording with no speech
   - Test transcription failures
   - Verify error alerts and recovery options

2. **Data Persistence**
   - Test app backgrounding during text entry
   - Verify data saves properly
   - Test app termination and restart

---

## 13. Performance Testing

### Test Steps:
1. **Smooth Animations**
   - Test section expansion/collapse animations
   - Verify celebration animations (if enabled)
   - Check scrolling performance

2. **Memory Usage**
   - Test extended usage sessions
   - Verify no memory leaks with repeated recordings
   - Test app stability over time

---

## Critical Issues to Watch For

### High Priority:
- Text cutoff on iPhone SE
- White-on-white text boxes in dark mode
- Star icon cutoff on small screens
- Voice recording transcription failures
- Keyboard squishing content
- **AI Coach**: Model loading failures or infinite loading
- **AI Coach**: Progress bar not showing during initial load
- **AI Coach**: AI responses not visible in dark mode

### Medium Priority:
- Text wrapping issues
- Color contrast problems
- Accessibility label accuracy
- Button responsiveness
- Data persistence reliability
- **AI Coach**: Response generation taking too long
- **AI Coach**: Chat interface scrolling issues
- **AI Coach**: Model download progress not updating

### Low Priority:
- Animation smoothness
- Minor spacing inconsistencies
- Performance optimizations
- **AI Coach**: Sparkle animation performance
- **AI Coach**: Model loading time variations

---

## Testing Checklist

- [ ] Onboarding flow completes successfully
- [ ] All text inputs have proper accessibility labels
- [ ] Dark mode colors are correct and visible
- [ ] iPhone SE layout works without cutoff
- [ ] Voice recording and transcription work
- [ ] Text wrapping functions properly
- [ ] All buttons are accessible and functional
- [ ] Data persists between app sessions
- [ ] Error handling works for failed recordings
- [ ] Scrolling works on small screens
- [ ] Keyboard dismissal functions properly
- [ ] VoiceOver navigation is smooth
- [ ] All success types display correctly
- [ ] Section expansion/collapse works
- [ ] Settings changes persist
- [ ] **AI Coach**: SparkleProgressView appears during initial model loading
- [ ] **AI Coach**: Progress bar shows realistic progress (2-3 minutes)
- [ ] **AI Coach**: Simple spinner appears during response generation
- [ ] **AI Coach**: AI responses are visible in dark mode (white text)
- [ ] **AI Coach**: Chat interface auto-scrolls to show user questions
- [ ] **AI Coach**: Model loads in background during onboarding
- [ ] **AI Coach**: Retry functionality works if model loading fails
- [ ] **AI Coach**: Send button is properly disabled/enabled based on state
- [ ] **AI Coach**: Chat bubbles display correctly in both light and dark modes
- [ ] **AI Coach**: App stays under 4GB size limit with MLX models

---

## Notes for Testers

1. **Focus on iPhone SE testing** - This device reveals most layout issues
2. **Test both light and dark modes** - Color adaptations are critical
3. **Use VoiceOver** - Accessibility is a key feature
4. **Test voice recording thoroughly** - This is a complex feature with many failure points
5. **Verify text wrapping** - This was a major issue that needed fixing
6. **Check small screen scrolling** - Content cutoff was a problem area
7. **AI Coach Testing** - Test model loading on first launch (may take 2-3 minutes)
8. **AI Coach Testing** - Verify progress bar appears and completes properly
9. **AI Coach Testing** - Test both initial loading and response generation states
10. **AI Coach Testing** - Check dark mode text visibility for AI responses

## Reporting Issues

When reporting issues, please include:
- Device model and iOS version
- Light or dark mode
- Steps to reproduce
- Expected vs actual behavior
- Screenshots if applicable
- VoiceOver behavior (if accessibility issue)
