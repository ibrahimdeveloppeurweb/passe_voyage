import 'package:flutter/material.dart';
import 'dart:ui';
import '../../../core/theme/app_colors.dart';
import '../../../config/routes.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Light premium background
      body: Stack(
        children: [
          // Background Glow Effects
          Positioned(
            top: -100,
            left: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF00C6F0).withOpacity(0.1),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
          
          RefreshIndicator(
            onRefresh: () async {
              await Future.delayed(const Duration(seconds: 1));
            },
            color: AppColors.primary,
            backgroundColor: Colors.white,
            displacement: 20,
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverAppBar(
                  backgroundColor: const Color(0xFFF4F7FA).withOpacity(0.9),
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  pinned: true,
                  toolbarHeight: 70,
                  title: GestureDetector(
                    onTap: () {
                      Navigator.pushNamed(context, AppRoutes.profile);
                    },
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.white,
                          child: Icon(Icons.person, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Bienvenue,', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const Text('Cissé Ibrahim', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    Container(
                      margin: const EdgeInsets.only(right: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          )
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.black87),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 10)),
                
                // Combined Balance and QR Card
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Left side: Balance and Deposit Button
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text('Compte courant', style: TextStyle(color: Colors.black54, fontSize: 15, fontWeight: FontWeight.w600)),
                                    const SizedBox(width: 8),
                                    Icon(Icons.visibility_off, color: Colors.grey[400], size: 18),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  '1.156 F',
                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                GestureDetector(
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.add, color: Colors.white, size: 18),
                                        SizedBox(width: 4),
                                        Text(
                                          "Déposer de l'argent",
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Right side: QR Code
                          GestureDetector(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
                            },
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.withOpacity(0.2)),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Icon(Icons.qr_code_2, size: 100, color: AppColors.primary),
                                  // Central logo mimicking the capture
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text('a', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, fontStyle: FontStyle.italic, color: Colors.black)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Quick Actions Title
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 32.0, bottom: 16.0),
                    child: const Text('Actions Rapides', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                // Quick Actions Grid
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 4,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    delegate: SliverChildListDelegate([
                      _buildLightActionItem(
                        Icons.send_rounded, 
                        'Transfert', 
                        const Color(0xFFE3F2FD), 
                        Colors.blue[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
                        },
                      ),
                      _buildLightActionItem(
                        Icons.shopping_basket_rounded, 
                        'Paiements', 
                        const Color(0xFFFFF3E0), 
                        Colors.orange[700]!,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.factures);
                        },
                      ),
                      _buildLightActionItem(
                        Icons.account_balance_rounded, 
                        'Banque', 
                        const Color(0xFFFFEBEE), 
                        Colors.red[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
                        },
                      ),
                      _buildLightActionItem(
                        Icons.credit_card_rounded, 
                        'Cartes', 
                        const Color(0xFFF3E5F5), 
                        Colors.purple[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
                        },
                      ),
                      _buildLightActionItem(
                        Icons.lock_rounded, 
                        'Coffre', 
                        const Color(0xFFFCE4EC), 
                        Colors.pink[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
                        },
                      ),
                      _buildLightActionItem(
                        Icons.receipt_long_rounded, 
                        'RIB', 
                        const Color(0xFFE0F2F1), 
                        Colors.teal[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
                        },
                      ),
                      _buildLightActionItem(
                        Icons.monetization_on_rounded, 
                        'Prêt', 
                        const Color(0xFFE8F5E9), 
                        Colors.green[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
                        },
                      ),

                      _buildLightActionItem(
                        Icons.location_on_rounded, 
                        'Agences', 
                        const Color(0xFFEFEBE9), 
                        Colors.brown[700]!,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bientôt disponible')));
                        },
                      ),
                    ]),
                  ),
                ),
                
                // Transactions
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 24.0, top: 32.0, bottom: 16.0),
                    child: const Text('Transactions Récentes', style: TextStyle(color: Colors.black87, fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
                
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final transactions = [
                        {'title': 'Paiement boutique', 'date': '27 juil.', 'amount': '-500 F', 'isNegative': true},
                        {'title': 'Dépôt', 'date': '26 juil.', 'amount': '+2.000 F', 'isNegative': false},
                      ];
                      
                      if (index >= transactions.length) return null;
                      final tx = transactions[index];
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: (tx['isNegative'] as bool) ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  (tx['isNegative'] as bool) ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
                                  color: (tx['isNegative'] as bool) ? Colors.redAccent : Colors.greenAccent,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(tx['title'] as String, style: const TextStyle(color: Colors.black87, fontSize: 16, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(tx['date'] as String, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                  ],
                                ),
                              ),
                              Text(
                                tx['amount'] as String,
                                style: TextStyle(
                                  color: (tx['isNegative'] as bool) ? Colors.black87 : Colors.green[600],
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    childCount: 2,
                  ),
                ),
                
                const SliverToBoxAdapter(child: SizedBox(height: 30)), // Petite hauteur en bas
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _buildLightActionItem(IconData icon, String title, Color bgColor, Color iconColor, {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 11),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
