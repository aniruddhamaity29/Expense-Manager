import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/url.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:month_picker_dialog/month_picker_dialog.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:pdf/widgets.dart' as pw;
import 'package:shimmer/shimmer.dart';
import 'package:skeletonizer/skeletonizer.dart';

class Monthly extends StatefulWidget {
  const Monthly({super.key});

  @override
  State<Monthly> createState() => _MonthlyState();
}

class _MonthlyState extends State<Monthly> {
  bool isLoading = true;
  DateTime currentDate = DateTime.now();
  int totalIncome = 0;
  int totalExpense = 0;
  int savings = 0;
  int balance = 0;
  List<Map<String, dynamic>> dailyTransactions = [];
  Map<String, List<Map<String, dynamic>>> groupedTransactions = {};
  RxString currencySymbol = ''.obs;
  SharedPreferences? sp;

  final String folderName = 'Reports';
  final String pdfFilename = 'Monthly_Report.pdf';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    sp = await SharedPreferences.getInstance();
    currencySymbol.value =
        sp?.getString('currency') ?? "\u20B9"; // Default to ₹

    await fetchDailyTransactions();
    await fetchMonthlyIncomeAndExpense();

    checkLoadingComplete();
  }

  Future<void> fetchDailyTransactions() async {
    if (sp == null) return;

    String month = currentDate.month.toString();
    String year = currentDate.year.toString();
    String userId = sp?.getString('user_id') ?? '';

    Map<String, String> data = {
      'user_id': userId,
      'month': month,
      'year': year,
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}get_all_transaction.php"),
        body: data,
      );

      var jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonData['status'] == true) {
        List<dynamic> expenseTransactions = jsonData['expense'] ?? [];
        List<dynamic> incomeTransactions = jsonData['income'] ?? [];

        setState(() {
          // Combine both income and expense transactions
          dailyTransactions = [
            ...expenseTransactions.map((e) => {...e, 'type': 'expense'}),
            ...incomeTransactions.map((i) => {...i, 'type': 'income'}),
          ];

          // Group transactions by date
          groupedTransactions = {};
          for (var transaction in dailyTransactions) {
            String date = transaction['date'];
            if (groupedTransactions.containsKey(date)) {
              groupedTransactions[date]!.add(transaction);
            } else {
              groupedTransactions[date] = [transaction];
            }
          }
        });
      } else {
        dailyTransactions = [];
      }
    } catch (e) {
      print('Error fetching daily transactions: $e');
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

  Future<void> fetchMonthlyIncomeAndExpense() async {
    if (sp == null) return;

    String month = currentDate.month.toString();
    String year = currentDate.year.toString();
    String userId = sp?.getString('user_id') ?? '';

    Map<String, String> data = {
      'user_id': userId,
      'month': month,
      'year': year,
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}total_income_expense.php"),
        body: data,
      );

      var jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonData['status'] == true) {
        setState(() {
          totalIncome = int.tryParse(jsonData['total_income'].toString()) ?? 0;
          totalExpense =
              int.tryParse(jsonData['total_expense'].toString()) ?? 0;
          balance = int.tryParse(jsonData['balance'].toString()) ?? 0;
        });
      } else {
        setState(() {
          totalIncome = 0;
          totalExpense = 0;
          balance = 0;
        });
      }
    } catch (e) {
      print('Error fetching monthly income and expense: $e');
    }

    checkLoadingComplete();
  }

  Widget buildTransactionCard(List<Map<String, dynamic>> transactions) {
    String date = transactions.isNotEmpty ? transactions[0]['date'] : '';
    List<Map<String, dynamic>> income = [];
    List<Map<String, dynamic>> expense = [];
    int dailyIncome = 0;
    int dailyExpense = 0;

    // Separate income and expense transactions and calculate the daily total
    for (var transaction in transactions) {
      if (transaction['type'] == 'income') {
        income.add(transaction);
        dailyIncome += int.tryParse(transaction['amount']?.toString() ?? '0')!;
      } else if (transaction['type'] == 'expense') {
        expense.add(transaction);
        dailyExpense += int.tryParse(transaction['amount']?.toString() ?? '0')!;
      }
    }

    // Calculate savings for the current date
    int dailySavings = dailyIncome - dailyExpense;

    // Build the transaction card for each date
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
          // Display the date
          Text(
            date,
            style: TextStyle(
              color: Colors.black,
              fontSize: Dimensions.font16,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: Dimensions.height8),

          // Row for Income and Expense sections
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Income Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Income (Credit)",
                    style: TextStyle(color: Colors.black),
                  ),
                  // Loop through income data and display each income transaction
                  ...income.map((sourceData) {
                    return Row(
                      children: [
                        Text(
                          "${sourceData['source']}",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: Dimensions.font16,
                              fontWeight: FontWeight.bold),
                        ),
                        Text(
                          " ${currencySymbol.value}${sourceData['amount']}",
                          style: TextStyle(
                              color: Colors.green,
                              fontSize: Dimensions.font16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    );
                  }),
                ],
              ),

              // Expense Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Expense (Debit)",
                    style: TextStyle(color: Colors.black),
                  ),
                  // Loop through expense data and display each expense transaction
                  ...expense.map((expenseData) {
                    return Row(
                      children: [
                        Text(
                          "${expenseData['purpose']}",
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: Dimensions.font16,
                              fontWeight: FontWeight.normal),
                        ),
                        Text(
                          " ${currencySymbol.value}${expenseData['amount']}",
                          style: TextStyle(
                              color: Colors.red,
                              fontSize: Dimensions.font16,
                              fontWeight: FontWeight.normal),
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ],
          ),
          const Divider(color: Colors.black),

          // Display savings for this specific date
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
                " ${currencySymbol.value}$dailySavings",
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

  void goToPreviousMonth() {
    setState(() {
      if (currentDate.month == 1) {
        currentDate = DateTime(currentDate.year - 1, 12);
      } else {
        currentDate = DateTime(currentDate.year, currentDate.month - 1);
      }
      isLoading = true;
      fetchMonthlyIncomeAndExpense();
      fetchDailyTransactions();
    });
  }

  void goToNextMonth() {
    setState(() {
      if (currentDate.month == 12) {
        currentDate = DateTime(currentDate.year + 1, 1);
      } else {
        currentDate = DateTime(currentDate.year, currentDate.month + 1);
      }
      isLoading = true;
      fetchMonthlyIncomeAndExpense();
      fetchDailyTransactions();
    });
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

  Future<void> generatePdfFile() async {
    QuickAlert.show(
      context: context,
      type: QuickAlertType.loading,
      title: 'Loading',
      text: 'Downloading monthly report',
    );
    // Get the directory to save the file
    final directory = await getApplicationDocumentsDirectory();
    final filePath = '${directory.path}/$folderName/$pdfFilename';
    // Load the custom font
    final ttfFont = await rootBundle.load("asset/fonts/Roboto-Regular.ttf");
    final pdfFont = pw.Font.ttf(ttfFont);

    // Create the PDF document
    final pdf = pw.Document();

    // Group transactions by date
    final groupedTransactions = <String, List<Map<String, dynamic>>>{};
    for (final transaction in dailyTransactions) {
      final date = transaction['date'];
      if (groupedTransactions[date] == null) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }

    // Add the content to the PDF
    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title
              pw.Align(
                alignment: pw.Alignment.topCenter,
                child: pw.Text(
                  'Monthly Transaction Report',
                  style: pw.TextStyle(
                    font: pdfFont,
                    color: PdfColor.fromHex("#75193A"),
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.SizedBox(height: 20),

              // Table Header
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2), // Date
                  1: const pw.FlexColumnWidth(4), // Income Details
                  2: const pw.FlexColumnWidth(4), // Expense Details
                  3: const pw.FlexColumnWidth(2), // Savings
                },
                children: [
                  // Header Row
                  pw.TableRow(
                    decoration:
                        pw.BoxDecoration(color: PdfColor.fromHex("#1B2479")),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Date',
                            style: pw.TextStyle(
                              fontSize: 12, font: pdfFont, // Apply custom font
                              color: PdfColor.fromHex("#FFFFFF"),
                            )),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Details of Income',
                            style: pw.TextStyle(
                              fontSize: 12, font: pdfFont, // Apply custom font
                              color: PdfColor.fromHex("#FFFFFF"),
                            )),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Details of Expense',
                            style: pw.TextStyle(
                              fontSize: 12, font: pdfFont, // Apply custom font
                              color: PdfColor.fromHex("#FFFFFF"),
                            )),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8.0),
                        child: pw.Text('Savings',
                            style: pw.TextStyle(
                              fontSize: 12, font: pdfFont, // Apply custom font
                              color: PdfColor.fromHex("#FFFFFF"),
                            )),
                      ),
                    ],
                  ),
                  // Populate Rows
                  ...groupedTransactions.entries.expand((entry) {
                    final date = entry.key;
                    final transactions = entry.value;

                    // Separate income and expense transactions
                    final incomeTransactions = transactions
                        .where((t) => t['type'] == 'income')
                        .toList();
                    final expenseTransactions = transactions
                        .where((t) => t['type'] == 'expense')
                        .toList();

                    // Calculate total income and expense for the date
                    final totalIncome = incomeTransactions.fold(
                      0.0, // Start with 0.0 to handle potential float values
                      (sum, t) =>
                          sum +
                          (t['amount'] != null
                              ? double.tryParse(t['amount'].toString()) ?? 0.0
                              : 0.0),
                    );
                    final totalExpense = expenseTransactions.fold(
                      0.0, // Start with 0.0 to handle potential float values
                      (sum, t) =>
                          sum +
                          (t['amount'] != null
                              ? double.tryParse(t['amount'].toString()) ?? 0.0
                              : 0.0),
                    );
                    final savings = totalIncome - totalExpense;

                    // Generate rows for this date
                    return [
                      pw.TableRow(
                        children: [
                          // Date
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(date,
                                style: pw.TextStyle(
                                    fontSize: 10,
                                    fontWeight: pw.FontWeight.bold)),
                          ),
                          // Income Details
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              incomeTransactions.isNotEmpty
                                  ? incomeTransactions
                                      .map((t) =>
                                          'Description: ${t['source']}, Amount: ${currencySymbol.value}${t['amount']}')
                                      .join('\n')
                                  : 'No Income',
                              style: pw.TextStyle(fontSize: 10, font: pdfFont),
                            ),
                          ),
                          // Expense Details
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              expenseTransactions.isNotEmpty
                                  ? expenseTransactions
                                      .map((t) =>
                                          'Purpose: ${t['purpose']}, Amount: ${currencySymbol.value}${t['amount']}')
                                      .join('\n')
                                  : 'No Expense',
                              style: pw.TextStyle(fontSize: 10, font: pdfFont),
                            ),
                          ),
                          // Savings
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(8.0),
                            child: pw.Text(
                              '${currencySymbol.value}$savings',
                              style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  font: pdfFont),
                            ),
                          ),
                        ],
                      ),
                    ];
                  }).toList(),
                ],
              ),
            ],
          );
        },
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.purple[200],
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: goToPreviousMonth,
        ),
        title: GestureDetector(
          onTap: () {
            showMonthPicker(
              context: context,
              initialDate: currentDate,
            ).then((date) {
              if (date != null) {
                setState(() {
                  currentDate = date;
                  isLoading = true;
                  fetchMonthlyIncomeAndExpense();
                  fetchDailyTransactions();
                });
              }
            });
          },
          child: Text(
            DateFormat('MMMM yyyy').format(currentDate),
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
            onPressed: goToNextMonth,
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
                      itemCount: groupedTransactions.length,
                      itemBuilder: (context, index) {
                        String date = groupedTransactions.keys.elementAt(index);
                        List<Map<String, dynamic>> transactions =
                            groupedTransactions[date]!;
                        return buildTransactionCard(transactions);
                      },
                    ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          generatePdfFile();
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
