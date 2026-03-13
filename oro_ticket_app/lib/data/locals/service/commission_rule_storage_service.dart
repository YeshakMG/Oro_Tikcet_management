import 'package:hive/hive.dart';
import 'package:oro_ticket_app/data/locals/models/commission_rule_model.dart';
import 'package:oro_ticket_app/data/locals/hive_boxes.dart';

class CommissionRuleStorageService {
  static Future<void> saveCommissionRules(List<CommissionRuleModel> rules) async {
    final box = await HiveBoxes.getBox<CommissionRuleModel>(HiveBoxes.commissionRulesBox);
    await box.clear();
    await box.addAll(rules);
    print('✅ Saved ${rules.length} commission rules to local storage');
  }

  static List<CommissionRuleModel> getCommissionRules() {
    final box = Hive.box<CommissionRuleModel>(HiveBoxes.commissionRulesBox);
    final rules = box.values.toList();
    print('📦 Retrieved ${rules.length} commission rules from local storage');
    return rules;
  }

  static Future<void> clearCommissionRules() async {
    final box = await HiveBoxes.getBox<CommissionRuleModel>(HiveBoxes.commissionRulesBox);
    await box.clear();
  }
}
