# Webhook 2 Sheet

## Summary

This project automates the process of appending data to a specific Google Sheet using a Google Cloud Function. It provides a webhook where you can send any JSON record as POST request to and it will be added as a new row in the Sheet. The mapping will be defined in a separate tab in the Sheet. It leverages the Google Sheets API to append new data sent via HTTP requests to a predefined spreadsheet. This solution is ideal for integrating various data sources into a centralized Google Sheet for reporting, analysis, or aggregation purposes.

## Prerequisites/Installation

Before deploying this project, ensure you have the following prerequisites:

- **Google Cloud Platform (GCP) Account**: You need a GCP account with billing enabled.
- **Terraform**: Terraform is used for deploying infrastructure as code. Install Terraform by following the [official installation guide](https://learn.hashicorp.com/tutorials/terraform/install-cli).
- **Google Cloud SDK**: The Google Cloud SDK is required for managing resources within your GCP account. Install it from the [Google Cloud SDK documentation](https://cloud.google.com/sdk/docs/install).

## Configuration (tfvars)

To configure the project for your environment, you need to create a `terraform.tfvars` file from the provided `terraform.tfvars.example`. Replace the example values with your specific project details:

```hcl
project_id = "yourProjectID"
region = "yourPreferredRegion"
function_name = "yourFunctionName"
spread_sheet_url= "https://docs.google.com/spreadsheets/d/yourSpreadsheetID"
```
Note, you can simply copy the Sheet url from the browser.

## Deployment

Follow these steps to deploy the project:

1. **Initialize Terraform**: Navigate to the project directory and run `terraform init` to initialize the Terraform project.
2. **Apply Terraform Configuration**: Deploy the infrastructure by executing `terraform apply`. Confirm the action by typing `yes` when prompted.
3. **Note the Output**: After successful deployment, Terraform displays outputs, including the service account email. You'll need this to set permissions on your Google Sheet.

## Preparing Google Sheet

To use this automation, prepare your Google Sheet with the following tabs and column names. Keep exact capitalization on tab and column names:

- **'data' Tab**: This is where the data will be appended. Define the column names based on the data you expect to receive.
- **'mapping' Tab**: Use this tab to map JSON keys from the incoming requests to your column names in the Data tab. It should have two columns: `json_key` and `column_header`. Add here for each key in the json of the request the column name that you would like to value to be added. Note, you don't have to add all json keys nor all column names if you don't want to fill them.

## Access to Google Sheet

Share the Google Sheet with the **service account email** provided by Terraform, granting it **Editor** access. 





