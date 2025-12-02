#!/usr/bin/env -S v -n -w -cg -gc none  -cc tcc -d use_openssl -enable-globals run

import incubaid.herolib.web.doctree.meta

import incubaid.herolib.core.playbook
import incubaid.herolib.ui.console

// Comprehensive HeroScript for testing multi-level navigation depths
const test_heroscript_nav_depth = '
!!site.config
    name: "nav_depth_test"
    title: "Navigation Depth Test Site"
    description: "Testing multi-level nested navigation"
    tagline: "Deep navigation structures"

!!site.navbar
    title: "Nav Depth Test"

!!site.navbar_item
    label: "Home"
    to: "/"
    position: "left"

// ============================================================
// LEVEL 1: Simple top-level category
// ============================================================
!!site.page_category
    path: "Why"
    collapsible: true
    collapsed: false

//COLLECTION WILL BE REPEATED, HAS NO INFLUENCE ON NAVIGATION LEVELS
!!site.page src: "mycollection:intro"
    label: "Why Choose Us"
    title: "Why Choose Us"
    description: "Reasons to use this platform"

!!site.page src: "benefits"
    label: "Key Benefits"
    title: "Key Benefits"
    description: "Main benefits overview"

// ============================================================
// LEVEL 1: Simple top-level category
// ============================================================
!!site.page_category
    path: "Tutorials"
    collapsible: true
    collapsed: false

!!site.page src: "getting_started"
    label: "Getting Started"
    title: "Getting Started"
    description: "Basic tutorial to get started"

!!site.page src: "first_steps"
    label: "First Steps"
    title: "First Steps"
    description: "Your first steps with the platform"

// ============================================================
// LEVEL 3: Three-level nested category (Tutorials > Operations > Urgent)
// ============================================================
!!site.page_category
    path: "Tutorials/Operations/Urgent"
    collapsible: true
    collapsed: false

!!site.page src: "emergency_restart"
    label: "Emergency Restart"
    title: "Emergency Restart"
    description: "How to emergency restart the system"

!!site.page src: "critical_fixes"
    label: "Critical Fixes"
    title: "Critical Fixes"
    description: "Apply critical fixes immediately"

!!site.page src: "incident_response"
    label: "Incident Response"
    title: "Incident Response"
    description: "Handle incidents in real-time"

// ============================================================
// LEVEL 2: Two-level nested category (Tutorials > Operations)
// ============================================================
!!site.page_category
    path: "Tutorials/Operations"
    collapsible: true
    collapsed: false

!!site.page src: "daily_checks"
    label: "Daily Checks"
    title: "Daily Checks"
    description: "Daily maintenance checklist"

!!site.page src: "monitoring"
    label: "Monitoring"
    title: "Monitoring"
    description: "System monitoring procedures"

!!site.page src: "backups"
    label: "Backups"
    title: "Backups"
    description: "Backup and restore procedures"

// ============================================================
// LEVEL 1: One-to-two level (Tutorials)
// ============================================================
// Note: This creates a sibling at the Tutorials level (not nested deeper)
!!site.page src: "advanced_concepts"
    label: "Advanced Concepts"
    title: "Advanced Concepts"
    description: "Deep dive into advanced concepts"

!!site.page src: "troubleshooting"
    label: "Troubleshooting"
    title: "Troubleshooting"
    description: "Troubleshooting guide"

// ============================================================
// LEVEL 2: Two-level nested category (Why > FAQ)
// ============================================================
!!site.page_category
    path: "Why/FAQ"
    collapsible: true
    collapsed: false

!!site.page src: "general"
    label: "General Questions"
    title: "General Questions"
    description: "Frequently asked questions"

!!site.page src: "pricing_questions"
    label: "Pricing"
    title: "Pricing Questions"
    description: "Questions about pricing"

!!site.page src: "technical_faq"
    label: "Technical FAQ"
    title: "Technical FAQ"
    description: "Technical frequently asked questions"

!!site.page src: "support_faq"
    label: "Support"
    title: "Support FAQ"
    description: "Support-related FAQ"

// ============================================================
// LEVEL 4: Four-level nested category (Tutorials > Operations > Database > Optimization)
// ============================================================
!!site.page_category
    path: "Tutorials/Operations/Database/Optimization"
    collapsible: true
    collapsed: false

!!site.page src: "query_optimization"
    label: "Query Optimization"
    title: "Query Optimization"
    description: "Optimize your database queries"

!!site.page src: "indexing_strategy"
    label: "Indexing Strategy"
    title: "Indexing Strategy"
    description: "Effective indexing strategies"

!!site.page_category
    path: "Tutorials/Operations/Database"
    collapsible: true
    collapsed: false

!!site.page src: "configuration"
    label: "Configuration"
    title: "Database Configuration"
    description: "Configure your database"

!!site.page src: "replication"
    label: "Replication"
    title: "Database Replication"
    description: "Set up database replication"

'

fn check(s2 meta.Site) {

	// assert s == s2
}


// ========================================================
// SETUP: Create and process playbook
// ========================================================
console.print_item('Creating playbook from HeroScript')
mut plbook := playbook.new(text: test_heroscript_nav_depth)!
console.print_green('✓ Playbook created')
console.lf()

console.print_item('Processing site configuration')
meta.play(mut plbook)!
console.print_green('✓ Site processed')
console.lf()

console.print_item('Retrieving configured site')
mut nav_site := meta.get(name: 'nav_depth_test')!
console.print_green('✓ Site retrieved')
console.lf()

// check(nav_site)
