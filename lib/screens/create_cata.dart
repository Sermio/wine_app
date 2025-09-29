import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/models/elemento_cata.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class CreateCataScreen extends StatefulWidget {
  const CreateCataScreen({super.key});

  @override
  State<CreateCataScreen> createState() => _CreateCataScreenState();
}

class _CreateCataScreenState extends State<CreateCataScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nombreController = TextEditingController();
  final List<_ElementoCataInput> _elementos = [_ElementoCataInput()];
  DateTime? _fecha;
  bool fechaObligatoria = false;
  bool elementosValidos = true;

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthService>(context, listen: false);
    final firestore = Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        title: const Text('Nueva cata'),
        centerTitle: true,
        backgroundColor: primaryColor,
        foregroundColor: textColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          16,
          16,
          16,
          100,
        ), // Padding inferior para evitar solapamiento
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2100),
                    initialDate: DateTime.now(),
                  );
                  if (date != null) {
                    setState(() {
                      _fecha = date;
                      fechaObligatoria = false;
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: fechaObligatoria
                          ? Colors.red
                          : Colors.grey.shade400,
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: fechaObligatoria ? Colors.red : textColor,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _fecha == null
                            ? 'Seleccionar fecha'
                            : _fecha!.toLocal().toString().split(' ')[0],
                        style: TextStyle(
                          color: fechaObligatoria ? Colors.red : textColor,
                          fontSize: 16,
                          fontWeight: _fecha == null
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _styledTextField(
                controller: nombreController,
                label: 'Nombre de la cata',
                validator: (value) => value == null || value.trim().isEmpty
                    ? 'Este campo es obligatorio'
                    : null,
              ),
              if (fechaObligatoria)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'La fecha es obligatoria',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              ..._elementos.asMap().entries.map((entry) {
                final index = entry.key;
                final elemento = entry.value;
                return elemento.build(
                  context,
                  index,
                  onRemove: () => setState(() => _elementos.removeAt(index)),
                  onUpdate: () =>
                      setState(() {}), // <- Esto hace que se redibuje
                );
              }),
              const SizedBox(height: 20),
              FloatingActionButton(
                backgroundColor: primaryColor,
                onPressed: () =>
                    setState(() => _elementos.add(_ElementoCataInput())),
                child: const Icon(Icons.add, color: textColor),
              ),
              if (!elementosValidos)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Debe haber al menos un elemento válido',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    bool hasError = false;

                    if (!_formKey.currentState!.validate()) return;

                    if (_fecha == null) {
                      setState(() => fechaObligatoria = true);
                      hasError = true;
                    }

                    final creador = auth.currentUser!.uid;
                    final elementos = <ElementoCata>[];

                    elementosValidos = false;

                    for (var v in _elementos) {
                      v.validate();
                      if (v.isValid()) elementosValidos = true;
                    }

                    if (!elementosValidos) hasError = true;

                    setState(() {});

                    if (hasError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Revisa los campos obligatorios'),
                        ),
                      );
                      return;
                    }

                    for (var entry in _elementos.asMap().entries) {
                      final index = entry.key;
                      final v = entry.value;

                      if (v.isValid()) {
                        elementos.add(
                          ElementoCata(
                            id: const Uuid().v4(),
                            nombreAuxiliar: 'Cata ${index + 1}',
                            nombre: v.nombre.text,
                            descripcion: v.descripcion.text,
                            precio: double.tryParse(v.precio.text) ?? 0,
                            imagenUrl: v.imagenUrl ?? '',
                          ),
                        );
                      }
                    }

                    final nuevaCata = Cata(
                      id: const Uuid().v4(),
                      nombre: nombreController.text.trim(),
                      fecha: _fecha!,
                      creadorId: creador,
                      elementos: elementos,
                    );

                    await firestore.addVotacion(nuevaCata);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Cata creada correctamente'),
                      ),
                    );

                    Navigator.pop(context);
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Crear cata',
                    style: TextStyle(color: textColor),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _styledTextField({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: textColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      validator: validator,
    );
  }
}

class _ElementoCataInput {
  final nombre = TextEditingController();
  final descripcion = TextEditingController();
  final precio = TextEditingController();
  String? imagenPath;
  String? imagenUrl;
  bool isUploading = false;

  bool showNombreError = false;
  bool showDescripcionError = false;
  bool showPrecioError = false;

  final ImagePicker _picker = ImagePicker();

  void validate() {
    showNombreError = nombre.text.trim().isEmpty;
    showDescripcionError = false;
    showPrecioError = double.tryParse(precio.text) == null;
  }

  bool isValid() => !showNombreError && !showPrecioError;

  Future<void> _selectAndUploadImage(
    BuildContext context,
    String elementoId,
    VoidCallback onUpdate,
  ) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Barra de agarre
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Tomar foto'),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('Seleccionar de galería'),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );

    if (source == null) return;

    final pickedFile = await _picker.pickImage(
      source: source,
      imageQuality: 70,
    );
    if (pickedFile != null) {
      isUploading = true;
      onUpdate();

      final file = File(pickedFile.path);
      final ref = FirebaseStorage.instance.ref().child(
        'elementos/$elementoId.jpg',
      );
      final uploadTask = ref.putFile(file);
      final snapshot = await uploadTask;
      final url = await snapshot.ref.getDownloadURL();

      imagenPath = file.path;
      imagenUrl = url;

      isUploading = false;
      onUpdate();
    }
  }

  Widget build(
    BuildContext context,
    int index, {
    VoidCallback? onRemove,
    VoidCallback? onUpdate,
  }) {
    final elementoId = const Uuid().v4();

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Elemento ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (onRemove != null)
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: primaryColor),
                    onPressed: onRemove,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _styledField(
              controller: nombre,
              label: 'Nombre',
              errorText: showNombreError ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 8),
            _styledField(controller: descripcion, label: 'Descripción'),
            const SizedBox(height: 8),
            _styledField(
              controller: precio,
              label: 'Precio (€)',
              keyboardType: TextInputType.number,
              errorText: showPrecioError ? 'Introduce un número válido' : null,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () async {
                await _selectAndUploadImage(
                  context,
                  elementoId,
                  onUpdate ?? () {},
                );
                if (onUpdate != null) onUpdate();
              },
              icon: const Icon(Icons.upload),
              label: const Text('Subir imagen'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: textColor,
              ),
            ),
            if (isUploading)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: SizedBox(
                  height: 100,
                  child: Center(
                    child: CircularProgressIndicator(color: primaryColor),
                  ),
                ),
              )
            else if (imagenPath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Image.file(
                  File(imagenPath!),
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    String? errorText,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        labelStyle: TextStyle(color: textColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }
}
