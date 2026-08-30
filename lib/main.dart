import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/supabase_config.dart';

import 'data/dog_repository.dart';
import 'models/dog.dart';
import 'models/dog_health_details.dart';
import 'models/medical_note.dart';

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
  bool _filterSterilized = false;
  bool _filterRabies = false;
  bool _filterNineInOne = false;

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
    final draft = await showDialog<_DogRecordDraft>(
      context: context,
      builder: (_) => const _AddDogDialog(),
    );
    if (draft == null || _repository == null) return;
    try {
      final savedDog = await _repository!.saveDog(draft.dog);
      await _repository!.saveHealthDetails(draft.healthDetails);
      if (mounted) setState(() => _dogs = [savedDog, ..._dogs]);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save to Supabase: $error')),
      );
    }
  }

  Future<void> _editDog(Dog dog) async {
    final draft = await showDialog<_DogRecordDraft>(
      context: context,
      builder: (_) => _AddDogDialog(dog: dog),
    );
    if (draft == null || _repository == null) return;
    try {
      final savedDog = await _repository!.saveDog(draft.dog);
      await _repository!.saveHealthDetails(draft.healthDetails);
      if (!mounted) return;
      setState(() {
        _dogs = _dogs
            .map(
              (existingDog) =>
                  existingDog.id == savedDog.id ? savedDog : existingDog,
            )
            .toList();
      });
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not update Supabase record: $error')),
      );
    }
  }

  Future<void> _showFilters() async {
    var sterilized = _filterSterilized;
    var rabies = _filterRabies;
    var nineInOne = _filterNineInOne;
    final applied = await showDialog<(bool, bool, bool)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Filter records'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                value: sterilized,
                onChanged: (value) =>
                    setDialogState(() => sterilized = value ?? false),
                title: const Text('Sterilized'),
              ),
              CheckboxListTile(
                value: rabies,
                onChanged: (value) =>
                    setDialogState(() => rabies = value ?? false),
                title: const Text('Rabies vaccinated'),
              ),
              CheckboxListTile(
                value: nineInOne,
                onChanged: (value) =>
                    setDialogState(() => nineInOne = value ?? false),
                title: const Text('9-in-1 vaccinated'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, (false, false, false)),
              child: const Text('Clear'),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, (sterilized, rabies, nineInOne)),
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    if (applied == null || !mounted) return;
    setState(() {
      _filterSterilized = applied.$1;
      _filterRabies = applied.$2;
      _filterNineInOne = applied.$3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final visibleDogs = _dogs.where((dog) {
      final text = '${dog.name} ${dog.area}'.toLowerCase();
      return text.contains(_query) &&
          (!_filterSterilized ||
              dog.sterilization == SterilizationStatus.yes) &&
          (!_filterRabies || dog.rabiesVaccinated) &&
          (!_filterNineInOne || dog.nineInOneVaccinated);
    }).toList();
    final hasActiveFilters =
        _filterSterilized || _filterRabies || _filterNineInOne;

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
                  LayoutBuilder(
                    builder: (context, constraints) => GridView.count(
                      crossAxisCount: 4,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      mainAxisExtent: 68,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _StatTile(
                          label: 'Registered',
                          value: '${_dogs.length}',
                          icon: const Icon(Icons.pets_rounded),
                          color: const Color(0xffdcefe7),
                        ),
                        _StatTile(
                          label: 'Sterilized',
                          value:
                              '${_dogs.where((dog) => dog.sterilization == SterilizationStatus.yes).length}',
                          icon: const _SterilizedIcon(),
                          color: const Color(0xfff1dedb),
                        ),
                        _StatTile(
                          label: 'Rabies',
                          value:
                              '${_dogs.where((dog) => dog.rabiesVaccinated).length}',
                          icon: const _RabiesIcon(),
                          color: const Color(0xffdde8f5),
                        ),
                        _StatTile(
                          label: '9-in-1',
                          value:
                              '${_dogs.where((dog) => dog.nineInOneVaccinated).length}',
                          icon: const Icon(Icons.vaccines_outlined),
                          color: const Color(0xffe9e2f2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Your records',
                    style: Theme.of(context).textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Search by name or area',
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
                      ),
                      const SizedBox(width: 8),
                      Badge(
                        isLabelVisible: hasActiveFilters,
                        child: IconButton.filledTonal(
                          onPressed: _showFilters,
                          icon: const Icon(Icons.filter_list_rounded),
                          tooltip: 'Filter records',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (visibleDogs.isEmpty)
                    _EmptyState(onAddDog: _addDog)
                  else
                    ...visibleDogs.map(
                      (dog) => _DogTile(
                        dog: dog,
                        repository: _repository!,
                        onEdit: () => _editDog(dog),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addDog,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Record a furfriend'),
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
  final Widget icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: const IconThemeData(size: 24, color: Color(0xff24574b)),
            child: icon,
          ),
          const SizedBox(width: 10),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

class _RabiesIcon extends StatelessWidget {
  const _RabiesIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xff24574b), width: 2),
      shape: BoxShape.circle,
    ),
    child: const Text(
      'R',
      style: TextStyle(
        color: Color(0xff24574b),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _SterilizedIcon extends StatelessWidget {
  const _SterilizedIcon();

  @override
  Widget build(BuildContext context) => Container(
    width: 24,
    height: 24,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xff24574b), width: 2),
      shape: BoxShape.circle,
    ),
    child: const Text(
      'S',
      style: TextStyle(
        color: Color(0xff24574b),
        fontSize: 15,
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}

class _DogTile extends StatelessWidget {
  const _DogTile({
    required this.dog,
    required this.repository,
    required this.onEdit,
  });
  final Dog dog;
  final DogRepository repository;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final vaccinationNeedsAttention =
        dog.vaccinationDueSoon ||
        (!dog.rabiesVaccinated && !dog.nineInOneVaccinated);
    final vaccinationTooltip = dog.vaccinationDueSoon
        ? 'Vaccination due within one month'
        : 'No vaccination recorded';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 0,
      color: Colors.white,
      child: ListTile(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => _DogDetailsPage(dog: dog, repository: repository),
            ),
          );
        },
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        leading: ClipOval(
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
            if (dog.sterilization != SterilizationStatus.yes) ...[
              const Tooltip(
                message: 'Not sterilized',
                child: Icon(
                  Icons.content_cut_outlined,
                  color: Color(0xffb54708),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (vaccinationNeedsAttention) ...[
              Tooltip(
                message: vaccinationTooltip,
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xffb54708),
                ),
              ),
              const SizedBox(width: 8),
            ],
            IconButton(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit record',
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoPlaceholder(BuildContext context) => Container(
    color: const Color(0xffdcefe7),
    child: Icon(
      Icons.pets_rounded,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

class _DogDetailsPage extends StatefulWidget {
  const _DogDetailsPage({required this.dog, required this.repository});

  final Dog dog;
  final DogRepository repository;

  @override
  State<_DogDetailsPage> createState() => _DogDetailsPageState();
}

class _DogDetailsPageState extends State<_DogDetailsPage> {
  List<MedicalNote> _medicalNotes = [];
  bool _loadingMedicalNotes = true;

  Dog get dog => widget.dog;

  @override
  void initState() {
    super.initState();
    _loadMedicalNotes();
  }

  Future<void> _loadMedicalNotes() async {
    try {
      final notes = await widget.repository.medicalNotesFor(dog.id);
      if (mounted) setState(() => _medicalNotes = notes);
    } catch (_) {
      // The table may not be deployed yet; the rest of the dog record remains usable.
    } finally {
      if (mounted) setState(() => _loadingMedicalNotes = false);
    }
  }

  Future<void> _addMedicalNote() async {
    final note = await showDialog<MedicalNote>(
      context: context,
      builder: (_) => _MedicalNoteDialog(dogId: dog.id),
    );
    if (note == null) return;
    try {
      await widget.repository.saveMedicalNote(note);
      if (mounted) setState(() => _medicalNotes = [note, ..._medicalNotes]);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save medical note: $error')),
      );
    }
  }

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
                  dog.name.isEmpty
                      ? 'Unnamed ${dog.animalCategory}'
                      : '${dog.name[0].toUpperCase()}${dog.name.substring(1)}',
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
            highlightedValue: dog.animalCategory,
            values: [
              _DetailValue('Gender', _display(dog.gender)),
              _DetailValue('Age', _display(dog.age)),
              _DetailValue('Breed', _display(dog.breed)),
              _DetailValue('Color / Identifying Marks', _display(dog.color)),
              _DetailValue('Notes', _display(dog.notes)),
              _DetailValue('Area', _display(dog.area)),
            ],
          ),
          const SizedBox(height: 16),
          _MedicalRecordsSection(dog: dog),
          const SizedBox(height: 16),
          _MedicalNotesSection(
            notes: _medicalNotes,
            loading: _loadingMedicalNotes,
            onAdd: _addMedicalNote,
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
                      style: TextStyle(fontWeight: FontWeight.w700),
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
            title: 'Record Information',
            compact: true,
            values: [
              _DetailValue('Created', _formatDate(dog.createdAt)),
              _DetailValue('Last Updated', _formatDate(dog.updatedAt)),
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

class _MedicalNotesSection extends StatelessWidget {
  const _MedicalNotesSection({
    required this.notes,
    required this.loading,
    required this.onAdd,
  });

  final List<MedicalNote> notes;
  final bool loading;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffe2e5df)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Medical Notes',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
            IconButton.filledTonal(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              tooltip: 'Add medical note',
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (loading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(),
            ),
          )
        else if (notes.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text('No medical conditions recorded.'),
          )
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columnSpacing: 20,
              headingTextStyle: const TextStyle(fontWeight: FontWeight.w700),
              columns: const [
                DataColumn(label: Text('Condition')),
                DataColumn(label: Text('Status')),
                DataColumn(label: Text('Treatment Given')),
                DataColumn(label: Text('Started')),
                DataColumn(label: Text('End Date')),
                DataColumn(label: Text('Caretaker')),
                DataColumn(label: Text('Vet Details')),
              ],
              rows: notes
                  .map(
                    (note) => DataRow(
                      cells: [
                        DataCell(Text(note.condition)),
                        DataCell(Text(note.treatmentStatus)),
                        DataCell(Text(note.treatmentGiven)),
                        DataCell(Text(_formatDate(note.startedDate))),
                        DataCell(
                          Text(
                            note.endDate == null
                                ? '-'
                                : _formatDate(note.endDate!),
                          ),
                        ),
                        DataCell(Text(note.caretaker)),
                        DataCell(Text(note.vetDetails)),
                      ],
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    ),
  );

  static String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

class _MedicalNoteDialog extends StatefulWidget {
  const _MedicalNoteDialog({required this.dogId});

  final String dogId;

  @override
  State<_MedicalNoteDialog> createState() => _MedicalNoteDialogState();
}

class _MedicalNoteDialogState extends State<_MedicalNoteDialog> {
  final _formKey = GlobalKey<FormState>();
  final _condition = TextEditingController();
  final _treatmentStatus = TextEditingController();
  final _treatmentGiven = TextEditingController();
  final _caretaker = TextEditingController();
  final _vetDetails = TextEditingController();
  DateTime _startedDate = DateTime.now();
  DateTime? _endDate;

  @override
  void dispose() {
    _condition.dispose();
    _treatmentStatus.dispose();
    _treatmentGiven.dispose();
    _caretaker.dispose();
    _vetDetails.dispose();
    super.dispose();
  }

  Future<void> _pickStartedDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _startedDate = date);
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startedDate,
      firstDate: _startedDate,
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _endDate = date);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      MedicalNote(
        id: DogRepository.newId(),
        dogId: widget.dogId,
        condition: _condition.text.trim(),
        treatmentStatus: _treatmentStatus.text.trim(),
        treatmentGiven: _treatmentGiven.text.trim(),
        startedDate: _startedDate,
        endDate: _endDate,
        caretaker: _caretaker.text.trim(),
        vetDetails: _vetDetails.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Add Medical Note'),
    content: SizedBox(
      width: 360,
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _condition,
                decoration: const InputDecoration(
                  labelText: 'Medical Condition',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the medical condition'
                    : null,
              ),
              TextFormField(
                controller: _treatmentStatus,
                decoration: const InputDecoration(
                  labelText: 'Treatment Status',
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Enter the treatment status'
                    : null,
              ),
              TextFormField(
                controller: _treatmentGiven,
                decoration: const InputDecoration(labelText: 'Treatment Given'),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickStartedDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    'Started: ${_MedicalNotesSection._formatDate(_startedDate)}',
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.event_available_outlined),
                  label: Text(
                    _endDate == null
                        ? 'End Date (optional)'
                        : 'Ended: ${_MedicalNotesSection._formatDate(_endDate!)}',
                  ),
                ),
              ),
              TextFormField(
                controller: _caretaker,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Caretaker Name or Mobile Number',
                ),
              ),
              TextFormField(
                controller: _vetDetails,
                decoration: const InputDecoration(labelText: 'Vet Details'),
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
      FilledButton(onPressed: _save, child: const Text('Add Note')),
    ],
  );
}

class _DetailValue {
  const _DetailValue(this.label, this.value);

  final String label;
  final String value;
}

class _DetailSection extends StatelessWidget {
  const _DetailSection({
    required this.title,
    required this.values,
    this.compact = false,
    this.highlightedValue,
  });

  final String title;
  final List<_DetailValue> values;
  final bool compact;
  final String? highlightedValue;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(compact ? 12 : 16),
    decoration: compact
        ? null
        : BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xffe2e5df)),
            borderRadius: BorderRadius.circular(8),
          ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: compact ? 13 : 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: compact ? 4 : 10),
        if (highlightedValue != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xffdcefe7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${highlightedValue![0].toUpperCase()}${highlightedValue!.substring(1)}',
              style: const TextStyle(
                color: Color(0xff1c6b5a),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
        ...values.map(
          (item) => Padding(
            padding: EdgeInsets.symmetric(vertical: compact ? 4 : 7),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: compact ? 104 : 132,
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: compact ? 11 : 13,
                      color: Colors.black54,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.value,
                    style: TextStyle(
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

class _MedicalRecordsSection extends StatelessWidget {
  const _MedicalRecordsSection({required this.dog});

  final Dog dog;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xffe2e5df)),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Sterilization Vaccination Records',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MedicalRecordBadge(
              icon: Icons.content_cut_outlined,
              label: 'Sterilized',
              complete: dog.sterilization == SterilizationStatus.yes,
            ),
            _MedicalRecordBadge(
              icon: Icons.shield_outlined,
              label: 'Rabies vaccinated',
              complete: dog.rabiesVaccinated,
            ),
            _MedicalRecordBadge(
              icon: Icons.medication_outlined,
              label: '9-in-1 vaccinated',
              complete: dog.nineInOneVaccinated,
            ),
            if (dog.vaccinationDueSoon)
              const _MedicalRecordBadge(
                icon: Icons.notifications_active_outlined,
                label: 'Vaccination due soon',
                complete: true,
              ),
          ],
        ),
      ],
    ),
  );
}

class _MedicalRecordBadge extends StatelessWidget {
  const _MedicalRecordBadge({
    required this.icon,
    required this.label,
    required this.complete,
  });

  final IconData icon;
  final String label;
  final bool complete;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: BoxDecoration(
      color: complete ? const Color(0xffdcefe7) : const Color(0xffeeeeee),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
          color: complete ? const Color(0xff1c6b5a) : Colors.black45,
        ),
        const SizedBox(width: 6),
        Text(
          '$label: ${complete ? 'Yes' : 'No'}',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
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
  const _AddDogDialog({this.dog});

  final Dog? dog;

  @override
  State<_AddDogDialog> createState() => _AddDogDialogState();
}

class _AddDogDialogState extends State<_AddDogDialog> {
  final _formKey = GlobalKey<FormState>();
  String _animalCategory = 'dog';
  int _page = 0;
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
  SterilizationStatus _sterilization = SterilizationStatus.no;
  bool _rabies = false;
  bool _nineInOne = false;
  DateTime? _vaccinationDate;

  @override
  void initState() {
    super.initState();
    final dog = widget.dog;
    if (dog == null) {
      _breed.text = 'Indie';
      return;
    }
    _animalCategory = dog.animalCategory;
    _name.text = dog.name;
    _breed.text = dog.breed;
    _gender = dog.gender;
    _age.text = dog.age;
    _identifyingMarks.text = dog.color;
    _notes.text = dog.notes;
    _address.text = dog.address;
    _area.text = dog.area;
    _photoUrl = dog.photoPath;
    _latitude = dog.latitude;
    _longitude = dog.longitude;
    _sterilization = dog.sterilization == SterilizationStatus.unknown
        ? SterilizationStatus.no
        : dog.sterilization;
    _rabies = dog.rabiesVaccinated;
    _nineInOne = dog.nineInOneVaccinated;
    _vaccinationDate = dog.vaccinationDate;
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

  void _continueToHealth() {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _page = 1);
  }

  Future<void> _selectVaccinationDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _vaccinationDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date != null && mounted) setState(() => _vaccinationDate = date);
  }

  void _save() {
    if ((_rabies || _nineInOne) && _vaccinationDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a vaccine and its vaccination date.'),
        ),
      );
      return;
    }
    final now = DateTime.now();
    final recordId = widget.dog?.id ?? DogRepository.newId();
    Navigator.pop(
      context,
      _DogRecordDraft(
        dog: Dog(
          id: recordId,
          animalCategory: _animalCategory,
          name: _name.text.trim(),
          breed: _breed.text.trim(),
          photoBytes: _photoBytes,
          photoPath: _photoUrl,
          gender: _gender,
          age: _age.text.trim(),
          color: _identifyingMarks.text.trim(),
          sterilization: _sterilization,
          notes: _notes.text.trim(),
          address: _address.text.trim(),
          locationNote: _address.text.trim(),
          area: _area.text.trim(),
          latitude: _latitude,
          longitude: _longitude,
          createdAt: widget.dog?.createdAt ?? now,
          updatedAt: now,
        ),
        healthDetails: DogHealthDetails(
          dogId: recordId,
          sterilization: _sterilization,
          rabies: _rabies,
          nineInOne: _nineInOne,
          vaccinationDate: _vaccinationDate,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dialogHeight = MediaQuery.sizeOf(context).height * 0.7;
    return AlertDialog(
      title: Text(_page == 0 ? 'Record a furfriend' : 'Health details'),
      content: SizedBox(
        width: 320,
        height: dialogHeight,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: _page == 0
                ? Column(
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
                          if (value != null) {
                            setState(() => _animalCategory = value);
                          }
                        },
                      ),
                      TextFormField(
                        controller: _name,
                        autofocus: true,
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Name',
                          hintText: 'Furry friend\'s name',
                        ),
                        validator: _requiredField('Name'),
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
                                  onPressed: () =>
                                      _pickPhoto(ImageSource.camera),
                                  icon: const Icon(Icons.camera_alt_outlined),
                                  label: const Text('Take photo'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 145,
                                child: OutlinedButton.icon(
                                  onPressed: () =>
                                      _pickPhoto(ImageSource.gallery),
                                  icon: const Icon(
                                    Icons.photo_library_outlined,
                                  ),
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
                          DropdownMenuItem(
                            value: 'Female',
                            child: Text('Female'),
                          ),
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Color / Identifying marks',
                        ),
                        validator: _requiredField('Color / Identifying marks'),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _notes,
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
                        autovalidateMode: AutovalidateMode.onUserInteraction,
                        decoration: const InputDecoration(
                          labelText: 'Building / Area',
                        ),
                        validator: _requiredField('Building / Area'),
                      ),
                    ],
                  )
                : _HealthDetailsPage(
                    sterilization: _sterilization,
                    rabies: _rabies,
                    nineInOne: _nineInOne,
                    vaccinationDate: _vaccinationDate,
                    onSterilizationChanged: (status) {
                      setState(() => _sterilization = status);
                    },
                    onRabiesChanged: (value) {
                      setState(() => _rabies = value);
                    },
                    onNineInOneChanged: (value) {
                      setState(() => _nineInOne = value);
                    },
                    onSelectDate: _selectVaccinationDate,
                  ),
          ),
        ),
      ),
      actions: [
        if (_page == 0)
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          )
        else
          TextButton(
            onPressed: () => setState(() => _page = 0),
            child: const Text('Back'),
          ),
        FilledButton(
          onPressed: _page == 0 ? _continueToHealth : _save,
          child: Text(_page == 0 ? 'Continue' : 'Save record'),
        ),
      ],
    );
  }

  String? Function(String?) _requiredField(String fieldName) =>
      (value) => value == null || value.trim().isEmpty
      ? '$fieldName is required'
      : null;
}

