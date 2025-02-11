import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/expense.dart';
import 'package:flutter_application_1/pages/earn.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/loading.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:flutter_application_1/utils/url.dart';
import 'package:http/http.dart' as http;
import 'package:ionicons/ionicons.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:toastification/toastification.dart';

class Daily extends StatefulWidget {
  const Daily({super.key});

  @override
  State<Daily> createState() => _DailyState();
}

class _DailyState extends State<Daily> {
  // Controllers for input fields
  TextEditingController purposeController = TextEditingController();
  TextEditingController expenseAmountController = TextEditingController();
  TextEditingController sourceController = TextEditingController();
  TextEditingController incomeAmountController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  // State variables
  bool isIncomeSelected = true;
  bool isIncomeMode = false; // Flag to indicate if we're in income mode

  late SharedPreferences sp;
  DateTime currentDate = DateTime.now();
  String formattedDate = "";
  String userId = '';

  // Lists to hold fetched data
  List<Expense> expensesList = [];
  List<Earn> incomesList = [];

  // Reactive state variables using GetX
  RxInt stIncome = 0.obs;
  RxInt stExpense = 0.obs;
  RxInt stSavings = 0.obs;
// Track the previous month and year
  int previousMonth = DateTime.now().month;
  int previousYear = DateTime.now().year;

  @override
  void initState() {
    formattedDate = DateFormat('MMMM dd, yyyy').format(currentDate);
    fetchUserId().then((_) {
      fetchAllData(); // Fetch data after obtaining userId and stSavings
    });
    final int income = stIncome.value;
    final int expense = stExpense.value;
    checkExpenseAndShowSnackbar(context, income, expense);
    super.initState();
  }

  void checkExpenseAndShowSnackbar(
      BuildContext context, int income, int expense) {
    if (income == 0 && expense > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('You are spending too much without any income!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Reset savings if the month changes

  @override
  void dispose() {
    purposeController.dispose();
    expenseAmountController.dispose();
    sourceController.dispose();
    incomeAmountController.dispose();
    super.dispose();
  }

  RxString currencySymbol = ''.obs;
  // Fetch userId from SharedPreferences and load stSavings
  Future<void> fetchUserId() async {
    sp = await SharedPreferences.getInstance();
    userId = sp.getString('user_id') ?? '';
    currencySymbol.value = sp.getString('currency') ?? "\u20B9"; // Default to ₹
    // Load stSavings from SharedPreferences using a unique key
    stSavings.value = sp.getInt('savings_$userId') ?? 0;
  }

  bool isLoading = true;

  // Fetch both expenses and incomes concurrently
  Future<void> fetchAllData() async {
    String selectedDate = DateFormat('dd/MM/yyyy').format(currentDate);

    setState(() {
      isLoading = true;
      stIncome.value = 0;
      stExpense.value = 0;
      stSavings.value = 0;
    });

    try {
      // Fetch expenses and incomes concurrently
      final results = await Future.wait([
        fetchExpenses(userId, selectedDate),
        fetchIncomes(userId, selectedDate),
      ]);

      List<Expense> fetchedExpenses = results[0] as List<Expense>;
      List<Earn> fetchedIncomes = results[1] as List<Earn>;

      // stIncome and stExpense are already being updated in fetchExpenses and fetchIncomes

      setState(() {
        expensesList = fetchedExpenses;
        incomesList = fetchedIncomes;
        stSavings.value = stIncome.value - stExpense.value;

        isLoading = false;
      });
    } catch (e) {
      print('Error fetching all data: $e');
    }
  }

  // Fetch expenses from API
  Future<List<Expense>> fetchExpenses(
      String userId, String selectedDate) async {
    Map data = {
      'user_id': userId,
      'date': selectedDate,
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}get_details.php"),
        body: data,
      );
      var jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonData['status'] == true) {
        List<Expense> tempList = (jsonData['data'] as List)
            .map((item) => Expense.fromJson(item))
            .toList();
        for (Expense x in tempList) {
          stExpense.value += x.amount;
        }
        return tempList;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching expenses: $e');
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text('Error fetching expenses'),
        autoCloseDuration: const Duration(seconds: 2),
        style: ToastificationStyle.flatColored,
        applyBlurEffect: true,
        icon: const Icon(
          Ionicons.close_circle,
          color: Colors.red,
        ),
        type: ToastificationType.error,
        pauseOnHover: true,
      );

      return [];
    }
  }

