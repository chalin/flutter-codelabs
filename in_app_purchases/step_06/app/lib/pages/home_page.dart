import 'package:dashclicker/logic/dash_purchases.dart';
import 'package:flutter/material.dart';
import 'package:dashclicker/logic/dash_counter.dart';
import 'package:dashclicker/logic/dash_upgrades.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 2,
          child: DashClickerWidget(),
        ),
        Expanded(child: UpgradeList()),
      ],
    );
  }
}

class DashClickerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          CounterStateWidget(),
          InkWell(
            // Don't listen as we don't need a rebuild when the count changes
            onTap: Provider.of<DashCounter>(context, listen: false).increment,
            child: Image.asset(context.read<DashPurchases>().beautifiedDash
                ? 'assets/dash.png'
                : 'assets/dash_old.png'),
          )
        ],
      ),
    );
  }
}

class CounterStateWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // This widget is the only widget that directly listens to the counter
    // and is thus updated almost every frame. Keep this as small as possible.
    var counter = context.watch<DashCounter>();
    return RichText(
      text: TextSpan(
        text: 'You have tapped Dash ',
        style: DefaultTextStyle.of(context).style,
        children: <TextSpan>[
          TextSpan(
              text: counter.countString,
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(text: ' times!'),
        ],
      ),
    );
  }
}

class UpgradeList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var upgrades = context.watch<DashUpgrades>();
    return ListView(children: [
      _UpgradeWidget(
        upgrade: upgrades.tim,
        title: 'Tim Sneath',
        onPressed: upgrades.addTim,
      ),
    ]);
  }
}

class _UpgradeWidget extends StatelessWidget {
  final Upgrade upgrade;
  final String title;
  final VoidCallback onPressed;

  _UpgradeWidget({
    Key? key,
    required this.upgrade,
    required this.title,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onPressed,
        child: ListTile(
          leading: Center(
            widthFactor: 1,
            child: Text(
              upgrade.count.toString(),
            ),
          ),
          title: Text(
            title,
            style: !upgrade.purchasable
                ? TextStyle(color: Colors.redAccent)
                : null,
          ),
          subtitle: Text('Produces ${upgrade.work} dashes per second'),
          trailing: Text(
            '${NumberFormat.compact().format(upgrade.cost)} dashes',
          ),
        ));
  }
}
