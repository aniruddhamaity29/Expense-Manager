import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/pages/expense.dart';
import 'package:flutter_application_1/pages/earn.dart';
import 'package:flutter_application_1/utils/dimensions.dart';
import 'package:flutter_application_1/utils/loading.dart';
import 'package:fluttertoast/fluttertoast.dart';
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

    super.initState();
  }

  void checkExpenseAndShowNotification(
      BuildContext context, int income, int expense) {
    if (income < expense) {
      // toastification.show(
      //   context: context, // optional if you use ToastificationWrapper
      //   title: const Text('Please add income!'),
      //   description: const Text(
      //       'Your expenses are significantly higher than your income.'),
      //   autoCloseDuration: const Duration(seconds: 4),
      //   style: ToastificationStyle.flatColored,
      //   applyBlurEffect: true,
      //   icon: const Icon(
      //     Ionicons.warning_outline,
      //     color: Colors.orange,
      //   ),
      //   type: ToastificationType.warning,
      //   pauseOnHover: true,
      // );
      Get.snackbar(
        'Please add income!',
        'Your expenses are significantly higher than your income.',
        icon: const Icon(
          Ionicons.warning_outline,
          color: Colors.orange,
          size: 35,
        ),
        backgroundColor: Colors.white,
        borderWidth: 2,
        borderColor: Colors.amber,
        duration: const Duration(seconds: 3),
      );
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(
      //     content: Text(
      //       'Your expenses are significantly higher than your income!',
      //     ),
      //     backgroundColor: Colors.orange,
      //   ),
      // );
    }
  }

  // Reset savings if the month changes
  void checkMonthlyReset() {
    int currentMonth = currentDate.month;
    int currentYear = currentDate.year;

    if (currentMonth != previousMonth || currentYear != previousYear) {
      stSavings.value = 0; // Reset savings
      sp.setInt('savings_$userId', stSavings.value); // Save updated savings
    }

    // Update previous month and year
    previousMonth = currentMonth;
    previousYear = currentYear;
  }

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
    checkMonthlyReset();
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

        // Check for excessive spending
        checkExpenseAndShowNotification(
            context, stIncome.value, stExpense.value);
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
        title: const Text('Error fetching expenses'),
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
        title: const Text('Error fetching incomes'),
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

  // Add Expense Transaction
  Future<void> addTransaction(String purpose, String amount) async {
    Map data = {
      'purpose': purpose,
      'amount': amount,
      'user_id': userId,
      'date': DateFormat('yyyy-MM-dd').format(currentDate),
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}insert_details.php"),
        body: data,
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == true) {
          purposeController.clear();
          expenseAmountController.clear();
          Fluttertoast.showToast(
            msg: 'Expense added successfully',
            textColor: Colors.white,
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.green,
          );

          fetchAllData(); // Refresh data after adding
        } else {
          toastification.show(
            context: context, // optional if you use ToastificationWrapper
            title: const Text('Failed to add expense'),
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
        }
      } else {
        print('Failed to add expense: ${response.statusCode}');
        Fluttertoast.showToast(
          msg: 'Server error, please try again later',
          textColor: Colors.black,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: const Color.fromARGB(180, 236, 117, 37),
        );
      }
    } catch (e) {
      print('Error adding expense: $e');
      Fluttertoast.showToast(
        msg: 'Network error, please try again later',
        textColor: Colors.black,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: const Color.fromARGB(180, 236, 117, 37),
      );
    }
  }

  // Add Income Transaction
  Future<void> addIncome(String source, String amount) async {
    Map data = {
      'source': source,
      'amount': amount,
      'user_id': userId,
      'date': DateFormat('yyyy-MM-dd').format(currentDate),
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}income_details.php"),
        body: data,
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == true) {
          sourceController.clear();
          incomeAmountController.clear();
          Fluttertoast.showToast(
            msg: 'Income added successfully',
            textColor: Colors.white,
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.green,
          );
          fetchAllData(); // Refresh data after adding
        } else {
          toastification.show(
            context: context, // optional if you use ToastificationWrapper
            title: const Text('Failed to add income'),
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
        }
      } else {
        print('Failed to add income: ${response.statusCode}');
        Fluttertoast.showToast(
          msg: 'Server error, please try again later',
          textColor: Colors.black,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: const Color.fromARGB(180, 236, 117, 37),
        );
      }
    } catch (e) {
      print('Error adding income: $e');
      Fluttertoast.showToast(
        msg: 'Network error, please try again later',
        textColor: Colors.black,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: const Color.fromARGB(180, 236, 117, 37),
      );
    }
  }

  Future<void> editExpense(int id, int oldAmount, String oldPurpose,
      String newAmount, String newPurpose) async {
    final url = Uri.parse('$mainurl/edit_expense.php');

    try {
      var response = await http.post(
        url,
        body: {
          'id': id.toString(),
          'new_amount': newAmount.toString(),
          'new_purpose': newPurpose,
          'user_id': userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == true) {
          purposeController.clear();
          expenseAmountController.clear();

          // Calculate the change in amount
          int oldExpenseAmount = oldAmount;
          int newExpenseAmount = int.parse(newAmount);

          stSavings.value =
              stSavings.value + oldExpenseAmount - newExpenseAmount;

          // Save the updated stSavings to SharedPreferences
          await sp.setInt('savings_$userId', stSavings.value);

          Fluttertoast.showToast(
            msg: 'Expense updated successfully',
            textColor: Colors.white,
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.green,
          );
          fetchAllData(); // Refresh data after updating
        } else {
          toastification.show(
            context: context, // optional if you use ToastificationWrapper
            title: Text(jsonData['msg']),
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
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Server error: ${response.statusCode}',
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred: $e',
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
    }
  }

  HashSet<int> selectedExpenseItems = HashSet<int>();
  HashSet<int> selectedIncomeItems = HashSet<int>();
  bool isMultiSelectionEnabled = false;
  bool selectAllEnabled = false;

  // AppBar actions for editing and deleting selected items
  List<Widget> buildAppBarActions() {
    List<Widget> actions = [];

    if (isMultiSelectionEnabled &&
        (selectedExpenseItems.isNotEmpty || selectedIncomeItems.isNotEmpty)) {
      // Close selection mode
      actions.add(
        IconButton(
          icon: const Icon(
            Icons.close,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              selectedExpenseItems.clear();
              selectedIncomeItems.clear();
              isMultiSelectionEnabled = false;
              selectAllEnabled = false;
            });
          },
        ),
      );

      actions.add(
        TextButton(
          child: Text(
            '${selectedExpenseItems.length + selectedIncomeItems.length} Selected',
            style: const TextStyle(
                fontSize: 20,
                color: Colors.black87,
                fontWeight: FontWeight.normal),
          ),
          onPressed: () {
            if (isMultiSelectionEnabled) {
              setState(() {
                selectedExpenseItems.clear();
                selectedIncomeItems.clear();
              });
            }
          },
        ),
      );

      // Show edit button only if exactly one item is selected
      if ((selectedExpenseItems.length == 1 && selectedIncomeItems.isEmpty) ||
          (selectedIncomeItems.length == 1 && selectedExpenseItems.isEmpty)) {
        actions.add(
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.black),
            onPressed: () {
              setState(() {
                if (selectedExpenseItems.length == 1) {
                  for (int index in selectedExpenseItems) {
                    final expense = expensesList[index];
                    showEditExpenseDialog(context, expense, index);
                  }
                  selectedExpenseItems.clear();
                } else if (selectedIncomeItems.length == 1) {
                  for (int index in selectedIncomeItems) {
                    final income = incomesList[index];
                    showEditIncomeDialog(context, income, index);
                  }

                  selectedIncomeItems.clear();
                }

                isMultiSelectionEnabled = false;
              });
            },
          ),
        );
      }

      // Delete button with confirmation dialog
      actions.add(
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.black),
          onPressed: () {
            showDialog(
              barrierDismissible: false,
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                backgroundColor: Colors.white,
                title: Column(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      size: 50,
                      color: Colors.amber,
                    ),
                    SizedBox(height: Dimensions.height10),
                    const Text(
                      'Delete Confirmation',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'Are you sure you want to delete the selected items? This action cannot be undone.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                  ),
                ),
                actionsAlignment: MainAxisAlignment.spaceEvenly,
                actionsPadding:
                    EdgeInsets.symmetric(vertical: Dimensions.height15),
                actions: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    onPressed: () {
                      setState(() {
                        // Perform deletion logic here
                        if (selectedExpenseItems.isNotEmpty) {
                          List<int> ids = [];
                          List<int> amounts = [];

                          for (int index in selectedExpenseItems) {
                            final expense = expensesList[index];
                            ids.add(expense.id);
                            amounts.add(expense.amount);
                          }

                          deleteExpenses(ids, amounts);
                          selectedExpenseItems.clear();
                        }

                        if (selectedIncomeItems.isNotEmpty) {
                          List<int> incomeIds = [];
                          List<int> incomeAmounts = [];

                          for (int index in selectedIncomeItems) {
                            final income = incomesList[index];
                            incomeIds.add(income.id);
                            incomeAmounts.add(income.amount);
                          }

                          deleteIncomes(incomeIds, incomeAmounts);
                          selectedIncomeItems.clear();
                        }

                        isMultiSelectionEnabled = false;
                        Navigator.pop(context);
                      });
                    },
                    child: const Text(
                      'Delete',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );

      actions.add(
        IconButton(
          icon: const Icon(Icons.date_range,
              color: Colors.black), // Date range icon
          onPressed: () async {
            // Temporarily disable multi-selection mode
            setState(() {
              isMultiSelectionEnabled = false;
            });

            // Check and transfer selected expenses
            if (selectedExpenseItems.isNotEmpty) {
              await transferSelectedExpenses(); // Transfer and delete selected expenses
              selectedExpenseItems.clear(); // Clear selected items locally
            }

            // Check and transfer selected incomes
            if (selectedIncomeItems.isNotEmpty) {
              await transferSelectedIncomes(); // Transfer and delete selected incomes
              selectedIncomeItems.clear(); // Clear selected items locally
            }

            // Refresh data to ensure updated UI
            await fetchAllData();

            // Close the dialog or navigate back
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }

            // Refresh UI after data transfer
            setState(() {});
          },
        ),
      );

      // Select All/Unselect All toggle button
      actions.add(
        IconButton(
          icon: Icon(
            selectAllEnabled ? Icons.check_circle : Icons.check_circle_outline,
            color: Colors.black,
          ),
          onPressed: () {
            setState(() {
              if (selectAllEnabled) {
                selectedExpenseItems.clear();
                selectedIncomeItems.clear();
                isMultiSelectionEnabled = false;
              } else {
                selectedExpenseItems.addAll(
                    List.generate(expensesList.length, (index) => index));
                selectedIncomeItems.addAll(
                    List.generate(incomesList.length, (index) => index));
                isMultiSelectionEnabled = true;
              }
              selectAllEnabled = !selectAllEnabled;
            });
          },
        ),
      );
    }

    return actions;
  }

  void showEditExpenseDialog(BuildContext context, Expense expense, int index) {
    // Pre-fill the controllers with existing data
    expenseAmountController.text = expense.amount.toString();
    purposeController.text = expense.purpose;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: Dimensions.height100,
              child: Image.asset(
                'asset/images/edit-file.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: Dimensions.height10),
            Text(
              'Edit Expense',
              style: TextStyle(
                fontSize: Dimensions.font24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: expenseAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\u20B9',
                ),
              ),
              SizedBox(height: Dimensions.height10),
              TextField(
                controller: purposeController,
                decoration: const InputDecoration(
                  labelText: 'Purpose',
                  prefixText: '📝',
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: EdgeInsets.symmetric(
            horizontal: Dimensions.width10, vertical: Dimensions.height10),
        actions: [
          TextButton(
            onPressed: () {
              expenseAmountController.clear();
              purposeController.clear();
              Navigator.pop(context); // Close the dialog
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              String newAmount = expenseAmountController.text.trim();
              String newPurpose = purposeController.text.trim();

              if (newAmount.isNotEmpty && newPurpose.isNotEmpty) {
                await editExpense(
                  expense.id,
                  expense.amount,
                  expense.purpose,
                  newAmount,
                  newPurpose,
                );

                Navigator.pop(context); // Close the dialog
              } else {
                toastification.show(
                  context: context,
                  title: const Text('Please fill in all fields'),
                  autoCloseDuration: const Duration(seconds: 4),
                  style: ToastificationStyle.flatColored,
                  applyBlurEffect: true,
                  icon: const Icon(
                    Ionicons.close_circle,
                    color: Colors.red,
                  ),
                  type: ToastificationType.error,
                  pauseOnHover: true,
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  } // Widget to build the floating action button

// deleteExpense Function
  Future<void> deleteExpenses(List<int> ids, List<int> amounts) async {
    // Convert the list of IDs into a comma-separated string
    String idString = ids.join(',');

    Map<String, String> data = {
      'id': idString,
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}delete_expense.php"),
        body: data,
      );

      var jsondata = jsonDecode(response.body);

      if (jsondata['status'] == true) {
        print(jsondata);

        // Remove the deleted expenses from the local list and update totals
        setState(() {
          for (int id in ids) {
            expensesList.removeWhere((expense) => expense.id == id);
          }
          // Update the totals for expenses and savings
          for (int amount in amounts) {
            stExpense.value -= amount;
            stSavings.value += amount;
          }
          // Check for excessive spending
          checkExpenseAndShowNotification(
              context, stIncome.value, stExpense.value);
        });

        // Save the updated stSavings to SharedPreferences
        await sp.setInt('savings_$userId', stSavings.value);
        // Provide user feedback
        Fluttertoast.showToast(
          msg: 'Expense deleted successfully',
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.green,
        );
      } else {
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text('Failed to delete expenses: ${jsondata['msg']}'),
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
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(
        msg: 'An error occurred while deleting',
        textColor: Colors.black,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red[200],
      );
    }
  }

  // deleteIncome Function
  Future<void> deleteIncomes(List<int> ids, List<int> amounts) async {
    // Convert the list of IDs into a comma-separated string
    String idString = ids.join(',');

    Map<String, String> data = {
      'id': idString,
    };

    try {
      var response = await http.post(
        Uri.parse("${mainurl}delete_income.php"),
        body: data,
      );

      var jsondata = jsonDecode(response.body);

      if (jsondata['status'] == true) {
        print(jsondata);

        // Remove the deleted incomes from the local list and update totals
        setState(() {
          for (int id in ids) {
            incomesList.removeWhere((income) => income.id == id);
          }
          // Update the totals for income and savings
          for (int amount in amounts) {
            stIncome.value -= amount;
            stSavings.value -=
                amount; // Adjust savings based on the deleted income
          }
          // Check for excessive spending
          checkExpenseAndShowNotification(
              context, stIncome.value, stExpense.value);
        });

        // Save the updated stSavings to SharedPreferences
        await sp.setInt('savings_$userId', stSavings.value);
        // Provide user feedback
        Fluttertoast.showToast(
          msg: 'Income deleted successfully',
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.green,
        );
      } else {
        toastification.show(
          context: context, // optional if you use ToastificationWrapper
          title: Text('Failed to delete income: ${jsondata['msg']}'),
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
      }
    } catch (e) {
      print("Error: $e");
      Fluttertoast.showToast(
        msg: 'An error occurred while deleting',
        textColor: Colors.black,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red[200],
      );
    }
  }

  Future<void> editIncome(int id, int oldAmount, String oldSource,
      String newAmount, String newSource) async {
    final url = Uri.parse('$mainurl/edit_income.php');

    try {
      var response = await http.post(
        url,
        body: {
          'id': id.toString(),
          'new_amount': newAmount.toString(),
          'new_source': newSource,
          'user_id': userId.toString(),
        },
      );

      if (response.statusCode == 200) {
        var jsonData = jsonDecode(response.body);
        if (jsonData['status'] == true) {
          sourceController.clear();
          incomeAmountController.clear();

          // Calculate the change in amount
          int oldIncomeAmount = oldAmount;
          int newIncomeAmount = int.parse(newAmount);

          // Subtract the old income amount from savings, then add the new income amount
          stSavings.value = stSavings.value - oldIncomeAmount + newIncomeAmount;

          // Save the updated stSavings to SharedPreferences
          await sp.setInt('savings_$userId', stSavings.value);
          // Show success message
          Fluttertoast.showToast(
            msg: 'Income updated successfully',
            textColor: Colors.white,
            toastLength: Toast.LENGTH_SHORT,
            backgroundColor: Colors.green,
          );
          fetchAllData(); // Refresh data after updating
        } else {
          toastification.show(
            context: context, // optional if you use ToastificationWrapper
            title: Text(jsonData['msg']),
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
        }
      } else {
        Fluttertoast.showToast(
          msg: 'Server error: ${response.statusCode}',
          textColor: Colors.white,
          toastLength: Toast.LENGTH_SHORT,
          backgroundColor: Colors.red,
        );
      }
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'An error occurred: $e',
        textColor: Colors.white,
        toastLength: Toast.LENGTH_SHORT,
        backgroundColor: Colors.red,
      );
    }
  }

  void showEditIncomeDialog(BuildContext context, Earn income, int index) {
    // Pre-fill the controllers with existing data
    incomeAmountController.text = income.amount.toString();
    sourceController.text = income.source;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        backgroundColor: Colors.white,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: Dimensions.height100,
              child: Image.asset(
                'asset/images/edit-file.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: Dimensions.height10),
            Text(
              'Edit Income',
              style: TextStyle(
                fontSize: Dimensions.font24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: incomeAmountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount',
                  prefixText: '\u20B9',
                ),
              ),
              SizedBox(height: Dimensions.height10),
              TextField(
                controller: sourceController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixText: '📝',
                ),
              ),
            ],
          ),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding: EdgeInsets.symmetric(
            horizontal: Dimensions.width10, vertical: Dimensions.height10),
        actions: [
          TextButton(
            onPressed: () {
              incomeAmountController.clear();
              sourceController.clear();
              Navigator.pop(context); // Close the dialog
            },
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text(
              'Cancel',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              String newAmount = incomeAmountController.text.trim();
              String newSource = sourceController.text.trim();

              if (newAmount.isNotEmpty && newSource.isNotEmpty) {
                await editIncome(
                  income.id,
                  income.amount,
                  income.source,
                  newAmount,
                  newSource,
                );

                Navigator.pop(context); // Close the dialog
              } else {
                toastification.show(
                  context: context,
                  title: const Text('Please fill in all fields'),
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
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              'Save',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  } // Widget to build the floating action button

  Future<void> transferSelectedIncomes() async {
    final DateTime? targetDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (targetDate != null) {
      List<Earn> incomesToTransfer =
          selectedIncomeItems.map((index) => incomesList[index]).toList();

      List<int> ids = [];
      List<int> amounts = [];
      for (Earn income in incomesToTransfer) {
        ids.add(income.id); // Collect the IDs for deletion
        amounts.add(income.amount); // Collect the amounts for updating totals
      }

      // Batch delete selected expenses after collecting all IDs
      await deleteIncomes(ids, amounts);

      // Update `currentDate` to target date before transferring each expense
      DateTime originalDate = currentDate;
      currentDate = targetDate;

      // Transfer each expense to the target date
      for (Earn income in incomesToTransfer) {
        await addIncome(income.source, income.amount.toString());
      }

      // Restore `currentDate` to original date
      currentDate = originalDate;

      // Refresh data for both dates
      // await fetchAllData(); // Refresh for the original date
      // currentDate = targetDate; // Update to the new date
      formattedDate = DateFormat('MMMM dd, yyyy').format(currentDate);
      await fetchAllData(); // Fetch data for the new date
    }
  }

  Future<void> transferSelectedExpenses() async {
    final DateTime? targetDate = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );

    if (targetDate != null) {
      List<Expense> expensesToTransfer =
          selectedExpenseItems.map((index) => expensesList[index]).toList();

      List<int> ids = [];
      List<int> amounts = [];
      for (Expense expense in expensesToTransfer) {
        ids.add(expense.id); // Collect the IDs for deletion
        amounts.add(expense.amount); // Collect the amounts for updating totals
      }

      // Batch delete selected expenses after collecting all IDs
      await deleteExpenses(ids, amounts);

      // Update `currentDate` to target date before transferring each expense
      DateTime originalDate = currentDate;
      currentDate = targetDate;

      // Transfer each expense to the target date
      for (Expense expense in expensesToTransfer) {
        await addTransaction(expense.purpose, expense.amount.toString());
      }

      // Restore `currentDate` to original date
      currentDate = originalDate;

      // Refresh data for both dates
      // await fetchAllData(); // Refresh for the original date
      // currentDate = targetDate; // Update to the new date
      formattedDate = DateFormat('MMMM dd, yyyy').format(currentDate);
      await fetchAllData(); // Fetch data for the new date
    }
  }

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

  void showAddTransactionModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      sheetAnimationStyle: AnimationStyle(
        duration: const Duration(milliseconds: 800),
      ),
      isScrollControlled: true, // For keyboard to adjust
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: Dimensions.height15,
                left: Dimensions.width15,
                right: Dimensions.width15,
              ),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Toggle between Income and Expense
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setStateModal(() {
                                  isIncomeSelected = false;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !isIncomeSelected
                                    ? Colors.blue
                                    : Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: Text(
                                'Income (Credit)',
                                style: TextStyle(
                                    color: !isIncomeSelected
                                        ? Colors.white
                                        : Colors.black26),
                              ),
                            ),
                          ),
                          SizedBox(width: Dimensions.width10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                setStateModal(() {
                                  isIncomeSelected = true;
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isIncomeSelected
                                    ? Colors.blue
                                    : Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30.0),
                                ),
                              ),
                              child: Text(
                                'Expense (Debit)',
                                style: TextStyle(
                                    color: isIncomeSelected
                                        ? Colors.white
                                        : Colors.black26),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Dimensions.height20),
                      // Input Fields based on selection
                      isIncomeSelected
                          ? Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller:
                                        purposeController, // Set the controller
                                    keyboardType: TextInputType.text,
                                    decoration: const InputDecoration(
                                      hintText: 'Purpose',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),
                                    style: const TextStyle(color: Colors.black),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the purpose';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: Dimensions.width20),
                                Expanded(
                                  child: TextFormField(
                                    controller:
                                        expenseAmountController, // Set the controller
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'Amount',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: Icon(Ionicons.wallet_outline),
                                    ),
                                    style: const TextStyle(color: Colors.black),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the amount';
                                      }
                                      int? parsedValue = int.tryParse(value);
                                      if (parsedValue == null) {
                                        return 'Please enter a valid number';
                                      }
                                      if (parsedValue < 0) {
                                        return 'Amount cannot be negative';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller:
                                        sourceController, // Set the controller
                                    keyboardType: TextInputType.text,

                                    decoration: const InputDecoration(
                                      hintText: 'Description',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: Icon(Icons.category_outlined),
                                    ),

                                    style: const TextStyle(color: Colors.black),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the description';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                SizedBox(width: Dimensions.width20),
                                Expanded(
                                  child: TextFormField(
                                    controller:
                                        incomeAmountController, // Set the controller
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: 'Amount',
                                      hintStyle: TextStyle(color: Colors.grey),
                                      prefixIcon: Icon(Ionicons.wallet_outline),
                                    ),
                                    style: const TextStyle(color: Colors.black),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Please enter the amount';
                                      }
                                      int? parsedValue = int.tryParse(value);
                                      if (parsedValue == null) {
                                        return 'Please enter a valid number';
                                      }
                                      if (parsedValue < 0) {
                                        return 'Amount cannot be negative';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ),
                      SizedBox(height: Dimensions.height25),
                      // Submit Button
                      ElevatedButton(
                        onPressed: () {
                          if (formKey.currentState!.validate()) {
                            if (isIncomeSelected) {
                              addTransaction(
                                purposeController.text,
                                expenseAmountController.text,
                              );
                            } else {
                              addIncome(
                                sourceController.text,
                                incomeAmountController.text,
                              );
                            }
                            Navigator.pop(context); // Close the modal
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize:
                              Size(Dimensions.width200, Dimensions.height40),
                          backgroundColor: Colors.purple[400],
                        ),
                        child: Text(
                          'Submit',
                          style: TextStyle(
                              fontSize: Dimensions.font18, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Function to select date
  Future<void> selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
    );
    if (picked != null && picked != currentDate) {
      setState(() {
        currentDate = picked;
        formattedDate = DateFormat('MMMM dd, yyyy').format(currentDate);
      });
      checkMonthlyReset();
      fetchAllData(); // Fetch data for the new date
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: isMultiSelectionEnabled
          ? AppBar(
              actions: buildAppBarActions(),
              backgroundColor: Colors.purple[200],
              elevation: 0,
            )
          : null,
      body: Column(
        children: [
          // Date Selector
          Container(
            color: const Color.fromARGB(
                255, 231, 171, 241), // Background color to match your design
            child: Row(
              children: [
                // Previous Day Button
                IconButton(
                  onPressed: () {
                    setState(() {
                      currentDate =
                          currentDate.subtract(const Duration(days: 1));
                      formattedDate =
                          DateFormat('MMMM dd, yyyy').format(currentDate);
                    });
                    fetchAllData();
                  },
                  icon: Icon(
                    Icons.arrow_back_ios,
                    color: Colors.black,
                    size: Dimensions.icon20,
                  ),
                ),
                // Date Display Section
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Day of the month display with border
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: Dimensions.width6,
                          vertical: Dimensions.height2),
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                Colors.black54), // Border around the dropdown
                        borderRadius:
                            BorderRadius.circular(4), // Rounded corners
                      ),
                      child: GestureDetector(
                        onTap: () => selectDate(context),
                        child: Text(
                          DateFormat('dd').format(currentDate),
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: Dimensions.font24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: Dimensions.width6),
                    // Month and Year display
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('MMMM, yyyy').format(currentDate),
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: Dimensions.font16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE').format(currentDate),
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: Dimensions.font16,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(width: Dimensions.width25),
                // Balance Display Section
                Column(
                  children: [
                    Text(
                      'Savings',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: Dimensions.font14,
                      ),
                    ),
                    Obx(
                      () => SizedBox(
                        width: 70,
                        child: Center(
                          child: AutoSizeText(
                            maxLines: 1,
                            '${currencySymbol.value}${stSavings.value}',
                            style: TextStyle(
                              color: stSavings.value >= 0
                                  ? Colors.green[700]
                                  : Colors.red[900],
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                // Next Day Button
                IconButton(
                  onPressed: () {
                    setState(() {
                      currentDate = currentDate.add(const Duration(days: 1));
                      formattedDate =
                          DateFormat('MMMM dd, yyyy').format(currentDate);
                    });
                    fetchAllData();
                  },
                  icon: Icon(
                    Icons.arrow_forward_ios,
                    color: Colors.black,
                    size: Dimensions.icon20,
                  ),
                ),
              ],
            ),
          ),
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
        onPressed: () {
          showAddTransactionModal(context);
        },
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
