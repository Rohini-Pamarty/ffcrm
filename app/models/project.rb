class Project < ActiveRecord::Base
 attr_accessor :calendar

  belongs_to  :user
  belongs_to  :assignee, :class_name => "User", :foreign_key => :assigned_to
  belongs_to  :completor, :class_name => "User", :foreign_key => :completed_by
  belongs_to  :asset, :polymorphic => true
  has_many    :activities, :as => :subject, :order => 'projects.created_at DESC'
scope :my, lambda { |user|
    includes(:assignee).
    where('(user_id = ? AND assigned_to IS NULL) OR assigned_to = ?', user[:user] || user, user[:user] || user).
    order(user[:order] || 'name ASC').
    limit(user[:limit]) # nil selects all records
  }
 scope :assigned_by, lambda { |user|
    includes(:assignee).
    where('user_id = ? AND assigned_to IS NOT NULL AND assigned_to != ?', user.id, user.id)
  }
# Status based scopes to be combined with the due date and completion time.
  scope :pending,       where('completed_at IS NULL').order('projects.due_at, projects.id')
  scope :assigned,      where('completed_at IS NULL AND assigned_to IS NOT NULL').order('projects.due_at, projects.id')
  scope :completed,     where('completed_at IS NOT NULL').order('projects.completed_at DESC')

  # Due date scopes.
  scope :due_asap,      where("due_at IS NULL AND bucket = 'due_asap'").order('projects.id DESC')
  scope :overdue,       where('due_at IS NOT NULL AND due_at < ?', Time.zone.now.midnight.utc).order('projects.id DESC')
  scope :due_today,     where('due_at >= ? AND due_at < ?', Time.zone.now.midnight.utc, Time.zone.now.midnight.tomorrow.utc).order('projects.id DESC')
  scope :due_tomorrow,  where('due_at >= ? AND due_at < ?', Time.zone.now.midnight.tomorrow.utc, Time.zone.now.midnight.tomorrow.utc + 1.day).order('projects.id DESC')
  scope :due_this_week, where('due_at >= ? AND due_at < ?', Time.zone.now.midnight.tomorrow.utc + 1.day, Time.zone.now.next_week.utc).order('projects.id DESC')
  scope :due_next_week, where('due_at >= ? AND due_at < ?', Time.zone.now.next_week.utc, Time.zone.now.next_week.end_of_week.utc + 1.day).order('projects.id DESC')
  scope :due_later,     where("(due_at IS NULL AND bucket = 'due_later') OR due_at >= ?", Time.zone.now.next_week.end_of_week.utc + 1.day).order('projects.id DESC')

  # Completion time scopes.
  scope :completed_today,      where('completed_at >= ? AND completed_at < ?', Time.zone.now.midnight.utc, Time.zone.now.midnight.tomorrow.utc)
  scope :completed_yesterday,  where('completed_at >= ? AND completed_at < ?', Time.zone.now.midnight.yesterday.utc, Time.zone.now.midnight.utc)
  scope :completed_this_week,  where('completed_at >= ? AND completed_at < ?', Time.zone.now.beginning_of_week.utc , Time.zone.now.midnight.yesterday.utc)
  scope :completed_last_week,  where('completed_at >= ? AND completed_at < ?', Time.zone.now.beginning_of_week.utc - 7.days, Time.zone.now.beginning_of_week.utc)
  scope :completed_this_month, where('completed_at >= ? AND completed_at < ?', Time.zone.now.beginning_of_month.utc, Time.zone.now.beginning_of_week.utc - 7.days)
  scope :completed_last_month, where('completed_at >= ? AND completed_at < ?', (Time.zone.now.beginning_of_month.utc - 1.day).beginning_of_month.utc, Time.zone.now.beginning_of_month.utc)


 def self.find_all_grouped(user, view)
	
    settings = (view == "completed" ? Setting.project_completed : Setting.project_bucket)
    Hash[
      settings.map do |key, value|
        [ key, view == "assigned" ? assigned_by(user).send(key).pending : my(user).send(key).send(view) ]
      end
    ]
  end

 # Returns project totals for each of the views as needed by projects sidebar.
  #----------------------------------------------------------------------------
  def self.totals(user, view = "pending")
    settings = (view == "completed" ? Setting.project_completed : Setting.project_bucket)
    settings.inject({ :all => 0 }) do |hash, key|
      hash[key] = (view == "assigned" ? assigned_by(user).send(key).pending.count : my(user).send(key).send(view).count)
      hash[:all] += hash[key]
      hash
    end
  end
end
