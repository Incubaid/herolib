export interface Attendee {
  user_id?: number;
  status_latest?: string;
  attendance_required?: boolean;
  admin?: boolean;
  organizer?: boolean;
  location?: string;
  log?: any[];
}
