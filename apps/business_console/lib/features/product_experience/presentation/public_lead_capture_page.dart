import 'package:flutter/material.dart';
import '../data/business_product_repository.dart';

class PublicLeadCapturePage extends StatefulWidget {
  const PublicLeadCapturePage({
    super.key,
    required this.repository,
    this.tenantId = 'synthetic-tenant',
    this.initialMessage,
  });
  final BusinessProductRepository repository;
  final String tenantId;
  final String? initialMessage;
  @override
  State<PublicLeadCapturePage> createState() => _PublicLeadCapturePageState();
}

class _PublicLeadCapturePageState extends State<PublicLeadCapturePage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final message = TextEditingController();
  bool busy = false;
  bool submitted = false;

  @override
  void initState() {
    super.initState();
    message.text = widget.initialMessage ?? '';
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    message.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (name.text.trim().isEmpty || phone.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and phone are required')),
      );
      return;
    }
    setState(() => busy = true);
    try {
      await widget.repository.submitPublicLead(widget.tenantId, {
        'full_name': name.text.trim(),
        'phone': phone.text.trim(),
        'email': email.text.trim(),
        'message': message.text.trim(),
      });
      if (mounted) {
        setState(() {
          busy = false;
          submitted = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => busy = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contact us')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: submitted
                ? Semantics(
                    container: true,
                    label: 'Lead submitted',
                    child: const Text('Thanks. Our team will contact you soon.'),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Plan your journey',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: name,
                        decoration: const InputDecoration(
                          labelText: 'Full name',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: email,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: message,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'How can we help?',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: busy ? null : submit,
                          child: busy
                              ? const CircularProgressIndicator()
                              : const Text('Send request'),
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
