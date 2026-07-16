
import '../../chat/presentation/chat_screen.dart';
import '../../../shared/widgets/feature_card.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      body: Container(
        width: double.infinity,
        color: colors.surface,
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
                  children: [
                    Text(
                      "👋 Good Morning",
                      style: TextStyle(
                        fontSize: 18,
                        color: colors.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 5),

                    Text(
                      "Pawan Yadav",
                      style: TextStyle(
                        fontSize: 30,
                        color: colors.onSurface,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Image.asset(
                  "assets/images/ai_logo.png",
                  width: 140,
                ),
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
      