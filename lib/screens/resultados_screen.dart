import 'package:flutter/material.dart';
import '../models/categoria.dart';
import '../models/palabra.dart';
import 'juego_screen.dart';
import 'categorias_screen.dart';

/// Pantalla de resultados al finalizar el juego
class ResultadosScreen extends StatelessWidget {
  final Categoria categoria;
  final int puntaje;
  final List<Palabra> palabrasJugadas;

  const ResultadosScreen({
    super.key,
    required this.categoria,
    required this.puntaje,
    required this.palabrasJugadas,
  });

  @override
  Widget build(BuildContext context) {
    // Calcular palabras acertadas y falladas
    final acertadas = palabrasJugadas.where((p) => p.acertada).toList();
    final falladas = palabrasJugadas.where((p) => !p.acertada).toList();

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [categoria.color.withOpacity(0.7), categoria.color],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Cabecera con puntaje
              Container(
                padding: EdgeInsets.all(30),
                child: Column(
                  children: [
                    Text(
                      "¡Tiempo terminado!",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 20),
                    Text(categoria.icono, style: TextStyle(fontSize: 80)),
                    SizedBox(height: 10),
                    Text(
                      categoria.nombre,
                      style: TextStyle(fontSize: 24, color: Colors.white),
                    ),
                    SizedBox(height: 20),
                    Container(
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Column(
                        children: [
                          Text(
                            "Puntaje",
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.grey[700],
                            ),
                          ),
                          Text(
                            "$puntaje",
                            style: TextStyle(
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                              color: categoria.color,
                            ),
                          ),
                          Text(
                            "${acertadas.length} aciertos - ${falladas.length} omitidas",
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Lista de palabras jugadas
              Expanded(
                child: Container(
                  margin: EdgeInsets.all(20),
                  padding: EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Palabras jugadas:",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: categoria.color,
                        ),
                      ),
                      SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: palabrasJugadas.length,
                          itemBuilder: (context, index) {
                            final palabra = palabrasJugadas[index];
                            return ListTile(
                              leading: Icon(
                                palabra.acertada
                                    ? Icons.check_circle
                                    : Icons.cancel,
                                color: palabra.acertada
                                    ? Colors.green
                                    : Colors.red,
                              ),
                              title: Text(
                                palabra.texto,
                                style: TextStyle(
                                  decoration: palabra.acertada
                                      ? TextDecoration.none
                                      : TextDecoration.lineThrough,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Botones de acción
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Volver a jugar con la misma categoría
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => JuegoScreen(categoria: categoria),
                            ),
                          );
                        },
                        icon: Icon(Icons.replay),
                        label: Text("Jugar de nuevo"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: categoria.color,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Volver a selección de categorías
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CategoriasScreen(),
                            ),
                          );
                        },
                        icon: Icon(Icons.category),
                        label: Text("Otra categoría"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: categoria.color,
                          padding: EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
