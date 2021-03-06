class User < ActiveRecord::Base
  paginates_per 25

  belongs_to :family
  has_many :tasks, dependent: :destroy
  has_many :completions, dependent: :destroy
  has_many :purchases, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :social_medium, dependent: :destroy, class_name: 'SocialMedia'
  has_many :activities, dependent: :destroy
  has_one :social_medium_stat, dependent: :destroy

  validates_presence_of :name
  validates :email, uniqueness: true, format: { with: /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, message: "invalid format" }
  has_secure_password
  validates :pin, numericality: {only_integer: true}, length: {is: 4}

  scope :default_order, -> {order('parent')}

  DAYS_OF_WEEK = ["sunday","monday","tuesday","wednesday","thursday","friday","saturday"]

  def expired?
    ENV['REGISTRATION'] == "1" ? (!activated? && (created_at < (Date.today - 30.days))) : false
  end

  def activated?
    ENV['REGISTRATION'] == "1" ? (family.registration && family.registration.end_date && family.registration.end_date > Date.today) : true
  end

  def clean_up
    date = Time.now.utc - 30.days
    completions.each {|comp| comp.destroy if comp.created_at < date }
    activities.each {|act| act.destroy if act.created_at < date }
  end

  def parent?
    parent
  end

  def child?
    !parent
  end

  def todays_tasks
     day = DAYS_OF_WEEK[Time.now.wday]
     tasks.where("daily = 't' OR #{day} = 't'")
  end

  def other_tasks
    tasks - todays_tasks
  end

  def task_progress
    t = todays_tasks.required
    total = t.count
    completed = t.select{|x| x.completed?}.count

    [completed, total]
  end

  def weekly_task_progress
    t = tasks.required
    completed = 0
    total = (t.where(daily: true).count * 7) + t.where(daily: false).count

    t.each do |task|
      completed += task.completions.where("completed > ?", Date.today.beginning_of_week.to_s).count
    end

    [completed, total]
  end

  def check_allowance
    apply = false
    complete = weekly_task_progress
    if complete[0] == complete[1]
      apply = self.last_allowance < Date.today.beginning_of_week
    end
    apply
  end

  def apply_allowance
    self.update_attributes({credits: (credits || 0) + (allowance || 0), last_allowance: Date.today}) if check_allowance
  end

  def instagram?
    social_medium.where(feed_type: 1).any?
  end

  def instagram
    social_medium.where(feed_type: 1).first
  end

  def facebook?
    social_medium.where(feed_type: 2).any?
  end

  def facebook
    social_medium.where(feed_type: 2).first
  end

  def tumblr?
    social_medium.where(feed_type: 3).any?
  end

  def tumblr
    social_medium.where(feed_type: 3).first
  end

  def twitter?
    social_medium.where(feed_type: 4).any?
  end

  def twitter
    social_medium.where(feed_type: 4).first
  end

  def google?
    social_medium.where(feed_type: 5).any?
  end

  def google
    social_medium.where(feed_type: 5).first
  end

  def pinterest?
    social_medium.where(feed_type: 6).any?
  end

  def pinterest
    social_medium.where(feed_type: 6).first
  end

  def update_social_medium_stats
    stats = self.social_medium_stat || SocialMediumStat.create(user_id: self.id)
    stats.update_data
  end

  def get_token
    unless self.token
      self.update_attribute(:token, generate_token)
    end
    self.token
  end

  def generate_token
    SecureRandom.base64(24)
  end

  def email_stats
    if self.family_id
      stats = self.social_medium_stat
      to = self.family.parents.where(notifications: 1).collect(&:email)
      puts "EMAILING STATS TO -> #{to}"
      ApplicationMailer.social_medium_stats(to, self, stats).deliver if to.any?
    end
  end
end
