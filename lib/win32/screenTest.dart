import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

// 定义回调函数的类型
typedef MonitorEnumProc = Int32 Function(
    IntPtr hMonitor, IntPtr hdcMonitor, Pointer<NativeType> lprcMonitor, IntPtr dwData);

// Dart 版本的函数签名
typedef MonitorEnumProcDart = int Function(
    int hMonitor, int hdcMonitor, Pointer<NativeType> lprcMonitor, int dwData);

void main() {
  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

  // 使用 EnumDisplayMonitors 枚举所有显示器
  EnumDisplayMonitors(
    NULL,
    nullptr,
    Pointer.fromFunction<MonitorEnumProc>(monitorEnumProc, 0),
    0,
  );

  // 打印所有显示器的信息
}

// 回调函数，用于处理每个显示器的信息
int monitorEnumProc(int hMonitor, int hdcMonitor, Pointer<NativeType> lprcMonitor, int dwData) {
  final monitorInfo = calloc<MONITORINFO>();
  monitorInfo.ref.cbSize = sizeOf<MONITORINFO>();

  // 获取显示器信息
  GetMonitorInfo(hMonitor, monitorInfo);

  final width = monitorInfo.ref.rcMonitor.right - monitorInfo.ref.rcMonitor.left;
  final height = monitorInfo.ref.rcMonitor.bottom - monitorInfo.ref.rcMonitor.top;

  // 打印显示器信息
  print('Monitor: Width = $width, Height = $height');

  calloc.free(monitorInfo);
  return 1; // 返回 1 继续枚举
}
