import 'dart:async';
import 'dart:convert';
import 'dart:io';
import '../Screens/ShareScreenOptions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Custom_Widgets/CustomPopups.dart';
import '../Models/Payment.dart';
import '../Services/LocalizationService.dart'; // Adjust import if needed
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import 'package:http_parser/http_parser.dart';

import '../Services/PaymentService.dart';
import '../Services/apiConstants.dart';
import '../Services/networking.dart';

class EmailBottomSheet extends StatefulWidget {
  final Payment payment;

  const EmailBottomSheet({
    Key? key,
    required this.payment,
  }) : super(key: key);

  @override
  _EmailBottomSheetState createState() => _EmailBottomSheetState();
}

class _EmailBottomSheetState extends State<EmailBottomSheet> {
  final TextEditingController _toController = TextEditingController();
  final FocusNode _toFocusNode = FocusNode();
  String? _errorText;
  String _selectedLanguage = 'ar';
  Map<String, dynamic>? _emailJson;
  String? _headerBase64;
  String? _footerBase64;

  @override
  void initState() {
    super.initState();
    _toFocusNode.addListener(() {
      setState(() {
        if (_toFocusNode.hasFocus) {
          _errorText = null; // Clear error when field is focused
        }
      });
    });
    _loadSavedLanguageCode();
    _loadLocalizedEmailContent(_selectedLanguage);
    _loadBase64Images();
  }

  Future<void> _loadSavedLanguageCode() async {
    setState(() {
      _selectedLanguage ='ar';
    });

    // Load the localized message for the saved/default language
    await _loadLocalizedEmailContent(_selectedLanguage);
  }

  Future<void> _loadLocalizedEmailContent(String languageCode) async {
    try {
      String jsonString = await rootBundle.loadString('assets/languages/$languageCode.json');
      setState(() {
        _emailJson = jsonDecode(jsonString);
      });
    } catch (e) {
      print("Error loading localized strings for $languageCode: $e");
    }
  }

  String getLocalizedEmailContent(String key) {
    if (_emailJson == null) {
      return '** $key not found';
    }
    return _emailJson![key] ?? '** $key not found';
  }

  Future<void> _loadBase64Images() async {
    try {
      final headerBase64 = await encodeImageToBase64('assets/images/headerEmail.jpg');
      final footerBase64 = await encodeImageToBase64('assets/images/footerEmail.jpg');
      setState(() {
        _headerBase64 = headerBase64;
        _footerBase64 = footerBase64;
      });
    } catch (e) {
      print("Error encoding images to Base64: $e");
    }
  }

  Future<String> encodeImageToBase64(String path) async {
    final ByteData data = await rootBundle.load(path);
    final List<int> bytes = data.buffer.asUint8List();
    return base64Encode(bytes);
  }

