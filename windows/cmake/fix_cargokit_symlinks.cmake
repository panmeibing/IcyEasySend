# Patch cargokit resolve_symlinks.ps1 in plugin symlinks.
# AppData and other system folders are hidden; Get-Item needs -Force on Windows.
set(_cargokit_fix_script "${CMAKE_CURRENT_LIST_DIR}/resolve_symlinks.ps1")
file(GLOB _cargokit_scripts
  "${CMAKE_CURRENT_SOURCE_DIR}/flutter/ephemeral/.plugin_symlinks/*/cargokit/cmake/resolve_symlinks.ps1")
foreach(_script ${_cargokit_scripts})
  configure_file("${_cargokit_fix_script}" "${_script}" COPYONLY)
endforeach()
