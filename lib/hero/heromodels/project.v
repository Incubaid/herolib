module heromodels

import crypto.blake3
import json

// Project represents a collection of issues organized in swimlanes
@[heap]
pub struct Project {
pub mut:
    id          string       // blake192 hash
    name        string
    description string
    group_id    string       // Associated group for permissions
    swimlanes   []Swimlane
    milestones  []Milestone
    issues      []string     // IDs of project issues
    fs_files    []string     // IDs of linked files
    status      ProjectStatus
    start_date  i64
    end_date    i64
    created_at  i64
    updated_at  i64
    tags        []string
}

pub struct Swimlane {
pub mut:
    id          string
    name        string
    description string
    order       int
    color       string
    is_done     bool
}

pub struct Milestone {
pub mut:
    id          string
    name        string
    description string
    due_date    i64
    completed   bool
    issues      []string // IDs of issues in this milestone
}

pub enum ProjectStatus {
    planning
    active
    on_hold
    completed
    cancelled
}

pub fn (mut p Project) calculate_id() {
    content := json.encode(ProjectContent{
        name: p.name
        description: p.description
        group_id: p.group_id
        swimlanes: p.swimlanes
        milestones: p.milestones
        issues: p.issues
        fs_files: p.fs_files
        status: p.status
        start_date: p.start_date
        end_date: p.end_date
        tags: p.tags
    })
    hash := blake3.sum256(content.bytes())
    p.id = hash.hex()[..48]
}

struct ProjectContent {
    name        string
    description string
    group_id    string
    swimlanes   []Swimlane
    milestones  []Milestone
    issues      []string
    fs_files    []string
    status      ProjectStatus
    start_date  i64
    end_date    i64
    tags        []string
}

pub fn new_project(name string, description string, group_id string) Project {
    mut project := Project{
        name: name
        description: description
        group_id: group_id
        status: .planning
        created_at: time.now().unix_time()
        updated_at: time.now().unix_time()
        swimlanes: [
            Swimlane{id: 'todo', name: 'To Do', order: 1, color: '#f1c40f'},
            Swimlane{id: 'in_progress', name: 'In Progress', order: 2, color: '#3498db'},
            Swimlane{id: 'done', name: 'Done', order: 3, color: '#2ecc71', is_done: true}
        ]
    }
    project.calculate_id()
    return project
}