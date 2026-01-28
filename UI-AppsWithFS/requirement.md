# Freestyle Workflows - Application Management Integration

## Background

UEM Customers today have the option to deploy, assign and manage Applications as a standalone resource where we provide complete lifecycle management of Applications.

Most Mobile application deployment needs are met with the capabilities provided by the standalone App Management module. However for complex application deployment requirements (mostly on desktop and also for some use cases on mobile - VPN, launcher etc.) which require sequencing of resources such as scripts or profiles along with the App, customers are choosing to deploy applications using Freestyle Workflows.

> **Note:** Resources used in Freestyle (data from Dec 2024) - see resource_usage_by_device_type screenshot

Given this growing usage of Freestyle for deployment of Applications along with other resources, there is a need to integrate, simplify and fine tune the disjointed experiences offered within UEM today.

## Customer Scenarios

### Ensure Apps on Devices are on the LATEST version
- Deployed via Onboarding; must be updated after

### Ensure Apps on Devices are on a SPECIFIC version
- Downgrade an app due to a Security threat or due to instability

### Managing App with Dependencies
- Should FS show dependent app information when app is selected and being viewed in canvas view?

### Managing Apps with Complex Installs: Pre/Post-Install scripts or Profiles
- Customer should have the choice to decide whether running the workflow again is necessary for updating the app

## Problems

### 1. Latest Version Management

Today, customers have a hard time ensuring Devices have the latest version of an App installed when using Freestyle Workflows. In a Freestyle workflow, admins can add steps to install applications and profiles on targeted devices. Freestyle Workflows offers customers the choice to deploy the latest version or a specific version of an App as part of a workflow.

**Current Behavior:**  
When a customer chooses to deploy an App using Workflows and selects the "Latest Version" option, and when a new version of that App is uploaded, an entirely new version of the workflow is created and published silently behind the scenes which includes that new resource. This is not always desired and needed.

**Impact:**
- Customers may not always need the entire workflow to run on the device when a new version of the App needs to be installed on the device
- The alternate option allows customers to choose a specific version of the Application to be installed via a workflow. However, this increases the maintenance overhead on the Admin by having to keep all their workflows updated with the right version of the Applications all the time
- This gets extreme for some of our power customers who have a lot of Applications that they deploy and manage via Workflows

> **Note:** This behavior is specific to Desktops and only for Apps. Profiles and Scripts deployed using workflows are not impacted by this behavior

## Solution: "Publish New Version to Workflows"

The ideal way to handle this is to offer a way for admin to know, when uploading the app, if there are workflows referencing this app and allow them to choose if:

1. **A new version of the workflow should be published** (how it works today)
2. **The app should be updated on the workflow assigned devices without running the entire workflow**  
   *PRD - FS-4005: Deploy latest versions of app/profile via DSM for wf-assigned resources*
3. **Do nothing for workflow assignments** (warn and do nothing)

If customer chooses to do nothing, then:
- Have clear UX to show that the admin is confirming not to update this app on workflow assigned devices
- Provide options for customer to invoke this flow outside of the App upload flow

### UX Flow

**Flow A:** When a new version of the App is uploaded, at some point during the assignment and publish process:

1. Show admins the list of workflows that reference this app
2. Have the admin choose what must happen to the App on those workflows' installed devices

**Choices:**
1. Automatically create and publish a new version of the workflow
2. Just update the app using the App deployment flow - means new version of the workflow will not be created
3. Do nothing

App Management options when interacting with the App should also be updated to invoke Flow A at any point as well.

## User Stories

### Story 1: See Impacted Workflows When Uploading a New App Version

**As an admin**  
I want to see which Freestyle workflows reference the app when I upload a new version  
So that I can choose how that new app version should affect devices targeted by those workflows.

#### Acceptance Criteria

- When a new app version is uploaded, the system looks up all workflows that reference that app
- A summary view lists:
  - Workflow name, version, type (Onboarding / Regular)
  - Whether the workflow currently uses "Latest Version" or "Specific Version"
- If no workflows reference the app, the UI explicitly shows "No workflows reference this app"

#### Task Breakdown

**Backend:**
- Add API to fetch all workflows referencing a given app ID/version
- Ensure performance at scale (e.g., Customers scenarios with large workflow counts)

**Frontend / UX:**
- Design and implement the "Impacted Workflows" panel in the app-publish flow
- Show badges for workflow type (Onboarding vs Regular) and version-selection mode (Latest/Specific)

---

### Story 2: Choose How New App Version Affects Existing Workflows

**As an admin**  
I want to choose how a new app version propagates to workflows  
So that I can control whether workflows re-run or devices just get the updated app.

#### Acceptance Criteria

- For each app with referencing workflows, admin is presented with three high-level choices:
  1. **Publish new workflow versions** (current behavior)
  2. **Update the app only on workflow-assigned devices** (no new workflow version)
  3. **Do nothing for workflow assignments**

- Choice #1 triggers automatic new workflow versions which include the new app version
- Choice #2 updates the app on devices using the underlying app deployment flow, without changing workflow version or re-running the full workflow
- Choice #3 leaves workflows and devices unchanged and shows a clear warning / confirmation

#### Task Breakdown

**Backend / Engine:**
- Implement option 1 – batch create and publish new workflow versions referencing the new app version
- Implement option 2 – app-only update path for devices in workflows:
  - Reuse existing "direct app deployment" engine for devices that were targeted via workflows
  - Ensure no additional workflow steps (scripts/profiles) are re-applied
- Implement option 3 – no-op behavior with persisted decision metadata (for auditing)

**UX / Frontend:**
- Create a decision step in the publish flow that clearly explains each choice, with pros/cons
- For "do nothing", include an explicit confirmation with clear language: "This app will NOT be updated on devices targeted only via workflows"

---

### Story 3: Invoke the "Publish New Version to Workflows" Flow from App Details

**As an admin**  
I want to trigger the same workflow-impact decision flow from the app details/management screen  
So that I can revisit or change workflow-update behavior outside the upload moment.

#### Acceptance Criteria

- App details page provides an entry point (e.g., "Publish to Workflow") that launches Flow A
- Admin can:
  - See current app version and all workflows referencing it
  - Re-run the choice between:
    - Create/publish new workflow versions
    - Update app-only on workflow devices
    - Do nothing
- If "do nothing" was previously selected, this is clearly indicated and can be overridden

#### Task Breakdown

**Frontend:**
- Add "Publish to Workflows" action to app details
- Reuse or adapt Flow A UI (impacted workflows list + option selection)

**Backend:**
- Expose an API to re-trigger the same operations as during upload, but for an already-uploaded version

---

### Story 4: Clear Admin Feedback on Device Impact

**As an admin**  
I want clear feedback on how my choice will affect devices  
So that I can make safe decisions for production environments.

#### Acceptance Criteria

**Before confirming, admin sees:**
- Approximate number of workflows and devices affected per selected option
- For option 1: "X workflows will publish new versions; workflows will re-run and reapply scripts/profiles"
- For option 2: "App will be updated on Y devices without re-running workflows"
  - No workflow version increment occurs
  - Workflow engine does not re-execute non-app steps (scripts, profiles, etc.) on devices
- For option 3: "No devices will receive this app update via workflows"

**Post-action status:**
- Summary banner or toast with what was done and links to detailed activity/logs

#### Task Breakdown

**Data:**
- Add query to estimate affected devices per workflow for each option

**Frontend:**
- Display device and workflow counts in confirmation step
- Show success/failure summaries with links to detailed deployment status

Path
wireframe-index
 - /Users/pk/Code/Freestyle/UI-AppsWithFS/wireframe-modal-step1.html
    - 