class _DogRecordDraft {
  const _DogRecordDraft({required this.dog, required this.healthDetails});

  final Dog dog;
  final DogHealthDetails healthDetails;
}

class _HealthDetailsPage extends StatelessWidget {
  const _HealthDetailsPage({
    required this.sterilization,
    required this.rabies,
    required this.nineInOne,
    required this.vaccinationDate,
    required this.onSterilizationChanged,
    required this.onRabiesChanged,
    required this.onNineInOneChanged,
    required this.onSelectDate,
  });

  final SterilizationStatus sterilization;
  final bool rabies;
  final bool nineInOne;
  final DateTime? vaccinationDate;
  final ValueChanged<SterilizationStatus> onSterilizationChanged;
  final ValueChanged<bool> onRabiesChanged;
  final ValueChanged<bool> onNineInOneChanged;
  final VoidCallback onSelectDate;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text('Sterilized', style: TextStyle(fontWeight: FontWeight.w600)),
      RadioGroup<SterilizationStatus>(
        groupValue: sterilization,
        onChanged: (status) {
          if (status != null) onSterilizationChanged(status);
        },
        child: const Column(
          children: [
            RadioListTile(value: SterilizationStatus.yes, title: Text('Yes')),
            RadioListTile(value: SterilizationStatus.no, title: Text('No')),
          ],
        ),
      ),
      const SizedBox(height: 12),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Rabies vaccinated'),
        value: rabies,
        onChanged: (value) => onRabiesChanged(value ?? false),
      ),
      CheckboxListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('9-in-1 vaccinated'),
        value: nineInOne,
        onChanged: (value) => onNineInOneChanged(value ?? false),
      ),
      if (rabies || nineInOne) ...[
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: onSelectDate,
          icon: const Icon(Icons.calendar_today_outlined),
          label: Text(
            vaccinationDate == null
                ? 'Vaccination date'
                : MaterialLocalizations.of(context)
                      .formatMediumDate(vaccinationDate!),
          ),
        ),
      ],
    ],
  );
}
