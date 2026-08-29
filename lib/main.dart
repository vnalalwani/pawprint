import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

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
    List<Dog> dogs = [];
    try {
      dogs = await repository.allDogs();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load Supabase records: $error')),
        );
      }
    }
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
      final savedDog = await _repository!.saveDog(dog);
      if (mounted) setState(() => _dogs = [savedDog, ..._dogs]);
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
        backgroundColor: const Color(0xfff5f3ee),
        toolbarHeight: 94,
        flexibleSpace: Center(
          child: Image.asset(
            'logo.png',
            width: 300,
            height: 94,
            fit: BoxFit.contain,
          ),
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                children: [
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
                'Keep your pawfriends close, safe, and connected.',
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
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => _DogDetailsPage(dog: dog)),
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      title: Text(
        dog.name.isEmpty ? 'Unnamed ${dog.animalCategory}' : dog.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        'Tag ID: ${dog.identification.isEmpty ? 'not set' : dog.identification}',
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipOval(
            child: SizedBox(
              width: 56,
              height: 56,
              child: dog.photoPath?.startsWith('http') ?? false
                  ? Image.network(
                      dog.photoPath!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _photoPlaceholder(context),
                    )
                  : _photoPlaceholder(context),
            ),
          ),
          const SizedBox(width: 10),
          Icon(
            dog.hasLocation
                ? Icons.location_on_rounded
                : Icons.location_off_outlined,
            color: dog.hasLocation ? const Color(0xff1c6b5a) : Colors.black26,
          ),
        ],
      ),
    ),
  );

  Widget _photoPlaceholder(BuildContext context) => Container(
    color: const Color(0xffdcefe7),
    child: Icon(
      Icons.pets_rounded,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

class _DogDetailsPage extends StatelessWidget {
  const _DogDetailsPage({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = dog.photoPath?.startsWith('http') ?? false;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dog details'),
        backgroundColor: const Color(0xfff5f3ee),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  dog.name.isEmpty ? 'Unnamed ${dog.animalCategory}' : dog.name,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(width: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: hasPhoto
                      ? Image.network(
                          dog.photoPath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              _detailPhotoPlaceholder(context),
                        )
                      : _detailPhotoPlaceholder(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Primary details',
            values: [
              _DetailValue('Animal category', dog.animalCategory),
              _DetailValue('Gender', _display(dog.gender)),
              _DetailValue('Age', _display(dog.age)),
              _DetailValue('Breed', _display(dog.breed)),
              _DetailValue('Color / Identifying marks', _display(dog.color)),
              _DetailValue('Notes', _display(dog.notes)),
              _DetailValue('Area', _display(dog.area)),
            ],
          ),
          if (dog.hasLocation)
            Padding(
              padding: const EdgeInsets.only(top: 16),
              child: InkWell(
                onTap: () => _openGoogleMaps(dog.latitude!, dog.longitude!),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Location',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _display(dog.address),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.blue,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to open in Google Maps',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),
          _DetailSection(
            title: 'Record information',
            values: [
              _DetailValue('Record ID', dog.id),
              _DetailValue('Created', _formatDate(dog.createdAt)),
              _DetailValue('Last updated', _formatDate(dog.updatedAt)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailPhotoPlaceholder(BuildContext context) => Container(
    color: const Color(0xffdcefe7),
    child: Icon(
      Icons.pets_rounded,
      size: 42,
      color: Theme.of(context).colorScheme.primary,
    ),
  );

  String _display(String? value) =>
      value == null || value.trim().isEmpty ? 'Not provided' : value;

  String _formatDate(DateTime value) => value.toLocal().toString();

  Future<void> _openGoogleMaps(double latitude, double longitude) async {
    final googleMapsUrl =
        'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    }
  }
}

class _DetailValue {
  const _DetailValue(this.label, this.value);

  final String label;
  final String value;
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.title, required this.values});

  final String title;
  final List<_DetailValue> values;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      const SizedBox(height: 8),
      ...values.map(
        (item) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 132,
                child: Text(
                  item.label,
                  style: const TextStyle(color: Colors.black54),
                ),
              ),
              Expanded(
                child: Text(
                  item.value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
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
  String _gender = '';
  final _age = TextEditingController();
  final _identifyingMarks = TextEditingController();
  final _notes = TextEditingController();
  final _address = TextEditingController();
  final _area = TextEditingController();
  Uint8List? _photoBytes;
  String? _photoName;
  String? _photoUrl;
  bool _gettingLocation = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _breed.text = 'Indie';
  }

  @override
  void dispose() {
    _name.dispose();
    _breed.dispose();
    _age.dispose();
    _identifyingMarks.dispose();
    _notes.dispose();
    _address.dispose();
    _area.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(source: source);
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      setState(() {
        _photoBytes = bytes;
        _photoName = file.name;
        _photoUrl = null;
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not load photo: $error')));
    }
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
    final recordId = DogRepository.newId();
    Navigator.pop(
      context,
      Dog(
        id: recordId,
        animalCategory: _animalCategory,
        name: _name.text.trim(),
        breed: _breed.text.trim(),
        photoBytes: _photoBytes,
        photoPath: _photoUrl,
        gender: _gender,
        age: _age.text.trim(),
        color: _identifyingMarks.text.trim(),
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
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.7;
    return AlertDialog(
      title: const Text('Record a stray dog'),
      content: SizedBox(
        width: 320,
        height: dialogHeight,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _animalCategory,
                  decoration: const InputDecoration(
                    labelText: 'Animal category',
                  ),
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
                    hintText: 'Furry friend\'s name',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _breed,
                  decoration: const InputDecoration(labelText: 'Breed'),
                ),
                const SizedBox(height: 8),
                if (_photoBytes != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _photoBytes!,
                        height: 140,
                        width: 320,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                if (_photoBytes != null) const SizedBox(height: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Photo',
                      style: TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        SizedBox(
                          width: 145,
                          child: OutlinedButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Take photo'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 145,
                          child: OutlinedButton.icon(
                            onPressed: () => _pickPhoto(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Browse photos'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_photoName != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        _photoName!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                DropdownButtonFormField<String>(
                  initialValue: _gender.isEmpty ? null : _gender,
                  decoration: const InputDecoration(labelText: 'Gender'),
                  items: const [
                    DropdownMenuItem(value: 'Male', child: Text('Male')),
                    DropdownMenuItem(value: 'Female', child: Text('Female')),
                    DropdownMenuItem(
                      value: 'Male Pup',
                      child: Text('Male Pup'),
                    ),
                    DropdownMenuItem(
                      value: 'Female Pup',
                      child: Text('Female Pup'),
                    ),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _gender = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _age,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                  validator: (value) =>
                      value != null &&
                          value.trim().isNotEmpty &&
                          int.tryParse(value.trim()) == null
                      ? 'Age must be a whole number'
                      : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _identifyingMarks,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Color / Identifying marks',
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _notes,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Notes'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _address,
                  decoration: const InputDecoration(
                    labelText: 'Address',
                    suffixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextButton.icon(
                        onPressed: _gettingLocation
                            ? null
                            : _useCurrentLocation,
                        icon: _gettingLocation
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.my_location),
                        label: const Text('Use current location'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _area,
                  decoration: const InputDecoration(
                    labelText: 'Building / Area',
                  ),
                ),
              ],
            ),
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
}
