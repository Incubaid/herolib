export interface Profile {
  user_id?: number;
  summary?: string;
  headline?: string;
  location?: string;
  industry?: string;
  picture_url?: string;
  background_image_url?: string;
  email?: string;
  phone?: string;
  website?: string;
  experience?: any[];
  education?: any[];
  skills?: any[];
  languages?: any[];
  // Properties from Base are inherited
}
