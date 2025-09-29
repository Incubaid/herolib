export interface PlanningRecurrenceRule {
  until?: number;
  by_weekday?: any[];
  by_monthday?: any[];
  hour_from?: number;
  hour_to?: number;
  duration?: number;
  priority?: number;
}
