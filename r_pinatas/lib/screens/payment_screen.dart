import 'package:flutter/material.dart';
import 'package:flutter_credit_card/flutter_credit_card.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/cart_provider.dart';

class PaymentScreen extends StatefulWidget {
  final double totalAmount;

  const PaymentScreen({super.key, required this.totalAmount});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String cardNumber = '';
  String expiryDate = '';
  String cardHolderName = '';
  String cvvCode = '';
  bool isCvvFocused = false;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Pago Seguro"),
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        elevation: 0,
        titleTextStyle: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 18,
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // TARJETA VISUAL ANIMADA
            CreditCardWidget(
              cardNumber: cardNumber,
              expiryDate: expiryDate,
              cardHolderName: cardHolderName,
              cvvCode: cvvCode,
              showBackView: isCvvFocused,
              obscureCardNumber: true,
              obscureCardCvv: true,
              isHolderNameVisible: true,
              cardBgColor: Colors.black87,
              isSwipeGestureEnabled: true,
              onCreditCardWidgetChange: (CreditCardBrand creditCardBrand) {},
            ),

            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // FORMULARIO SIMPLIFICADO (Sin parámetros conflictivos)
                    CreditCardForm(
                      formKey: formKey,
                      obscureCvv: true,
                      obscureNumber: true,
                      cardNumber: cardNumber,
                      cvvCode: cvvCode,
                      isHolderNameVisible: true,
                      isCardNumberVisible: true,
                      isExpiryDateVisible: true,
                      cardHolderName: cardHolderName,
                      expiryDate: expiryDate,
                      // Eliminamos themeColor, textColor y decorations personalizados
                      // para usar los estilos por defecto de la nueva versión y evitar errores.
                      onCreditCardModelChange:
                          (CreditCardModel? creditCardModel) {
                            setState(() {
                              cardNumber = creditCardModel!.cardNumber;
                              expiryDate = creditCardModel.expiryDate;
                              cardHolderName = creditCardModel.cardHolderName;
                              cvvCode = creditCardModel.cvvCode;
                              isCvvFocused = creditCardModel.isCvvFocused;
                            });
                          },
                    ),

                    const SizedBox(height: 20),

                    // BOTÓN DE PAGO CON LÓGICA DE FIREBASE
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onPressed: _isProcessing ? null : _onValidate,
                          child: _isProcessing
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 10),
                                    Text("Procesando..."),
                                  ],
                                )
                              : const Text(
                                  'PAGAR AHORA',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
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

  void _onValidate() async {
    if (formKey.currentState!.validate()) {
      setState(() => _isProcessing = true);

      // 1. SIMULACIÓN DE TIEMPO BANCARIO (3 segundos)
      await Future.delayed(const Duration(seconds: 3));

      // 2. GUARDAR ORDEN EN FIREBASE
      if (!mounted) return;
      await _saveOrderToFirebase();
    } else {
      // Usamos debugPrint en lugar de print para producción
      debugPrint('Formulario inválido');
    }
  }

  Future<void> _saveOrderToFirebase() async {
    final cart = Provider.of<CartProvider>(context, listen: false);
    final user = FirebaseAuth.instance.currentUser;
    final products = cart.productDetails;

    try {
      final List<Map<String, dynamic>> orderItems = [];
      cart.items.forEach((productId, quantity) {
        if (products.containsKey(productId)) {
          final product = products[productId]!;
          orderItems.add({
            'productId': productId,
            'name': product.name,
            'price': product.price,
            'quantity': quantity,
            'image': product.images.isNotEmpty ? product.images[0] : '',
          });
        }
      });

      // Crear objeto de orden
      final orderData = {
        'userId': user!.uid,
        'userEmail': user.email,
        'totalAmount': widget.totalAmount,
        'status': 'Pagado', // ¡YA ENTRA COMO PAGADO!
        'paymentMethod':
            'Tarjeta ${cardNumber.length >= 4 ? cardNumber.substring(cardNumber.length - 4) : '****'}',
        'createdAt': FieldValue.serverTimestamp(),
        'items': orderItems,
      };

      // Guardar en Firestore
      await FirebaseFirestore.instance.collection('orders').add(orderData);

      // Limpiar carrito
      cart.clearCart();

      if (!mounted) return;

      // ÉXITO
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          icon: const Icon(Icons.check_circle, color: Colors.green, size: 60),
          title: const Text("¡Pago Exitoso!"),
          content: const Text(
            "Tu pedido ha sido confirmado y pagado correctamente.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Cierra diálogo
                Navigator.pop(context); // Cierra pantalla pago
                Navigator.pop(context); // Regresa al Home
              },
              child: const Text("Aceptar"),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }
}
