import flask
import gspread
from google.oauth2 import service_account
import json
import os
import re


def sheets_append(request):
    # Retrieve the service account JSON from an environment variable
    service_account_info_json = os.environ.get('SERVICE_ACCOUNT_JSON')
    if not service_account_info_json:
        return flask.jsonify({'error': 'Service account JSON not found in environment variables'}), 500
    
    # Parse the service account JSON
    service_account_info = json.loads(service_account_info_json)

    # Define the required OAuth2 scopes
    scopes = [
        'https://www.googleapis.com/auth/spreadsheets',
        'https://www.googleapis.com/auth/drive'
    ]

    # Authenticate with Google Sheets and Drive API
    creds = service_account.Credentials.from_service_account_info(service_account_info, scopes=scopes)
    client = gspread.authorize(creds)

    # Parse the incoming JSON data
    request_json = request.get_json()
    # Print each key on a separate line -> this will allow you to get the keys for the mapping in the sheet
    print("json keys:", " ".join(request_json.keys()))
    # Open the spreadsheet by ID from an environment variable
    spreadsheet_url = os.environ.get('SPREADSHEET_URL')
    match = re.search(r"/spreadsheets/d/([a-zA-Z0-9-_]+)", spreadsheet_url)
    spreadsheet_id = match.group(1) if match else None
    # Open the spreadsheet
    spreadsheet = client.open_by_key(spreadsheet_id)

    # Fetch mappings from the "mapping" sheet
    mapping_sheet = spreadsheet.worksheet('mapping')
    mappings = mapping_sheet.get_all_records()

    # Prepare the mapping dictionary
    column_mapping = {mapping['json_key']: mapping['column_header'] for mapping in mappings}
    print("mapping:", column_mapping)

    # Open the "data" sheet
    data_sheet = spreadsheet.worksheet('data')

    # Get column headers from the "data" sheet
    column_headers = data_sheet.row_values(1)
    print("headers:", column_headers)

    # Prepare the row to be inserted
    row_to_insert = []
    for header in column_headers:
        json_key = next((key for key, value in column_mapping.items() if value == header), None)
        row_to_insert.append(request_json.get(json_key, ''))
    print(['[redacted]' if value else '' for value in row_to_insert])

    # Append the new row to the "data" sheet
    data_sheet.append_row(row_to_insert)

    return flask.jsonify({'status': 'success', 'message': 'Data appended to the sheet successfully.'})