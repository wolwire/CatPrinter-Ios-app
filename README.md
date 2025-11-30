CatPrinter (iOS app)
=====================

This workspace contains two related projects:

- `CatPrinter` — an iOS SwiftUI app (located under `CatPrinter/CatPrinter`) that can pick images, apply dithering (Atkinson and Floyd–Steinberg), and send print commands to a BLE thermal printer.

- `cat-printer-python` — a Python helper package (separate folder at the workspace root) that contains image processing, dithering algorithms, and command/encoding logic for the same thermal printers. That package is available in `../cat-printer-python` and is MIT licensed.

License
-------

This project is licensed under the MIT License — see `LICENSE` for details.

Notes
-----

- BLE printing must be tested on a physical iPhone (the Simulator does not support CoreBluetooth).
- If you use the Python helpers, install the dependencies listed in `cat-printer-python/requirements.txt` (bleak, numpy, opencv-python, ...).

References
----------

- https://github.com/rbaron/catprinter

