import 'package:flutter/material.dart';

/// Phase 7: State Management UI Patterns
/// 16 widgets for managing UI states, loading, errors, and user feedback

enum StatusType { active, inactive, pending, error, success }

class LoadingStateWidget extends StatelessWidget {
  final double? size;
  final Color? color;
  final String? message;

  const LoadingStateWidget({
    Key? key,
    this.size = 50,
    this.color,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              color ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
        if (message != null) ...[
          SizedBox(height: 16),
          Text(
            message!,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class ErrorStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorStateWidget({
    Key? key,
    this.title = 'Error',
    this.message = 'Something went wrong',
    this.onRetry,
    this.icon = Icons.error_outline,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.red),
          SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh),
              label: Text('Retry'),
            ),
          ],
        ],
      ),
    );
  }
}

class EmptyStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final VoidCallback? onAction;
  final String? actionLabel;

  const EmptyStateWidget({
    Key? key,
    this.title = 'No Data',
    this.message = 'Nothing to display yet',
    this.icon = Icons.inbox,
    this.onAction,
    this.actionLabel = 'Create',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onAction,
              icon: Icon(Icons.add),
              label: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class SkeletonLoader extends StatefulWidget {
  final int itemCount;
  final double height;
  final double width;
  final double borderRadius;

  const SkeletonLoader({
    Key? key,
    this.itemCount = 3,
    this.height = 16,
    this.width = double.infinity,
    this.borderRadius = 8,
  }) : super(key: key);

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(
        widget.itemCount,
        (index) => Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: _SkeletonItem(
            animation: _controller,
            height: widget.height,
            width: widget.width,
            borderRadius: widget.borderRadius,
          ),
        ),
      ),
    );
  }
}

class _SkeletonItem extends StatelessWidget {
  final Animation<double> animation;
  final double height;
  final double width;
  final double borderRadius;

  const _SkeletonItem({
    required this.animation,
    required this.height,
    required this.width,
    required this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          height: height,
          width: width,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: Colors.grey[300],
          ),
          foregroundDecoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                animation.value - 0.3,
                animation.value,
                animation.value + 0.3,
              ],
              colors: [
                Colors.transparent,
                Colors.white.withOpacity(0.3),
                Colors.transparent,
              ],
            ),
          ),
        );
      },
    );
  }
}

class SuccessStateWidget extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onDismiss;
  final Duration duration;

  const SuccessStateWidget({
    Key? key,
    this.title = 'Success',
    this.message = 'Operation completed',
    this.onDismiss,
    this.duration = const Duration(seconds: 3),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 64, color: Colors.green),
          SizedBox(height: 16),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          if (onDismiss != null) ...[
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: onDismiss,
              child: Text('Dismiss'),
            ),
          ],
        ],
      ),
    );
  }
}

class RetryButton extends StatelessWidget {
  final VoidCallback onPressed;
  final String label;
  final bool isLoading;
  final IconData icon;

  const RetryButton({
    Key? key,
    required this.onPressed,
    this.label = 'Retry',
    this.isLoading = false,
    this.icon = Icons.refresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon),
      label: Text(label),
    );
  }
}

class ProgressIndicator extends StatelessWidget {
  final double progress;
  final String? label;
  final bool showPercentage;
  final Color? backgroundColor;
  final Color? progressColor;
  final double height;

