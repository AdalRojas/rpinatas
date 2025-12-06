import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../services/auth_service.dart';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  void _onCreditCardModelChange(CreditCardModel? creditCardModel) {
    setState(() {
      cardNumber = creditCardModel!.cardNumber;
      expiryDate = creditCardModel.expiryDate;
      cardHolderName = creditCardModel.cardHolderName;
      cvvCode = creditCardModel.cvvCode;
      isCvvFocused = creditCardModel.isCvvFocused;
    });
  }

  // ESTA ES LA FUNCIÓN QUE PROCESA EL PEDIDO REALMENTE
  void _processPayment() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    // Validación visual básica de tarjeta (simulada)
    if (cardNumber.length < 16 || cvvCode.length < 3) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Datos de tarjeta inválidos")));
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final cart = Provider.of<CartProvider>(context, listen: false);
      final user = AuthService().currentUser;

      if (user == null) throw Exception("Usuario no identificado");

      // 1. LLAMAMOS A LA TRANSACCIÓN SEGURA (STOCK)
      await cart.placeOrder(user.uid);

      // 2. ÉXITO
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("¡Pago aprobado y Pedido creado!"),
            backgroundColor: Colors.green),
      );

      // Regresar hasta el Home (borrando carrito y pago del historial)
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      // 3. ERROR (STOCK O RED)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: ${e.toString().replaceAll("Exception:", "")}"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text("Pago Seguro")),
      body: SafeArea(
        child: Column(
          children: [
            // TARJETA VISUAL
            CreditCardWidget(
              cardNumber: cardNumber,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              showBackView: isCvvFocused,
              obscureCardNumber: true,
              obscureCardCvv: true,
              isHolderNameVisible: true,
              cardBgColor: Colors.deepPurple,
              onCreditCardWidgetChange: (CreditCardBrand brand) {},
            ),

            // FORMULARIO
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    CreditCardForm(
                      formKey: formKey,
                      onCreditCardModelChange: _onCreditCardModelChange,
                      obscureCvv: true,
                      obscureNumber: true,
                      cardNumber: cardNumber,
                      cvvCode: cvvCode,
                      isHolderNameVisible: true,
                      isCardNumberVisible: true,
                      isExpiryDateVisible: true,
                      cardHolderName: cardHolderName,
                      expiryDate: expiryDate,
                      inputConfiguration: InputConfiguration(
                        cardNumberDecoration: InputDecoration(
                          labelText: 'Número',
                          hintText: 'XXXX XXXX XXXX XXXX',
                          border: OutlineInputBorder(),
                        ),
                        expiryDateDecoration: InputDecoration(
                          labelText: 'Vence',
                          hintText: 'XX/XX',
                          border: OutlineInputBorder(),
                        ),
                        cvvCodeDecoration: InputDecoration(
                          labelText: 'CVV',
                          hintText: 'XXX',
                          border: OutlineInputBorder(),
                        ),
                        cardHolderDecoration: InputDecoration(
                          labelText: 'Titular',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    SizedBox(height: 20),

                    // RESUMEN DE PAGO
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Total a Pagar:",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("\$${cart.totalAmount.toStringAsFixed(0)}",
                              style: TextStyle(
                                  fontSize: 22,
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),

                    // BOTÓN PAGAR
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: _isLoading ? null : _processPayment,
                          child: _isLoading
                              ? CircularProgressIndicator(color: Colors.white)
                              : Text("PAGAR AHORA",
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
