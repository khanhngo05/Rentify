import 'package:url_launcher/url_launcher.dart';

import '../models/branch_model.dart';

class BranchDetailViewModel {
  const BranchDetailViewModel({
    required this.branch,
    required this.distanceText,
    required this.openLabel,
    required this.closeLabel,
    required this.isOpen,
  });

  final BranchModel branch;
  final String distanceText;
  final String openLabel;
  final String closeLabel;
  final bool isOpen;

  String get statusDetail =>
      isOpen ? 'Đóng lúc $closeLabel' : 'Mở lại lúc $openLabel';

  Future<void> openDirections() async {
    final destination = '${branch.latitude},${branch.longitude}';
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$destination&travelmode=driving',
    );

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }
}
