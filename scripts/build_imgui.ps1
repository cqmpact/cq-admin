$ErrorActionPreference = "Stop"

$root = (Get-Item -LiteralPath $PSScriptRoot).Parent.FullName
$imguiDir = Join-Path $root "imgui"
$outDir = Join-Path $root "html"

$sources = @(
  (Join-Path $root "imgui_app.cpp"),
  (Join-Path $imguiDir "imgui.cpp"),
  (Join-Path $imguiDir "imgui_draw.cpp"),
  (Join-Path $imguiDir "imgui_tables.cpp"),
  (Join-Path $imguiDir "imgui_widgets.cpp"),
  (Join-Path $imguiDir "backends\imgui_impl_glfw.cpp"),
  (Join-Path $imguiDir "backends\imgui_impl_opengl3.cpp")
)

$flags = @(
  "-std=c++17",
  "-O3",
  "-s", "MODULARIZE=1",
  "-s", "EXPORT_NAME=CQAdminImGui",
  "-s", "ALLOW_MEMORY_GROWTH=1",
  "-s", "NO_EXIT_RUNTIME=1",
  "-s", "DISABLE_EXCEPTION_CATCHING=1",
  "-s", "ENVIRONMENT=web",
  "-s", "USE_GLFW=3",
  "-s", "USE_WEBGL2=1",
  "-s", "FULL_ES3=1",
  "-s", "MIN_WEBGL_VERSION=2",
  "-s", "MAX_WEBGL_VERSION=2",
  "-s", "EXPORTED_RUNTIME_METHODS=['ccall','cwrap']"
)

$includes = @(
  "-I", $imguiDir,
  "-I", (Join-Path $imguiDir "backends")
)

$quotedSources = $sources | ForEach-Object { '"' + $_ + '"' }
$quotedIncludes = @(
  "-I", ('"' + $imguiDir + '"'),
  "-I", ('"' + (Join-Path $imguiDir "backends") + '"')
)
$outFile = '"' + (Join-Path $outDir "imgui.js") + '"'

Write-Host "Building ImGui WASM bundle..."
& emcc @quotedSources @quotedIncludes @flags -lembind -o $outFile
Write-Host "Done: html/imgui.js and html/imgui.wasm"
