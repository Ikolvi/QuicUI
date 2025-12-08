import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() async {
  const supabaseUrl = 'https://pcaxvanjhtfaeimflgfk.supabase.co';
  const anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBjYXh2YW5qaHRmYWVpbWZsZ2ZrIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MzI2MjkyNDEsImV4cCI6MjA0ODIwNTI0MX0.jNRkjfhTmNH9lZdxxXhB4OjKQHKBOBvqcfzZOEP7t_0';
  
  print('🗑️  Deleting old patch for v3.0.46...');
  
  // Delete the old patch
  final deleteResponse = await http.delete(
    Uri.parse('$supabaseUrl/rest/v1/patches?app_id=eq.com.example.quicuiProductionTest&version=eq.3.0.46&platform=eq.ios'),
    headers: {
      'apikey': anonKey,
      'Authorization': 'Bearer $anonKey',
      'Content-Type': 'application/json',
    },
  );
  
  if (deleteResponse.statusCode == 204 || deleteResponse.statusCode == 200) {
    print('✅ Old patch deleted successfully');
  } else {
    print('⚠️  Delete response: ${deleteResponse.statusCode} - ${deleteResponse.body}');
  }
  
  print('');
  print('Now run: dart run ../../packages/quicui_cli/bin/quicui.dart upload-patch --patch 1764327189870');
}
