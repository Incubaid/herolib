module giteaclient

import time

pub struct APIError {
pub:
	message string
	url     string
}

pub struct AccessToken {
pub:
	id               i64
	name             string
	scopes           []string
	sha1             string
	token_last_eight string
}

pub struct ActionVariable {
pub:
	owner_id i64
	repo_id  i64
	name     string
	data     string
}

pub struct Activity {
pub:
	act_user    User
	act_user_id i64
	comment     Comment
	comment_id  i64
	content     string
	created     time.Time
	id          i64
	is_private  bool
	op_type     string
	ref_name    string
	repo        Repository
	repo_id     i64
	user_id     i64
}

pub struct AddCollaboratorOption {
pub:
	permission string
}

pub struct AddTimeOption {
pub:
	time      i64
	created   time.Time
	user_name string
}

pub struct AnnotatedTagObject {
pub:
	sha string
	typ string @[json: 'type'] // `type` is a keyword in V
	url string
}

pub struct AnnotatedTag {
pub:
	message      string
	object       AnnotatedTagObject
	sha          string
	tag          string
	tagger       CommitUser
	url          string
	verification PayloadCommitVerification
}

pub struct Attachment {
pub:
	browser_download_url string
	created_at           time.Time
	download_count       i64
	id                   i64
	name                 string
	size                 i64
	uuid                 string
}

pub struct Badge {
pub:
	id          i64
	slug        string
	description string
	image_url   string
}

pub struct Branch {
pub:
	commit                           PayloadCommit
	effective_branch_protection_name string
	enable_status_check              bool
	name                             string
	protected                        bool
	required_approvals               i64
	status_check_contexts            []string
	user_can_merge                   bool
	user_can_push                    bool
}

pub struct BranchProtection {
pub:
	branch_name                       string
	rule_name                         string
	enable_push                       bool
	enable_push_whitelist             bool
	push_whitelist_usernames          []string
	push_whitelist_teams              []string
	push_whitelist_deploy_keys        bool
	enable_merge_whitelist            bool
	merge_whitelist_usernames         []string
	merge_whitelist_teams             []string
	enable_status_check               bool
	status_check_contexts             []string
	required_approvals                i64
	enable_approvals_whitelist        bool
	approvals_whitelist_username      []string
	approvals_whitelist_teams         []string
	block_on_rejected_reviews         bool
	block_on_official_review_requests bool
	block_on_outdated_branch          bool
	dismiss_stale_approvals           bool
	ignore_stale_approvals            bool
	require_signed_commits            bool
	protected_file_patterns           string
	unprotected_file_patterns         string
	created_at                        time.Time
	updated_at                        time.Time
}

pub struct ChangeFileOperation {
pub:
	operation string // "create", "update", "delete"
	path      string
	content   string // base64 encoded
	from_path string
	sha       string
}

pub struct ChangeFilesOptions {
pub:
	author     Identity
	branch     string
	committer  Identity
	dates      CommitDateOptions
	files      []ChangeFileOperation
	message    string
	new_branch string
	signoff    bool
}

pub struct ChangedFile {
pub:
	additions         i64
	changes           i64
	contents_url      string
	deletions         i64
	filename          string
	html_url          string
	previous_filename string
	raw_url           string
	status            string
}

pub struct Commit {
pub:
	author    User
	commit    RepoCommit
	committer User
	created   time.Time
	files     []CommitAffectedFiles
	html_url  string
	parents   []CommitMeta
	sha       string
	stats     CommitStats
	url       string
}

pub struct CommitAffectedFiles {
pub:
	filename string
	status   string
}

pub struct CommitDateOptions {
pub:
	author    time.Time
	committer time.Time
}

pub struct CommitMeta {
pub:
	created time.Time
	sha     string
	url     string
}

pub struct CommitStats {
pub:
	additions i64
	deletions i64
	total     i64
}

pub struct CommitUser {
pub:
	date  string
	email string
	name  string
}

pub struct Comment {
pub:
	assets             []Attachment
	body               string
	created_at         time.Time
	html_url           string
	id                 i64
	issue_url          string
	original_author    string
	original_author_id i64
	pull_request_url   string
	updated_at         time.Time
	user               User
}

pub struct CreateIssueOption {
pub:
	title     string
	assignee  string
	assignees []string
	body      string
	closed    bool
	due_date  time.Time
	labels    []i64
	milestone i64
	ref       string
}

pub struct CreateRepoOption {
pub:
	name               string
	auto_init          bool
	default_branch     string
	description        string
	gitignores         string
	issue_labels       string
	license            string
	object_format_name string // "sha1" or "sha256"
	private            bool
	readme             string
	template           bool
	trust_model        string // "default", "collaborator", "committer", "collaboratorcommitter"
}

