BMCodeScanner
=============

A simple 1D and 2D code scanner using native iOS API. Supports commonly used UPC and QR codes, as well as Code 39, Code 39 mod 43, EAN-13 (including UPC-A), EAN-8, Code 93, Code 128, PDF417, and Aztec.


Run the project for a simple demo, and feel free to reuse `BMCodeScannerView` class in your own projects.

`BMCodeScannerView` class sets up all necessary video frameworks, decodes strings found in the captured codes and passes them on to a delegate, and handles events such as frame changes and device rotation correctly.