  const ProgressIndicator({
    Key? key,
    required this.progress,
    this.label,
    this.showPercentage = true,
    this.backgroundColor,
    this.progressColor,
    this.height = 8,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final percentage = (progress * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null || showPercentage) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (label != null) Text(label!, style: Theme.of(context).textTheme.bodyMedium),
              if (showPercentage) Text('$percentage%', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          SizedBox(height: 8),
        ],
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.clamp(0.0, 1.0),
            minHeight: height,
            backgroundColor: backgroundColor ?? Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final StatusType type;
  final IconData? icon;
  final EdgeInsets padding;

  const StatusBadge({
    Key? key,
    required this.label,
    this.type = StatusType.active,
    this.icon,
    this.padding = const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
  }) : super(key: key);

  Color _getColor() {
    switch (type) {
      case StatusType.active:
        return Colors.green;
      case StatusType.inactive:
        return Colors.grey;
      case StatusType.pending:
        return Colors.orange;
      case StatusType.error:
        return Colors.red;
      case StatusType.success:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: _getColor().withOpacity(0.1),
        border: Border.all(color: _getColor(), width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: _getColor()),
            SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              color: _getColor(),
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class StateTransitionWidget extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const StateTransitionWidget({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 300),
  }) : super(key: key);

  @override
  State<StateTransitionWidget> createState() => _StateTransitionWidgetState();
}

class _StateTransitionWidgetState extends State<StateTransitionWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(StateTransitionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _fadeAnimation, child: widget.child);
  }
}

class DataRefreshWidget extends StatelessWidget {
  final String label;
  final VoidCallback onRefresh;
  final bool isRefreshing;
  final DateTime? lastRefreshTime;

  const DataRefreshWidget({
    Key? key,
    this.label = 'Refresh Data',
    required this.onRefresh,
    this.isRefreshing = false,
    this.lastRefreshTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: Theme.of(context).textTheme.titleSmall),
            if (lastRefreshTime != null)
              Text(
                'Last: ${lastRefreshTime!.hour}:${lastRefreshTime!.minute.toString().padLeft(2, '0')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
          ],
        ),
        SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : Icon(Icons.refresh),
            label: Text(isRefreshing ? 'Refreshing...' : 'Refresh'),
          ),
        ),
      ],
    );
  }
}

class OfflineIndicator extends StatelessWidget {
  final bool isOnline;
  final String onlineMessage;
  final String offlineMessage;

