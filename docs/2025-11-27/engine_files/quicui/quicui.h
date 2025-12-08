#ifndef FLUTTER_SHELL_COMMON_QUICUI_QUICUI_H_
#define FLUTTER_SHELL_COMMON_QUICUI_QUICUI_H_

#include "flutter/common/settings.h"
#include "shell/platform/embedder/embedder.h"

namespace flutter {

struct ReleaseVersion {
  std::string version;
  std::string build_number;
};

struct QuicUIConfigArgs {
  std::string code_cache_path;
  std::string app_storage_path;
  std::string release_app_library_path;
  std::string quicui_yaml;
  ReleaseVersion release_version;

  QuicUIConfigArgs(std::string code_cache_path,
                      std::string app_storage_path,
                      std::string release_app_library_path,
                      std::string quicui_yaml,
                      ReleaseVersion release_version)
      : code_cache_path(code_cache_path),
        app_storage_path(app_storage_path),
        release_app_library_path(release_app_library_path),
        quicui_yaml(quicui_yaml),
        release_version(release_version) {}
};

bool ConfigureQuicUI(const QuicUIConfigArgs& args,
                        std::string& patch_path);

void ConfigureQuicUI(std::string code_cache_path,
                        std::string app_storage_path,
                        Settings& settings,
                        const std::string& quicui_yaml,
                        const std::string& version,
                        const std::string& version_code);

}  // namespace flutter

#endif  // FLUTTER_SHELL_COMMON_QUICUI_QUICUI_H_
