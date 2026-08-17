/**
 * =============================================================================
 * MAKTABA IHSAN - LIBRARY MANAGEMENT SYSTEM
 * Backend: Google Apps Script (GAS) REST API
 * Cloud DB: Google Sheets
 * =============================================================================
 *
 * HOW TO DEPLOY:
 *   1. Paste this code into your Google Apps Script project.
 *   2. To set API KEY: Extensions > Apps Script > Project Settings > Script Properties
 *      Add property: Key = "API_KEY", Value = "your-secret-key-here"
 *   3. Run `initializeSheets()` once to create all sheets with headers.
 *   4. Deploy as a Web App:
 *      - Execute as: Me (your account)
 *      - Who has access: Anyone (Flutter will supply the API key)
 */

const SHEET_NAMES = {
  BOOKS: "Books",
  USERS: "Users",
  TRANSACTIONS: "Transactions",
  SYNC_LOG: "SyncLog"
};

const HEADERS = {
  [SHEET_NAMES.BOOKS]: [
    'accession_no', 'book_name', 'volume_no', 'author', 'translator',
    'publisher', 'address', 'subject_category', 'shelf_no', 'remarks',
    'status', 'last_updated'
  ],
  [SHEET_NAMES.USERS]: [
    'user_id', 'name', 'phone', 'pin', 'type',
    'class_jamat', 'status', 'last_updated'
  ],
  [SHEET_NAMES.TRANSACTIONS]: [
    'trx_id', 'accession_no', 'user_id', 'issue_date', 'expected_return',
    'actual_return', 'status', 'last_updated'
  ],
  [SHEET_NAMES.SYNC_LOG]: [
    'id', 'table_name', 'operation', 'record_id', 'synced_at'
  ]
};

function initializeSheets() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();

  Object.keys(HEADERS).forEach(sheetName => {
    const columns = HEADERS[sheetName];
    let sheet = ss.getSheetByName(sheetName);

    if (!sheet) {
      sheet = ss.insertSheet(sheetName);
      sheet.appendRow(columns);
      const headerRange = sheet.getRange(1, 1, 1, columns.length);
      headerRange.setFontWeight("bold");
      headerRange.setBackground("#4A90D9");
      headerRange.setFontColor("#FFFFFF");
      sheet.setFrozenRows(1);
    } else {
      // If sheet exists, ensure headers are at least present (doesn't overwrite data)
      const firstRow = sheet.getRange(1, 1, 1, columns.length).getValues()[0];
      const hasHeaders = firstRow.some(cell => cell !== "");
      if (!hasHeaders) {
        sheet.getRange(1, 1, 1, columns.length).setValues([columns]);
        sheet.getRange(1, 1, 1, columns.length).setFontWeight("bold");
      }
    }
  });

  return "Initialization complete. All sheets are ready.";
}

function validateApiKey(providedKey) {
  if (!providedKey) return false;
  try {
    const storedKey = PropertiesService.getScriptProperties().getProperty("API_KEY");
    if (!storedKey) return false;
    if (providedKey.length !== storedKey.length) return false;
    return providedKey === storedKey;
  } catch (error) {
    return false;
  }
}

function buildErrorResponse(message) {
  return ContentService
    .createTextOutput(JSON.stringify({ status: 'error', message: message }))
    .setMimeType(ContentService.MimeType.JSON);
}

function buildSuccessResponse(data) {
  return ContentService
    .createTextOutput(JSON.stringify({ status: 'success', ...data }))
    .setMimeType(ContentService.MimeType.JSON);
}

function doGet(e) {
  try {
    const params = e.parameter || {};

    const action = (params.action || "").trim().toLowerCase();

    if (action === "ping") {
      return buildSuccessResponse({ message: "Maktaba API is online." });
    }

    if (action === "pull") {
      const lastSyncedAtMs = (params.last_synced_at && params.last_synced_at.trim() !== '')
        ? new Date(params.last_synced_at).getTime()
        : 0;

      const responseData = {
        books: getAllRows(SHEET_NAMES.BOOKS, lastSyncedAtMs),
        users: getAllRows(SHEET_NAMES.USERS, lastSyncedAtMs),
        transactions: getAllRows(SHEET_NAMES.TRANSACTIONS, lastSyncedAtMs),
        timestamp: new Date().toISOString()
      };

      return buildSuccessResponse({ data: responseData });
    }

    return buildErrorResponse("Unknown action");

  } catch (error) {
    return buildErrorResponse(error.toString());
  }
}

