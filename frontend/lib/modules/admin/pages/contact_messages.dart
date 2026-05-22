import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/api_config.dart';
import '../../../core/services/auth_service.dart';

class ContactMessagesPage extends StatefulWidget {
  const ContactMessagesPage({super.key});

  @override
  State<ContactMessagesPage> createState() => _ContactMessagesPageState();
}

class _ContactMessagesPageState extends State<ContactMessagesPage> {
  List<dynamic> messages = [];
  bool isLoading = true;
  String? error;
  String searchQuery = '';
  String statusFilter = 'all';

  // Stats
  Map<String, int> stats = {
    'total': 0,
    'new': 0,
    'read': 0,
    'replied': 0,
    'archived': 0,
  };

  @override
  void initState() {
    super.initState();
    fetchMessages();
    fetchStats();
  }

  Future<void> fetchMessages() async {
    try {
      setState(() => isLoading = true);
      
      final token = await AuthService().getAccessToken();
      
      String url = '${ApiConfig.contactMessages}?';
      if (statusFilter != 'all') {
        url += 'status=$statusFilter&';
      }
      if (searchQuery.isNotEmpty) {
        url += 'search=$searchQuery';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          messages = data['results'] ?? data;
          isLoading = false;
        });
      } else if (response.statusCode == 401) {
        // Token expired, try to refresh
        final refreshed = await AuthService().refreshToken();
        if (refreshed) {
          fetchMessages(); // Retry
        } else {
          setState(() {
            error = 'Session expired. Please login again.';
            isLoading = false;
          });
        }
      } else {
        throw Exception('Failed to load messages: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        error = e.toString();
        isLoading = false;
      });
    }
  }

  Future<void> fetchStats() async {
    try {
      final token = await AuthService().getAccessToken();
      final response = await http.get(
        Uri.parse(ApiConfig.contactStats),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          stats = Map<String, int>.from(data);
        });
      }
    } catch (e) {
      // Silently fail for stats
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      final token = await AuthService().getAccessToken();
      await http.patch(
        Uri.parse(ApiConfig.contactMessageDetail(id)),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'status': status}),
      );
      fetchMessages();
      fetchStats();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  Future<void> deleteMessage(int id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message'),
        content: const Text('Are you sure you want to delete this message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final token = await AuthService().getAccessToken();
        await http.delete(
          Uri.parse(ApiConfig.contactMessageDetail(id)),
          headers: {
            if (token != null) 'Authorization': 'Bearer $token',
          },
        );
        fetchMessages();
        fetchStats();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting message: $e')),
        );
      }
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'new':
        return Colors.blue;
      case 'read':
        return Colors.orange;
      case 'replied':
        return Colors.green;
      case 'archived':
        return Colors.grey;
      default:
        return Colors.blue;
    }
  }

  void showReplyDialog(dynamic message) {
    final subjectController = TextEditingController(
      text: 'RE: Message from ${message['full_name']}',
    );
    final bodyController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${message['full_name']}'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 500, maxWidth: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('To: ${message['email']}'),
                const SizedBox(height: 16),
                TextField(
                  controller: subjectController,
                  decoration: const InputDecoration(
                    labelText: 'Subject',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: bodyController,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  maxLines: 8,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              sendReply(
                message['id'],
                subjectController.text,
                bodyController.text,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }

  Future<void> sendReply(int id, String subject, String body) async {
    if (subject.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Subject and message are required')),
      );
      return;
    }

    try {
      final token = await AuthService().getAccessToken();
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/contact/messages/$id/reply/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'subject': subject,
          'message': body,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Reply sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        fetchMessages();
        fetchStats();
      } else {
        final error = jsonDecode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error['error'] ?? 'Failed to send reply'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats Cards
            _buildStatsRow(),
            const SizedBox(height: 24),
            
            // Filters
            _buildFilters(),
            const SizedBox(height: 16),
            
            // Messages List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : error != null
                      ? Center(child: Text('Error: $error'))
                      : messages.isEmpty
                          ? const Center(child: Text('No messages found'))
                          : _buildMessagesList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _buildStatCard('Total', stats['total'] ?? 0, Colors.blue),
        _buildStatCard('New', stats['new'] ?? 0, Colors.blue.shade700),
        _buildStatCard('Read', stats['read'] ?? 0, Colors.orange),
        _buildStatCard('Replied', stats['replied'] ?? 0, Colors.green),
        _buildStatCard('Archived', stats['archived'] ?? 0, Colors.grey),
      ],
    );
  }

  Widget _buildStatCard(String title, int count, Color color) {
    return Container(
      width: 120,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Row(
      children: [
        // Search
        Expanded(
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search messages...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onChanged: (value) {
              searchQuery = value;
              fetchMessages();
            },
          ),
        ),
        const SizedBox(width: 16),
        
        // Status Filter
        DropdownButton<String>(
          value: statusFilter,
          items: const [
            DropdownMenuItem(value: 'all', child: Text('All Status')),
            DropdownMenuItem(value: 'new', child: Text('New')),
            DropdownMenuItem(value: 'read', child: Text('Read')),
            DropdownMenuItem(value: 'replied', child: Text('Replied')),
            DropdownMenuItem(value: 'archived', child: Text('Archived')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => statusFilter = value);
              fetchMessages();
            }
          },
        ),
        
        const SizedBox(width: 16),
        
        // Refresh Button
        IconButton(
          onPressed: () {
            fetchMessages();
            fetchStats();
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
    );
  }

  Widget _buildMessagesList() {
    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ExpansionTile(
            leading: CircleAvatar(
              backgroundColor: _getStatusColor(message['status']).withOpacity(0.1),
              child: Icon(
                Icons.message,
                color: _getStatusColor(message['status']),
              ),
            ),
            title: Text(message['full_name'] ?? 'Unknown'),
            subtitle: Text(message['email'] ?? ''),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Chip(
                  label: Text(
                    message['status'].toUpperCase(),
                    style: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  backgroundColor: _getStatusColor(message['status']),
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => showReplyDialog(message),
                  icon: const Icon(Icons.reply, color: Colors.blue),
                  tooltip: 'Reply via Email',
                ),
                PopupMenuButton<String>(
                  onSelected: (value) => updateStatus(message['id'], value),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'new', child: Text('Mark as New')),
                    const PopupMenuItem(value: 'read', child: Text('Mark as Read')),
                    const PopupMenuItem(value: 'replied', child: Text('Mark as Replied')),
                    const PopupMenuItem(value: 'archived', child: Text('Archive')),
                  ],
                ),
                IconButton(
                  onPressed: () => deleteMessage(message['id']),
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
              ],
            ),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow('Phone', message['phone'] ?? 'N/A'),
                    const SizedBox(height: 8),
                    _buildDetailRow('Date', message['created_at']?.toString() ?? 'N/A'),
                    const SizedBox(height: 16),
                    const Text(
                      'Message:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(message['message'] ?? ''),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label: ',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(value),
      ],
    );
  }
}
