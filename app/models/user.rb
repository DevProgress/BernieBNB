class User < ActiveRecord::Base
  include ActionView::Helpers::NumberHelper
  include ActiveModel::Dirty

  MAX_DOMESTIC_PHONE_NUMBER = 12
  MAX_INTERNATIONAL_PHONE_NUMBER = 14

  validate :phone_number_length
  validates :first_name, presence: true, allow_nil: true
  validates :email, presence: true, allow_nil: true, uniqueness: true
  validates :uid, :session_token, presence: true, uniqueness: true
  validates_format_of :email,
    :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/,
    allow_nil: true
  validate :no_changes_to_email_after_confirmed

  before_create :create_confirmation_token

  after_initialize :ensure_session_token

  has_many :visits, dependent: :destroy

  has_many :hostings, class_name: "Hosting", foreign_key: :host_id, dependent: :destroy

  def self.generate_secure_token
    SecureRandom::urlsafe_base64(16)
  end

  def self.create_with_omniauth(auth)
    if auth["info"]["email"]
      create! do |user|
        user.provider = auth["provider"]
        user.uid = auth["uid"]
        user.email = auth["info"]["email"]
      end
    else
      create! do |user|
        user.provider = auth["provider"]
        user.uid = auth["uid"]
      end
    end
  end

  def phone=(number)
    number = number[1..-1] if number[0] == "1" # Alway remove leading "1".

    if number[0] == "+" # international
      pnumber = number_to_phone(number.gsub(/\D+/, ''))
      super("+" + pnumber)
    else # not international
      pnumber = number_to_phone(number.gsub(/\D+/, ''))
      super(pnumber)
    end
  end

  def phone_number_length
    return if phone.nil?
    if phone.size > MAX_DOMESTIC_PHONE_NUMBER
      if phone[0] == '+' # international +DD XXX XXXXXX (2,3,6 chars)
        if phone.size > MAX_INTERNATIONAL_PHONE_NUMBER
          self.errors.add(:phone, "number is too long: #{phone}")
        elsif phone.size < MAX_INTERNATIONAL_PHONE_NUMBER
          self.errors.add(:phone, "number is too short: #{phone}")
        end
      else # not international
        self.errors.add(:phone, "number is too long: #{phone}")
      end
    elsif phone.size < MAX_DOMESTIC_PHONE_NUMBER
      self.errors.add(:phone, "number is too short: #{phone}")
    end
  end

  def no_changes_to_email_after_confirmed
    if email_changed? && email_confirmed && !email_confirmed_changed?
      self.errors.add(:email, "cannot be changed after being confirmed")
    end
  end

  def reset_session_token!
    self.session_token ||= self.class.generate_secure_token
    self.save!
    self.session_token
  end

  def ensure_session_token
    self.session_token ||= self.class.generate_secure_token
  end

  def create_confirmation_token
    self.confirm_token ||= self.class.generate_secure_token
  end

  def email_activate
    self.email_confirmed = true
    save!(validate: false)
  end
end