  @override
  Widget build(BuildContext context) {
    if (_emailJson == null || _headerBase64 == null || _footerBase64 == null) {
      return Center(child: CircularProgressIndicator());
    }
    DateTime transactionDate = widget.payment.transactionDate!;

// Extract year, month, day, hour, and minute
    int year = transactionDate.year;
    int month = transactionDate.month;
    int day = transactionDate.day;
    int hour = transactionDate.hour;
    int minute = transactionDate.minute;

// Format the output as a string
    String formattedDate = '${year.toString().padLeft(4, '0')}/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
   // String formattedDate = '${year.toString().padLeft(4, '0')}/${month.toString().padLeft(2, '0')}/${day.toString().padLeft(2, '0')}';

    var appLocalization = Provider.of<LocalizationService>(context, listen: false);
    String currentLanguageCode = Localizations.localeOf(context).languageCode;

    return Directionality(
      textDirection: currentLanguageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Padding(
        // Adjust bottom padding dynamically based on keyboard visibility
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Adjust the bottom sheet size
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appLocalization.getLocalizedString('sendEmail'),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),

                // To Field (editable)
                TextField(
                  controller: _toController,
                  focusNode: _toFocusNode,
                  decoration: InputDecoration(
                    labelText: appLocalization.getLocalizedString('to'),
                    labelStyle: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    errorText: _errorText,
                    errorStyle: TextStyle(color: Colors.red, fontSize: 14),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey, width: 2),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey, width: 1),
                    ),
                    prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[700]),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                SizedBox(height: 24),
                // Language Switcher for Message
                Text(appLocalization.getLocalizedString('selectLanguageForMessage')),
                SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildLanguageButton(
                        context,
                        'en',
                        'English',
                        Icons.language,
                        _selectedLanguage == 'en',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _buildLanguageButton(
                        context,
                        'ar',
                        'Arabic',
                        Icons.language,
                        _selectedLanguage == 'ar',
                      ),
                    ),


                  ],
                ),
                SizedBox(height: 24),

                // Send Button
                Row(
                  mainAxisAlignment: currentLanguageCode == 'ar' ? MainAxisAlignment.start : MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: currentLanguageCode == 'ar' ? Alignment.centerLeft : Alignment.centerRight,
                        child: ElevatedButton.icon(
                          onPressed: () async {

                            setState(() {
                              if (_toController.text.isEmpty) {
                                _errorText = appLocalization.getLocalizedString('toFieldError');
                                return;
                              }
                              if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(_toController.text)) {
                                _errorText = appLocalization.getLocalizedString('invalidEmailError'); // Localized string for invalid email
                                return;
                              }
                              _errorText = null; // Clear error if valid
                            });
                            if(_errorText ==null) {
                              // Handle send action
                              String transactionDate = widget.payment.transactionDate.toString(); // Your original string
                              int spaceIndex = transactionDate.indexOf(' ');

                              String result; // Define the result variable
                              if (spaceIndex != -1) {
                                result = transactionDate.substring(0, spaceIndex); // Get the part before the first space
                              } else {
                                result = transactionDate; // If no space found, use the entire string
                              }

                              String fileName="اشعاردفع-${result}";
                              String toEmail = _toController.text;
                              print("To: $toEmail");
                              print("Subject: $fileName");
                              String direction = _selectedLanguage == 'en' ? 'left' : 'right';
                              print("_selectedLanguage :${_selectedLanguage} and direction :${direction}");
                              String emailBody = "<html>\n"
                                  + "<body style=\"font-family: Arial, sans-serif; margin: 0; padding: 0; max-width: 970px; align=${direction == 'right' ? 'right' : 'left'};\">\n"
                                  + "    <!-- Header Image -->\n"
                                  + "    <div style=\"font-family: Arial, sans-serif; margin: 0; padding: 0; max-width: 970px; background-color: #f0f0f0;\">\n"
                                  + "        <table role=\"presentation\" style=\"max-width: 970px; border: 0; cellpadding: 0; cellspacing: 0;\">\n"
                                  + "        <tr>\n"
                                  + "            <td style=\"padding: 10px 0;\">\n"
                                  + "                <img src=\"cid:headerImageCID\" alt=\"Header Image\" style=\"max-width: 970px; height: auto; display: block;\"/>\n"
                                  + "            </td>\n"
                                  + "        </tr>\n"
                                  + "    </table>\n"
                                  + "    </div>\n"
                                  + "    <!-- Email Content -->\n"
                                  + "    <table role=\"presentation\" style=\"width: 970px; border: 0; cellpadding: 0; cellspacing: 0; text-align: ${direction};\">\n"
                                  + "        <tr>\n"
                                  + "            <td style=\"padding: 20px 10px; border-bottom: 1px solid #dddddd;\">\n"
                                  + "                <p style=\"font-size: 18px; color: #333333; margin: 0;\">${getLocalizedEmailContent('emailBodyLine1')}</p>\n"
                                  + "                <br/>\n"
                                  + "                <br/>\n"
                                  + "                <p style=\"font-size: 18px; color: #333333; margin: 0;\">${getLocalizedEmailContent('emailBodyLine2')} ${formattedDate}</p>\n"
                                  + "                <br/>\n"
                                  + "                <p style=\"font-size: 18px; color: #333333; margin: 0;\">${getLocalizedEmailContent('noteEmail')}</p>\n"
                                  + "                <br/>\n"
                                  + "                <br/>\n"
                                  + "                <p style=\"font-size: 18px; color: #333333; margin: 0;\">${getLocalizedEmailContent('thankYou')}</p>\n"
                                  + "            </td>\n"
                                  + "        </tr>\n"
                                  + "    </table>\n"
                                  + "    <div style=\"font-family: Arial, sans-serif; margin: 0; padding: 0; max-width: 970px; background-color: #f0f0f0;\">\n"
                                  + "        <table role=\"presentation\" style=\"max-width: 970px; border-collapse: collapse;\">\n"
                                  + "            <tr>\n"
                                  + "                <td style=\"max-width: 487px; padding: 10px; border-right: 1px solid #ddd; vertical-align: top; text-align: left; direction: ltr;\">\n"
                                  + "                    <div style=\"font-weight: bold; margin-bottom: 2px;\">Disclaimer</div>\n"
                                  + "                    <p style=\"max-width: 487px;\">The information in this email may contain confidential material and it is intended solely for the addresses. Access to this email by anyone else is unauthorized. If you are not the intended recipient, please delete the email instantly.</p>\n"
                                  + "                </td>\n"
                                  + "                <td style=\"max-width: 487px; padding: 10px; border-left: 1px solid #ddd; text-align: right; vertical-align: top; direction: rtl;\">\n"
                                  + "                    <div style=\"font-weight: bold; margin-bottom: 2px;\">إخلاء المسؤوليه</div>\n"
                                  + "                    <p style=\"max-width: 487px;\">قد يحتوي هذا البريد الإلكتروني على مواد سرية. الحصول على هذه الرسالة من قبل أي شخص آخر، هو شيء غير مصرح به. إذا لم تكن المتلقي المقصود، يرجى حذف هذا البريد الإلكتروني على الفور.</p>\n"
                                  + "                </td>\n"
                                  + "            </tr>\n"
                                  + "        </table>\n"
                                  + "    </div>\n"

                                  + "    <div style=\"font-family: Arial, sans-serif; margin: 0; padding: 0;max-width: 970px; background-color: #f0f0f0;\">\n"
                                  + "        <table role=\"presentation\" style=\"max-width: 970px; border: 0; cellpadding: 0; cellspacing: 0;\">\n"
                                  + "            <tr>\n"
                                  + "                <td style=\"padding: 10px 0;\">\n"
                                  + "                    <img src=\"cid:footerImageCID\" alt=\"Footer Image\" style=\"max-width: 100%; height: auto; display: block;\"/>\n"
                                  + "                </td>\n"
                                  + "            </tr>\n"
                                  + "        </table>\n"
                                  + "    </div>\n"
                                  + "</body>\n"
                                  + "</html>";

                              final file = await ShareScreenOptions.sharePdf(
                                  context, widget.payment.id!,
                                  _selectedLanguage);
                              if (file == null) {
                                print("file is null");
                              }
                              else {
                                print("ready to send to email api");
                                await sendPdfFileViaApi(context, file, toEmail, fileName, emailBody,fileName);
                              }
                              // Close bottom sheet if no error
                              Navigator.pop(context);
                            }
                          },
                          icon: Icon(Icons.send),
                          label: Text(appLocalization.getLocalizedString('send')),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFFC62828),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> sendPdfFileViaApi(BuildContext context,File pdfFile, String toEmail, String subject, String emailBody,String fileName) async {
    try {


      // Add headers
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? tokenID = prefs.getString('token');
      if (tokenID == null) {
        print('Token not found');
        return;
      }
      String fullToken = "Barer ${tokenID}";
      print(fullToken);
      Map<String, String> headers = {
        'tokenID': fullToken,
      };
      Map<String, String> emailDetails = {
        'to': toEmail,
        'subject': subject,
        'body': emailBody,
      };

      NetworkHelper networkHelper = NetworkHelper(
        url: apiUrlEmail, // Replace with your API URL
        headers: headers
      );

      String emailDetailsJson = jsonEncode(emailDetails);
      print("file name before send : ${fileName}");
      dynamic response = await networkHelper.uploadFile(
        fileName: fileName,
        file: pdfFile,
        emailDetailsJson: emailDetailsJson,
      ).timeout(Duration(seconds: 4));

      if (response == 200) {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.check_circle, color: Colors.green, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailOk"),
          buttonText:  Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            // Define what happens when the button is pressed
            print('Success acknowledged');
          },
        );
      }
      else if(response == 401){
        int responseNumber = await PaymentService.attemptReLogin(context);
        print("the response number from get expend the session is :${responseNumber}");
        if(responseNumber == 200 ){
          print("relogin successfully");
          tokenID = prefs.getString('token');
          if (tokenID == null) {
            print('Token not found');
            return;
          }
          fullToken = "Barer ${tokenID}";
          headers = {
            'tokenID': fullToken,
          };
          networkHelper = NetworkHelper(
              url: apiUrlEmail, // Replace with your API URL
              headers: headers
          );

          dynamic reloginResponse = await networkHelper.uploadFile(
            fileName: fileName,
            file: pdfFile,
            emailDetailsJson: emailDetailsJson,
          );
          if (reloginResponse == 200) {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.check_circle, color: Colors.green, size: 40),
              message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailOk"),
              buttonText:  Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                // Define what happens when the button is pressed
                print('Success acknowledged');
              },
            );
          }
          else {
            CustomPopups.showCustomResultPopup(
              context: context,
              icon: Icon(Icons.error, color: Colors.red, size: 40),
              message: '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailFailed")}: Failed to upload file , $reloginResponse.statusCode',
              buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
              onPressButton: () {
                print('Failed to upload file. Status code: ${reloginResponse.statusCode}');
              },
            );
          }



        }
      }
      else if (response.statusCode == 408) {
        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: Colors.red, size: 40),
          message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("networkTimeoutError"),
          buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            print('Error timeout');
          },
        );
      }
      else {
        print(response.statusCode);
        print(response.reasonPhrase);

        CustomPopups.showCustomResultPopup(
          context: context,
          icon: Icon(Icons.error, color: Colors.red, size: 40),
          message: '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailFailed")}: Failed to upload file , $response.statusCode',
          buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
          onPressButton: () {
            print('Failed to upload file. Status code: ${response.statusCode}');
          },
        );
      }
    }
    on SocketException catch (e) {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Colors.red, size: 40),
        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("networkError"),
        buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
          print('Network error acknowledged');
        },
      );
    } on TimeoutException catch (e) {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Colors.red, size: 40),
        message: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("networkTimeoutError"),
        buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
          print('Timeout error acknowledged');
        },
      );
    }
    catch (e) {
      CustomPopups.showCustomResultPopup(
        context: context,
        icon: Icon(Icons.error, color: Colors.red, size: 40),
        message: '${Provider.of<LocalizationService>(context, listen: false).getLocalizedString("paymentSentEmailFailed")}',
        buttonText: Provider.of<LocalizationService>(context, listen: false).getLocalizedString("ok"),
        onPressButton: () {
// Define what happens when the button is pressed
          print('Error: $e');
        },
      );
    }
  }

  Widget _buildLanguageButton(
      BuildContext context,
      String languageCode,
      String languageName,
      IconData icon,
      bool isSelected) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          _selectedLanguage = languageCode;
        });
        await _loadLocalizedEmailContent(languageCode);
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? Color(0xFFC62828) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected ? Color(0xFFC62828) : Colors.grey[700],
                ),
                SizedBox(width: 12),
                Text(
                  languageName,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isSelected ? Color(0xFFC62828) : Colors.grey[700],
                  ),
                ),
              ],
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: Color(0xFFC62828),
              ),
          ],
        ),
      ),
    );
  }

}

void showEmailBottomSheet(BuildContext context, Payment payment) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true, // Enable the bottom sheet to resize based on the content
    builder: (context) => EmailBottomSheet(payment: payment),
  );
}