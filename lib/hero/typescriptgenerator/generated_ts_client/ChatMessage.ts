export interface ChatMessage {
  content?: string;
  chat_group_id?: number;
  sender_id?: number;
  parent_messages?: any[];
  fs_files?: any[];
  message_type?: string;
  status?: string;
  reactions?: any[];
  mentions?: any[];
  // Properties from Base are inherited
}
