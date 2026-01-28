/**
 * Wireframe Navigation Configuration
 * 
 * This file controls the flow between different wireframe screens based on user selections.
 * Update this configuration to change navigation behavior without modifying individual HTML files.
 */

const WireframeConfig = {
    // Main flow pages
    pages: {
        listView: 'wireframe-index.html',
        step1: 'wireframe-modal-step1.html',
        step1Empty: 'wireframe-modal-step1-empty.html',
        step2: 'wireframe-modal-step2.html',
        error: 'wireframe-modal-error.html'
    },

    // Success pages mapped to update methods
    successPages: {
        'publish-workflows': 'wireframe-modal-step2.1.html',      // Publish New Workflow Versions
        'update-app-only': 'wireframe-modal-step2.2.html',        // Update App Only on Devices
        'do-nothing': 'wireframe-modal-step2.3.html'              // Do Nothing for Workflow Assignments
    },

    // Button navigation logic
    navigation: {
        // Step 1: Workflow Selection & Method Selection
        step1: {
            cancel: 'wireframe-index.html',
            next: 'wireframe-modal-step2.html'
        },

        // Step 2: Review Selection
        step2: {
            back: 'wireframe-modal-step1.html',
            publish: function() {
                // Dynamically determine which success page to show
                const method = sessionStorage.getItem('selectedMethod');
                return WireframeConfig.successPages[method] || 'wireframe-modal-step2.2.html';
            }
        },

        // Success pages - all return to list view
        success: {
            done: 'wireframe-index.html'
        },

        // Error page
        error: {
            cancel: 'wireframe-index.html',
            retry: 'wireframe-modal-step2.html'
        }
    },

    // Get success page based on selected method
    getSuccessPage: function() {
        const method = sessionStorage.getItem('selectedMethod');
        return this.successPages[method] || this.successPages['update-app-only'];
    },

    // Method metadata for display purposes
    methods: {
        'publish-workflows': {
            label: 'Publish New Workflow Versions',
            description: 'Create and publish new versions of all impacted workflows with the updated app. The entire workflow will re-run on devices, reapplying all steps including scripts, profiles, and applications.',
            successTitle: 'Workflows Published Successfully',
            successMessage: 'New workflow versions have been created. The complete workflows will re-run on all assigned devices.'
        },
        'update-app-only': {
            label: 'Update App Only on Devices',
            description: 'Update only the application on devices without creating new workflow versions. No workflow steps will re-run — only the app will be updated using the app deployment engine.',
            successTitle: 'Update Initiated Successfully',
            successMessage: 'The app is now being deployed to workflow-assigned devices. The app will be updated without re-running the entire workflows.'
        },
        'do-nothing': {
            label: 'Do Nothing for Workflow Assignments',
            description: 'Do not update the app on workflow-assigned devices. Workflows will continue using the current app version. You can manually update workflows or trigger this flow later from the app details page.',
            successTitle: 'Selection Saved',
            successMessage: 'No updates will be deployed to workflow-assigned devices. Workflows will continue using their current app versions.'
        }
    }
};

// Make config globally available
window.WireframeConfig = WireframeConfig;
