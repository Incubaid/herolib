export interface Planning {
  color?: string;
  timezone?: string;
  is_public?: boolean;
  calendar_template_id?: number;
  registration_desk_id?: number;
  autoschedule_rules?: any[];
  invite_rules?: any[];
  attendees_required?: any[];
  attendees_optional?: any[];
  // Properties from Base are inherited
}
