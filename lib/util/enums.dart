enum ModelType { task, subtask, deadline, reminder, routine, group }

enum Priority { low, medium, high }

enum Fade { none, fadeIn, fadeOut }

enum Frequency { once, daily, weekly, monthly, yearly, custom }

enum TaskType { small, large, huge }

enum SortMethod { none, name, due_date, weight, priority, duration }

enum Effect {
  disabled,
  transparent,
  aero,
  acrylic,
  mica,
  sidebar,
}

enum UserStatus { normal, missing, multiple, unknown }

enum ThemeType { system, light, dark }

enum RepeatableState { normal, projected, template, delta }

enum ToneMapping {
  system,
  soft,
  vivid,
  jolly,
  candy,
  monochromatic,
  high_contrast,
  ultra_high_contrast,
}

enum DeleteSchedule {
  never,
  fifteenDays,
  thirtyDays,
  oneYear,
}

enum NotificationAction { set, cancel, clear }
// this is not necessary
// enum NotificationStatus { success, failure }
