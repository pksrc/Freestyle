# Plan: Build UX Wireframes for "Publish New Version to Workflows" Flow

Create interactive HTML/CSS wireframes for the app version management flow using modal dialogs. Build 7-9 clickable screens covering the main flow, empty states, and error scenarios.

## Steps

1. **Create wireframe-modal-step1.html - Impacted Workflows Summary Screen** - Display modal with table showing workflows referencing the app: `workflow name`, `version`, `type badge` (Onboarding/Regular), `version mode` (Latest/Specific). Include workflow count in modal header. Add "Next" button to proceed. Reuse table styles from wireframe-index.html.

2. **Create wireframe-modal-step1-empty.html - No Workflows Found State** - Show modal with empty state message "No workflows reference this app" with icon/illustration. Include explanation that app can be published without workflow impact. Provide "Continue" button to complete upload.

3. **Create wireframe-modal-step2.html - Decision Selection Screen** - Display radio options for 3 choices: "Publish new workflow versions", "Update app only", "Do nothing". Add descriptions and impact summaries for each. Include "Back" and "Next" buttons.

4. **Create wireframe-modal-step3.html - Impact Preview & Confirmation** - Show device/workflow impact counts with choice-specific messaging. For "do nothing" option, display warning banner. Include "Back" and "Confirm" buttons.

5. **Create wireframe-modal-step4.html - Success Status** - Display success banner in modal with operation summary, affected counts, and action links to "View Deployment Status" and "View Workflow Activity". Add "Done" button to close.

6. **Create wireframe-modal-error.html - Error State** - Show error modal when workflow update fails with error message, affected workflows list, and options to "Retry" or "Cancel and Review Manually".

7. **Create wireframe-index.html - App Details Entry Point** - Build app details page with "Publish to Workflows" button that launches Flow A. Show "Workflow Associations" section displaying current workflows using this app and last decision made.

8. **Create wireframe-navigation.js and wireframe-styles.css** - Add JavaScript for modal navigation between steps and CSS for modal overlay, transitions, and consistent styling across all wireframes.

## Further Considerations

1. **Interactive Prototype** - Should we add more interactivity like workflow filtering/search in step 1 for better realism with large lists? No
2. **Mobile Responsiveness** - Wireframes will be desktop-focused based on wireframe-index.html. Should modals be responsive for tablet views? No
3. **Animation/Transitions** - Include subtle modal transitions (fade in/out) between steps for better flow demonstration? Yes