pub struct Identity {
pub:
	email string
	name  string
}

pub struct InternalTracker {
pub:
	allow_only_contributors_to_track_time bool
	enable_issue_dependencies             bool
	enable_time_tracker                   bool
}

pub struct Issue {
pub:
	id                 i64
	url                string
	html_url           string
	number             i64
	user               User
	original_author    string
	original_author_id i64
	title              string
	body               string
	ref                string
	labels             []Label
	milestone          Milestone
	assignee           User
	assignees          []User
	state              string // StateType
	is_locked          bool
	comments           i64
	created_at         time.Time
	updated_at         time.Time
	closed_at          time.Time
	due_date           time.Time
	pull_request       PullRequestMeta
	repository         RepositoryMeta
	assets             []Attachment
	pin_order          i64
}

pub struct Label {
pub:
	id          i64
	name        string
	exclusive   bool
	is_archived bool
	color       string
	description string
	url         string
}

pub struct Milestone {
pub:
	id            i64
	title         string
	description   string
	state         string // StateType
	open_issues   i64
	closed_issues i64
	created_at    time.Time
	updated_at    time.Time
	closed_at     time.Time
	due_on        time.Time
}

pub struct Organization {
pub:
	avatar_url                    string
	description                   string
	email                         string
	full_name                     string
	id                            i64
	location                      string
	name                          string
	repo_admin_change_team_access bool
	username                      string
	visibility                    string
	website                       string
}

pub struct PayloadCommitVerification {
pub:
	payload   string
	reason    string
	signature string
	signer    PayloadUser
	verified  bool
}

pub struct PayloadCommit {
pub:
	added        []string
	author       PayloadUser
	committer    PayloadUser
	id           string
	message      string
	modified     []string
	removed      []string
	timestamp    time.Time
	url          string
	verification PayloadCommitVerification
}

pub struct PayloadUser {
pub:
	email    string
	name     string
	username string
}

pub struct Permission {
pub:
	admin bool
	pull  bool
	push  bool
}

pub struct PullRequestMeta {
pub:
	merged    bool
	merged_at time.Time
	draft     bool
	html_url  string
}

pub struct RepoCommit {
pub:
	author       CommitUser
	committer    CommitUser
	message      string
	tree         CommitMeta
	url          string
	verification PayloadCommitVerification
}

pub struct Repository {
pub:
	id                                i64
	owner                             User
	name                              string
	full_name                         string
	description                       string
	empty                             bool
	private                           bool
	fork                              bool
	template                          bool
	parent_id                         i64
	mirror                            bool
	size                              i64
	language                          string
	languages_url                     string
	html_url                          string
	url                               string
	link                              string
	ssh_url                           string
	clone_url                         string
	website                           string
	stars_count                       i64
	forks_count                       i64
	watchers_count                    i64
	open_issues_count                 i64
	open_pr_counter                   i64
	release_counter                   i64
	default_branch                    string
	archived                          bool
	created_at                        time.Time
	updated_at                        time.Time
	archived_at                       time.Time
	permissions                       Permission
	has_issues                        bool
	internal_tracker                  InternalTracker
	has_wiki                          bool
	has_pull_requests                 bool
	has_projects                      bool
	has_releases                      bool
	has_packages                      bool
	has_actions                       bool
	ignore_whitespace_conflicts       bool
	allow_merge_commits               bool
	allow_rebase                      bool
	allow_rebase_explicit             bool
	allow_squash_merge                bool
	allow_fast_forward_only_merge     bool
	allow_rebase_update               bool
	default_delete_branch_after_merge bool
	default_merge_style               string
	default_allow_maintainer_edit     bool
	avatar_url                        string
	internal                          bool
	mirror_interval                   string
	mirror_updated                    time.Time
	repo_transfer                     RepoTransfer
}

pub struct RepositoryMeta {
pub:
	id        i64
	name      string
	owner     string
	full_name string
}

pub struct Team {
pub:
	can_create_org_repo       bool
	description               string
	id                        i64
	includes_all_repositories bool
	name                      string
	organization              Organization
	permission                string
	units                     []string
	units_map                 map[string]string
}

pub struct RepoTransfer {
pub:
	doer      User
	recipient User
	teams     []Team
}

pub struct User {
pub:
	id                  i64
	login               string
	full_name           string
	email               string
	avatar_url          string
	language            string
	is_admin            bool
	last_login          time.Time
	created             time.Time
	restricted          bool
	active              bool
	prohibit_login      bool
	location            string
	website             string
	description         string
	visibility          string
	followers_count     i64
	following_count     i64
	starred_repos_count i64
	username            string
}
