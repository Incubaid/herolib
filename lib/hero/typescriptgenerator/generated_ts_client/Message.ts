export interface Message {
  subject?: string;
  message?: string;
  parent?: number;
  author?: number;
  to?: any[];
  cc?: any[];
  send_log?: any[];
  // Properties from Base are inherited
}
