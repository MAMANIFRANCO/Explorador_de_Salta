import 'package:flutter/material.dart';
import 'categorias_screen.dart';
import 'configuracion_screen.dart';

/// Pantalla de inicio del juego "¿Quién soy yo?" con animaciones y fondo dinámico
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _tituloController;
  late Animation<Offset> _tituloOffset;
  late AnimationController _botonesController;
  late Animation<Offset> _botonesOffset;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();

    // Animación del título
    _tituloController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _tituloOffset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _tituloController, curve: Curves.easeOut));

    // Animación de los botones
    _botonesController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _botonesOffset = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _botonesController, curve: Curves.easeOut));

    // Fade-in de todo
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(_fadeController);

    // Iniciar animaciones con retrasos
    _tituloController.forward().then((_) => _botonesController.forward());
    _fadeController.forward();
  }

  @override
  void dispose() {
    _tituloController.dispose();
    _botonesController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Fondo animado con gradiente
          AnimatedContainer(
            duration: const Duration(seconds: 5),
            onEnd: () => setState(() {}),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.purple.shade400,
                  Colors.blue.shade600,
                  Colors.pink.shade400,
                ],
              ),
            ),
          ),
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SlideTransition(
                      position: _tituloOffset,
                      child: Column(
                        children: [
                          const Text("🎭", style: TextStyle(fontSize: 100)),
                          const SizedBox(height: 20),
                          Text(
                            "¿Quién Soy Yo?",
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  blurRadius: 10.0,
                                  color: Colors.black45,
                                  offset: Offset(3, 3),
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "Adivina la palabra antes de que termine el tiempo",
                            style: TextStyle(
                              fontSize: width < 400 ? 14 : 16,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 60),
                    SlideTransition(
                      position: _botonesOffset,
                      child: Column(
                        children: [
                          _buildMenuButton(
                            context: context,
                            label: "🎮 JUGAR",
                            color: Colors.green,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => CategoriasScreen()),
                            ),
                          ),
                          const SizedBox(height: 20),
                          _buildMenuButton(
                            context: context,
                            label: "⚙️ CONFIGURACIÓN",
                            color: Colors.orange,
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => ConfiguracionScreen()),
                            ),
                          ),
                          const SizedBox(height: 40),
                          _buildInstrucciones(width),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuButton({
    required BuildContext context,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return GestureDetector(
      onTapDown: (_) => setState(() {}),
      onTapUp: (_) => setState(() {}),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 60, vertical: 20),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          elevation: 5,
          shadowColor: Colors.black45,
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildInstrucciones(double width) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 40),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const Text(
            "📱 Instrucciones:",
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 10),
          _buildInstruccion("⬆️  Inclinar arriba = Acierto", width),
          _buildInstruccion("⬇️  Inclinar abajo = Pasar", width),
        ],
      ),
    );
  }

  Widget _buildInstruccion(String texto, double width) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Text(
        texto,
        style: TextStyle(
          color: Colors.white,
          fontSize: width < 400 ? 12 : 14,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
