import 'package:flutter/foundation.dart';
import 'package:twilio_flutter/twilio_flutter.dart';

class SmsService {
  TwilioFlutter? _twilioFlutter;
  String _accountSid = 'ACxxxxxxxxxxxxxxxxxxxx';
  String _authToken = 'xxxxxxxxxxxxxxxxxxxxxx';
  String _twilioNumber ='+15551234567'; 

  void updateCredentials(String sid, String token, String number) {
    _accountSid = sid;
    _authToken = token;
    _twilioNumber = number;
    if (!kIsWeb) {
      _initializeTwilio();
    }
  }

  Future<bool> sendOtpSms(String phoneNumber, String otp) async {
    if (kIsWeb) {
      debugPrint('SMS Service [WEB]: Mock SMS sent to $phoneNumber with code $otp');
      return true; 
    }
    if (_twilioFlutter == null) {
      _initializeTwilio();
    }
    if (_twilioFlutter == null) {
      debugPrint('SMS Service Error: Twilio keys are not correctly configured.');
      return false;
    }
    try {
      String formattedNumber = phoneNumber.trim();
      if (!formattedNumber.startsWith('+')) {
        formattedNumber = '+' + formattedNumber;
      }
      await _twilioFlutter!.sendSMS(
        toNumber: formattedNumber,
        messageBody: 'ICU Suite Pro: Your verification code is $otp. Use this to reset your clinical password.',
      );
      debugPrint('SMS sent successfully to: $formattedNumber');
      return true;
    } catch (e) {
      debugPrint('Real SMS Sending Failed: $e');
      return false;
    }
  }

  void _initializeTwilio() {
    if (kIsWeb) return;
    if (_accountSid.isNotEmpty && !_accountSid.contains('YOUR_TWILIO')) {
      _twilioFlutter = TwilioFlutter(
        accountSid: _accountSid,
        authToken: _authToken,
        twilioNumber: _twilioNumber,
      );
    }
  }
}
