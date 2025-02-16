import 'dart:math';

import 'package:flutter/material.dart';

/// FRIEND HOME & APP
class FriendHomePage extends StatelessWidget {
  const FriendHomePage({super.key});
  @override
  Widget build(BuildContext context) {
    return DashboardScreen();
  }
}

class FinanceTrackerApp extends StatelessWidget {
  const FinanceTrackerApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF121212),
        primaryColor: Colors.black,
        colorScheme: ColorScheme.dark().copyWith(secondary: Colors.cyanAccent),
      ),
      home: DashboardScreen(),
    );
  }
}

/// DASHBOARD SCREEN
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;

  // Removed const because the child widgets have non-const fields.
  final List<Widget> _pages = [
    HomePage(),
    InvestmentsScreen(),
    GoalsScreen(),
    AnalysisScreen(),
    UpcomingPaymentsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.person, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfileDetailsScreen()),
            );
          },
        ),
      ),
      body: SafeArea(child: _pages[_currentIndex]),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentIndex,
      onTap: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
      backgroundColor: const Color(0xFF1E1E1E),
      selectedItemColor: Colors.cyanAccent,
      unselectedItemColor: Colors.white70,
      type: BottomNavigationBarType.fixed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(
            icon: Icon(Icons.trending_up), label: "Investments"),
        BottomNavigationBarItem(icon: Icon(Icons.flag), label: "Goals"),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Analysis"),
        BottomNavigationBarItem(
            icon: Icon(Icons.money), label: "Upcoming Payments"),
      ],
    );
  }
}

/// HOME PAGE
class HomePage extends StatelessWidget {
  final double todaysSpend = 345.00;
  final double weeklySpend = 5640.00;
  final double monthlySpend = 16980.00;
  final double budget = 18000.00;
  final double accountBalance = 0.00;

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _buildBackground(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                const SizedBox(height: 25),
                _buildSpendingCards(),
                const SizedBox(height: 25),
                _buildSummaryCards(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Background image using a relative asset path.
  Widget _buildBackground() {
    return Positioned.fill(
      child: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/Blog-Post-Pics-8.png'),
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  /// Header with fixed text size.
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          "Welcome Back Krishil",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24, // Fixed size for better appearance
            fontWeight: FontWeight.bold,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white24),
          ),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet,
                  color: Colors.white70, size: 18),
              const SizedBox(width: 5),
              // Replace the visible $ with the rupee sign while keeping interpolation
              Text(
                "₹${accountBalance.toStringAsFixed(2)}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpendingCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _spendCard("Today's Spend", "₹${todaysSpend.toStringAsFixed(2)}",
            "Yesterday: ₹900", "₹700", Colors.yellowAccent),
        _spendCard("This Week Spend", "₹${weeklySpend.toStringAsFixed(2)}",
            "Last Week: ₹4540", "₹5000", Colors.redAccent),
        _spendCard(
            "This Month Spend",
            "₹${monthlySpend.toStringAsFixed(2)}",
            "Last Month: ₹17,937",
            "₹${budget.toStringAsFixed(2)}",
            Colors.blueAccent),
      ],
    );
  }

  Widget _spendCard(
      String title, String amount, String prev, String budget, Color dotColor) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(color: Colors.black38, blurRadius: 10, spreadRadius: 2),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 14)),
                const Spacer(),
                const Icon(Icons.more_vert, color: Colors.white38),
              ],
            ),
            const SizedBox(height: 5),
            Text(amount,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(prev,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text("Budget: $budget",
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _summaryCard("History", "₹5640", "Show this week's history"),
        _summaryCard("Increase from past month", "+₹6400", "Show this month's history"),
        _summaryCard("Remaining", "₹5000", "For next week"),
      ],
    );
  }

  Widget _summaryCard(String title, String value, String subtitle) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 5),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(title,
                    style:
                        const TextStyle(color: Colors.white54, fontSize: 14)),
                const Spacer(),
                const Icon(Icons.more_vert, color: Colors.white38),
              ],
            ),
            const SizedBox(height: 5),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(subtitle,
                style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}

