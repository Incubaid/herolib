export interface Group {
  members?: any[];
  subgroups?: any[];
  parent_group?: number;
  is_public?: boolean;
  // Properties from Base are inherited
}
