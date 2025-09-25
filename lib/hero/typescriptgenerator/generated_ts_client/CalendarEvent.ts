export interface CalendarEvent {
  title?: string;
  start_time?: number;
  end_time?: number;
  location?: string;
  attendees?: any[];
  fs_items?: any[];
  calendar_id?: number;
  status?: string;
  is_all_day?: boolean;
  is_recurring?: boolean;
  recurrence?: any[];
  reminder_mins?: any[];
  color?: string;
  timezone?: string;
  // Properties from Base are inherited
}
