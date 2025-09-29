export interface CalendarEvent {
  title?: string;
  start_time?: number;
  end_time?: number;
  registration_desks?: any[];
  attendees?: any[];
  docs?: any[];
  calendar_id?: number;
  status?: string;
  is_all_day?: boolean;
  reminder_mins?: any[];
  color?: string;
  timezone?: string;
  priority?: string;
  public?: boolean;
  locations?: any[];
  is_template?: boolean;
  // Properties from Base are inherited
}