/// INVESTMENTS SCREEN
class InvestmentsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> investments = [
    {"title": "Apple Inc (AAPL)", "value": "₹250,000", "change": "+3.2%"},
    {"title": "Tesla Inc (TSLA)", "value": "₹150,000", "change": "-1.8%"},
    {"title": "Bitcoin (BTC)", "value": "₹500,000", "change": "+5.6%"},
    {"title": "Ethereum (ETH)", "value": "₹220,000", "change": "-0.5%"},
    {"title": "Real Estate Fund", "value": "₹100,000", "change": "+2.0%"},
    {"title": "Mutual Fund XYZ", "value": "₹300,000", "change": "+4.5%"},
  ];

  InvestmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Investments", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: investments.length,
        itemBuilder: (context, index) {
          return _buildInvestmentCard(investments[index]);
        },
      ),
    );
  }

  Widget _buildInvestmentCard(Map<String, dynamic> investment) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(investment["title"],
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        subtitle: Text(investment["value"],
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 16)),
        trailing: Text(
          investment["change"],
          style: TextStyle(
            color: investment["change"].contains("-")
                ? Colors.redAccent
                : Colors.green,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}

/// GOALS SCREEN
class GoalsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> financialGoals = [
    {
      "goal": "Save for Vacation",
      "targetAmount": 50000,
      "currentAmount": 15000,
      "icon": Icons.beach_access,
    },
    {
      "goal": "Emergency Fund",
      "targetAmount": 100000,
      "currentAmount": 35000,
      "icon": Icons.savings,
    },
    {
      "goal": "Get iPhone",
      "targetAmount": 75000,
      "currentAmount": 25000,
      "icon": Icons.trending_up,
    },
    {
      "goal": "Pay Off Student Debt",
      "targetAmount": 200000,
      "currentAmount": 80000,
      "icon": Icons.school,
    },
  ];

  GoalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Financial Goals",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: financialGoals.length,
          itemBuilder: (context, index) {
            return _buildGoalCard(financialGoals[index]);
          },
        ),
      ),
    );
  }

  Widget _buildGoalCard(Map<String, dynamic> goal) {
    double progress = goal["currentAmount"] / goal["targetAmount"];
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(goal["icon"], color: Colors.cyanAccent, size: 30),
                const SizedBox(width: 10),
                Text(goal["goal"],
                    style: const TextStyle(color: Colors.white, fontSize: 18)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Saved: ₹${goal["currentAmount"]} / ₹${goal["targetAmount"]}",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white24,
              color: Colors.blue,
              minHeight: 8,
            ),
          ],
        ),
      ),
    );
  }
}

/// ANALYSIS SCREEN
class AnalysisScreen extends StatelessWidget {
  final List<double> projectedSpendings = [500, 650, 720, 850, 900, 1100, 1300];
  final List<Map<String, dynamic>> spendCategories = [
    {"category": "Food", "amount": 300, "color": Color(0xFFE89CA7)},
    {"category": "Rent", "amount": 1200, "color": Color(0xFFE9E5A5)},
    {"category": "Shopping", "amount": 450, "color": Color(0xFFC89CC8)},
    {"category": "Travel", "amount": 600, "color": Color(0xFF89C8A7)},
    {"category": "Bills", "amount": 700, "color": Color(0xFFE8A68A)},
  ];

  AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Analysis", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1E1E1E),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildProjectedSpendings(),
            const SizedBox(height: 40),
            _buildSpendAnalysis(),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectedSpendings() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(70)),
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "PROJECTED SPENDINGS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "AI predicts a 15% increase in spendings next month.",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 150,
              child: CustomPaint(
                painter: LineChartPainter(projectedSpendings),
                child: Container(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpendAnalysis() {
    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "SPEND ANALYSIS",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              width: 200,
              child: CustomPaint(
                painter: PieChartPainter(spendCategories),
                child: Container(),
              ),
            ),
            const SizedBox(height: 40),
            Column(
              children: spendCategories.map((category) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: category["color"],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category["category"],
                            style: const TextStyle(color: Colors.white),
                          ),
                        ],
                      ),
                      Text(
                        "₹${category["amount"]}",
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

/// LINE CHART PAINTER
class LineChartPainter extends CustomPainter {
  final List<double> dataPoints;
  LineChartPainter(this.dataPoints);
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.cyanAccent
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;
    final Path path = Path();
    double stepX = size.width / (dataPoints.length - 1);
    path.moveTo(0, size.height - (dataPoints[0] / 1500 * size.height));
    for (int i = 1; i < dataPoints.length; i++) {
      double x = stepX * i;
      double y = size.height - (dataPoints[i] / 1500 * size.height);
      path.lineTo(x, y);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// PIE CHART PAINTER
class PieChartPainter extends CustomPainter {
  final List<Map<String, dynamic>> categories;
  PieChartPainter(this.categories);
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()..style = PaintingStyle.fill;
    final Paint borderPaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    double total = categories.fold(0, (sum, item) => sum + item["amount"]);
    double startAngle = 0;
    for (var category in categories) {
      final double sweepAngle = (category["amount"] / total) * 2 * pi;
      paint.color = category["color"];
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        startAngle,
        sweepAngle,
        true,
        paint,
      );
      canvas.drawArc(
        Rect.fromLTWH(0, 0, size.width, size.height),
        startAngle,
        sweepAngle,
        true,
        borderPaint,
      );
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

/// UPCOMING PAYMENTS SCREEN
class UpcomingPaymentsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> upcomingPayments = [
    {
      "title": "Netflix Subscription",
      "amount": "₹999",
      "dueDate": "Due on 20th Feb",
      "icon": Icons.subscriptions
    },
    {
      "title": "Credit Card Bill",
      "amount": "₹45675",
      "dueDate": "Due on 25th Feb",
      "icon": Icons.credit_card
    },
    {
      "title": "Electricity Bill",
      "amount": "₹3450",
      "dueDate": "Due on 10th Mar",
      "icon": Icons.lightbulb
    },
    {
      "title": "Internet Bill",
      "amount": "₹399",
      "dueDate": "Due on 5th Mar",
      "icon": Icons.wifi
    },
  ];

  UpcomingPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upcoming Payments",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView.builder(
          itemCount: upcomingPayments.length,
          itemBuilder: (context, index) {
            return _buildPaymentCard(upcomingPayments[index]);
          },
        ),
      ),
    );
  }

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(payment["icon"], color: Colors.cyanAccent, size: 30),
        title: Text(payment["title"],
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        subtitle: Text(payment["dueDate"],
            style: const TextStyle(color: Colors.white70, fontSize: 14)),
        trailing: Text(
          payment["amount"],
          style: const TextStyle(
              color: Colors.red, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

/// PROFILE DETAILS & SETTINGS
class ProfileDetailsScreen extends StatelessWidget {
  const ProfileDetailsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildSettingsList(context),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white24,
            child: Icon(Icons.person, size: 40, color: Colors.white),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: const [
              Text(
                "Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 5),
              SizedBox(
                height: 2,
                width: 60,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: Colors.cyanAccent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildQuickActionButton(Icons.report, "Report fraud"),
          _buildQuickActionButton(Icons.credit_card, "Lost card"),
          _buildQuickActionButton(Icons.smartphone, "Lost device"),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(IconData icon, String label) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          print("$label button tapped");
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.black54,
              radius: 28,
              child: Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    List<Map<String, dynamic>> settingsOptions = [
      {
        "title": "Linked Accounts",
        "subtitle": "Find all your linked accounts here",
        "icon": Icons.link,
        "route": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => LinkedAccountsScreen())),
      },
      {
        "title": "Wealth protection",
        "subtitle": "Protect your assets with biometrics",
        "icon": Icons.security,
        "route": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => WealthProtectionScreen())),
      },
      {
        "title": "Devices",
        "subtitle": "Manage your logged-in devices",
        "icon": Icons.devices,
        "route": () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => DevicesScreen())),
      },
      {
        "title": "Merchants and payments",
        "subtitle": "Manage trusted or blocked merchants",
        "icon": Icons.store,
        "route": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => MerchantsPaymentsScreen())),
      },
      {
        "title": "Gambling block",
        "subtitle": "Block gambling transactions",
        "icon": Icons.block,
        "route": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => GamblingBlockScreen())),
      },
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: settingsOptions
            .map((option) => _buildSettingsItem(context, option))
            .toList(),
      ),
    );
  }

  Widget _buildSettingsItem(BuildContext context, Map<String, dynamic> option) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: ListTile(
        leading: Icon(option["icon"], color: Colors.cyanAccent, size: 30),
        title: Text(
          option["title"],
          style: const TextStyle(
              color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          option["subtitle"],
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        trailing: const Icon(Icons.arrow_forward_ios,
            color: Colors.white70, size: 18),
        onTap: option["route"],
      ),
    );
  }
}

