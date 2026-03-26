// lib/src/download/platform.dart
import 'dart:io' show Platform, Process;

class HostPlatform {
  final String os;
  final String arch;

  static const _supportedOs = {'darwin', 'linux'};
  static const _supportedArch = {'arm64', 'x64'};

  HostPlatform({required this.os, required this.arch}) {
    if (!_supportedOs.contains(os)) {
      throw UnsupportedError('Unsupported OS: $os');
    }
    if (!_supportedArch.contains(arch)) {
      throw UnsupportedError('Unsupported architecture: $arch');
    }
  }

  factory HostPlatform.current() {
    final os = Platform.operatingSystem; // 'macos' or 'linux'
    final normalizedOs = os == 'macos' ? 'darwin' : os;

    final arch = _detectArch();
    return HostPlatform(os: normalizedOs, arch: arch);
  }

  String get assetSuffix => '$os-$arch';

  static String _detectArch() {
    // Dart's Platform doesn't expose CPU arch directly.
    // On macOS/Linux, use the dart executable's path or process info.
    // For dart compile exe, the compiled binary runs natively on the host arch.
    // We use a simple heuristic: check pointer size + OS.
    final version = Platform.version; // contains arch info on some platforms
    if (version.contains('arm64') || version.contains('aarch64')) {
      return 'arm64';
    }
    if (version.contains('x86_64') ||
        version.contains('x64') ||
        version.contains('amd64')) {
      return 'x64';
    }
    // Fallback: check process result
    return _detectArchFromUname();
  }

  static String _detectArchFromUname() {
    try {
      final result = Process.runSync('uname', ['-m']);
      final machine = (result.stdout as String).trim();
      if (machine == 'arm64' || machine == 'aarch64') return 'arm64';
      if (machine == 'x86_64') return 'x64';
      throw UnsupportedError('Unknown architecture: $machine');
    } catch (e) {
      if (e is UnsupportedError) rethrow;
      throw UnsupportedError('Cannot detect architecture');
    }
  }
}
