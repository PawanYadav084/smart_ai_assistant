import 'package:flutter/material.dart';
import '../../../core/theme/theme_service.dart';



class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ThemeService _themeService = ThemeService.instance;

  @override
  void initState() {
    super.initState();
    _themeService.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          const SizedBox(height: 12),

        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Theme'),
          subtitle: Text(_themeService.themeMode.name.toUpperCase()),
          trailing: DropdownButton<ThemeMode>(
            value: _themeService.themeMode,
            underline: const SizedBox(),
            onChanged: (mode) async {
              if (mode == null) return;

              await _themeService.setThemeMode(mode);

              if (mounted) {
                setState(() {});
              }
            },
            items: const [
              DropdownMenuItem(
                value: ThemeMode.system,
                child: Text("System"),
              ),
              DropdownMenuItem(
                value: ThemeMode.light,
                child: Text("Light"),
              ),
              DropdownMenuItem(
                value: ThemeMode.dark,
                child: Text("Dark"),
              ),
            ],
          ),
        ),

          const Divider(height: 1),

          const ListTile(
            leading: Icon(Icons.smart_toy_outlined),
            title: Text('AI Provider'),
            subtitle: Text('Groq'),
            trailing: Icon(Icons.chevron_right),
          ),

          const Divider(height: 1),

          SwitchListTile(
            value: true,
            onChanged: (_) {},
            secondary: const Icon(Icons.travel_explore),
            title: const Text('Web Search'),
            subtitle: const Text('Use Tavily for internet search'),
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('Clear Chat History'),
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: () {},
          ),

          const Divider(height: 1),

          const AboutListTile(
            icon: Icon(Icons.info_outline),
            applicationName: 'Smart AI Assistant',
            applicationVersion: '1.0.0',
            applicationLegalese: '© 2026 Pawan Kumar',
          ),
        ],
      ),
        );
      },
    );
  }
}