  // Fetch incomes from API
  Future<List<Earn>> fetchIncomes(String userId, String selectedDate) async {
    Map data = {
      'user_id': userId,
      'date': selectedDate,
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}income_get_details.php"),
        body: data,
      );
      var jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonData['status'] == true) {
        List<Earn> tempList = (jsonData['data'] as List)
            .map((item) => Earn.fromJson(item))
            .toList();
        for (Earn x in tempList) {
          stIncome.value += x.amount;
        }
        return tempList;
      } else {
        return [];
      }
    } catch (e) {
      print('Error fetching incomes: $e');
      toastification.show(
        context: context, // optional if you use ToastificationWrapper
        title: Text('Error fetching incomes'),
        autoCloseDuration: const Duration(seconds: 2),
        style: ToastificationStyle.flatColored,
        applyBlurEffect: true,
        icon: const Icon(
          Ionicons.close_circle,
          color: Colors.red,
        ),
        type: ToastificationType.error,
        pauseOnHover: true,
      );
      return [];
    }
  }

  HashSet<int> selectedExpenseItems = HashSet<int>();
  HashSet<int> selectedIncomeItems = HashSet<int>();
  bool isMultiSelectionEnabled = false;
  bool selectAllEnabled = false;

  // AppBar actions for editing and deleting selected items

  // Widget for empty layout
  Widget emptyLayout() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_outlined,
            size: Dimensions.icon50,
            color: Colors.grey,
          ),
          SizedBox(height: Dimensions.height10),
          Text(
            'No records for this day.\nTap + to add new expenses or incomes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey,
              fontSize: Dimensions.font15,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  //expensesSection Widget
  Widget expensesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(top: Dimensions.height8),
          child: SizedBox(
            height: Dimensions.height50,
            width: Dimensions.width355,
            child: Card(
              color: Colors.purple[100],
              shape: const RoundedRectangleBorder(),
              child: Padding(
                padding: EdgeInsets.all(Dimensions.height8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Expenses(Debit)',
                      style: TextStyle(
                        fontSize: Dimensions.font20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    Obx(
                      () => Text(
                        '${currencySymbol.value}${stExpense.value}',
                        style: TextStyle(
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                          fontSize: Dimensions.font15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        expensesList.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: expensesList.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedExpenseItems.contains(index);
                  final expense = expensesList[index];
                  return ListTile(
                    tileColor: isSelected ? Colors.grey[300] : Colors.white,
                    title: Text(expense.purpose),
                    trailing: Text(
                      '${currencySymbol.value}${expense.amount}',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: Dimensions.font15,
                      ),
                    ),
                    onLongPress: () {
                      setState(() {
                        isMultiSelectionEnabled = true;
                        if (isSelected) {
                          selectedExpenseItems.remove(index);
                        } else {
                          selectedExpenseItems.add(index);
                        }
                      });
                    },
                    onTap: () {
                      if (isMultiSelectionEnabled) {
                        setState(() {
                          if (isSelected) {
                            selectedExpenseItems.remove(index);
                          } else {
                            selectedExpenseItems.add(index);
                          }
                          if (selectedExpenseItems.isEmpty) {
                            isMultiSelectionEnabled = false;
                          }
                        });
                      }
                    },
                  );
                },
              )
            : Padding(
                padding: EdgeInsets.only(
                    top: Dimensions.height8, left: Dimensions.width8),
                child: const Text(
                  'No expenses for this day.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
      ],
    );
  }

//incomesSection Widget
  Widget incomesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: Dimensions.height50,
          width: Dimensions.width355,
          child: Card(
            color: Colors.purple[100],
            shape: const RoundedRectangleBorder(),
            child: Padding(
              padding: EdgeInsets.all(Dimensions.height8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Incomes(Credit)',
                    style: TextStyle(
                      fontSize: Dimensions.font20,
                      fontWeight: FontWeight.w500,
                      color: Colors.black,
                    ),
                  ),
                  Obx(
                    () => Text(
                      '${currencySymbol.value}${stIncome.value}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                        fontSize: Dimensions.font15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        incomesList.isNotEmpty
            ? ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: incomesList.length,
                itemBuilder: (context, index) {
                  bool isSelected = selectedIncomeItems.contains(index);
                  final income = incomesList[index];
                  return ListTile(
                    tileColor: isSelected ? Colors.grey[300] : Colors.white,
                    title: Text(
                      income.source,
                      style: const TextStyle(color: Colors.black),
                    ),
                    trailing: Text(
                      '${currencySymbol.value}${income.amount}',
                      style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: Dimensions.font15,
                      ),
                    ),
                    onLongPress: () {
                      setState(() {
                        isMultiSelectionEnabled = true;
                        if (isSelected) {
                          selectedIncomeItems.remove(index);
                        } else {
                          selectedIncomeItems.add(index);
                        }
                      });
                    },
                    onTap: () {
                      if (isMultiSelectionEnabled) {
                        setState(() {
                          if (isSelected) {
                            selectedIncomeItems.remove(index);
                          } else {
                            selectedIncomeItems.add(index);
                          }
                          if (selectedIncomeItems.isEmpty) {
                            isMultiSelectionEnabled = false;
                          }
                        });
                      }
                    },
                  );
                },
              )
            : Padding(
                padding: EdgeInsets.only(
                    top: Dimensions.height8, left: Dimensions.width8),
                child: const Text(
                  'No incomes for this day.',
                  style: TextStyle(color: Colors.black87),
                ),
              ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isMultiSelectionEnabled
          ? AppBar(
              backgroundColor: Colors.purple[200],
              elevation: 0,
            )
          : null,
      body: Column(
        children: [
          // Date Selector
          // Data Display Section
          Expanded(
            child: isLoading
                ? const LoadingDialog()
                : (expensesList.isEmpty && incomesList.isEmpty)
                    ? emptyLayout()
                    : SingleChildScrollView(
                        child: Column(
                          children: [
                            // Incomes Section
                            incomesSection(context),
                            // Expenses Section
                            expensesSection(context),
                          ],
                        ),
                      ),
          ),
        ],
      ),
      // Floating Action Button to Add Transaction
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.purple[200],
        shape: const CircleBorder(),
        child: Icon(
          Icons.add,
          size: Dimensions.icon35,
          color: Colors.white,
        ),
      ),
    );
  }
}
