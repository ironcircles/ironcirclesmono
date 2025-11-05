import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:intl/intl.dart';
import 'package:ironcirclesapp/blocs/ironcoin_bloc.dart';
import 'package:ironcirclesapp/models/export_models.dart';
import 'package:ironcirclesapp/models/ironcointransaction.dart';
import 'package:ironcirclesapp/screens/widgets/ictext.dart';
import 'package:ironcirclesapp/screens/widgets/ictextstyle.dart';
import 'package:ironcirclesapp/screens/widgets/wrapper.dart';

class CoinLedger extends StatefulWidget {
  UserFurnace userFurnace;

  CoinLedger({
    Key? key,
    required this.userFurnace,
  }) : super(key: key);

  @override
  _CoinLedgerState createState() {
    return _CoinLedgerState();
  }
}

class _CoinLedgerState extends State<CoinLedger> {
  List<IronCoinTransaction> _payments = [];
  final IronCoinBloc _ironCoinBloc = IronCoinBloc();

  @override
  void initState() {
    super.initState();

    _ironCoinBloc.coinLedger.listen((payments) {
      if (mounted) {
        setState(() {
          _payments = payments; //.reversed.toList();
        });
      }
    }, onError: (err) {
      debugPrint("CoinLedgerViewer.initState: $err");
    }, cancelOnError: false);

    if (globalState.userFurnace != null &&
        globalState.userFurnace!.authServer == true) {
      _ironCoinBloc.fetchLedger();
    } else {
      if (widget.userFurnace.authServer == true) {
        _ironCoinBloc.fetchLedger();
      }
    }
  }

  getLocalizedPaymentType(payment) {
    if (payment.paymentType == CoinPaymentType.GIFTED_COINS) {
      return AppLocalizations.of(context)!.giftedIronCoin;
    } else if (payment.paymentType == CoinPaymentType.SUBSCRIBER_COINS) {
      return AppLocalizations.of(context)!.subscriptionIronCoin;
    } else if (payment.paymentType == CoinPaymentType.GAVE_COINS) {
      return AppLocalizations.of(context)!.gaveIronCoin;
    } else if (payment.paymentType == CoinPaymentType.REFUND_IRONCOIN) {
      return AppLocalizations.of(context)!.refundedIronCoin;
    } else if (payment.paymentType == CoinPaymentType.PURCHASED_COINS) {
      return AppLocalizations.of(context)!.purchasedIronCoin;
    } else if (payment.paymentType == CoinPaymentType.IMAGE_GENERATION) {
      return AppLocalizations.of(context)!.generatedImage;
    } else if (payment.paymentType == CoinPaymentType.INPAINTING) {
      return AppLocalizations.of(context)!.inpaintingImage;
    } else {
      return payment.paymentType;
    }
  }

  TableRow _buildTableRow(IronCoinTransaction payment) {
    return TableRow(
        decoration: BoxDecoration(
            color: globalState.theme.tableBackground, border: Border.all()),
        children: [
          Padding(
              padding: const EdgeInsets.only(left: 15),
              child: SizedBox(
                  height: 50,
                  child: Center(
                    child: Text(getLocalizedPaymentType(payment),
                        textScaler: const TextScaler.linear(1.0),
                        style: TextStyle(color: globalState.theme.tableText)),
                  ))),
          SizedBox(
              height: 50,
              child: Center(
                child: Text(
                    DateFormat.yMMMd().format(DateTime.parse(payment.created!)),
                    textScaler: const TextScaler.linear(1.0),
                    style: TextStyle(color: globalState.theme.tableText)),
              )),
          SizedBox(
              height: 50,
              child: Center(
                child: Text(
                    payment.created != null
                        ? DateFormat.jm()
                            .format(DateTime.parse(payment.created!).toLocal())
                        : '',
                    textScaler: const TextScaler.linear(1.0),
                    style: TextStyle(color: globalState.theme.tableText)),
              )),
          SizedBox(
              height: 50,
              child: Center(
                  child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  payment.paymentType == CoinPaymentType.GIFTED_COINS ||
                          payment.paymentType ==
                              CoinPaymentType.SUBSCRIBER_COINS ||
                          payment.paymentType ==
                              CoinPaymentType.REFUND_IRONCOIN ||
                          payment.paymentType == CoinPaymentType.PURCHASED_COINS
                      ? Icon(
                          Icons.add,
                          color: globalState.theme.tableText,
                          size: 15.0,
                        )
                      : Icon(
                          Icons.remove,
                          color: globalState.theme.tableText,
                          size: 15.0,
                        ),
                  ClipOval(
                      child: Image.asset(
                    'assets/images/ironcoin.png',
                    height: 20,
                    width: 20,
                    fit: BoxFit.fitHeight,
                  )),
                  const Padding(padding: EdgeInsets.only(right: 3)),
                  Text(payment.amount.toString(),
                      textScaler: const TextScaler.linear(1.0),
                      style: TextStyle(color: globalState.theme.tableText)),
                ],
              )))
        ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: globalState.theme.background,
      appBar: AppBar(
        backgroundColor: globalState.theme.appBar,
        iconTheme: IconThemeData(
          color: globalState.theme.menuIcons,
        ),
        elevation: 0.1,
        title: Text("IronCoin ${AppLocalizations.of(context)!.ledger}",
            style: ICTextStyle.getStyle(
                context: context,
                color: globalState.theme.textTitle,
                fontSize: ICTextStyle.appBarFontSize)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _payments.isEmpty
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: Center(
                  child: ICText(
                AppLocalizations.of(context)!.noIronCoinHistory,
                fontSize: 18,
              )))
          : SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              scrollDirection: Axis.vertical,
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                scrollDirection: Axis.vertical,
                child: WrapperWidget(
                    child: Table(
                        children: _payments
                            .map((item) => _buildTableRow(item))
                            .toList())),
              )),
    );
  }
}
