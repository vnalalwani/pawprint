import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import 'config/supabase_config.dart';

import 'data/dog_repository.dart';
import 'models/dog.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, this.repository});

  final DogRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'pawhere',
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
    try {
      await _repository!.saveDog(dog);
      if (mounted) setState(() => _dogs = [dog, ..._dogs]);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save to Supabase: $error')),
      );
    }
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
        title: Image.asset(
          'logo.png',
          width: 132,
          height: 48,
          fit: BoxFit.contain,
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
  String _animalCategory = 'dog';
  final _name = TextEditingController();
  final _breed = TextEditingController();
  final _id = TextEditingController();
  final _gender = TextEditingController();
  final _age = TextEditingController();
  final _color = TextEditingController();
  final _identifyingMarks = TextEditingController();
  final _notes = TextEditingController();
  final _address = TextEditingController();
  final _area = TextEditingController();
  Uint8List? _photoBytes;
  String? _photoName;
  bool _gettingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _id.dispose();
    _gender.dispose();
    _age.dispose();
    _color.dispose();
    _identifyingMarks.dispose();
    _notes.dispose();
    _address.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    final file = await ImagePicker().pickImage(source: source);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    setState(() {
      _photoBytes = bytes;
      _photoName = file.name;
    });
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception('Location services are disabled on this device.');
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      _address.text =
          'Current location: ${position.latitude.toStringAsFixed(6)}, '
          '${position.longitude.toStringAsFixed(6)}';
      _latitude = position.latitude;
      _longitude = position.longitude;
      setState(() {});
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not get current location: $error')),
      );
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final now = DateTime.now();
    Navigator.pop(
      context,
      Dog(
        id: DogRepository.newId(),
        animalCategory: _animalCategory,
        name: _name.text.trim(),
        breed: _breed.text.trim(),
        identification: _id.text.trim(),
        photoBytes: _photoBytes,
        gender: _gender.text.trim(),
        age: _age.text.trim(),
        color: _color.text.trim(),
        identifyingMarks: _identifyingMarks.text.trim(),
        medicalIssues: _identifyingMarks.text.trim(),
        notes: _notes.text.trim(),
        address: _address.text.trim(),
        locationNote: _address.text.trim(),
        area: _area.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
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
            DropdownButtonFormField<String>(
              initialValue: _animalCategory,
              decoration: const InputDecoration(labelText: 'Animal category'),
              items: const [
                DropdownMenuItem(value: 'dog', child: Text('Dog')),
                DropdownMenuItem(value: 'cat', child: Text('Cat')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _animalCategory = value);
              },
            ),
            TextFormField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'A friendly name',
              ),
            ),
            TextFormField(
              controller: _breed,
              decoration: const InputDecoration(
                labelText: 'Breed / description',
              ),
            ),
            TextFormField(
              controller: _id,
              decoration: const InputDecoration(
                labelText: 'Tag or ID (optional)',
              ),
            ),
            if (_photoBytes != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.memory(
                    _photoBytes!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take photo'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickPhoto(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Browse photos'),
                  ),
                ),
              ],
            ),
            if (_photoName != null)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _photoName!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ),
            TextFormField(
              controller: _gender,
              decoration: const InputDecoration(labelText: 'Gender (optional)'),
            ),
            TextFormField(
              controller: _age,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Age (optional)'),
              validator: (value) =>
                  value != null &&
                      value.trim().isNotEmpty &&
                      int.tryParse(value.trim()) == null
                  ? 'Age must be a whole number'
                  : null,
            ),
            TextFormField(
              controller: _color,
              decoration: const InputDecoration(labelText: 'Color (optional)'),
            ),
            TextFormField(
              controller: _identifyingMarks,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Identifying marks (optional)',
              ),
            ),
            TextFormField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Notes (optional)'),
            ),
            TextFormField(
              controller: _address,
              decoration: const InputDecoration(
                labelText: 'Address (optional)',
                suffixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _gettingLocation ? null : _useCurrentLocation,
                icon: _gettingLocation
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.my_location),
                label: const Text('Use current location'),
              ),
            ),
            TextFormField(
              controller: _area,
              decoration: const InputDecoration(labelText: 'Area (optional)'),
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
