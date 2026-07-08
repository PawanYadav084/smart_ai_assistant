// import '../../home/presentation/home_screen.dart';
// import 'package:flutter/material.dart';

// class HomeScreen extends StatelessWidget {
//   const HomeScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Home"),
//         centerTitle: true,
//       ),
//       body: const Center(
//         child: Text(
//           "Welcome Home 🎉",
//           style: TextStyle(
//             fontSize: 28,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//       ),
//     );
//   }
// }






import '../../chat/presentation/chat_screen.dart';
import '../../../shared/widgets/feature_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFF6A11CB),
              Color(0xFF2575FC),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [

              // Greeting
              Align(
                alignment: Alignment.centerLeft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      "👋 Good Morning",
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey,
                      ),
                    ),

                    SizedBox(height: 5),

                    Text(
                      "Pawan Yadav",
                      style: TextStyle(
                        fontSize: 30,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Image.asset(
                "assets/images/ai_logo.png",
                width: 140,
              ),

              const SizedBox(height: 30),

              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                  childAspectRatio: 1.1,
                  children: [
                    FeatureCard(
                      icon: Icons.chat_bubble_outline,
                      title: "New Chat",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ChatScreen(),
                          ),
                        );
                      },
                    ),
                    FeatureCard(
                      icon: Icons.image_outlined,
                      title: "Scan Image",
                      onTap: () {
                        debugPrint("Scan Image");
                      },
                    ),
                    FeatureCard(
                      icon: Icons.mic_none,
                      title: "Voice Assistant",
                      onTap: () {
                        debugPrint("Voice Assistant");
                      },
                    ),
                    FeatureCard(
                      icon: Icons.picture_as_pdf_outlined,
                      title: "Summarize PDF",
                      onTap: () {
                        debugPrint("Summarize PDF");
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
      