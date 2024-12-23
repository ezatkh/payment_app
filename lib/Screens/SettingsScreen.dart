import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:ooredoo_app/Screens/printerService/PrinterSettingScreen.dart';
import 'package:ooredoo_app/Services/apiConstants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Screens/LanguageSettingsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../Custom_Widgets/CustomAboutDialogScreen.dart';
import '../Services/LocalizationService.dart';
import '../Services/PaymentService.dart';
import '../Services/networking.dart';
import 'LoginScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';


class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String currentLanguage = "";
  String currentPrinter = "";

  @override
  void initState() {
    super.initState();
    _getSubTitles();
  }

  // Retrieve the default device address from SharedPreferences
  void _getSubTitles() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      currentPrinter = prefs.getString('default_device_label') ?? ''; // Provide fallback if null

      currentLanguage = Provider.of<LocalizationService>(context, listen: false).selectedLanguageCode ?? 'ENGLISH'; // Provide fallback if null

      print("currentLanguage :${currentLanguage} : currentPrinter :${currentPrinter}");
    });
  }

  @override
  Widget build(BuildContext context) {
    ScreenUtil.init(context, designSize: Size(360, 690));

    // Access the LocalizationService directly using Provider.of
    final localizationService = Provider.of<LocalizationService>(context);

    return  Directionality(
      textDirection: localizationService.selectedLanguageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            localizationService.getLocalizedString('settings'),
            style: TextStyle(fontFamily: "NotoSansUI", fontSize: 18.sp, color: Colors.white),
          ),
          backgroundColor: Color(0xFFC62828),
          elevation: 0,
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              _buildSettingSection(localizationService,'Preferences', [
                _buildSettingOption(localizationService,Icons.language, 'languageSettings', onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 300),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: LanguageSettingsScreen(),
                        );
                      },
                    ),
                  );
                },subtitle:currentLanguage=='en' ? localizationService.getLocalizedString('english') :localizationService.getLocalizedString('arabic')),
              ]),
              _buildSettingSection(localizationService,'Printer', [
                _buildSettingOption(localizationService,Icons.print, 'printerSettings', onTap: () {
                  Navigator.push(
                    context,
                    PageRouteBuilder(
                      transitionDuration: Duration(milliseconds: 300),
                      pageBuilder: (context, animation, secondaryAnimation) {
                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(1.0, 0.0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: PrinterSettingScreen(),
                        );
                      },
                    ),
                  );
                },subtitle: currentPrinter),

              ]),
              _buildSettingSection(localizationService,'Other', [
                _buildSettingOption(localizationService,Icons.info_outline, 'aboutHelp', onTap: () async {
                  showDialog(
                    context: context,
                    barrierDismissible: true,
                    builder: (BuildContext context) {
                      return Dialog(
                        insetPadding: EdgeInsets.symmetric(horizontal: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
                        elevation: 0,
                        backgroundColor: Colors.transparent,
                        child: CustomAboutDialogScreen(),
                      );
                    },
                  );
                }),
              ]),
              _buildSettingSection(localizationService,'Account', [
                _buildSettingOption(localizationService,Icons.logout, 'logout', onTap: () {
                  _showLogoutDialog(context);
                }),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingSection(LocalizationService localizationService, title, List<Widget> options) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 0,
            blurRadius: 6,
            offset: Offset(0, 2), // subtle shadow for depth
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
            child: Text(
              localizationService.getLocalizedString(title.toLowerCase()),
              style: TextStyle(fontFamily: "NotoSansUI", fontSize: 16.sp, fontWeight: FontWeight.bold),
            ),
          ),
          ...options,
        ],
      ),
    );
  }


  Widget _buildSettingOption(LocalizationService localizationService, icon, String title, {VoidCallback? onTap, String? subtitle}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, color: Color(0xFFC62828), size: 24.sp),
                    SizedBox(width: 20.w),
                    Text(
                      localizationService.getLocalizedString(title)
                      ,
                      style: TextStyle(fontFamily: "NotoSansUI", fontSize: 16.sp),
                    ),
                  ],
                ),
                Icon(Icons.arrow_forward_ios, size: 16.sp, color: Colors.grey),
              ],
            ),
            // Add subtitle only if provided
            if (subtitle != null) _buildSubTitleSettingOption(subtitle),
          ],
        ),
      ),
    );
  }

  Widget _buildSubTitleSettingOption(subtitle) {
    return Padding(
      padding: EdgeInsets.only(left: 50.w,right: 50.w, top: 4.h), // Adjust padding for alignment
      child: Text(
        subtitle,
        style: TextStyle(
          fontFamily: "NotoSansUI",
          fontSize: 13.sp, // Smaller font size
          color: Colors.grey, // Grey color
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
            ),
            elevation: 0,
            backgroundColor: Colors.transparent,
            child: _buildLogoutDialogContent(dialogContext),
          ),
        );
      },
    );
  }

  Widget _buildLogoutDialogContent(BuildContext context) {
    final localizationService = Provider.of<LocalizationService>(context, listen: false);
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.44),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.white.withOpacity(0.2),
              width: 1.0,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                localizationService.getLocalizedString('logoutBody'),
                style: TextStyle(
                  fontSize: 18.sp,
                  fontFamily: "NotoSansUI",
                  fontWeight: FontWeight.bold,
                  color: Colors.white, // Ooredoo theme color
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDialogButton(
                    context: context,
                    label: localizationService.getLocalizedString('cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                    backgroundColor: Colors.grey.shade300,
                    textColor: Colors.black,
                  ),
                  _buildDialogButton(
                    context: context,
                    label: localizationService.getLocalizedString('logout'),
                    onPressed: () async {
                      // Logout logic
                    },
                    backgroundColor: Color(0xFFC62828), // Ooredoo theme color
                    textColor: Colors.white,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDialogButton({
    required BuildContext context,
    required String label,
    required VoidCallback onPressed,
    required Color backgroundColor,
    required Color textColor,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: backgroundColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(label, style: TextStyle(fontFamily: "NotoSansUI", color: textColor)),
    );
  }
}