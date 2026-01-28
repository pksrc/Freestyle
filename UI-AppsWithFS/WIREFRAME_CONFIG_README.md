# Wireframe Navigation Configuration Guide

## Overview
The `wireframe-config.js` file controls all navigation and page relationships in the workflow impact management wireframe flow. This makes it easy to understand and modify the flow without editing individual HTML files.

## Configuration Structure

### 1. Pages Object
Defines all main pages in the flow:
```javascript
pages: {
    listView: 'wireframe-index.html',
    step1: 'wireframe-modal-step1.html',
    step1Empty: 'wireframe-modal-step1-empty.html',
    step2: 'wireframe-modal-step2.html',
    error: 'wireframe-modal-error.html'
}
```

### 2. Success Pages Mapping
Maps each update method to its corresponding success page:
```javascript
successPages: {
    'publish-workflows': 'wireframe-modal-step2.1.html',
    'update-app-only': 'wireframe-modal-step2.2.html',
    'do-nothing': 'wireframe-modal-step2.3.html'
}
```

### 3. Navigation Rules
Defines button behavior for each screen:
```javascript
navigation: {
    step1: {
        cancel: 'wireframe-index.html',
        next: 'wireframe-modal-step2.html'
    },
    step2: {
        back: 'wireframe-modal-step1.html',
        publish: function() { /* dynamic based on method */ }
    },
    success: {
        done: 'wireframe-index.html'
    }
}
```

## Flow Diagram

```
wireframe-index.html (List View)
    │
    │ (User selects version + clicks "Publish to Workflows")
    │
    ▼
wireframe-modal-step1.html (Select Workflows & Method)
    │
    │ Cancel → wireframe-index.html
    │ Next → wireframe-modal-step2.html
    │
    ▼
wireframe-modal-step2.html (Review Selection)
    │
    │ Back → wireframe-modal-step1.html
    │ Publish → (dynamic success page)
    │
    ├─ If "Publish New Workflow Versions" selected
    │  └→ wireframe-modal-step2.1.html
    │
    ├─ If "Update App Only on Devices" selected
    │  └→ wireframe-modal-step2.2.html
    │
    └─ If "Do Nothing for Workflow Assignments" selected
       └→ wireframe-modal-step2.3.html

All success pages → Done → wireframe-index.html
```

## Update Methods

### publish-workflows
- **Label**: Publish New Workflow Versions
- **Success Page**: wireframe-modal-step2.1.html
- **Action**: Creates new workflow versions, entire workflow re-runs

### update-app-only
- **Label**: Update App Only on Devices
- **Success Page**: wireframe-modal-step2.2.html
- **Action**: Updates app only, no workflow re-run

### do-nothing
- **Label**: Do Nothing for Workflow Assignments
- **Success Page**: wireframe-modal-step2.3.html
- **Action**: No changes made, workflows remain unchanged

## How to Use in HTML Files

### Include the configuration file:
```html
<script src="wireframe-config.js"></script>
```

### Get the success page dynamically:
```javascript
const successPage = WireframeConfig.getSuccessPage();
// Returns the correct page based on sessionStorage.getItem('selectedMethod')
```

### Access method metadata:
```javascript
const method = sessionStorage.getItem('selectedMethod');
const methodInfo = WireframeConfig.methods[method];
console.log(methodInfo.label);        // "Update App Only on Devices"
console.log(methodInfo.successTitle);  // "Update Initiated Successfully"
```

## Making Changes

### To add a new update method:
1. Add entry to `successPages` mapping
2. Create the success page HTML file
3. Add method details to `methods` object
4. Update the dropdown in wireframe-modal-step1.html

### To change navigation flow:
1. Update the `navigation` object
2. No need to modify individual HTML files

### To rename files:
1. Update file names in `pages` or `successPages`
2. Rename actual HTML files to match

## SessionStorage Keys Used
- `selectedMethod`: The update method chosen (publish-workflows, update-app-only, do-nothing)
- `selectedApp`: App name (e.g., "7-Zip")
- `selectedVersion`: Version number (e.g., "23.01")
- `selectedVersionType`: Version type ("latest" or "specific")
- `selectedWorkflowCount`: Number of workflows selected
- `selectedMethodText`: Display text for selected method

## Example: Adding a New Method

```javascript
// 1. Add to successPages
successPages: {
    'publish-workflows': 'wireframe-modal-step2.1.html',
    'update-app-only': 'wireframe-modal-step2.2.html',
    'do-nothing': 'wireframe-modal-step2.3.html',
    'schedule-update': 'wireframe-modal-step2.4.html'  // NEW
}

// 2. Add to methods
methods: {
    // ... existing methods ...
    'schedule-update': {
        label: 'Schedule Update for Later',
        description: 'Schedule the app update for a specific date and time.',
        successTitle: 'Update Scheduled',
        successMessage: 'The app update has been scheduled successfully.'
    }
}

// 3. Create wireframe-modal-step2.4.html (copy from step2.1.html template)

// 4. Add option to step1 dropdown
// <option value="schedule-update" data-tooltip="...">Schedule Update for Later</option>
```

## Files in the Flow
- `wireframe-config.js` - This configuration file
- `wireframe-navigation.js` - Navigation handler
- `workflow-data.js` - Workflow mapping data
- `wireframe-index.html` - Main app list view
- `wireframe-modal-step1.html` - Workflow & method selection
- `wireframe-modal-step2.html` - Review selection
- `wireframe-modal-step2.1.html` - Success (publish-workflows)
- `wireframe-modal-step2.2.html` - Success (update-app-only)
- `wireframe-modal-step2.3.html` - Success (do-nothing)
- `wireframe-modal-step1-empty.html` - No workflows found
- `wireframe-modal-error.html` - Error state
