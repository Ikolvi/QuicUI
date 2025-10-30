# Supabase + QuicUI Examples

**Complete, Ready-to-Use Examples**

---

## Example 1: Todo App with Real-time Sync

### Step 1: Create Supabase Table

```sql
CREATE TABLE todos (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id),
  title TEXT NOT NULL,
  description TEXT,
  completed BOOLEAN DEFAULT FALSE,
  priority TEXT DEFAULT 'medium',
  due_date DATE,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE todos ENABLE ROW LEVEL SECURITY;

-- Only users can see their own todos
CREATE POLICY "Users can view their own todos"
ON todos FOR SELECT
USING (auth.uid() = user_id);

-- Only users can create their own todos
CREATE POLICY "Users can create todos"
ON todos FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Only users can update their own todos
CREATE POLICY "Users can update their own todos"
ON todos FOR UPDATE
USING (auth.uid() = user_id);

-- Only users can delete their own todos
CREATE POLICY "Users can delete their own todos"
ON todos FOR DELETE
USING (auth.uid() = user_id);

-- Enable realtime
ALTER PUBLICATION supabase_realtime ADD TABLE todos;
```

### Step 2: Flutter Implementation

```dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:quicui/quicui.dart';

class TodoAppWithSupabase extends StatefulWidget {
  const TodoAppWithSupabase({Key? key}) : super(key: key);

  @override
  State<TodoAppWithSupabase> createState() => _TodoAppWithSupabaseState();
}

class _TodoAppWithSupabaseState extends State<TodoAppWithSupabase> {
  final supabase = Supabase.instance.client;
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  
  late RealtimeChannel todosChannel;
  List<Map<String, dynamic>> todos = [];
  
  @override
  void initState() {
    super.initState();
    setupRealtimeListener();
    loadTodos();
  }
  
  void setupRealtimeListener() {
    todosChannel = supabase
      .channel('todos')
      .on(
        RealtimeListenTypes.postgresChanges,
        ChannelFilter(
          event: '*',
          schema: 'public',
          table: 'todos',
          filter: 'user_id=eq.${supabase.auth.currentUser?.id}',
        ),
        (payload, [ref]) {
          print('Change received: ${payload.eventType}');
          loadTodos(); // Refresh list on any change
        },
      )
      .subscribe();
  }
  
  Future<void> loadTodos() async {
    final userId = supabase.auth.currentUser?.id;
    
    final response = await supabase
      .from('todos')
      .select()
      .eq('user_id', userId!)
      .order('created_at', ascending: false);
    
    setState(() {
      todos = List<Map<String, dynamic>>.from(response);
    });
  }
  
  Future<void> addTodo() async {
    if (titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }
    
    final userId = supabase.auth.currentUser?.id;
    
    await supabase.from('todos').insert({
      'user_id': userId,
      'title': titleController.text,
      'description': descriptionController.text,
      'priority': 'medium',
    });
    
    titleController.clear();
    descriptionController.clear();
  }
  
  Future<void> toggleTodo(String id, bool completed) async {
    await supabase
      .from('todos')
      .update({'completed': !completed})
      .eq('id', id);
  }
  
  Future<void> deleteTodo(String id) async {
    await supabase.from('todos').delete().eq('id', id);
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Realtime Todos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Todo Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description (optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: addTodo,
                  child: const Text('Add Todo'),
                ),
              ],
            ),
          ),
          Expanded(
            child: todos.isEmpty
              ? const Center(child: Text('No todos yet!'))
              : ListView.builder(
                  itemCount: todos.length,
                  itemBuilder: (context, index) {
                    final todo = todos[index];
                    return ListTile(
                      leading: Checkbox(
                        value: todo['completed'] ?? false,
                        onChanged: (_) => toggleTodo(
                          todo['id'],
                          todo['completed'] ?? false,
                        ),
                      ),
                      title: Text(
                        todo['title'],
                        style: TextStyle(
                          decoration: todo['completed'] ?? false
                            ? TextDecoration.lineThrough
                            : null,
                        ),
                      ),
                      subtitle: Text(
                        todo['description'] ?? '',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => deleteTodo(todo['id']),
                      ),
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
  
  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    todosChannel.unsubscribe();
    super.dispose();
  }
}
```

---

## Example 2: Product Catalog with Offline Support

### Database Setup

```sql
CREATE TABLE products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name TEXT NOT NULL,
  description TEXT,
  price DECIMAL(10, 2) NOT NULL,
  image_url TEXT,
  stock_quantity INTEGER DEFAULT 0,
  category TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

CREATE INDEX idx_products_category ON products(category);
```

### Flutter Implementation

