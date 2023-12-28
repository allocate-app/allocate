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
  sidebar,
}

enum ThemeType { system, light, dark, hi_contrast_light, hi_contrast_dark }

enum ToneMapping {
  system,
  soft,
  vivid,
  monochromatic,
  hi_contrast,
  ultra_hi_contrast,
}

enum DeleteSchedule {
  never,
  monthly,
  yearly,
}
