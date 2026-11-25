/**
 * ============================================================================
 * CINEVA STREAM — GOOGLE APPS SCRIPT FEEDBACK WEBHOOK (Telegram + Google Sheets)
 * ============================================================================
 *
 * Cara Pasang / Update di Google Apps Script (https://script.google.com):
 * 1. Buka project Apps Script webhook Cineva kamu.
 * 2. Pastikan konstanta TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID, dan SPREAD脚本/Sheet
 *    di bawah sesuai dengan milikmu (atau gunakan Script Properties).
 * 3. Klik "Deploy" -> "Manage deployments" -> Edit (ikon pensil) ->
 *    pilih Version: "New version" -> Klik "Deploy".
 */

const _PROPS = PropertiesService.getScriptProperties();
const TELEGRAM_BOT_TOKEN =
  _PROPS.getProperty('TELEGRAM_BOT_TOKEN') ||
  _PROPS.getProperty('BOT_TOKEN') ||
  _PROPS.getProperty('TELEGRAM_TOKEN') ||
  '';
const TELEGRAM_CHAT_ID =
  _PROPS.getProperty('TELEGRAM_CHAT_ID') ||
  _PROPS.getProperty('CHAT_ID') ||
  '';
const SPREADSHEET_ID =
  _PROPS.getProperty('SPREADSHEET_ID') ||
  _PROPS.getProperty('SHEET_ID') ||
  '';
const SHEET_NAME = _PROPS.getProperty('SHEET_NAME') || 'Feedback';

function doPost(e) {
  try {
    if (!e || !e.postData || !e.postData.contents) {
      return _jsonResponse({ status: 'error', message: 'Empty payload' });
    }

    const data = JSON.parse(e.postData.contents);
    const timestamp = _formatJakartaTimestamp(data.timestamp);
    const name = (data.name || 'Anonim').toString().trim();
    const email = (data.email || '').toString().trim();
    const category = (data.category || 'Lainnya').toString().trim();
    const title = (data.title || '-').toString().trim();
    const description = (data.description || '-').toString().trim();
    const deviceInfo = (data.deviceInfo || 'Tidak disertakan').toString().trim();
    const appVersion = (data.appVersion || '-').toString().trim();

    // 1. Simpan ke Google Sheets (termasuk kolom Email)
    let sheetSaved = false;
    try {
      sheetSaved = _appendToSheet({
        timestamp: timestamp,
        name: name,
        email: email || '-',
        category: category,
        title: title,
        description: description,
        deviceInfo: deviceInfo,
        appVersion: appVersion,
      });
    } catch (sheetErr) {
      Logger.log('Google Sheets error: ' + sheetErr);
    }

    // 2. Kirim Notifikasi ke Bot Telegram Developer
    let telegramSent = false;
    try {
      telegramSent = _sendToTelegram({
        timestamp: timestamp,
        name: name,
        email: email,
        category: category,
        title: title,
        description: description,
        deviceInfo: deviceInfo,
        appVersion: appVersion,
      });
    } catch (tgErr) {
      Logger.log('Telegram error: ' + tgErr);
    }

    return _jsonResponse({
      status: 'success',
      sheetSaved: sheetSaved,
      telegramSent: telegramSent,
    });
  } catch (err) {
    return _jsonResponse({
      status: 'error',
      message: err.toString(),
    });
  }
}

/**
 * Menyimpan baris laporan ke Google Sheets dengan urutan kolom:
 * [Timestamp, Name, Email, Category, Title, Description, Device Info, App Version]
 */
function _appendToSheet(entry) {
  const ss = SPREADSHEET_ID
    ? SpreadsheetApp.openById(SPREADSHEET_ID)
    : SpreadsheetApp.getActiveSpreadsheet();
  if (!ss) return false;

  let sheet = ss.getSheetByName(SHEET_NAME) || ss.getActiveSheet();
  if (!sheet) return false;

  const headers = [
    'Timestamp',
    'Name',
    'Email',
    'Category',
    'Title',
    'Description',
    'Device Info',
    'App Version',
  ];

  if (sheet.getLastRow() === 0) {
    sheet.appendRow(headers);
    sheet.getRange(1, 1, 1, headers.length).setFontWeight('bold');
  } else {
    // Jika sheet lama belum memiliki kolom "Email" di kolom C, sisipkan kolom Email secara otomatis
    const firstRow = sheet.getRange(1, 1, 1, sheet.getLastColumn()).getValues()[0];
    const hasEmailCol = firstRow.some(function (h) {
      return h && h.toString().toLowerCase() === 'email';
    });
    if (!hasEmailCol && firstRow.length >= 2) {
      sheet.insertColumnAfter(2);
      sheet.getRange(1, 3).setValue('Email').setFontWeight('bold');
    }
  }

  sheet.appendRow([
    entry.timestamp,
    entry.name,
    entry.email,
    entry.category,
    entry.title,
    entry.description,
    entry.deviceInfo,
    entry.appVersion,
  ]);
  return true;
}

/**
 * Mengirim pesan HTML rapi ke Telegram Bot Developer
 */
function _sendToTelegram(entry) {
  if (!TELEGRAM_BOT_TOKEN || TELEGRAM_BOT_TOKEN === 'YOUR_TELEGRAM_BOT_TOKEN') {
    return false;
  }

  const emailDisplay = entry.email ? _escapeHtml(entry.email) : '<i>Tidak dicantumkan</i>';

  const message = [
    '🎬 <b>CINEVA FEEDBACK &amp; REPORT</b>',
    '',
    '👤 <b>Nama:</b> ' + _escapeHtml(entry.name),
    '📧 <b>Email:</b> ' + emailDisplay,
    '📂 <b>Kategori:</b> ' + _escapeHtml(entry.category),
    '📌 <b>Judul:</b> ' + _escapeHtml(entry.title),
    '',
    '📝 <b>Deskripsi:</b>',
    _escapeHtml(entry.description),
    '',
    '📱 <b>Perangkat:</b> ' + _escapeHtml(entry.deviceInfo),
    '🏷️ <b>Versi App:</b> <code>' + _escapeHtml(entry.appVersion) + '</code>',
    '🕒 <b>Waktu:</b> <code>' + _escapeHtml(entry.timestamp) + '</code>',
  ].join('\n');

  const url = 'https://api.telegram.org/bot' + TELEGRAM_BOT_TOKEN + '/sendMessage';
  const payload = {
    chat_id: TELEGRAM_CHAT_ID,
    text: message,
    parse_mode: 'HTML',
    disable_web_page_preview: true,
  };

  const response = UrlFetchApp.fetch(url, {
    method: 'post',
    contentType: 'application/json',
    payload: JSON.stringify(payload),
    muteHttpExceptions: true,
  });

  return response.getResponseCode() >= 200 && response.getResponseCode() < 300;
}

function _formatJakartaTimestamp(rawTimestamp) {
  let dateObj = new Date();
  if (rawTimestamp) {
    const parsed = new Date(rawTimestamp);
    if (!isNaN(parsed.getTime())) {
      dateObj = parsed;
    }
  }
  return Utilities.formatDate(dateObj, 'Asia/Jakarta', 'dd/MM/yyyy HH:mm:ss');
}

function _escapeHtml(str) {
  return (str || '')
    .toString()
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

function _jsonResponse(obj) {
  return ContentService.createTextOutput(JSON.stringify(obj)).setMimeType(
    ContentService.MimeType.JSON
  );
}
