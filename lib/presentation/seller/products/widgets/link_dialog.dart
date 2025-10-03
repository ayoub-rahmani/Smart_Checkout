// presentation/seller/products/widgets/link_dialog.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class LinkDialog extends StatelessWidget {
  final String productName;
  final String productLink;
  final String qrData;

  const LinkDialog({
    super.key,
    required this.productName,
    required this.productLink,
    required this.qrData,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.link, size: 48, color: Colors.blue),
            const SizedBox(height: 16),
            Text(
              'Product Link',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              productName,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: SelectableText(
                productLink,
                style: const TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: productLink));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied to clipboard!')),
                      );
                    },
                    icon: const Icon(Icons.copy),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      // You can add a QR code viewer here
                      _showQRCode(context);
                    },
                    icon: const Icon(Icons.qr_code),
                    label: const Text('QR Code'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Implement share functionality
                  _shareLink(context);
                },
                child: const Text('Share Link'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Add QR code widget here
            Container(
              width: 200,
              height: 200,
              color: Colors.grey[200],
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.qr_code, size: 64, color: Colors.grey),
                  SizedBox(height: 8),
                  Text('QR Code Preview'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Scan to view: $productName',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _shareLink(BuildContext context) async {
    // This would use the share_plus package
    // For now, just copy to clipboard
    Clipboard.setData(ClipboardData(text: productLink));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Link copied! Share it anywhere.')),
    );
  }
}