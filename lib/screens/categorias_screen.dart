import 'package:flutter/material.dart';
import '../database/quien_soy_db.dart';
import '../models/categoria.dart';
import 'juego_screen.dart';

/// Pantalla de selección de categorías
class CategoriasScreen extends StatefulWidget {
  const CategoriasScreen({super.key});

  @override
  State<CategoriasScreen> createState() => _CategoriasScreenState();
}

class _CategoriasScreenState extends State<CategoriasScreen> {
  List<Categoria> _categorias = [];
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarCategorias();
  }

  /// Carga las categorías desde la base de datos
  Future<void> _cargarCategorias() async {
    try {
      final data = await QuienSoyDB.obtenerCategorias();
      setState(() {
        _categorias = data.map((map) => Categoria.fromMap(map)).toList();
        _cargando = false;
      });
    } catch (e) {
      print("Error cargando categorías: $e");
      setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Elige una categoría"),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      body: _cargando
          ? Center(child: CircularProgressIndicator())
          : Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.purple.shade100, Colors.blue.shade100],
                ),
              ),
              child: _categorias.isEmpty
                  ? Center(
                      child: Text(
                        "No hay categorías disponibles",
                        style: TextStyle(fontSize: 18),
                      ),
                    )
                  : GridView.builder(
                      padding: EdgeInsets.all(20),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 15,
                        mainAxisSpacing: 15,
                        childAspectRatio: 1,
                      ),
                      itemCount: _categorias.length,
                      itemBuilder: (context, index) {
                        return _buildCategoriaCard(_categorias[index]);
                      },
                    ),
            ),
    );
  }

  /// Construye una tarjeta de categoría
  Widget _buildCategoriaCard(Categoria categoria) {
    return InkWell(
      onTap: () {
        // Navegar a la pantalla de juego con esta categoría
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => JuegoScreen(categoria: categoria)),
        );
      },
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [categoria.color.withOpacity(0.8), categoria.color],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono grande
              Text(categoria.icono, style: TextStyle(fontSize: 60)),
              SizedBox(height: 10),
              // Nombre de la categoría
              Text(
                categoria.nombre,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      blurRadius: 5.0,
                      color: Colors.black45,
                      offset: Offset(2, 2),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
