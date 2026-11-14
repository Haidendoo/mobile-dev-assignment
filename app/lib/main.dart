import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import 'data/campaign_repository.dart';
import 'ui/campaign_app.dart';
import 'ui/forest_theme.dart';
import 'viewmodels/campaign_view_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  runApp(const _Bootstrap());
}

class _Bootstrap extends StatefulWidget {
  const _Bootstrap();
  @override
  State<_Bootstrap> createState() => _BootstrapState();
}

class _BootstrapState extends State<_Bootstrap> {
  CampaignViewModel? _model;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    setState(() => _failed = false);
    try {
      final repository = await SqliteCampaignRepository.open();
      if (!mounted) {
        await repository.close();
        return;
      }
      final model = CampaignViewModel(repository);
      setState(() => _model = model);
      await model.initialize();
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  void dispose() {
    _model?.dispose();
    _model?.repository.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _model != null
      ? CampaignApp(model: _model!)
      : MaterialApp(
          theme: forestTheme(),
          home: Scaffold(
            body: Center(
              child: _failed
                  ? Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('Local storage could not be opened.'),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _open,
                          child: const Text('Retry'),
                        ),
                      ],
                    )
                  : const CircularProgressIndicator(),
            ),
          ),
        );
}
