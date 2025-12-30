import 'package:app/pages/landing_page.dart';
import 'package:app/pages/login_page.dart';
import 'package:app/pages/register_page.dart';
import 'package:app/services/auth_service.dart';
import 'package:chat_plugin/chat_plugin.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light
  ));

  final isLoggedIn = await AuthService.isLoggedIn();

  if(isLoggedIn == true){
    await AuthService.initializeChatPlugin();
  }
  runApp(MyApp(isLoggedIn: isLoggedIn!,));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver{


@override
void initState() {
  super.initState();

  WidgetsBinding.instance.addObserver(this);

  if(widget.isLoggedIn){
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureChatConnection();
    });
  }
}

void _ensureChatConnection() async {
  if(ChatConfig.instance.userId != null) {
    try {
      final chatService = ChatPlugin.chatService;
      if(!chatService.isSocketConnected){
        await chatService.initGlobalConnection();
      }else {
        chatService.refreshGlobalConnection();
      }

      chatService.updateUserStatus(true);
    }catch(err) {
      debugPrint('Error establishing connection');
    }
  }else {
    await AuthService.initializeChatPlugin();
  }
}


@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if(!widget.isLoggedIn) true;

  if(state == AppLifecycleState.resumed){
    _ensureChatConnection();
  }
  else if(state == AppLifecycleState.paused){
    try{
      final chatService = ChatPlugin.chatService;
      chatService.updateUserStatus(false);
    }catch(err){}
  }
}

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => InitializerWidget(),
         '/landing': (context) => const LandingScreen(),
          '/login': (context) => const LoginScreen(),
           '/register': (context) => RegisterScreen(),
            '/directMessages': (context) => InitializerWidget(),
      },
    );
  }
}

class InitializerWidget extends StatefulWidget {
  const InitializerWidget({super.key});

  @override
  State<InitializerWidget> createState() => _InitializerWidgetState();
}

class _InitializerWidgetState extends State<InitializerWidget> {
  String? initialRoute;

@override
void initState(){
  super.initState();
  _checkLogin();
}

Future<void> _checkLogin() async{
  final isLoggedIn = await AuthService.isLoggedIn();
  if(isLoggedIn == true){
    initialRoute = '/directMessages';
  }else{
    initialRoute = '/landing';
  }

  Navigator.of(context).pushReplacementNamed(initialRoute!);
}

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}



