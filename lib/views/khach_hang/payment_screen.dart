// import 'package:flutter/material.dart';
// // import 'package:momo_vn/momo_vn.dart';

// class PaymentScreen extends StatefulWidget {
//   final int userId;
//   final double amount;
//   final String invoiceId; // Dùng làm orderId hoặc nhận diện hóa đơn
//   final String period;

//   const PaymentScreen({
//     super.key, 
//     required this.userId, 
//     required this.amount, 
//     required this.invoiceId,
//     required this.period,
//   });

//   @override
//   State<PaymentScreen> createState() => _PaymentScreenState();
// }

// class _PaymentScreenState extends State<PaymentScreen> {
//   late MomoVn _momoPay;
//   String _paymentStatus = "Đang khởi tạo thanh toán...";
//   bool _isProcessing = false;

//   @override
//   void initState() {
//     super.initState();
//     _momoPay = MomoVn();
    
//     // Đăng ký lắng nghe sự kiện trả về từ MoMo
//     _momoPay.on(MomoVn.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
//     _momoPay.on(MomoVn.EVENT_PAYMENT_ERROR, _handlePaymentError);

//     // Tự động kích hoạt ví MoMo sau khi vào màn hình 0.5 giây
//     Future.delayed(const Duration(milliseconds: 500), () {
//       _openMomoPayment();
//     });
//   }

//   @override
//   void dispose() {
//     _momoPay.clear();
//     super.dispose();
//   }

//   void _handlePaymentSuccess(PaymentResponse response) {
//     setState(() {
//       _isProcessing = false;
//       _paymentStatus = "Thành công! Đang đồng bộ hệ thống...";
//     });
    
//     // Hiện thông báo thành công
//     _showResultDialog(
//       title: "Thành công",
//       message: "Giao dịch thành công. Token: ${response.token}",
//       isSuccess: true,
//     );
//     // TODO: Gửi response.token này về Backend PHP của bạn để gọi API xác thực với MoMo
//   }

//   void _handlePaymentError(PaymentResponse response) {
//     setState(() {
//       _isProcessing = false;
//       _paymentStatus = "Giao dịch thất bại hoặc bị hủy.";
//     });
    
//     _showResultDialog(
//       title: "Thất bại",
//       message: response.message ?? "Người dùng hủy giao dịch hoặc lỗi kết nối.",
//       isSuccess: false,
//     );
//   }

//   void _openMomoPayment() {
//     if (_isProcessing) return;
//     setState(() {
//       _isProcessing = true;
//       _paymentStatus = "Đang kết nối ví MoMo...";
//     });

//     MomoPaymentInfo options = MomoPaymentInfo(
//       merchantName: "Hệ thống Phòng Trọ",
//       merchantCode: "MOMOI9RE20220907", // Mã test mặc định
//       appScheme: "MOMOI9RE20220907",
//       amount: widget.amount.toInt(), // Ép kiểu số tiền về dạng Int
//       orderId: "HD_${widget.invoiceId}_${DateTime.now().millisecondsSinceEpoch}",
//       orderLabel: "Tiền nhà Kỳ tháng ${widget.period}",
//       merchantNameLabel: "Thanh toán hóa đơn",
//       fee: 0,
//       description: "Thanh toán hóa đơn phòng trọ kỳ tháng ${widget.period}",
//       username: "user_${widget.userId}",
//       partnerCode: "MOMOI9RE20220907",
//       isTestMode: true, partner: '', // Bật true để chạy môi trường thử nghiệm (Sandbox)
//     );

//     try {
//       _momoPay.open(options);
//     } catch (e) {
//       setState(() {
//         _isProcessing = false;
//         _paymentStatus = "Không thể mở ứng dụng MoMo.";
//       });
//     }
//   }

//   void _showResultDialog({required String title, required String message, required bool isSuccess}) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: Row(
//           children: [
//             Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
//             const SizedBox(width: 8),
//             Text(title),
//           ],
//         ),
//         content: Text(message),
//         actions: [
//           TextButton(
//             onPressed: () {
//               Navigator.pop(context); // Đóng Dialog
//               Navigator.pop(context, isSuccess); // Quay lại HomeScreen (trả về kết quả true/false nếu cần load lại dữ liệu)
//             },
//             child: const Text("Xác nhận", style: TextStyle(fontWeight: FontWeight.bold)),
//           )
//         ],
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Thanh toán MoMo"),
//         backgroundColor: const Color(0xFF2563EB),
//         foregroundColor: Colors.white,
//       ),
//       body: Center(
//         child: Padding(
//           padding: const EdgeInsets.all(24.0),
//           child: Column(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Image.network(
//                 'https://upload.wikimedia.org/wikipedia/vi/f/fe/MoMo_Logo.png', 
//                 height: 80, 
//                 errorBuilder: (c, e, s) => const Icon(Icons.wallet, size: 80, color: Colors.pink)
//               ),
//               const SizedBox(height: 24),
//               Text(
//                 _paymentStatus,
//                 textAlign: TextAlign.center,
//                 style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF1E293B)),
//               ),
//               const SizedBox(height: 32),
//               if (_isProcessing)
//                 const CircularProgressIndicator(color: Colors.pink)
//               else
//                 ElevatedButton.icon(
//                   onPressed: _openMomoPayment,
//                   icon: const Icon(Icons.refresh),
//                   label: const Text("Thử thanh toán lại"),
//                   style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), foregroundColor: Colors.white),
//                 )
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }