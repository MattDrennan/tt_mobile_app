import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart';

class SignUpScreen extends StatefulWidget {
  final int troopid; // Accept troop ID as a parameter

  const SignUpScreen({super.key, required this.troopid});

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  bool showSignUpForm = false; // Controls the visibility of the form
  String? selectedOption =
      'I\'ll be there!'; // Stores the selected option from the dropdown
  String?
      selectedSearchableOption; // Stores the selected value from the searchable dropdown

  final List<String> customOptions = [
    'Option 1',
    'Option 2',
    'Option 3',
    'Option 4',
  ];

  // Define the list of options
  final List<String> options = ['I\'ll be there!', 'Tentative'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButton<String>(
              value: selectedOption, // The currently selected value
              items: options.map((String option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(), // Map options to DropdownMenuItem widgets
              hint: const Text('Choose an option'), // Placeholder text
              onChanged: (String? newValue) {
                setState(() {
                  selectedOption = newValue; // Update the selected option
                });
              },
              isExpanded: true, // Make dropdown take up full width
              underline: Container(
                height: 2,
                color: Colors.blue, // Custom underline color
              ),
            ),
            const SizedBox(height: 16),
            const Text('Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<String>(
              selectedItem: "Menu",
              items: (filter, infiniteScrollProps) =>
                  ["Menu", "Dialog", "Modal", "BottomSheet"],
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: PopupProps.menu(
                  showSearchBox: true, // Enable the search box
                  fit: FlexFit.loose,
                  constraints: BoxConstraints()),
            ),
            const SizedBox(height: 16),
            const Text('Backup Costume:', style: TextStyle(fontSize: 16)),
            DropdownSearch<String>(
              selectedItem: "Menu",
              items: (filter, infiniteScrollProps) =>
                  ["Menu", "Dialog", "Modal", "BottomSheet"],
              decoratorProps: DropDownDecoratorProps(
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              popupProps: PopupProps.menu(
                  showSearchBox: true, // Enable the search box
                  fit: FlexFit.loose,
                  constraints: BoxConstraints()),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (selectedOption == null ||
                    selectedSearchableOption == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Please select both options before signing up!'),
                    ),
                  );
                } else {
                  // Handle sign-up logic
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Signed up for $selectedOption - $selectedSearchableOption!'),
                    ),
                  );
                }
              },
              child: const Text('Sign Up'),
            ),
          ],
        ),
      ),
    );
  }
}
