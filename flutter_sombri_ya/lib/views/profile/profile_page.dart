import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import 'manage_account_page.dart';

import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_bloc.dart';
import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_event.dart';
import 'package:flutter_sombri_ya/presentation/blocs/profile/profile_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _storage = const FlutterSecureStorage();
  late final ProfileBloc _bloc;
  String? _userId;

  static const double _goalKm = 5.0;

  @override
  void initState() {
    super.initState();
    _bloc = context.read<ProfileBloc>();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    _userId = await _storage.read(key: 'user_id');

    if (_userId != null) {
      _bloc.add(LoadProfile(_userId!));
    } else {
      print('Advertencia: userId no encontrado en storage.');
    }
  }

  void _navigateToManageAccount() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            BlocProvider.value(value: _bloc, child: const ManageAccountPage()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Perfil',
          style: GoogleFonts.cormorantGaramond(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: const Color(0xFF90E0EF),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.errorMessage}')),
            );
            _bloc.add(ClearProfileMessages());
          }
          if (state.successMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Éxito: ${state.successMessage}')),
            );
            _bloc.add(ClearProfileMessages());
          }
        },
        builder: (context, state) {
          if (state.loading && state.profile == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final name = state.profile?['name'] ?? 'Cargando...';
          final email = state.profile?['email'] ?? 'cargando@email.com';
          final distanceKm = state.totalDistanceKm ?? 0.0;
          final progress = (distanceKm / _goalKm).clamp(0.0, 1.0);
          final distanceMeters = (distanceKm * 1000).toInt();
          final umbrellaRentals = state.umbrellaRentals ?? 0;

          return RefreshIndicator(
            onRefresh: () async {
              if (_userId != null) {
                _bloc.add(RefreshProfile(_userId!));
              }
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _buildProfileHeader(name, email),
                  const SizedBox(height: 30),

                  _buildActivitySection(progress, distanceMeters, _goalKm),
                  const SizedBox(height: 30),

                  _buildUmbrellaRentalsSection(umbrellaRentals),
                  const SizedBox(height: 30),

                  _buildManageAccountButton(_navigateToManageAccount),

                  if (state.loading)
                    const Padding(
                      padding: EdgeInsets.only(top: 20),
                      child: LinearProgressIndicator(),
                    ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(String name, String email) {
    return Column(
      children: [
        const CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey,
          child: Icon(Icons.person, size: 50, color: Colors.white),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        Text(
          email,
          style: GoogleFonts.cormorantGaramond(
            fontSize: 16,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }

  Widget _buildActivitySection(
    double progress,
    int distanceMeters,
    double goalKm,
  ) {
    return _StatsCard(
      icon: Icons.directions_walk,
      title: 'Actividad Física',
      color: const Color(0xFF90E0EF),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          CircularPercentIndicator(
            radius: 50.0,
            lineWidth: 8.0,
            percent: progress,
            center: Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18.0,
                color: Colors.black87,
              ),
            ),
            progressColor: const Color(0xFF90E0EF),
            backgroundColor: Colors.blue.shade100,
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pasos Recorridos',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 16,
                  color: Colors.grey[700],
                ),
              ),
              Text(
                '${distanceMeters.toStringAsFixed(0)} mts',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Meta: ${goalKm.toStringAsFixed(1)} Km',
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 14,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUmbrellaRentalsSection(int rentals) {
    return _StatsCard(
      icon: FontAwesomeIcons.umbrellaBeach,
      title: 'Historial de Rentas',
      color: const Color(0xFFFF9800),
      child: Column(
        children: [
          Text(
            'Número de Reservas',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rentals.toString(),
            style: GoogleFonts.cormorantGaramond(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Text(
            rentals == 1 ? 'Sombrilla Rentada' : 'Sombrillas Rentadas',
            style: GoogleFonts.cormorantGaramond(
              fontSize: 14,
              color: Colors.orange[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManageAccountButton(VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Icon(Icons.settings, color: Color(0xFF90E0EF), size: 24),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Administrar Cuenta',
                    style: GoogleFonts.cormorantGaramond(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey, size: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _StatsCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.cormorantGaramond(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Center(child: child),
        ],
      ),
    );
  }
}
