import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/categoria.dart';
import '../models/palabra.dart';
import 'juego_screen.dart';
import 'categorias_screen.dart';

class ResultadosScreen extends StatefulWidget {
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
  State<ResultadosScreen> createState() => _ResultadosScreenState();
}

class _ResultadosScreenState extends State<ResultadosScreen> {
  final Color fondoOscuro = const Color(0xFF0F0C29);
  final Color azulElectric = const Color(0xFF00F5FF);
  final Color verdeBrillante = const Color(0xFF00FF7F);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final acertadas = widget.palabrasJugadas.where((p) => p.acertada).toList();
    final falladas = widget.palabrasJugadas.where((p) => !p.acertada).toList();

    return WillPopScope(
      onWillPop: () async {
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        return true;
      },
      child: Scaffold(
        backgroundColor: fondoOscuro,
        body: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // 🔹 Cabecera
              Text(
                "¡Tiempo terminado!",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: azulElectric,
                  shadows: [
                    Shadow(
                      color: azulElectric.withOpacity(0.5),
                      blurRadius: 10,
                    )
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(widget.categoria.icono,
                  style: const TextStyle(fontSize: 90)),
              const SizedBox(height: 10),
              Text(
                widget.categoria.nombre,
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 25),

              // 🌟 Tarjeta de puntaje
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding:
                    const EdgeInsets.symmetric(vertical: 25, horizontal: 40),
                decoration: BoxDecoration(
                  color: fondoOscuro.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: azulElectric, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: azulElectric.withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Colors.white, size: 60),
                    const SizedBox(height: 10),
                    Text(
                      "${widget.puntaje}",
                      style: TextStyle(
                        fontSize: 62,
                        color: verdeBrillante,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "${acertadas.length} aciertos - ${falladas.length} omitidas",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // 📋 Lista de palabras jugadas
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: fondoOscuro.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: azulElectric.withOpacity(0.8), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: azulElectric.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Palabras jugadas",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: azulElectric,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: widget.palabrasJugadas.length,
                          itemBuilder: (context, index) {
                            final palabra = widget.palabrasJugadas[index];
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    palabra.texto,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      decoration: palabra.acertada
                                          ? TextDecoration.none
                                          : TextDecoration.lineThrough,
                                      decorationColor: Colors.redAccent,
                                    ),
                                  ),
                                  Icon(
                                    palabra.acertada
                                        ? Icons.check_circle
                                        : Icons.cancel,
                                    color: palabra.acertada
                                        ? verdeBrillante
                                        : Colors.redAccent,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 25),

              // 🔘 Botones inferiores
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  JuegoScreen(categoria: widget.categoria),
                            ),
                          );
                        },
                        icon: const Icon(Icons.replay, color: Colors.black),
                        label: const Text(
                          "Jugar de nuevo",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: azulElectric,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const CategoriasScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.category, color: Colors.black),
                        label: const Text(
                          "Otra categoría",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.black),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: verdeBrillante,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }
}
