import 'package:flutter/material.dart';

import 'data/dog_repository.dart';
import 'models/dog.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});

  final DogRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pawprint',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff1c6b5a)),
        scaffoldBackgroundColor: const Color(0xfff5f3ee),
        useMaterial3: true,
      ),
      home: HomePage(repository: repository),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.repository});

  final DogRepository? repository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _searchController = TextEditingController();
  DogRepository? _repository;
  List<Dog> _dogs = [];
  bool _loading = true;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
    _loadDogs();
  }

  Future<void> _loadDogs() async {
    final repository = widget.repository ?? await DogRepository.open();
    final dogs = await repository.allDogs();
    if (!mounted) return;
    setState(() {
      _repository = repository;
      _dogs = dogs;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _addDog() async {
    final dog = await showDialog<Dog>(
      context: context,
      builder: (_) => const _AddDogDialog(),
    );
    if (dog == null || _repository == null) return;
    await _repository!.saveDog(dog);
    if (mounted) setState(() => _dogs = [dog, ..._dogs]);
  }

  @override
  Widget build(BuildContext context) {
    final visibleDogs = _dogs.where((dog) {
      final text = '${dog.name} ${dog.breed} ${dog.identification}'
          .toLowerCase();
      return text.contains(_query);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text(
          'Pawprint',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.notifications_none_rounded),
          ),
          const Padding(
            padding: EdgeInsets.only(right: 20, left: 6),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xffe5b86d),
              child: Text(
                'VP',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xff4e3515),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDogs,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  Text(
                    'Good morning, volunteer',
                    style: Theme.of(context).textTheme.bodyLarge
                        ?.copyWith(color: Colors.black54),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Community dog registry',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: const Color(0xff173d36),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _WelcomePanel(onAddDog: _addDog),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _StatTile(
                        label: 'Registered',
                        value: '${_dogs.length}',
                        icon: Icons.pets_rounded,
                        color: const Color(0xffdcefe7),
                      ),
                      const SizedBox(width: 10),
                      _StatTile(
                        label: 'Located',
                        value:
                            '${_dogs.where((dog) => dog.hasLocation).length}',
                        icon: Icons.location_on_outlined,
                        color: const Color(0xfff5e8cd),
                      ),
                      const SizedBox(width: 10),
                      _StatTile(
                        label: 'Sterilized',
                        value:
                            '${_dogs.where((dog) => dog.sterilization == SterilizationStatus.yes).length}',
                        icon: Icons.favorite_border_rounded,
                        color: const Color(0xfff1dedb),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your records',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search by name, breed or ID',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: _searchController.clear,
                              icon: const Icon(Icons.close_rounded),
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  if (visibleDogs.isEmpty)
                    _EmptyState(onAddDog: _addDog)
                  else
                    ...visibleDogs.map((dog) => _DogTile(dog: dog)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Record dog'),
      ),
    );
  }
}

class _WelcomePanel extends StatelessWidget {
  const _WelcomePanel({required this.onAddDog});
  final VoidCallback onAddDog;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xff1c6b5a),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Every pawprint matters.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 6),
              Text(
                'Keep your neighborhood dogs visible, cared for, and connected.',
                style: TextStyle(color: Color(0xffd2ebe1), height: 1.35),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        IconButton.filled(
          onPressed: onAddDog,
          style: IconButton.styleFrom(
            backgroundColor: const Color(0xffe5b86d),
            foregroundColor: const Color(0xff173d36),
          ),
          icon: const Icon(Icons.add_rounded),
          tooltip: 'Record a dog',
        ),
      ],
    ),
  );
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label, value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: const Color(0xff24574b)),
          const SizedBox(height: 9),
          Text(
            value,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    ),
  );
}

class _DogTile extends StatelessWidget {
  const _DogTile({required this.dog});
  final Dog dog;

  @override
  Widget build(BuildContext context) => Card(
    margin: const EdgeInsets.only(bottom: 10),
    elevation: 0,
    color: Colors.white,
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      leading: CircleAvatar(
        backgroundColor: const Color(0xffdcefe7),
        child: Icon(
          Icons.pets_rounded,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      title: Text(
        dog.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${dog.breed}  -  ID ${dog.identification.isEmpty ? 'not set' : dog.identification}',
      ),
      trailing: Icon(
        dog.hasLocation
            ? Icons.location_on_rounded
            : Icons.location_off_outlined,
        color: dog.hasLocation ? const Color(0xff1c6b5a) : Colors.black26,
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAddDog});
  final VoidCallback onAddDog;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 38),
    child: Column(
      children: [
        const Icon(Icons.pets_outlined, size: 42, color: Colors.black26),
        const SizedBox(height: 10),
        const Text(
          'No dogs recorded yet',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        const Text(
          'Start building your neighborhood registry.',
          style: TextStyle(color: Colors.black54),
        ),
        const SizedBox(height: 14),
        OutlinedButton.icon(
          onPressed: onAddDog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add first dog'),
        ),
      ],
    ),
  );
}

class _AddDogDialog extends StatefulWidget {
  const _AddDogDialog();

  @override
  State<_AddDogDialog> createState() => _AddDogDialogState();
}

class _AddDogDialogState extends State<_AddDogDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _id = TextEditingController();
  final _location = TextEditingController();

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _id.dispose();
    _location.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.pop(
      context,
      Dog(
        id: DogRepository.newId(),
        name: _name.text.trim(),
        breed: _breed.text.trim(),
        identification: _id.text.trim(),
        locationNote: _location.text.trim(),
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Record a stray dog'),
    content: Form(
      key: _formKey,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'A friendly name',
              ),
              validator: (value) =>
                  value == null || value.trim().isEmpty ? 'Add a name' : null,
            ),
            TextFormField(
              controller: _breed,
              decoration: const InputDecoration(
                labelText: 'Breed / description',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Add a description'
                  : null,
            ),
            TextFormField(
              controller: _id,
              decoration: const InputDecoration(
                labelText: 'Tag or ID (optional)',
              ),
            ),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: 'Where found (optional',
              ),
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
      FilledButton(onPressed: _save, child: const Text('Save record')),
    ],
  );
}