/// LINKED ACCOUNTS SCREEN
class LinkedAccountsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> linkedAccounts = [
    {
      "bank": "HDFC Bank",
      "accountType": "Savings Account",
      "balance": "₹150,000",
      "lastTransaction": "Feb 12, 2025"
    },
    {
      "bank": "ICICI Bank",
      "accountType": "Current Account",
      "balance": "₹75,500",
      "lastTransaction": "Feb 10, 2025"
    },
    {
      "bank": "SBI",
      "accountType": "Savings Account",
      "balance": "₹200,000",
      "lastTransaction": "Feb 14, 2025"
    },
    {
      "bank": "PayPal",
      "accountType": "Digital Wallet",
      "balance": "₹50,000",
      "lastTransaction": "Feb 11, 2025"
    },
  ];

  LinkedAccountsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Linked Accounts",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: linkedAccounts.length,
        itemBuilder: (context, index) {
          return _buildLinkedAccountCard(linkedAccounts[index]);
        },
      ),
    );
  }

  Widget _buildLinkedAccountCard(Map<String, dynamic> account) {
    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        title: Text(account["bank"],
            style: const TextStyle(color: Colors.white, fontSize: 18)),
        subtitle: Text(account["accountType"],
            style: const TextStyle(color: Colors.cyanAccent, fontSize: 16)),
        trailing: Text("Balance: ${account["balance"]}",
            style: const TextStyle(color: Colors.greenAccent, fontSize: 14)),
      ),
    );
  }
}

/// WEALTH PROTECTION SCREEN
class WealthProtectionScreen extends StatelessWidget {
  const WealthProtectionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Wealth Protection",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
      ),
      body: const Center(
        child: Text(
          "Wealth Protection Screen",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}

/// DEVICES SCREEN
class DevicesScreen extends StatelessWidget {
  final List<String> devices = [
    "Android Phone (Pixel 6)",
    "iPhone 14",
    "iPad Pro",
    "Web Browser (Chrome)",
  ];

  DevicesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Devices", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
      ),
      body: ListView.builder(
        itemCount: devices.length,
        itemBuilder: (context, index) {
          final deviceName = devices[index];
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: ListTile(
              title:
                  Text(deviceName, style: const TextStyle(color: Colors.white)),
              subtitle: const Text("Logged in",
                  style: TextStyle(color: Colors.white70)),
              onTap: () => _showDeviceOptions(context, deviceName),
            ),
          );
        },
      ),
    );
  }

  void _showDeviceOptions(BuildContext context, String deviceName) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.redAccent),
            title: const Text('Log out from device',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              print('Logged out from $deviceName');
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete, color: Colors.redAccent),
            title: const Text('Remove device',
                style: TextStyle(color: Colors.white)),
            onTap: () {
              Navigator.pop(context);
              print('Removed $deviceName');
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel, color: Colors.white70),
            title:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
            onTap: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }
}

/// MERCHANTS & PAYMENTS SCREEN
class MerchantsPaymentsScreen extends StatelessWidget {
  const MerchantsPaymentsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final List<String> blockedMerchants = [
      "Merchant A",
      "Merchant B",
      "Merchant C",
    ];
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text("Merchants & Payments",
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: blockedMerchants.length,
        itemBuilder: (context, index) {
          return Card(
            color: const Color(0xFF1E1E1E),
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text(
                blockedMerchants[index],
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              subtitle: const Text("Blocked merchant",
                  style: TextStyle(color: Colors.redAccent, fontSize: 14)),
            ),
          );
        },
      ),
    );
  }
}

/// GAMBLING BLOCK SCREEN
class GamblingBlockScreen extends StatelessWidget {
  const GamblingBlockScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title:
            const Text("Gambling Block", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF121212),
      ),
      body: const Center(
        child: Text(
          "Gambling Block Screen",
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
      ),
    );
  }
}
