class Visit < ActiveRecord::Base
  validates_date :start_date, on: :create, presence: true
  validate :validate_start_date_is_not_in_the_past, if: :start_date

  validates_date :end_date, on: :create, on_or_after: :start_date
  validates :zipcode, zipcode: { country_code: :es }

  belongs_to :user
  has_many :contacts

  after_validation :geocode

  geocoded_by :zipcode do |visit, results|
    if geo = results.first
      visit.city = geo.city
      visit.state = geo.state
      visit.latitude = geo.latitude
      visit.longitude = geo.longitude
    else
      visit.errors.add(:base, "Unknown Zip Code") unless visit.zipcode.nil?
    end
  end

  acts_as_paranoid

  def validate_start_date_is_not_in_the_past
    errors.add(:start_date, :in_past) unless start_date >= Time.zone.now.beginning_of_day
  end

  def available_hostings(current_user)
    available_hostings = Hosting
      .near(self, 75, order: 'distance')
      .where("start_date <= ?", self.end_date)
      .where("end_date >= ?", self.start_date)

    if Rails.env.production? or Rails.env.staging?
      # :nocov:
      return available_hostings.where("host_id != (?)", self.user_id)
      # :nocov:
    else
      return available_hostings
    end
  end

  def start_and_end_dates
    starting = start_date.strftime("%m/%d/%y")
    ending = end_date.strftime("%m/%d/%y")

    "#{starting} - #{ending}"
  end
end
