import 'package:charusat_recruitment/Providers/announcement_provider.dart';
import 'package:charusat_recruitment/Providers/menu_provider.dart';
import 'package:charusat_recruitment/Providers/pie_chart_provider.dart';
import 'package:charusat_recruitment/Providers/theme_provider.dart';
import 'package:charusat_recruitment/const.dart';
import 'package:charusat_recruitment/screens/auth/facultydetail.dart';
import 'package:charusat_recruitment/screens/auth/studentdetail.dart';
import 'package:charusat_recruitment/screens/auth/forgotpage.dart';
import 'package:charusat_recruitment/screens/auth/login.dart';
import 'package:charusat_recruitment/screens/auth/otp.dart';
import 'package:charusat_recruitment/screens/auth/register.dart';
import 'package:charusat_recruitment/screens/home.dart';
import 'package:charusat_recruitment/screens/screens_after_auth/home/announcement_manage.dart';
import 'package:charusat_recruitment/screens/screens_after_auth/company/company_manager.dart';
import 'package:charusat_recruitment/screens/screens_after_auth/company/company_round.dart';
import 'package:charusat_recruitment/screens/screens_after_auth/company/student_list.dart';
import 'package:charusat_recruitment/screens/welcome.dart';
import 'package:charusat_recruitment/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'service/users/faculty_service.dart';
import 'service/users/student_service.dart';

void main() async {
  print("Step 1");
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]).then((_) {
    runApp(const MyApp());
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  late Future<bool> _isLoggedIn;
  @override
  void initState() {
    super.initState();
    _isLoggedIn = _checkLoginStatus();
  }

  Future<bool> _checkLoginStatus() async {
    String? accessToken = await _storage.read(key: 'access_token');
    String? refreshToken = await _storage.read(key: 'refresh_token');
    String? _email = await _storage.read(key: 'email');

    print(
        "Checking login: Access Token: $accessToken, Email: $_email , Refresh: $refreshToken");
    if (_email != null) {
      email= _email ;
      role = determineEmailType(email);
      if(role=='faculty'){
          FacultyService().getFacultyDetails(context);
        }else{
          StudentService().getStudentDetails(context, extractIdFromEmail(email));
        }
    }
    return (accessToken != null && _email != null);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isLoggedIn,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const MaterialApp(
            debugShowCheckedModeBanner: false,
            home: Scaffold(
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                        width: 200,
                        height: 200,
                        child: CircularProgressIndicator()),
                    SizedBox(height: 20),
                    Text('Checking authentication...')
                  ],
                ),
              ),
            ),
          );
        }
        bool isLoggedIn = snapshot.data ?? false;
        return MultiProvider(
          providers: [
            ChangeNotifierProvider(create: (_) => Themechange()),
            ChangeNotifierProvider(create: (_) => PieChartProvider()),
            ChangeNotifierProvider(create: (_) => MenuProvider()),
            ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
          ],
          child: Builder(
            builder: (context) {
              final themechanger = Provider.of<Themechange>(context);
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Charusat Placement App',
                themeMode: themechanger.themeMode,
                theme: ThemeManager.lightmode,
                darkTheme: ThemeManager.darkmode,
                home: isLoggedIn
                    ? const Home()
                    : const Welcome(), // Show correct screen
                routes: {
                  '/home': (context) => const Home(),
                  '/welcome': (context) => const Welcome(),
                  '/login': (context) => const LoginPage(),
                  '/register': (context) => const RegisterPage(),
                  '/forgot': (context) => const ForgotPage(),
                  '/announcement': (context) => const AnnouncementManagement(),
                  '/companymanager': (context) => const CompanyManager(),
                  '/round': (context) => const RoundManager(),
                  '/studentDetails': (context) => const StudentDetailsPage(),
                  '/facultyDetails': (context) => const FacultyDetailsPage(),
                },
              );
            },
          ),
        );
      },
    );
  }
}
