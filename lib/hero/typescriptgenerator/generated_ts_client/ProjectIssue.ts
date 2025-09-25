export interface ProjectIssue {
  title?: string;
  project_id?: number;
  issue_type?: string;
  priority?: string;
  status?: string;
  swimlane?: string;
  assignees?: any[];
  reporter?: number;
  milestone?: string;
  deadline?: number;
  estimate?: number;
  fs_files?: any[];
  parent_id?: number;
  children?: any[];
  // Properties from Base are inherited
}
