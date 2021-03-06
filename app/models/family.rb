class Family < ActiveRecord::Base

  has_many :users
  has_many :events, dependent: :destroy
  has_many :tasks, dependent: :destroy
  has_many :activities, dependent: :destroy
  has_many :meals, dependent: :destroy
  has_one :registration, dependent: :destroy

  validates_presence_of :name, :url
  validates_uniqueness_of :url
  validates_length_of :name, :url, maximum: 256

  def portal_url
    "http://#{Rails.env.development? ? 'localhost:3000' : 'www.ml-family.com'}/my_family/" + url
  end

  def members
    users.order(:dob)
  end

  def parents
    users.where(parent: true).order(:dob)
  end

  def children
    users.where(parent: false).order(:dob)
  end

  def email
    name
  end

  def todays_tasks
     day = User::DAYS_OF_WEEK[Time.now.wday]
     tasks.where("daily = 't' OR #{day} = 't'")
  end

  def other_tasks
    tasks - todays_tasks
  end

  def self.random_id
    Random.new.rand(1000000000..10000000000).to_s
  end
end
