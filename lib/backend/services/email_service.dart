import 'package:flutter/foundation.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  String _smtpUser = 'YOUR_SMTP_USER';
  String _smtpPass = 'YOUR_SMTP_PASSWORD';

  void updateCredentials(String user, String pass) {
    _smtpUser = user;
    _smtpPass = pass;
  }

  Future<bool> sendOtpEmail(String recipientEmail, String otp) async {
    if (kIsWeb) {
      debugPrint('Email Service [WEB]: Mock Email sent to $recipientEmail with code $otp');
      return true; 
    }
    if (_smtpUser == 'YOUR_SMTP_USER' || _smtpUser.isEmpty) {
      debugPrint('Email Service: SMTP credentials not configured.');
      return false;
    }
    final smtpServer = gmail(_smtpUser, _smtpPass);
    final message = Message()
      ..from = Address(_smtpUser, 'ICU Suite Pro Support')
      ..recipients.add(recipientEmail)
      ..subject = 'Your ICU Suite Pro Verification Code'
      ..text = 'Your verification code is: $otp\n\nThis code will allow you to reset your password. Please do not share it with anyone.';
    try {
      final sendReport = await send(message, smtpServer);
      debugPrint('Message sent: ' + sendReport.toString());
      return true;
    } on MailerException catch (e) {
      debugPrint('Message not sent.');
      for (var p in e.problems) {
        debugPrint('Problem: ${p.code}: ${p.msg}');
      }
      return false;
    }
  }
}
