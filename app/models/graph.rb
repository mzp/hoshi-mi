class Graph < ActiveRecord::Base
  has_many :logs
  belongs_to :created_by, :class_name => :User
  attr_accessible :color, :name, :secret, :section, :service, :id, :created_by_id, :created_at, :updated_at

  validates_format_of :service, :with => /[\w]+/
  validates_format_of :section, :with => /[\w]+/
  validates_format_of :name, :with => /[\w]+/

  before_create :on_create

  def owner?(user)
    return false if user.nil? or created_by.nil? or user.id.nil? or created_by.id.nil?
    user.id == created_by.id
  end

  def as_json(options = {})
    if not options.has_key?(:current_user) or not owner?(options[:current_user])
      options[:except] ||= :secret
    end
    super(options)
  end

  def logs_by(resolution)
    xs = logs.group_by{|item|
      case resolution
      when :hour
        item.happened_at.change(:min=>0)
      when :day
        item.happened_at.beginning_of_day
      when :month
        item.happened_at.beginning_of_month
      end
    }.map{|key, values|
      ys = values.map{|v| v.number }
      [ key, ys.sum / ys.size ]
    }.sort_by{|item|
      item.first
    }
  end

  private
  def on_create
    self.color = '#0000ff' if self.color.blank?
    self.secret = random_str
  end

  def random_str
    UUIDTools::UUID.random_create.to_s.delete("-")
  end

end
