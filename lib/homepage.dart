import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  double amount = 20.00;
  Map<String, dynamic>? intentPaymentData;

  showPaymentSheet() async {
    try {
      await Stripe.instance.presentPaymentSheet().then((val) {
        intentPaymentData = null;
      }).onError((errorMsg, sTrace) {
        if (kDebugMode) {
          print(errorMsg.toString() + sTrace.toString());
        }
      });
    } on StripeException catch (error) {
      if (kDebugMode) {
        print(error);
      }
      showDialog(
          context: context,
          builder: (c) => const AlertDialog(
                content: Text("Cancelled"),
              ));
    } catch (error, s) {
      if (kDebugMode) {
        print(s);
      }

      print(error.toString());
    }
  }

  makeIntentForPayment(amountToBeCharge, currency) async {
    try {
      String parsedAmount = (int.parse(amountToBeCharge) * 100).toString();
      Map<String, dynamic>? paymentInfo = {
        "amount": parsedAmount,
        "currency": currency,
      };

      var responseFromStripeAPI = await http.post(
          Uri.parse("https://api.stripe.com/v1/payment_intents"),
          body: paymentInfo,
          headers: {
            "Authorization": "Bearer ${dotenv.env['STRIPE_SECRET_KEY']}",
            "Content-Type": "application/x-www-form-urlencoded"
          });

      print("response from StripeAPI: " + responseFromStripeAPI.body);

      return jsonDecode(responseFromStripeAPI.body);
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }

      print(error.toString());
    }
  }

  paymentSheetInitialization(amountToBeCharge, currency) async {
    try {
      intentPaymentData =
          await makeIntentForPayment(amountToBeCharge, currency);
      await Stripe.instance
          .initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              allowsDelayedPaymentMethods: true,
              paymentIntentClientSecret: intentPaymentData!["client_secret"],
              merchantDisplayName: 'Minkey',

              // Set to true for custom flow
              // customFlow: false,
              // // Customer keys
              // customerEphemeralKeySecret: intentPaymentData!['ephemeralKey'],
              // customerId: intentPaymentData!['customer'],
              // Extra options
              // applePay: const PaymentSheetApplePay(
              //   merchantCountryCode: 'US',
              // ),
              // googlePay: const PaymentSheetGooglePay(
              //   merchantCountryCode: 'US',
              //   testEnv: true,
              // ),
              style: ThemeMode.dark,
            ),
          )
          .then((value) => print(value));

      showPaymentSheet();
    } catch (error, s) {
      if (kDebugMode) {
        print(s);
      }

      print(error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton(
            onPressed: () {
              paymentSheetInitialization(amount.round().toString(), "EUR");
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: Text(
              "Pay now € ${amount.toString()}",
              style: const TextStyle(color: Colors.white),
            ),
          )
        ]),
      ),
    );
  }
}
