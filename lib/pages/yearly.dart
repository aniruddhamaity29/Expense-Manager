import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/url.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:pdf/widgets.dart' as pw;

class Yearly extends StatefulWidget {
  const Yearly({super.key});

  @override
  State<Yearly> createState() => _YearlyState();
}

class _YearlyState extends State<Yearly> {
  bool isLoading = true;
  DateTime currentDate = DateTime.now();
  int totalIncome = 0;
  int totalExpense = 0;
  int savings = 0;
  int balance = 0;
  List<Map<String, dynamic>> monthlyTransactions = [];
  Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
  RxString currencySymbol = ''.obs;
  SharedPreferences? sp;

  final String folderName = 'Reports';
  final String pdfFilename = 'Yearly_Report.pdf';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    sp = await SharedPreferences.getInstance();
    currencySymbol.value =
        sp?.getString('currency') ?? "\u20B9"; // Default to ₹

    await fetchMonthlyTransactions();
    await fetchYearlyIncomeAndExpense();

    checkLoadingComplete();
  }

  Future<void> fetchMonthlyTransactions() async {
    if (sp == null) return;

    String year = currentDate.year.toString();
    String userId = sp?.getString('user_id') ?? '';

    Map<String, String> data = {
      'user_id': userId,
      'year': year,
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}get_month_transaction.php"),
        body: data,
      );

      // Decode the response body
      var jsonData = jsonDecode(response.body) as Map<String, dynamic>;

      if (jsonData['status'] == true) {
        List<Map<String, dynamic>> transactions =
            []; // Explicitly define the type here

        // Check if 'transactions' key exists in the response
        if (jsonData.containsKey('transactions')) {
          // Loop through the transactions for the year
          for (var transaction in jsonData['transactions']) {
            transactions.add({
              "monthyear": transaction['monthyear'],
              "total_income": transaction['total_income'],
              "total_expense": transaction['total_expense'],
              "savings": transaction['savings'],
            });
          }
        }

        setState(() {
          monthlyTransactions =
              transactions; // Update the state with the transactions
        });
      } else {
        setState(() {
          monthlyTransactions = []; // Handle case where status is false
        });
      }
    } catch (e) {
      print('Error fetching monthly transactions: $e');
    }

    checkLoadingComplete();
  }

  void checkLoadingComplete() {
    if (mounted) {
      setState(() {
        isLoading = false; // Stop loading once data is fetched
      });
    }
  }

  Future<void> fetchYearlyIncomeAndExpense() async {
    if (sp == null) return;

    String year = currentDate.year.toString();
    String userId = sp?.getString('user_id') ?? '';

    Map<String, String> data = {
      'user_id': userId,
      'year': year,
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}yearly_income_expense.php"),
        body: data,
      );

      var jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonData['status'] == true) {
        setState(() {
          totalIncome = int.tryParse(jsonData['total_income'].toString()) ?? 0;
          totalExpense =
              int.tryParse(jsonData['total_expense'].toString()) ?? 0;
          balance = int.tryParse(jsonData['savings'].toString()) ?? 0;
        });
      } else {
        setState(() {
          totalIncome = 0;
          totalExpense = 0;
          savings = 0;
        });
      }
    } catch (e) {
      print('Error fetching yearly income and expense: $e');
    }

    checkLoadingComplete();
  }

  Widget buildMonthlyTransactionCard({
    required String monthyear,
    required int totalIncome,
    required int totalExpense,
    required int savings,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: Dimensions.height10),
      padding: EdgeInsets.all(Dimensions.height10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 161, 201, 221),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Display the month-year
          Text(
            monthyear,
            style: TextStyle(
              color: Colors.black,
              fontSize: Dimensions.font16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Dimensions.height8),

          // Row for displaying Total Income and Total Expense
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Total Income Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Income",
                    style: TextStyle(color: Colors.black),
                  ),
                  Text(
                    " ${currencySymbol.value}$totalIncome",
                    style: TextStyle(
                        color: Colors.green,
                        fontSize: Dimensions.font16,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),

              // Total Expense Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Total Expense",
                    style: TextStyle(color: Colors.black),
                  ),
                  Text(
                    " ${currencySymbol.value}$totalExpense",
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: Dimensions.font16,
                        fontWeight: FontWeight.normal),
                  ),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.black),

          // Display savings for this specific month
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                "Savings:",
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
              Text(
                " ${currencySymbol.value}$savings",
                style: const TextStyle(
                  fontWeight: FontWeight.normal,
                  color: Colors.black,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void goToPreviousYear() {
    setState(() {
      currentDate = DateTime(currentDate.year - 1);
    });
    isLoading = true;
    fetchYearlyIncomeAndExpense();
    fetchMonthlyTransactions();
  }

  void goToNextYear() {
    setState(() {
      currentDate = DateTime(currentDate.year + 1);
    });
    isLoading = true;
    fetchYearlyIncomeAndExpense();
    fetchMonthlyTransactions();
  }

  List<PieChartSectionData> showingSections() {
    final total = totalIncome;

    // Prevent division by zero and ensure meaningful percentages
    final double expensePercentage =
        total > 0 ? (totalExpense / total) * 100 : (totalExpense > 0 ? 100 : 0);
    final double savingsPercentage =
        total > 0 ? (balance / total) * 100 : (balance > 0 ? 100 : 0);

    return [
      PieChartSectionData(
        color: Colors.redAccent,
        value: expensePercentage,
        title: expensePercentage > 0
            ? '${expensePercentage.toStringAsFixed(1)}%'
            : '',
        radius: 30,
        titleStyle: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      PieChartSectionData(
        color: Colors.green[600]!,
        value: savingsPercentage,
        title: savingsPercentage > 0
            ? '${savingsPercentage.toStringAsFixed(1)}%'
            : '',
        radius: 30,
        titleStyle: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    ];
  }

  // Method to build indicator for the pie chart
  Widget buildIndicator(Color color, String text) {
    return Row(
      children: [
        Container(
          width: Dimensions.width20,
          height: Dimensions.height20,
          color: color,
        ),
        SizedBox(width: Dimensions.width6),
        Text(text),
      ],
    );
  }

  Future generatePdfFile_YearlyReport() async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Loading',
      text: 'Downloading yearly report',
    );

    // Get the directory to save the file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$folderName/$pdfFilename';
    // Load the custom font
    final ttfFont = await rootBundle.load("asset/fonts/Roboto-Regular.ttf");
    final pdfFont = pw.Font.ttf(ttfFont);

    // Define the column headings for the report
    List<String> colHeadings = [
      'Month/Year',
      'Total Income',
      'Total Expense',
      'Savings'
    ];

    // Map `dailyTransactions` data into a format suitable for the PDF table rows
    final transactionData = monthlyTransactions.map((transaction) {
      return [
        transaction['monthyear'] ?? 'N/A', // Month/Year field
        '${currencySymbol.value}${transaction['total_income']?.toString() ?? '0'}', // Total Income with ₹ symbol
        '${currencySymbol.value}${transaction['total_expense']?.toString() ?? '0'}', // Total Expense with ₹ symbol
        '${currencySymbol.value}${transaction['savings']?.toString() ?? '0'}', // Savings with ₹ symbol
      ];
    }).toList();

    // Create the PDF document
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        orientation: pw.PageOrientation.portrait,
        build: (pw.Context context) => [
          pw.Align(
            alignment: pw.Alignment.topCenter,
            child: pw.Text(
              'Yearly Transaction Report',
              style: pw.TextStyle(
                font: pdfFont, // Use the custom font
                color: PdfColor.fromHex("#75193A"),
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 20),
          // Table with column headers and transaction data
          pw.Table.fromTextArray(
            headers: colHeadings,
            data: transactionData,
            headerAlignment: pw.Alignment.center,
            cellAlignment: pw.Alignment.center,
            headerStyle: pw.TextStyle(
              font: pdfFont, // Use the custom font for headers
              color: PdfColor.fromHex("#FFFFFF"),
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: pw.BoxDecoration(
              color: PdfColor.fromHex("#1B2479"),
            ),
            cellStyle: pw.TextStyle(
              font: pdfFont, // Use the custom font for cell text
            ),
            cellPadding:
                const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 8),
            cellHeight: 30,
            tableWidth: pw.TableWidth.max,
            columnWidths: {
              0: const pw.FlexColumnWidth(2), // Month/Year column width
              1: const pw.FlexColumnWidth(2), // Total Income width
              2: const pw.FlexColumnWidth(2), // Total Expense width
              3: const pw.FlexColumnWidth(2), // Savings width
            },
          ),
        ],
      ),
    );

    // Save the PDF to the file system
    final file = File(filePath);
    await file.create(recursive: true);
    await file.writeAsBytes(await pdf.save());
    Navigator.pop(context);
    // Show a success message
    QuickAlert.show(
      context: context,
      type: QuickAlertType.success,
      title: 'PDF Generated!',
      onConfirmBtnTap: () {
        OpenFile.open(filePath); // Open the generated PDF
      },
      showCancelBtn: true,
      onCancelBtnTap: () {
        Navigator.pop(context);
      },
    );
  }

  Future<bool> _requestPermission(Permission permission) async {
    if (await permission.isGranted) {
      return true;
    } else {
      PermissionStatus result = await permission.request();
      if (result == PermissionStatus.granted) {
        return true;
      } else {
        return false;
      }
    }
  }

  void getPermissions() async {
    if (Platform.isAndroid) {
      final pt = await Permission.storage.status;
      if (pt.isDenied) {
        AndroidDeviceInfo deviceInfo = await DeviceInfoPlugin().androidInfo;
        if (deviceInfo.version.sdkInt >= 30) {
          await _requestPermission(Permission.manageExternalStorage);
        } else {
          await _requestPermission(Permission.storage);
        }
      }
      await _requestPermission(Permission.accessMediaLocation);
    }
  }

  Widget buildShimmerCard() {
    return Container(
      margin: EdgeInsets.only(bottom: Dimensions.height10),
      padding: EdgeInsets.all(Dimensions.height10),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: Dimensions.width100,
            height: Dimensions.height15,
            color: Colors.grey[800],
          ),
          SizedBox(height: Dimensions.height8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  2,
                  (index) => Padding(
                    padding: EdgeInsets.symmetric(vertical: Dimensions.height5),
                    child: Container(
                      width: Dimensions.width100,
                      height: Dimensions.height15,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(
                  2,
                  (index) => Padding(
                    padding: EdgeInsets.symmetric(vertical: Dimensions.height5),
                    child: Container(
                      width: Dimensions.width100,
                      height: Dimensions.height15,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: Dimensions.height10),
          Container(
            width: Dimensions.width50,
            height: Dimensions.height15,
            color: Colors.grey[800],
          ),
        ],
      ),
    );
  }

  Future<void> selectYear(BuildContext context) async {
    final DateTime? pickedYear = await showDialog(
      context: context,
      barrierDismissible: true, // Allow quick dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Year'),
          content: SizedBox(
            height: Dimensions.height300,
            child: YearPicker(
              firstDate: DateTime(DateTime.now().year - 10),
              lastDate: DateTime(2030),
              // ignore: deprecated_member_use
              initialDate: currentDate,
              selectedDate: currentDate,
              onChanged: (DateTime dateTime) {
                Navigator.pop(
                    context, dateTime); // Dismiss immediately on selection
              },
            ),
          ),
        );
      },
    );

    // Only refresh data if the year actually changed
    if (pickedYear != null) {
      setState(() {
        currentDate = pickedYear;
        isLoading = true;
      });
      fetchYearlyIncomeAndExpense();
      fetchMonthlyTransactions();
    }
  }

  @override
  Widget build(BuildContext context) {
    String formattedYear = DateFormat('yyyy').format(currentDate);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[200],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: goToPreviousYear,
        ),
        title: GestureDetector(
          onTap: () => selectYear(context),
          child: Text(
            formattedYear,
            style: TextStyle(
              color: Colors.white,
              fontSize: Dimensions.font18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_forward, color: Colors.white),
            onPressed: goToNextYear,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(Dimensions.height10),
          child: Column(
            children: [
              Skeletonizer(
                enabled: isLoading,
                child: Container(
                  padding: EdgeInsets.all(Dimensions.height10),
                  decoration: BoxDecoration(
                    color: Colors.purple[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Income (Credit)",
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: Dimensions.height5),
                          Text(
                            "= ${currencySymbol.value}$totalIncome",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: Dimensions.font16),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Total Expense (Debit)",
                            style: TextStyle(color: Colors.white70),
                          ),
                          SizedBox(height: Dimensions.height5),
                          Text(
                            "= ${currencySymbol.value}${totalExpense.abs()}",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: Dimensions.font16),
                          ),
                          SizedBox(height: Dimensions.height5),
                          Text(
                            "Savings=${currencySymbol.value}$balance",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: Dimensions.font16),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(
                height: Dimensions.height150, // Set a height for the pie chart

                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    PieChart(
                      PieChartData(
                        sections: showingSections(),
                        centerSpaceRadius: 30,
                        sectionsSpace: 1,
                        borderData: FlBorderData(show: false),
                        startDegreeOffset: 0,
                      ),
                    ),
                    // Center text for income amount
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Income',
                          style: TextStyle(
                            fontSize: Dimensions.font10,
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${currencySymbol.value}$totalIncome', // Display income for selected time frame
                          style: TextStyle(
                            fontSize: Dimensions.font12,
                            color: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),

                    // Indicators for Expense and Savings
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: <Widget>[
                        buildIndicator(Colors.redAccent, 'Expense'),
                        SizedBox(height: Dimensions.height5),
                        buildIndicator(Colors.green, 'Saving'),
                      ],
                    ),
                  ],
                ),
              ),
              SizedBox(height: Dimensions.height10),
              isLoading
                  ? Padding(
                      padding: EdgeInsets.all(Dimensions.height8),
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey.shade300,
                        highlightColor: Colors.grey.shade100,
                        child: Column(
                          children:
                              List.generate(3, (index) => buildShimmerCard()),
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      shrinkWrap: true,
                      itemCount: monthlyTransactions.length,
                      itemBuilder: (context, index) {
                        final transaction = monthlyTransactions[index];
                        return buildMonthlyTransactionCard(
                          monthyear: transaction['monthyear'],
                          totalIncome:
                              int.parse(transaction['total_income'].toString()),
                          totalExpense: int.parse(
                              transaction['total_expense'].toString()),
                          savings: int.parse(transaction['savings'].toString()),
                        );
                      },
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          generatePdfFile_YearlyReport();
        },
        backgroundColor: Colors.purple[200],
        shape: const CircleBorder(),
        child: Icon(
          Icons.picture_as_pdf,
          size: Dimensions.icon35,
          color: Colors.white,
        ),
      ),
    );
  }
}
