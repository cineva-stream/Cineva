import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Service that sends an automated, professional English confirmation email
/// via Google SMTP (`smtp.gmail.com:465` Implicit TLS) using a 16-digit
/// Google App Password.
///
/// Sender address: `noreply.cineva@gmail.com`
/// Follow-up developer contact noted in email: `cineva.dev@gmail.com`
///
/// The 16-digit App Password is resolved in the following priority order:
/// 1. `--dart-define=CINEVA_SMTP_APP_PASSWORD=...` (GitHub Actions Repository Secret)
/// 2. OS Environment variable `CINEVA_SMTP_APP_PASSWORD`
/// 3. Local `.env` file (`CINEVA_SMTP_APP_PASSWORD=...` or `SMTP_APP_PASSWORD=...`)
class FeedbackSmtpService {
  FeedbackSmtpService._();

  static const String smtpHost = 'smtp.gmail.com';
  static const int smtpPort = 465;

  /// Automated no-reply sender email address.
  static const String senderEmail = 'noreply.cineva@gmail.com';
  static const String senderName = 'Cineva Stream';

  /// Official developer follow-up email address mentioned in the auto-reply note.
  static const String developerContactEmail = 'cineva.dev@gmail.com';

  static const String _dartDefineAppPassword = String.fromEnvironment(
    'CINEVA_SMTP_APP_PASSWORD',
    defaultValue: '',
  );

  static String? _cachedEnvPassword;

  /// Validates whether [email] is a well-formed email address.
  static bool isValidEmail(String email) {
    final trimmed = email.trim();
    if (trimmed.isEmpty) return false;
    return RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    ).hasMatch(trimmed);
  }

  /// Resolves the 16-digit Google App Password from `--dart-define`,
  /// OS environment variables, or a local `.env` file (removing any spaces).
  static Future<String> resolveAppPassword() async {
    if (_dartDefineAppPassword.trim().isNotEmpty) {
      return _normalizePassword(_dartDefineAppPassword);
    }

    if (!kIsWeb) {
      final osEnv =
          Platform.environment['CINEVA_SMTP_APP_PASSWORD'] ??
          Platform.environment['SMTP_APP_PASSWORD'] ??
          '';
      if (osEnv.trim().isNotEmpty) {
        return _normalizePassword(osEnv);
      }
    }

    if (_cachedEnvPassword != null) {
      return _cachedEnvPassword!;
    }

    // 1. Check local .env file on filesystem (useful in Windows Desktop / local dev)
    if (!kIsWeb) {
      try {
        final envFile = File('.env');
        if (await envFile.exists()) {
          final content = await envFile.readAsString();
          final parsed = parseEnvForPassword(content);
          if (parsed.isNotEmpty) {
            _cachedEnvPassword = parsed;
            return parsed;
          }
        }
      } catch (_) {}
    }

    // 2. Check bundled asset .env if present
    try {
      final assetContent = await rootBundle.loadString('.env');
      final parsed = parseEnvForPassword(assetContent);
      if (parsed.isNotEmpty) {
        _cachedEnvPassword = parsed;
        return parsed;
      }
    } catch (_) {}

    return '';
  }

  /// Extracts `CINEVA_SMTP_APP_PASSWORD` or `SMTP_APP_PASSWORD` from `.env` content.
  static String parseEnvForPassword(String envContent) {
    for (final rawLine in envContent.split('\n')) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final eqIndex = line.indexOf('=');
      if (eqIndex <= 0) continue;
      final key = line.substring(0, eqIndex).trim();
      if (key == 'CINEVA_SMTP_APP_PASSWORD' || key == 'SMTP_APP_PASSWORD') {
        var value = line.substring(eqIndex + 1).trim();
        if ((value.startsWith('"') && value.endsWith('"')) ||
            (value.startsWith("'") && value.endsWith("'"))) {
          value = value.substring(1, value.length - 1);
        }
        return _normalizePassword(value);
      }
    }
    return '';
  }

  static String _normalizePassword(String raw) {
    return raw.replaceAll(RegExp(r'\s+'), '').trim();
  }

  /// Converts Indonesian/internal category labels to clean English labels for the email.
  static String toEnglishCategory(String rawCategory) {
    final lower = rawCategory.toLowerCase();
    if (lower.contains('bug') || lower.contains('teknis')) {
      return 'Bugs & Technical Issues';
    }
    if (lower.contains('fitur') || lower.contains('feature')) {
      return 'Feature Suggestion';
    }
    if (lower.contains('konten') ||
        lower.contains('tayangan') ||
        lower.contains('media')) {
      return 'Media / Subtitle Report';
    }
    return 'General Feedback';
  }

  /// Builds the RFC 5322 multipart/alternative MIME message (Plain Text + HTML)
  /// in professional English, noting that this is an automated email from
  /// `noreply.cineva@gmail.com` and any developer follow-up will come from
  /// `cineva.dev@gmail.com`.
  static String buildAutoReplyMimeMessage({
    required String recipientEmail,
    required String userName,
    required String category,
    required String title,
    required String description,
    required String appVersion,
  }) {
    final cleanName =
        (userName.trim().isEmpty ||
            userName.trim().toLowerCase() == 'anonim' ||
            userName.trim().toLowerCase() == 'anonymous')
        ? 'Cineva User'
        : userName.trim();
    final englishCat = toEnglishCategory(category);
    final subject = 'Thank You for Your Feedback — Cineva Stream';
    const boundary = 'CinevaMimeBoundary_20261125';

    final plainText = '''
Dear $cleanName,

Thank you for taking the time to share your thoughts and feedback with us. We truly appreciate your support in helping us make Cineva Stream better across all devices.

Here is a summary of your submission:
- Category: $englishCat
- Subject: ${title.trim()}
- App Version: ${appVersion.trim()}
- Message:
"${description.trim()}"

What happens next?
Our development team has received your submission and will review it carefully. Please note that this is an automated confirmation sent from $senderEmail. If we require any further details or clarification regarding your report, our developer will contact you directly via $developerContactEmail.

Warm regards,
Cineva Stream Team
https://cineva.primadev.id
'''.trim();

    final escapedName = _escapeHtml(cleanName);
    final escapedCat = _escapeHtml(englishCat);
    final escapedTitle = _escapeHtml(title.trim());
    final escapedVersion = _escapeHtml(appVersion.trim());
    final escapedDesc = _escapeHtml(description.trim()).replaceAll('\n', '<br>');

    final htmlBody = '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
</head>
<body style="margin:0;padding:0;background-color:#0A0A0E;font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;color:#F3F3F7;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#0A0A0E;padding:32px 16px;">
    <tr>
      <td align="center">
        <table width="100%" cellpadding="0" cellspacing="0" style="max-width:560px;background-color:#121218;border-radius:16px;border:1px solid #242430;overflow:hidden;">
          <tr>
            <td style="padding:24px 28px;border-bottom:1px solid #22222E;">
              <span style="display:inline-block;width:10px;height:10px;border-radius:50%;background-color:#FF9500;margin-right:8px;"></span>
              <span style="font-size:15px;font-weight:800;letter-spacing:1.5px;color:#FF9500;">CINEVA STREAM</span>
            </td>
          </tr>
          <tr>
            <td style="padding:28px;">
              <h2 style="margin:0 0 14px 0;font-size:20px;font-weight:700;color:#FFFFFF;">Thank You for Your Feedback</h2>
              <p style="margin:0 0 16px 0;font-size:14px;line-height:1.6;color:#C8C8D4;">
                Dear <strong style="color:#FFFFFF;">$escapedName</strong>,
              </p>
              <p style="margin:0 0 20px 0;font-size:14px;line-height:1.6;color:#C8C8D4;">
                Thank you for taking the time to share your thoughts and feedback with us. We truly appreciate your contribution in helping us improve the <strong style="color:#FFFFFF;">Cineva Stream</strong> experience.
              </p>
              <div style="background-color:#181822;border-left:3px solid #FF9500;border-radius:10px;padding:16px 18px;margin-bottom:22px;">
                <div style="font-size:11px;font-weight:700;text-transform:uppercase;letter-spacing:0.8px;color:#FF9500;margin-bottom:10px;">Submission Summary</div>
                <p style="margin:0 0 6px 0;font-size:13px;color:#D6D6E0;"><strong style="color:#8E8E9E;">Category:</strong> $escapedCat</p>
                <p style="margin:0 0 6px 0;font-size:13px;color:#D6D6E0;"><strong style="color:#8E8E9E;">Subject:</strong> $escapedTitle</p>
                <p style="margin:0 0 10px 0;font-size:13px;color:#D6D6E0;"><strong style="color:#8E8E9E;">App Version:</strong> $escapedVersion</p>
                <div style="font-size:13px;line-height:1.55;color:#EAEAF2;padding-top:8px;border-top:1px solid #262634;">
                  &ldquo;$escapedDesc&rdquo;
                </div>
              </div>
              <div style="background-color:#15151D;border:1px solid #262634;border-radius:10px;padding:14px 16px;margin-bottom:22px;">
                <p style="margin:0;font-size:12.5px;line-height:1.55;color:#B4B4C4;">
                  <strong style="color:#FFFFFF;">Note on Follow-Up:</strong> This is an automated confirmation sent from <span style="color:#FF9500;">$senderEmail</span>. Our team is reviewing your report, and if we need any further clarification or details, our developer will contact you directly from <a href="mailto:$developerContactEmail" style="color:#FF9500;text-decoration:none;font-weight:600;">$developerContactEmail</a>.
                </p>
              </div>
              <p style="margin:0;font-size:13.5px;line-height:1.5;color:#9A9AA8;">
                Warm regards,<br>
                <strong style="color:#FFFFFF;">Cineva Development Team</strong><br>
                <a href="https://cineva.primadev.id" style="color:#FF9500;text-decoration:none;font-size:12.5px;">cineva.primadev.id</a>
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
'''.trim();

    final buffer = StringBuffer()
      ..writeln('From: "$senderName" <$senderEmail>')
      ..writeln('To: <${recipientEmail.trim()}>')
      ..writeln('Reply-To: <$developerContactEmail>')
      ..writeln('Subject: =?UTF-8?B?${base64.encode(utf8.encode(subject))}?=')
      ..writeln('MIME-Version: 1.0')
      ..writeln('Content-Type: multipart/alternative; boundary="$boundary"')
      ..writeln()
      ..writeln('--$boundary')
      ..writeln('Content-Type: text/plain; charset="UTF-8"')
      ..writeln('Content-Transfer-Encoding: base64')
      ..writeln()
      ..writeln(_chunkBase64(base64.encode(utf8.encode(plainText))))
      ..writeln('--$boundary')
      ..writeln('Content-Type: text/html; charset="UTF-8"')
      ..writeln('Content-Transfer-Encoding: base64')
      ..writeln()
      ..writeln(_chunkBase64(base64.encode(utf8.encode(htmlBody))))
      ..writeln('--$boundary--');

    return buffer.toString().replaceAll('\r\n', '\n').replaceAll('\n', '\r\n');
  }

  static String _chunkBase64(String b64) {
    final out = StringBuffer();
    for (var i = 0; i < b64.length; i += 76) {
      final end = (i + 76 < b64.length) ? i + 76 : b64.length;
      out.writeln(b64.substring(i, end));
    }
    return out.toString().trimRight();
  }

  static String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }

  /// Connects to `smtp.gmail.com:465` over TLS and sends the auto-reply email.
  /// Returns `true` if sent, or `false` if skipped (e.g. App Password not configured)
  /// or if the network blocked SMTP.
  static Future<bool> sendAutoReplyEmail({
    required String recipientEmail,
    required String userName,
    required String category,
    required String title,
    required String description,
    required String appVersion,
    String? overrideAppPassword,
  }) async {
    final cleanRecipient = recipientEmail.trim();
    if (!isValidEmail(cleanRecipient)) return false;

    final appPassword = overrideAppPassword != null
        ? _normalizePassword(overrideAppPassword)
        : await resolveAppPassword();
    if (appPassword.isEmpty) {
      debugPrint(
        '[FeedbackSmtpService] Skipping SMTP auto-reply: CINEVA_SMTP_APP_PASSWORD is not set in .env or --dart-define.',
      );
      return false;
    }

    SecureSocket? socket;
    try {
      socket = await SecureSocket.connect(
        smtpHost,
        smtpPort,
        timeout: const Duration(seconds: 12),
      );

      final lineCompleterList = <Completer<String>>[];
      final responseHistory = <String>[];
      var lineBuffer = '';

      Future<String> nextResponse({
        Duration timeout = const Duration(seconds: 10),
      }) {
        final completer = Completer<String>();
        lineCompleterList.add(completer);
        return completer.future.timeout(timeout);
      }

      var currentMultiline = StringBuffer();

      socket.listen(
        (data) {
          lineBuffer += utf8.decode(data, allowMalformed: true);
          while (lineBuffer.contains('\n')) {
            final idx = lineBuffer.indexOf('\n');
            final line = lineBuffer.substring(0, idx).replaceAll('\r', '');
            lineBuffer = lineBuffer.substring(idx + 1);
            if (line.isEmpty) continue;
            responseHistory.add(line);
            currentMultiline.writeln(line);
            // SMTP final line of a response has a space at index 3 (e.g. "250 OK"),
            // while continuation lines have a hyphen (e.g. "250-SIZE").
            if (line.length >= 4 && line[3] == '-') {
              continue;
            }
            final fullResp = currentMultiline.toString().trim();
            currentMultiline = StringBuffer();
            if (lineCompleterList.isNotEmpty) {
              final c = lineCompleterList.removeAt(0);
              if (!c.isCompleted) c.complete(fullResp);
            }
          }
        },
        onError: (Object err) {
          while (lineCompleterList.isNotEmpty) {
            final c = lineCompleterList.removeAt(0);
            if (!c.isCompleted) c.completeError(err);
          }
        },
      );

      Future<String> sendCommand(String cmd) async {
        final respFuture = nextResponse();
        socket!.add(utf8.encode('$cmd\r\n'));
        await socket.flush();
        return respFuture;
      }

      // 1. Server Greeting (220)
      final greeting = await nextResponse();
      if (!greeting.startsWith('220')) return false;

      // 2. EHLO
      final ehlo = await sendCommand('EHLO cineva.app');
      if (!ehlo.startsWith('250')) return false;

      // 3. AUTH LOGIN
      final authStart = await sendCommand('AUTH LOGIN');
      if (!authStart.startsWith('334')) return false;

      final userB64 = base64.encode(utf8.encode(senderEmail));
      final userResp = await sendCommand(userB64);
      if (!userResp.startsWith('334')) return false;

      final passB64 = base64.encode(utf8.encode(appPassword));
      final passResp = await sendCommand(passB64);
      if (!passResp.startsWith('235')) {
        debugPrint('[FeedbackSmtpService] SMTP AUTH failed: $passResp');
        return false;
      }

      // 4. MAIL FROM & RCPT TO
      final mailFrom = await sendCommand('MAIL FROM:<$senderEmail>');
      if (!mailFrom.startsWith('250')) return false;

      final rcptTo = await sendCommand('RCPT TO:<$cleanRecipient>');
      if (!rcptTo.startsWith('250')) return false;

      // 5. DATA
      final dataCmd = await sendCommand('DATA');
      if (!dataCmd.startsWith('354')) return false;

      final mimeMessage = buildAutoReplyMimeMessage(
        recipientEmail: cleanRecipient,
        userName: userName,
        category: category,
        title: title,
        description: description,
        appVersion: appVersion,
      );

      // Dot-stuffing per RFC 5321
      final dotStuffed = mimeMessage.replaceAll('\r\n.', '\r\n..');
      final dataEndResp = await sendCommand('$dotStuffed\r\n.');
      if (!dataEndResp.startsWith('250')) return false;

      // 6. QUIT
      try {
        await sendCommand('QUIT');
      } catch (_) {}

      return true;
    } catch (e) {
      debugPrint('[FeedbackSmtpService] Error sending auto-reply: $e');
      return false;
    } finally {
      try {
        await socket?.close();
      } catch (_) {}
    }
  }
}
