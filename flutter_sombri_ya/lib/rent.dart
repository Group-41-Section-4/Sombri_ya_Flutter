import 'package:flutter/material.dart';

class RentPage extends StatelessWidget {
  const RentPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AppBar (same as Home)
      appBar: AppBar(
        backgroundColor: const Color(0xFF28BCEF),
        foregroundColor: Colors.white,
        title: const Text('Rentar'),
        leading: IconButton(
          icon: const Icon(Icons.notifications_none),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white24,
              backgroundImage: AssetImage('assets/images/profile.png'),
            ),
          ),
        ],
      ),

      // QR Scanner Body or NFC Activation
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/qr_img.png',  
              fit: BoxFit.cover,
              filterQuality: FilterQuality.low,
              cacheWidth: 1080,
            ),
          ),

          // Scanner square
          Align(
            alignment: Alignment.center,
            child: Container(
              width: MediaQuery.of(context).size.width * 0.78,
              height: MediaQuery.of(context).size.width * 0.58,
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFF28BCEF),
                  width: 3,
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    spreadRadius: 1,
                  )
                ],
              ),
            ),
          ),

          // Activate NFC button
          Positioned(
            bottom: 100,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.contactless, size: 32),
                label: const Text(
                  'Activar NFC',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 20),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF004D63),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: StadiumBorder(
                    side: BorderSide(color: const Color(0xFF004D63).withOpacity(0.15)),
                  ),
                  elevation: 8,
                  shadowColor: Colors.black26,
                ),
                onPressed: () {
                  // TODO: NFC logic
                },
              ),
            ),
          ),
        ],
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: SafeArea(
        child: Container(
          height: 76,
          color: const Color(0xFF28BCEF),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: const [
              _BottomItem(icon: Icons.map, label: 'Mapa'),
              SizedBox(width: 48),
              _BottomItem(icon: Icons.menu, label: 'Más'),
            ],
          ),
        ),
      ),

      // Floating Action Button (Home)
      floatingActionButton: SizedBox(
        width: 76,
        height: 76,
        child: FloatingActionButton(
          backgroundColor : const Color(0xFFFF4645),
          elevation: 6,
          onPressed: () {},
          child: Image.asset(
            'assets/images/home_button.png',
            width: 52,
            height: 52,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}



  class _BottomItem extends StatelessWidget {
    final IconData icon;
    final String label;
    const _BottomItem({required this.icon, required this.label});

    @override
    Widget build(BuildContext context) {
      return SizedBox(
        width: 88, height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
          ],
        ),
      );
    }
  }
