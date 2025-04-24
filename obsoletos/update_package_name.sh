#!/bin/bash

# Find all Dart files and update the import statements
find . -name "*.dart" -type f -exec sed -i 's/package:preparatorio_concursos\//package:concursos_ia\//g' {} \;

echo "Package name updated in all Dart files."