```dart
class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({Key? key}) : super(key: key);

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final supabase = Supabase.instance.client;
  final service = QuicUIService();
  
  List<Map<String, dynamic>> products = [];
  List<Map<String, dynamic>> localProducts = [];
  bool isOnline = true;
  
  @override
  void initState() {
    super.initState();
    monitorConnectivity();
    loadProducts();
  }
  
  void monitorConnectivity() async {
    final connectivity = Connectivity();
    connectivity.onConnectivityChanged.listen((result) {
      setState(() {
        isOnline = result != ConnectivityResult.none;
      });
      
      if (isOnline) {
        syncProducts();
      }
    });
  }
  
  Future<void> loadProducts() async {
    try {
      // Try to load from cloud first
      final response = await supabase
        .from('products')
        .select()
        .order('created_at', ascending: false)
        .timeout(const Duration(seconds: 5));
      
      setState(() {
        products = List<Map<String, dynamic>>.from(response);
      });
      
      // Cache locally
      await service.cacheProducts(products);
    } catch (e) {
      print('Cloud load error: $e');
      
      // Fallback to local cache
      localProducts = await service.getCachedProducts();
      setState(() {
        products = localProducts;
      });
    }
  }
  
  Future<void> syncProducts() async {
    // Sync local changes to cloud
    final unsyncedProducts = await service.getUnsyncedProducts();
    
    for (var product in unsyncedProducts) {
      try {
        await supabase.from('products').upsert(product);
        await service.markProductAsSynced(product['id']);
      } catch (e) {
        print('Sync error: $e');
      }
    }
    
    // Reload from cloud
    loadProducts();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                isOnline ? '🟢 Online' : '🔴 Offline',
                style: const TextStyle(fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      body: products.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ProductCard(product: product);
            },
          ),
    );
  }
}

class ProductCard extends StatelessWidget {
  final Map<String, dynamic> product;
  
  const ProductCard({required this.product, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Image.network(
              product['image_url'] ?? '',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Placeholder(),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '\$${product['price']}',
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Stock: ${product['stock_quantity']}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## Example 3: User Profile with Image Upload

### Database Setup

```sql
CREATE TABLE user_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) UNIQUE,
  name TEXT,
  bio TEXT,
  profile_picture_url TEXT,
  location TEXT,
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE user_profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all profiles"
ON user_profiles FOR SELECT
USING (true);

CREATE POLICY "Users can update their own profile"
ON user_profiles FOR UPDATE
USING (auth.uid() = user_id);
```

### Storage Setup

In Supabase dashboard:
1. Go to Storage
2. Create a bucket named "profiles"
3. Set permissions to allow authenticated users to upload

### Flutter Implementation

```dart
import 'package:image_picker/image_picker.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final supabase = Supabase.instance.client;
  final imagePicker = ImagePicker();
  
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isUploading = false;
  
  @override
  void initState() {
    super.initState();
    loadUserProfile();
  }
  
  Future<void> loadUserProfile() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      
      final response = await supabase
        .from('user_profiles')
        .select()
        .eq('user_id', userId!)
        .single();
      
      setState(() {
        userProfile = response;
        isLoading = false;
      });
    } catch (e) {
      print('Load error: $e');
      setState(() => isLoading = false);
    }
  }
  
  Future<void> uploadProfilePicture() async {
    try {
      final image = await imagePicker.pickImage(source: ImageSource.gallery);
      if (image == null) return;
      
      setState(() => isUploading = true);
      
      final userId = supabase.auth.currentUser!.id;
      final fileName = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      
      // Upload to storage
      await supabase.storage.from('profiles').upload(
        fileName,
        File(image.path),
        fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
      );
      
      // Get public URL
      final imageUrl = supabase.storage.from('profiles').getPublicUrl(fileName);
      
      // Update profile
      await supabase
        .from('user_profiles')
        .upsert({
          'user_id': userId,
          'profile_picture_url': imageUrl,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .select();
      
      // Reload profile
      loadUserProfile();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture updated!')),
      );
    } catch (e) {
      print('Upload error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: $e')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => supabase.auth.signOut(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 80,
                  backgroundImage: userProfile?['profile_picture_url'] != null
                    ? NetworkImage(userProfile!['profile_picture_url'])
                    : null,
                  child: userProfile?['profile_picture_url'] == null
                    ? const Icon(Icons.person, size: 80)
                    : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: FloatingActionButton(
                    mini: true,
                    onPressed: uploadProfilePicture,
                    child: isUploading
                      ? const CircularProgressIndicator()
                      : const Icon(Icons.camera_alt),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              userProfile?['name'] ?? 'User',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              userProfile?['bio'] ?? 'No bio yet',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location: ${userProfile?['location'] ?? 'Not set'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Joined: ${userProfile?['created_at']?.toString().split('T').first ?? ''}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## Running the Examples

1. **Set up Supabase project** with tables above
2. **Update initialization** in main.dart:
   ```dart
   await QuicUIService().initialize(
     appApiKey: 'your-app-api-key',
     supabaseUrl: 'https://your-project.supabase.co',
     supabaseAnonKey: 'your-supabase-anon-key',
   );
   ```
3. **Run the app**: `flutter run`

---

## Key Takeaways

✅ Real-time updates with PostgreSQL changes  
✅ Offline-first with local caching  
✅ Secure with Row Level Security  
✅ Easy file uploads with Storage  
✅ Complete user authentication

---

**Last Updated:** October 30, 2025  
**QuicUI Version:** 1.0.0
