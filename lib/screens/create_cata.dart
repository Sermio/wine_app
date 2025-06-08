import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:wine_app/models/cata.dart';
import 'package:wine_app/models/elemento_cata.dart';
import 'package:wine_app/services/auth_service.dart';
import 'package:wine_app/services/firestore_service.dart';
import 'package:wine_app/utils/styles.dart';

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
        padding: const EdgeInsets.all(16),
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
                            imagenUrl: v.imagenPath ?? '',
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

  bool showNombreError = false;
  bool showDescripcionError = false;
  bool showPrecioError = false;

  void validate() {
    showNombreError = nombre.text.trim().isEmpty;
    showDescripcionError = false;
    showPrecioError = double.tryParse(precio.text) == null;
  }

  bool isValid() => !showNombreError && !showPrecioError;

  Widget build(BuildContext context, int index, {VoidCallback? onRemove}) {
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
            _styledField(
              controller: descripcion,
              label: 'Descripción',
              errorText: showDescripcionError ? 'Campo obligatorio' : null,
            ),
            const SizedBox(height: 8),
            _styledField(
              controller: precio,
              label: 'Precio (€)',
              keyboardType: TextInputType.number,
              errorText: showPrecioError ? 'Introduce un número válido' : null,
            ),
            if (imagenPath != null)
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
