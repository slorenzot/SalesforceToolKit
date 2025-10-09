# Plan to Document ALT Key Feature

## Summary of Changes

- Added a feature to display the Salesforce organization ID in the menu when the user presses the ALT key.
- Modified the application to fetch and store the organization ID upon successful authentication.
- Ensured backward compatibility for existing authenticated orgs that do not have a stored organization ID.

## Modified Files

- `SalesforceToolKit/Model/AuthenticatedOrg.swift`
- `SalesforceToolKit/Controller/SalesforceCLI.swift`
- `SalesforceToolKit/Controller/AuthenticatedOrgManager.swift`
- `SalesforceToolKit/SalesforceToolKitApp.swift`

## Reason for Changes

This feature was requested by the user to provide a quick way to view the organization ID for authenticated orgs directly from the menu bar.

## How to Test

1.  Run the application.
2.  If you have existing authenticated orgs, open the menu and press the `ALT` key. The orgs should display "No Org ID".
3.  Authenticate a new org.
4.  Open the menu and view the list of authenticated orgs.
5.  Press the `ALT` key. The newly authenticated org should display its organization ID.
