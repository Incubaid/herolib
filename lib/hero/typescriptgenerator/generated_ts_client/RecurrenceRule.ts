export interface RecurrenceRule {
  frequency?: string;
  interval?: number;
  until?: number;
  count?: number;
  by_weekday?: any[];
  by_monthday?: any[];
}