  const OfflineIndicator({
    Key? key,
    required this.isOnline,
    this.onlineMessage = 'Online',
    this.offlineMessage = 'Offline',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isOnline ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        border: Border.all(
          color: isOnline ? Colors.green : Colors.red,
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.cloud_done : Icons.cloud_off,
            color: isOnline ? Colors.green : Colors.red,
            size: 18,
          ),
          SizedBox(width: 8),
          Text(
            isOnline ? onlineMessage : offlineMessage,
            style: TextStyle(
              color: isOnline ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class SyncStatusWidget extends StatelessWidget {
  final bool isSyncing;
  final bool isSynced;
  final String? message;

  const SyncStatusWidget({
    Key? key,
    this.isSyncing = false,
    this.isSynced = false,
    this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;
    String status;

    if (isSyncing) {
      icon = Icons.sync;
      color = Colors.blue;
      status = 'Syncing...';
    } else if (isSynced) {
      icon = Icons.check_circle;
      color = Colors.green;
      status = 'Synced';
    } else {
      icon = Icons.sync_disabled;
      color = Colors.orange;
      status = 'Not Synced';
    }

    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (isSyncing)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation(color)),
            )
          else
            Icon(icon, color: color),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                if (message != null) Text(message!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ValidationIndicator extends StatelessWidget {
  final bool isValid;
  final String? errorMessage;
  final String? successMessage;

  const ValidationIndicator({
    Key? key,
    required this.isValid,
    this.errorMessage,
    this.successMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          isValid ? Icons.check_circle : Icons.cancel,
          color: isValid ? Colors.green : Colors.red,
          size: 20,
        ),
        SizedBox(width: 8),
        Expanded(
          child: Text(
            isValid ? (successMessage ?? 'Valid') : (errorMessage ?? 'Invalid'),
            style: TextStyle(
              color: isValid ? Colors.green : Colors.red,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

class WarningBanner extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;
  final IconData icon;
  final Color? backgroundColor;

  const WarningBanner({
    Key? key,
    required this.message,
    this.onDismiss,
    this.icon = Icons.warning,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.orange.withOpacity(0.1),
        border: Border.all(color: Colors.orange, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.orange),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.orange[900], fontWeight: FontWeight.w500),
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: Icon(Icons.close, size: 18),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
        ],
      ),
    );
  }
}

class InfoPanel extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onAction;
  final String? actionLabel;
  final Color? backgroundColor;

  const InfoPanel({
    Key? key,
    required this.title,
    required this.message,
    this.onAction,
    this.actionLabel,
    this.backgroundColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.blue.withOpacity(0.1),
        border: Border.all(color: Colors.blue, width: 1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[900],
                ),
          ),
          SizedBox(height: 8),
          Text(
            message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.blue[800],
                ),
          ),
          if (onAction != null && actionLabel != null) ...[
            SizedBox(height: 12),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

class ToastNotification extends StatefulWidget {
  final String message;
  final Duration duration;
  final Color? backgroundColor;
  final Color? textColor;
  final VoidCallback? onDismiss;

  const ToastNotification({
    Key? key,
    required this.message,
    this.duration = const Duration(seconds: 3),
    this.backgroundColor,
    this.textColor,
    this.onDismiss,
  }) : super(key: key);

  @override
  State<ToastNotification> createState() => _ToastNotificationState();
}

class _ToastNotificationState extends State<ToastNotification>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _controller.forward();
    Future.delayed(widget.duration, () {
      if (mounted) {
        _controller.reverse().then((_) {
          widget.onDismiss?.call();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: Tween<Offset>(begin: Offset(0, 1), end: Offset.zero).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      ),
      child: Container(
        margin: EdgeInsets.all(16),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.grey[800],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          widget.message,
          style: TextStyle(
            color: widget.textColor ?? Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ===== PHASE 7 WIDGETS BUILDER CLASS =====
class Phase7Widgets {
  static Widget buildLoadingStateWidget(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return LoadingStateWidget(
      size: (properties['size'] as num?)?.toDouble(),
      color: _parseColor(properties['color']),
      message: properties['message'] as String?,
    );
  }

  static Widget buildErrorStateWidget(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return ErrorStateWidget(
      title: properties['title'] as String? ?? 'Error',
      message: properties['message'] as String? ?? 'Something went wrong',
      onRetry: null,
      icon: _parseIconData(properties['icon'] as String? ?? 'error_outline'),
    );
  }

  static Widget buildEmptyStateWidget(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return EmptyStateWidget(
      title: properties['title'] as String? ?? 'No Data',
      message: properties['message'] as String? ?? 'Nothing to display yet',
      icon: _parseIconData(properties['icon'] as String? ?? 'inbox'),
      onAction: null,
      actionLabel: properties['actionLabel'] as String? ?? 'Create',
    );
  }

  static Widget buildSkeletonLoader(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return SkeletonLoader(
      itemCount: (properties['itemCount'] as num?)?.toInt() ?? 3,
      height: (properties['height'] as num?)?.toDouble() ?? 16,
      width: (properties['width'] as num?)?.toDouble() ?? double.infinity,
      borderRadius: (properties['borderRadius'] as num?)?.toDouble() ?? 8,
    );
  }

  static Widget buildSuccessStateWidget(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return SuccessStateWidget(
      title: properties['title'] as String? ?? 'Success',
      message: properties['message'] as String? ?? 'Operation completed',
      onDismiss: null,
      duration: Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 3000),
    );
  }

  static Widget buildRetryButton(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return RetryButton(
      onPressed: () {},
      label: properties['label'] as String? ?? 'Retry',
      isLoading: properties['isLoading'] as bool? ?? false,
      icon: _parseIconData(properties['icon'] as String? ?? 'refresh'),
    );
  }

  static Widget buildProgressIndicator(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return ProgressIndicator(
      progress: (properties['progress'] as num?)?.toDouble() ?? 0.0,
      label: properties['label'] as String?,
      showPercentage: properties['showPercentage'] as bool? ?? true,
      backgroundColor: _parseColor(properties['backgroundColor']),
      progressColor: _parseColor(properties['progressColor']),
      height: (properties['height'] as num?)?.toDouble() ?? 8,
    );
  }

  static Widget buildStatusBadge(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return StatusBadge(
      label: properties['label'] as String? ?? 'Status',
      type: _parseStatusType(properties['type'] as String?),
      icon: properties['icon'] != null ? _parseIconData(properties['icon'] as String) : null,
      padding: _parseEdgeInsets(properties['padding']) ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    );
  }

  static Widget buildStateTransitionWidget(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return StateTransitionWidget(
      child: const SizedBox(),
      duration: Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 300),
    );
  }

  static Widget buildDataRefreshWidget(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return DataRefreshWidget(
      label: properties['label'] as String? ?? 'Refresh Data',
      onRefresh: () {},
      isRefreshing: properties['isRefreshing'] as bool? ?? false,
      lastRefreshTime: null,
    );
  }

  static Widget buildOfflineIndicator(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return OfflineIndicator(
      isOnline: properties['isOnline'] as bool? ?? true,
      onlineMessage: properties['onlineMessage'] as String? ?? 'Online',
      offlineMessage: properties['offlineMessage'] as String? ?? 'Offline',
    );
  }

  static Widget buildSyncStatusWidget(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return SyncStatusWidget(
      isSyncing: properties['isSyncing'] as bool? ?? false,
      isSynced: properties['isSynced'] as bool? ?? false,
      message: properties['message'] as String?,
    );
  }

  static Widget buildValidationIndicator(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return ValidationIndicator(
      isValid: properties['isValid'] as bool? ?? true,
      errorMessage: properties['errorMessage'] as String?,
      successMessage: properties['successMessage'] as String?,
    );
  }

  static Widget buildWarningBanner(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return WarningBanner(
      message: properties['message'] as String? ?? 'Warning',
      onDismiss: null,
      icon: _parseIconData(properties['icon'] as String? ?? 'warning'),
      backgroundColor: _parseColor(properties['backgroundColor']),
    );
  }

  static Widget buildInfoPanel(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return InfoPanel(
      title: properties['title'] as String? ?? 'Information',
      message: properties['message'] as String? ?? 'Info message',
      onAction: null,
      actionLabel: properties['actionLabel'] as String?,
      backgroundColor: _parseColor(properties['backgroundColor']),
    );
  }

  static Widget buildToastNotification(Map<String, dynamic> properties, List<dynamic> childrenData) {
    return ToastNotification(
      message: properties['message'] as String? ?? 'Message',
      duration: Duration(milliseconds: (properties['duration'] as num?)?.toInt() ?? 3000),
      backgroundColor: _parseColor(properties['backgroundColor']),
      textColor: _parseColor(properties['textColor']),
      onDismiss: null,
    );
  }

  // ===== HELPER METHODS =====
  static Color? _parseColor(dynamic value) {
    if (value == null) return null;
    if (value is Color) return value;
    if (value is String) {
      try {
        return Color(int.parse(value.replaceFirst('#', '0xff')));
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  static IconData _parseIconData(String iconName) {
    return switch (iconName) {
      'error_outline' => Icons.error_outline,
      'inbox' => Icons.inbox,
      'refresh' => Icons.refresh,
      'warning' => Icons.warning,
      'check_circle' => Icons.check_circle,
      'sync' => Icons.sync,
      'cloud_off' => Icons.cloud_off,
      'info' => Icons.info,
      _ => Icons.help,
    };
  }

  static EdgeInsets? _parseEdgeInsets(dynamic value) {
    if (value == null) return null;
    if (value is EdgeInsets) return value;
    return null;
  }

  static StatusType _parseStatusType(dynamic value) {
    return switch (value) {
      'active' => StatusType.active,
      'inactive' => StatusType.inactive,
      'pending' => StatusType.pending,
      'error' => StatusType.error,
      'success' => StatusType.success,
      _ => StatusType.active,
    };
  }
}