function getAllRows(sheetName, lastSyncedAtMs) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheet = ss.getSheetByName(sheetName);
  if (!sheet) return [];

  const data = sheet.getDataRange().getValues();
  if (data.length <= 1) return [];

  const headers = data[0];
  let updatedIndex = headers.indexOf('last_updated');
  if (updatedIndex === -1) updatedIndex = headers.indexOf('updated_at');

  const results = [];

  for (let i = 1; i < data.length; i++) {
    const row = data[i];
    if (row.every(cell => cell === '' || cell === null || cell === undefined)) continue;

    if (lastSyncedAtMs === 0) {
      const record = {};
      headers.forEach((header, colIndex) => {
        let val = row[colIndex];
        if (val instanceof Date) val = val.toISOString();
        record[header] = val !== undefined ? String(val) : '';
      });
      results.push(record);
      continue;
    }

    const rowUpdatedStr = updatedIndex >= 0 ? row[updatedIndex] : '';
    if (!rowUpdatedStr || rowUpdatedStr === '') {
      const record = {};
      headers.forEach((header, colIndex) => {
        let val = row[colIndex];
        if (val instanceof Date) val = val.toISOString();
        record[header] = val !== undefined ? String(val) : '';
      });
      results.push(record);
    } else {
      const rowUpdatedMs = new Date(rowUpdatedStr).getTime();
      if (!isNaN(rowUpdatedMs) && rowUpdatedMs > lastSyncedAtMs) {
        const record = {};
        headers.forEach((header, colIndex) => {
          let val = row[colIndex];
          if (val instanceof Date) val = val.toISOString();
          record[header] = val !== undefined ? String(val) : '';
        });
        results.push(record);
      }
    }
  }

  return results;
}

function doPost(e) {
  try {
    let payload;
    try {
      payload = JSON.parse(e.postData.contents);
    } catch(err) {
      return buildErrorResponse("Invalid JSON");
    }

    const action = (payload.action || "").trim().toLowerCase();

    if (action === 'push') {
      const changes = payload.changes || [];
      const results = [];

      changes.forEach(change => {
        try {
          processChange(change);
          results.push({ id: change.data.id || change.data.accession_no || change.data.trx_id || change.data.user_id, status: 'success' });
        } catch (err) {
          results.push({ id: change.data.id || change.data.accession_no || change.data.trx_id || change.data.user_id, status: 'error', error: err.toString() });
        }
      });

      return buildSuccessResponse({ results: results, timestamp: new Date().toISOString() });
    }

    return buildErrorResponse("Unknown action");

  } catch (error) {
    return buildErrorResponse(error.toString());
  }
}

function processChange(change) {
  const sheetName = change.table;
  const operation = change.operation;
  const recordData = change.data;

  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(sheetName);

  if (!sheet) {
    initializeSheets();
    sheet = ss.getSheetByName(sheetName);
  }

  const headers = HEADERS[sheetName] || sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
  const data = sheet.getDataRange().getValues();

  const primaryKeyHeader = headers[0]; 
  const recordId = recordData[primaryKeyHeader] || recordData['id'] || recordData['accession_no'] || recordData['trx_id'] || recordData['user_id'];

  let rowIndex = -1;
  for (let i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(recordId)) {
      rowIndex = i + 1;
      break;
    }
  }

  if (operation === 'DELETE') {
    if (rowIndex > -1) {
      sheet.deleteRow(rowIndex);
      logSync(sheetName, operation, recordId);
    }
    return;
  }

  const newRow = headers.map(header => {
    if (recordData[header] !== undefined && recordData[header] !== null) {
      return recordData[header];
    }
    if (header === 'updated_at' || header === 'last_updated') {
      return new Date().toISOString();
    }
    if (rowIndex > -1) {
      return data[rowIndex - 1][headers.indexOf(header)];
    }
    return '';
  });

  if (rowIndex > -1) {
    sheet.getRange(rowIndex, 1, 1, newRow.length).setValues([newRow]);
  } else {
    sheet.appendRow(newRow);
  }

  logSync(sheetName, operation, recordId);
}

function logSync(tableName, operation, recordId) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName(SHEET_NAMES.SYNC_LOG);
    if (sheet) {
      sheet.appendRow([
        Utilities.getUuid(),
        tableName,
        operation,
        recordId,
        new Date().toISOString()
      ]);
    }
  } catch(e) {}
}
