// Workflow mapping: associates workflows with apps
// Each workflow stores which version it references (either 'latest' or a specific version like '22.01')
const workflowMapping = {
    '7-Zip': {
        availableVersions: ['23.01', '22.01', '21.07', '19.00'], // All uploaded versions, sorted newest first
        workflows: [
            // Workflows configured to use "Latest Version"
            { name: 'Desktop Onboarding - Standard', version: 'v3.2', type: 'Onboarding', versionReference: 'latest', devices: 1248 },
            { name: 'Software Update - Q1 2026', version: 'v2.1', type: 'Regular', versionReference: 'latest', devices: 842 },
            { name: 'Engineering Workstation Config', version: 'v4.0', type: 'Regular', versionReference: 'latest', devices: 512 },
            { name: 'Remote Worker Initial Setup', version: 'v2.8', type: 'Onboarding', versionReference: 'latest', devices: 1890 },
            { name: 'Contractor Device Provisioning', version: 'v1.0', type: 'Onboarding', versionReference: 'latest', devices: 234 },
            
            // Workflows pinned to specific versions
            { name: 'Q4 2025 Standard Deployment', version: 'v2.3', type: 'Regular', versionReference: '23.01', devices: 678 },
            { name: 'Finance Department Setup', version: 'v1.5', type: 'Onboarding', versionReference: '22.01', devices: 356 },
            { name: 'Security Compliance Update', version: 'v1.2', type: 'Regular', versionReference: '21.07', devices: 2145 },
            { name: 'Legacy Systems Maintenance', version: 'v0.9', type: 'Regular', versionReference: '19.00', devices: 98 }
        ]
    },
    '1Password': {
        availableVersions: ['8.10.16', '8.9.12', '8.8.0'],
        workflows: [
            { name: 'Desktop Onboarding - Standard', version: 'v3.2', type: 'Onboarding', versionReference: 'latest', devices: 1248 },
            { name: 'Security Compliance Update', version: 'v1.2', type: 'Regular', versionReference: 'latest', devices: 2145 },
            { name: 'Finance Department Setup', version: 'v1.5', type: 'Onboarding', versionReference: '8.9.12', devices: 356 }
        ]
    }
};

/**
 * Compare two version strings numerically
 * @param {string} v1 - First version (e.g., '23.01')
 * @param {string} v2 - Second version (e.g., '22.01')
 * @returns {number} 1 if v1 > v2, -1 if v1 < v2, 0 if equal
 */
function compareVersions(v1, v2) {
    const parts1 = v1.split('.').map(Number);
    const parts2 = v2.split('.').map(Number);
    
    const maxLength = Math.max(parts1.length, parts2.length);
    
    for (let i = 0; i < maxLength; i++) {
        const num1 = parts1[i] || 0;
        const num2 = parts2[i] || 0;
        
        if (num1 > num2) return 1;
        if (num1 < num2) return -1;
    }
    
    return 0;
}

/**
 * Get the latest version for an app
 * @param {string} app - The app name
 * @returns {string|null} The latest version number or null if no versions exist
 */
function getLatestVersion(app) {
    if (!workflowMapping[app] || !workflowMapping[app].availableVersions || workflowMapping[app].availableVersions.length === 0) {
        return null;
    }
    // Find the highest version
    const versions = workflowMapping[app].availableVersions;
    return versions.reduce((latest, current) => {
        return compareVersions(current, latest) > 0 ? current : latest;
    });
}

/**
 * Generate display text for version mode
 * @param {string} versionReference - Either 'latest' or a specific version like '22.01'
 * @returns {string} Display text like "Latest Version" or "Specific (v22.01)"
 */
function getVersionModeDisplay(versionReference) {
    return versionReference === 'latest' ? 'Latest Version' : `Specific (v${versionReference})`;
}

/**
 * Get workflows for a specific app version
 * Shows workflows that will be impacted when uploading a new version
 * @param {string} app - The app name (e.g., '7-Zip', '1Password')
 * @param {string} uploadType - The upload type ('latest' or 'specific')
 * @param {string} uploadVersion - The version number being uploaded (e.g., '24.00')
 * @returns {Array} Array of workflow objects with generated versionMode field
 */
function getWorkflowsForVersion(app, uploadType, uploadVersion) {
    console.log(`\n=== getWorkflowsForVersion called ===`);
    console.log(`App: ${app}, Upload Type: ${uploadType}, Upload Version: ${uploadVersion}`);
    
    if (!workflowMapping[app]) {
        console.log(`No workflows found for app: ${app}`);
        return [];
    }
    
    const allWorkflows = workflowMapping[app].workflows || [];
    const result = [];
    
    console.log(`Total workflows for ${app}: ${allWorkflows.length}`);
    
    // When uploading a version marked as "latest", include:
    // 1. All workflows with versionReference: 'latest'
    // 2. All workflows with versionReference <= uploadVersion
    if (uploadType === 'latest') {
        console.log(`Upload is marked as 'latest' - including workflows with 'latest' reference and specific versions <= ${uploadVersion}`);
        
        allWorkflows.forEach(wf => {
            if (wf.versionReference === 'latest') {
                console.log(`  ✓ Including: ${wf.name} (references 'latest')`);
                result.push({
                    ...wf,
                    versionMode: getVersionModeDisplay(wf.versionReference)
                });
            } else {
                // Check if specific version <= upload version
                const comparison = compareVersions(wf.versionReference, uploadVersion);
                if (comparison <= 0) {
                    console.log(`  ✓ Including: ${wf.name} (references v${wf.versionReference}, which is <= v${uploadVersion})`);
                    result.push({
                        ...wf,
                        versionMode: getVersionModeDisplay(wf.versionReference)
                    });
                } else {
                    console.log(`  ✗ Excluding: ${wf.name} (references v${wf.versionReference}, which is > v${uploadVersion})`);
                }
            }
        });
    } 
    // When uploading a specific version (not marked as latest), include:
    // All workflows with versionReference <= uploadVersion (but NOT 'latest' workflows)
    else {
        console.log(`Upload is a specific version - including workflows that reference v${uploadVersion} and below`);
        
        allWorkflows.forEach(wf => {
            // Skip workflows that reference 'latest'
            if (wf.versionReference === 'latest') {
                console.log(`  ✗ Excluding: ${wf.name} (references 'latest', not affected by specific version upload)`);
                return;
            }
            
            // Include workflows with versionReference <= uploadVersion
            const comparison = compareVersions(wf.versionReference, uploadVersion);
            if (comparison <= 0) {
                console.log(`  ✓ Including: ${wf.name} (references v${wf.versionReference}, which is <= v${uploadVersion})`);
                result.push({
                    ...wf,
                    versionMode: getVersionModeDisplay(wf.versionReference)
                });
            } else {
                console.log(`  ✗ Excluding: ${wf.name} (references v${wf.versionReference}, which is > v${uploadVersion})`);
            }
        });
    }
    
    console.log(`Total workflows returned: ${result.length}`);
    console.log(`Workflows:`, result.map(w => `${w.name} [${w.versionMode}]`));
    return result;
}

/**
 * Get total device count for workflows
 * @param {Array} workflows - Array of workflow objects
 * @returns {number} Total device count
 */
function getTotalDeviceCount(workflows) {
    return workflows.reduce((total, wf) => total + wf.devices, 0);
}
