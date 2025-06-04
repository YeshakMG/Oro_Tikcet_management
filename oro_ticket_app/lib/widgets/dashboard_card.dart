import 'package:flutter/material.dart';
import 'package:oro_ticket_app/core/constants/app_graphs.dart';
import 'package:oro_ticket_app/core/constants/typography.dart';

class DashboardCard extends StatefulWidget {
  const DashboardCard({super.key});

  @override
  State<DashboardCard> createState() => _DashboardCardState();
}

class _DashboardCardState extends State<DashboardCard> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, 2),
          )
        ],
      ),
      child: Row(
        children: [
          // Left side (text content)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("Tensae Tefera", style: AppTextStyles.subtitle2),
                SizedBox(height: 8),
                Text("946 ETB", style: AppTextStyles.displayMedium),
                SizedBox(height: 4),
                Text("Your sales increased this\nmonth by 5.7%",
                    style: AppTextStyles.caption),
              ],
            ),
          ),
          // Right side (bubble chart)
          SizedBox(
            width: 120,
            height: 120,
            child: AppGraphs.defaultChartLayout(
              children: AppGraphs.dashboardBubbles,
            ),
          ),
        ],
      ),
    );
  }
}
